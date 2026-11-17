import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionModel extends ChangeNotifier {
  String? adminToken;
  String? kassaToken;
  SharedPreferences? _prefs;

  bool get isAdmin => adminToken != null && adminToken!.isNotEmpty;
  bool get isKassa => isAdmin || (kassaToken != null && kassaToken!.isNotEmpty);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _prefs = prefs;
    adminToken = _clean(prefs.getString('adminToken'));
    kassaToken = _clean(prefs.getString('kassaToken'));
    notifyListeners();
  }

  Future<void> setAdmin(String token) async {
    adminToken = token;
    await _prefs?.setString('adminToken', token);
    notifyListeners();
  }

  Future<void> setKassa(String token) async {
    kassaToken = token;
    await _prefs?.setString('kassaToken', token);
    notifyListeners();
  }

  Future<void> clearAdmin() async {
    adminToken = null;
    await _prefs?.remove('adminToken');
    notifyListeners();
  }

  Future<void> clearKassa() async {
    kassaToken = null;
    await _prefs?.remove('kassaToken');
    notifyListeners();
  }

  String? _clean(String? value) {
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
