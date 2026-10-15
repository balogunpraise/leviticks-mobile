import '../core/network/api_client.dart';
import '../models/auth_models.dart';
import '../models/common.dart';

/// Mirrors `src/lib/services/auth.ts`.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  Future<ApiResponse<AuthenticateResponseDto>?> login(String email, String password) {
    return _client.post<ApiResponse<AuthenticateResponseDto>>(
      'Auth/login',
      (json) => ApiResponse.fromJson(json, (d) => AuthenticateResponseDto.fromJson(d as Map<String, dynamic>)),
      body: {'email': email, 'password': password},
    );
  }

  Future<({bool success, String message, dynamic data})> register(RegisterModel model) async {
    final raw = await _client.postRaw('Auth/register', body: model.toRequestJson());
    if (!raw.isSuccess) {
      return (success: false, message: 'Registration failed (${raw.statusCode}).', data: null);
    }
    return (success: true, message: 'Registration successful.', data: null);
  }

  Future<ApiResponse<AuthResponseDto>?> refreshToken(String refreshToken) {
    return _client.post<ApiResponse<AuthResponseDto>>(
      'Auth/refresh-token',
      (json) => ApiResponse.fromJson(json, (d) => AuthResponseDto.fromJson(d as Map<String, dynamic>)),
      body: {'refreshToken': refreshToken},
    );
  }

  Future<ApiResponse<dynamic>?> logout(String refreshToken) {
    return _client.post<ApiResponse<dynamic>>(
      'Auth/logout',
      (json) => ApiResponse.fromJson(json, (d) => d),
      body: {'refreshToken': refreshToken},
    );
  }

  Future<ApiResponse<UserProfileDto>?> getUserProfile(String? token) {
    return _client.get<ApiResponse<UserProfileDto>>(
      'Auth/user-profile',
      (json) => ApiResponse.fromJson(json, (d) => UserProfileDto.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  // Second step of sign-in when two-factor is on: swaps the emailed code for tokens.
  Future<ApiResponse<AuthenticateResponseDto>?> login2fa(String userId, String code) {
    return _client.post<ApiResponse<AuthenticateResponseDto>>(
      'Auth/login-2fa',
      (json) => ApiResponse.fromJson(json, (d) => AuthenticateResponseDto.fromJson(d as Map<String, dynamic>)),
      body: {'userId': userId, 'code': code},
    );
  }

  Future<ApiResponse<dynamic>?> resendTwoFactorCode(String userId) {
    return _client.post<ApiResponse<dynamic>>(
      'Auth/login-2fa/resend',
      (json) => ApiResponse.fromJson(json, (d) => d),
      body: {'userId': userId},
    );
  }

  Future<ApiResponse<TwoFactorStatus>?> getTwoFactorStatus(String? token) {
    return _client.get<ApiResponse<TwoFactorStatus>>(
      'Auth/2fa',
      (json) => ApiResponse.fromJson(json, (d) => TwoFactorStatus.fromJson(d as Map<String, dynamic>)),
      token: token,
    );
  }

  // Step one of turning two-factor on: emails a code to the account's address.
  Future<ApiResponse<dynamic>?> startTwoFactorSetup(String? token) {
    return _client.post<ApiResponse<dynamic>>(
      'Auth/2fa/setup',
      (json) => ApiResponse.fromJson(json, (d) => d),
      body: const {},
      token: token,
    );
  }

  // Step two: confirms the emailed code and switches two-factor on.
  Future<ApiResponse<TwoFactorStatus>?> enableTwoFactor(String? token, String code) {
    return _client.post<ApiResponse<TwoFactorStatus>>(
      'Auth/2fa/enable',
      (json) => ApiResponse.fromJson(json, (d) => TwoFactorStatus.fromJson(d as Map<String, dynamic>)),
      body: {'code': code},
      token: token,
    );
  }

  // Needs the account password, not just a signed-in session.
  Future<ApiResponse<TwoFactorStatus>?> disableTwoFactor(String? token, String password) {
    return _client.post<ApiResponse<TwoFactorStatus>>(
      'Auth/2fa/disable',
      (json) => ApiResponse.fromJson(json, (d) => TwoFactorStatus.fromJson(d as Map<String, dynamic>)),
      body: {'password': password},
      token: token,
    );
  }

  // Instantly upgrades the signed-in account so it can also organize events; the response
  // carries fresh tokens (roles live in the access token) that must replace the current session.
  Future<ApiResponse<AuthenticateResponseDto>?> becomeOrganizer(String? token, String organizerName) {
    return _client.post<ApiResponse<AuthenticateResponseDto>>(
      'Auth/become-organizer',
      (json) => ApiResponse.fromJson(json, (d) => AuthenticateResponseDto.fromJson(d as Map<String, dynamic>)),
      body: {'organizerName': organizerName},
      token: token,
    );
  }

  Future<ApiResponse<dynamic>?> forgotPassword(String email) {
    return _client.post<ApiResponse<dynamic>>(
      'Auth/forgot-password',
      (json) => ApiResponse.fromJson(json, (d) => d),
      body: {'email': email},
    );
  }

  Future<ApiResponse<dynamic>?> resetPassword(ResetPasswordRequest request) {
    return _client.post<ApiResponse<dynamic>>(
      'Auth/reset-password',
      (json) => ApiResponse.fromJson(json, (d) => d),
      body: request.toJson(),
    );
  }
}
