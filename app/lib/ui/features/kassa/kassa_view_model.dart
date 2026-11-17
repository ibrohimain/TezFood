import 'dart:async';

import 'package:flutter/services.dart';

import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../safe_notifier.dart';

class KassaViewModel extends SafeNotifier {
  KassaViewModel(this._repository);

  final TezRepository _repository;
  Timer? _timer;
  bool loading = true;
  bool showDone = false;
  String? error;
  List<ShopOrder> orders = [];
  final Set<int> _known = {};
  bool _seenOnce = false;

  int pending = 0;

  Future<void> start() async {
    await refresh();
    _timer ??= Timer.periodic(const Duration(seconds: 4), (_) => refresh(silent: true));
  }

  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      loading = true;
      error = null;
      notifyListeners();
    }
    try {
      final today = DateTime.now();
      final next = await _repository.orders(
        status: showDone ? 'done' : 'new',
        day: showDone ? today : null,
      );
      if (!showDone) {
        _alertNew(next);
        pending = next.length;
      } else {
        final open = await _repository.orders(status: 'new');
        pending = open.length;
      }
      orders = next;
      error = null;
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void _alertNew(List<ShopOrder> next) {
    final ids = next.map((order) => order.id).toSet();
    if (_seenOnce && ids.any((id) => !_known.contains(id))) {
      SystemSound.play(SystemSoundType.alert);
    }
    _known
      ..clear()
      ..addAll(ids);
    _seenOnce = true;
  }

  Future<void> show(bool done) async {
    showDone = done;
    await refresh();
  }

  Future<void> mark(ShopOrder order, String status) async {
    try {
      await _repository.setStatus(order.id, status);
      await refresh(silent: true);
    } on ApiException catch (error) {
      this.error = error.message;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
