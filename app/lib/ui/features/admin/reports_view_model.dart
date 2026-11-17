import '../../../data/repositories/tez_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../domain/models.dart';
import '../../core/format.dart';
import '../../safe_notifier.dart';

class ReportsViewModel extends SafeNotifier {
  ReportsViewModel(this._repository);

  final TezRepository _repository;

  bool loading = true;
  String? error;
  SalesReport? report;
  String period = 'today';
  String season = currentSeasonKey(DateTime.now());
  DateTime? customFrom;
  DateTime? customTo;

  ReportRange get range {
    final now = DateTime.now();
    if (period == 'custom' && customFrom != null && customTo != null) {
      final from = customFrom!;
      final to = customTo!;
      final start = from.isBefore(to) ? from : to;
      final end = from.isBefore(to) ? to : from;
      return ReportRange(from: start, to: end, label: '${prettyDate(start)} — ${prettyDate(end)}');
    }
    if (period == 'season') return rangeFor(season, now);
    return rangeFor(period, now);
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    final selected = range;
    try {
      report = await _repository.report(selected.from, selected.to);
    } on ApiException catch (error) {
      this.error = error.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> select(String value) async {
    period = value;
    await load();
  }

  Future<void> selectSeason(String value) async {
    period = 'season';
    season = value;
    await load();
  }

  Future<void> selectCustom(DateTime from, DateTime to) async {
    period = 'custom';
    customFrom = from;
    customTo = to;
    await load();
  }
}
