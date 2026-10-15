import 'package:shared_preferences/shared_preferences.dart';

/// Mirrors the localStorage keys in `src/context/AuthContext.tsx` so the
/// session shape (access/refresh token, user type, user theme) matches the web app.
class TokenStorage {
  static const _accessKey = 'auth_access_token';
  static const _refreshKey = 'auth_refresh_token';
  static const _userTypeKey = 'auth_user_type';
  static const _userThemeKey = 'auth_user_theme';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int userType,
    required int userTheme,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, accessToken);
    await prefs.setString(_refreshKey, refreshToken);
    await prefs.setInt(_userTypeKey, userType);
    await prefs.setInt(_userThemeKey, userTheme);
  }

  Future<String?> get accessToken async => (await SharedPreferences.getInstance()).getString(_accessKey);
  Future<String?> get refreshToken async => (await SharedPreferences.getInstance()).getString(_refreshKey);
  Future<int?> get userType async => (await SharedPreferences.getInstance()).getInt(_userTypeKey);
  Future<int?> get userTheme async => (await SharedPreferences.getInstance()).getInt(_userThemeKey);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove(_userTypeKey);
    await prefs.remove(_userThemeKey);
  }
}
