import 'package:shared_preferences/shared_preferences.dart';
import 'api_client.dart';

class AuthSession {
  final String token;
  final String userId;
  final String name;
  final String email;

  const AuthSession({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });
}

class AuthService {
  static const String _keyToken = 'auth_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyIsLoggedIn = 'is_logged_in';

  static final ApiClient _api = ApiClient();

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (prefs.getBool(_keyIsLoggedIn) != true || token == null) return false;

    _api.setToken(token);
    return true;
  }

  static Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) return null;

    _api.setToken(token);
    return AuthSession(
      token: token,
      userId: prefs.getString(_keyUserId) ?? '',
      name: prefs.getString(_keyUserName) ?? '',
      email: prefs.getString(_keyUserEmail) ?? '',
    );
  }

  static Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
    String? position,
    String? company,
  }) async {
    final data = await _api.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
      if (position != null) 'position': position,
      if (company != null) 'company': company,
    });
    return _persistSession(data);
  }

  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _api.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return _persistSession(data);
  }

  static Future<AuthSession> _persistSession(dynamic data) async {
    final token = data['token'] as String;
    final user = data['user'] as Map<String, dynamic>;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUserId, user['id'].toString());
    await prefs.setString(_keyUserName, user['name'] as String);
    await prefs.setString(_keyUserEmail, user['email'] as String);
    await prefs.setBool(_keyIsLoggedIn, true);

    _api.setToken(token);
    return AuthSession(
      token: token,
      userId: user['id'].toString(),
      name: user['name'] as String,
      email: user['email'] as String,
    );
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyUserEmail);
    _api.setToken(null);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }
}
