import 'package:flutter/foundation.dart';
import '../services/database_service.dart';

class AdminProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _users = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get users => _users;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _users = await DatabaseService.getAllUsers();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
