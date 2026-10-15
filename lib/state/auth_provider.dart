import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/jwt/jwt_utils.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_models.dart';
import '../models/common.dart';
import '../services/auth_service.dart';

/// Mirrors `src/context/AuthContext.tsx`: session bootstrap, token refresh,
/// and the profile fields the shell/header need.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._authService, this._storage);

  final AuthService _authService;
  final TokenStorage _storage;

  bool isLoading = true;
  String? _accessToken;
  String? _refreshToken;
  int? userType;
  int? userTheme;
  UserProfileDto? profile;

  bool get isAuthenticated => _accessToken != null && !JwtUtils.isExpired(_accessToken!);
  String? get accessTokenOrNull => _accessToken;

  Future<void> bootstrap() async {
    isLoading = true;
    notifyListeners();
    try {
      final storedAccess = await _storage.accessToken;
      final storedRefresh = await _storage.refreshToken;
      if (storedAccess != null && !JwtUtils.isExpired(storedAccess)) {
        _accessToken = storedAccess;
        _refreshToken = storedRefresh;
        userType = await _storage.userType;
        userTheme = await _storage.userTheme;
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse<AuthenticateResponseDto>?> login(String email, String password) async {
    final result = await _authService.login(email, password);
    await _applyAuthenticateResult(result?.data);
    return result;
  }

  /// Swaps the emailed 2FA code for tokens, finishing the login that `login()`
  /// left in the `requiresTwoFactor` state.
  Future<ApiResponse<AuthenticateResponseDto>?> completeTwoFactorLogin(String userId, String code) async {
    final result = await _authService.login2fa(userId, code);
    await _applyAuthenticateResult(result?.data);
    return result;
  }

  Future<void> resendTwoFactorCode(String userId) => _authService.resendTwoFactorCode(userId);

  Future<void> _applyAuthenticateResult(AuthenticateResponseDto? data) async {
    final jwt = data?.jwtToken;
    if (jwt == null || jwt.accessToken.isEmpty) return;
    await _applySession(
      access: jwt.accessToken,
      refresh: jwt.refreshToken,
      type: data!.userType,
      theme: data.userTheme,
    );
  }

  Future<({bool success, String message, dynamic data})> register(RegisterModel model) {
    return _authService.register(model);
  }

  Future<String?> getValidAccessToken() async {
    final token = _accessToken ?? await _storage.accessToken;
    if (token == null) return null;
    if (!JwtUtils.isExpired(token)) return token;
    return _refresh();
  }

  Future<String?> _refresh() async {
    final stored = _refreshToken ?? await _storage.refreshToken;
    if (stored == null) return null;
    final response = await _authService.refreshToken(stored);
    final data = response?.data;
    if (response?.statusCode != ApiResponse.successCode || data == null || data.accessToken.isEmpty) {
      await logout();
      return null;
    }
    await _applySession(
      access: data.accessToken,
      refresh: data.refreshToken,
      type: data.userType,
      theme: data.userTheme,
    );
    return data.accessToken;
  }

  Future<void> _applySession({
    required String access,
    required String refresh,
    required int type,
    required int theme,
  }) async {
    await _storage.saveSession(accessToken: access, refreshToken: refresh, userType: type, userTheme: theme);
    _accessToken = access;
    _refreshToken = refresh;
    userType = type;
    userTheme = theme;
    notifyListeners();
  }

  Future<ApiResponse<UserProfileDto>?> loadProfile() async {
    final token = await getValidAccessToken();
    final response = await _authService.getUserProfile(token);
    if (response?.data != null) {
      profile = response!.data;
      notifyListeners();
    }
    return response;
  }

  /// Upgrades the signed-in account to also organize events; the response
  /// carries fresh tokens (roles live in the access token) that replace the session.
  Future<ApiResponse<AuthenticateResponseDto>?> becomeOrganizer(String organizerName) async {
    final token = await getValidAccessToken();
    final result = await _authService.becomeOrganizer(token, organizerName);
    await _applyAuthenticateResult(result?.data);
    return result;
  }

  Future<void> logout() async {
    final refresh = _refreshToken ?? await _storage.refreshToken;
    if (refresh != null) {
      // Revokes this device's refresh token server-side; best-effort, always reports success.
      unawaited(_authService.logout(refresh));
    }
    await _storage.clear();
    _accessToken = null;
    _refreshToken = null;
    userType = null;
    userTheme = null;
    profile = null;
    notifyListeners();
  }
}
