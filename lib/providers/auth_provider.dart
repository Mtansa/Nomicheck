import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class AuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _userName = '';
  String _userEmail = '';
  String _userId = '';

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String get userName => _userName;
  String get userEmail => _userEmail;
  String get userId => _userId;

  Future<void> checkLoginStatus() async {
    _isLoading = true;
    notifyListeners();

    final session = await AuthService.getSession();
    final loggedIn = await AuthService.isLoggedIn();

    _isLoggedIn = loggedIn && session != null;
    _userName = session?.name ?? '';
    _userEmail = session?.email ?? '';
    _userId = session?.userId ?? '';

    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final session = await AuthService.login(email: email, password: password);
    _isLoggedIn = true;
    _userName = session.name;
    _userEmail = session.email;
    _userId = session.userId;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? position,
    String? company,
  }) async {
    final session = await AuthService.register(
      name: name,
      email: email,
      password: password,
      position: position,
      company: company,
    );
    _isLoggedIn = true;
    _userName = session.name;
    _userEmail = session.email;
    _userId = session.userId;
    notifyListeners();
  }

  Future<void> logout() async {
    final userId = _userId;
    await AuthService.logout();
    if (userId.isNotEmpty) {
      await DatabaseService.deleteShiftsForUser(userId);
    }
    _isLoggedIn = false;
    _userName = '';
    _userEmail = '';
    _userId = '';
    notifyListeners();
  }
}
