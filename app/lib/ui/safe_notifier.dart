import 'package:flutter/foundation.dart';

/// So'rov tugaguncha sahifa yopilsa, eshitishni to'xtatadi.
class SafeNotifier extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
