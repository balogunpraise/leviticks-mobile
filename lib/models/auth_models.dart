/// Mirrors `src/types/auth.ts`.
class TokenResponse {
  TokenResponse({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenResponse.fromJson(Map<String, dynamic> json) => TokenResponse(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );
}

class AuthenticateResponseDto {
  AuthenticateResponseDto({
    required this.userId,
    required this.userType,
    required this.userTheme,
    required this.isTwoFactorEnabled,
    this.requiresTwoFactor = false,
    this.twoFactorCodeSentTo,
    this.twoFactorCodeExpiresAt,
    this.jwtToken,
  });

  final String userId;
  final int userType;
  final int userTheme;
  final bool isTwoFactorEnabled;
  // true when the password was accepted but an emailed code is still needed; jwtToken is null then.
  final bool requiresTwoFactor;
  final String? twoFactorCodeSentTo;
  final DateTime? twoFactorCodeExpiresAt;
  final TokenResponse? jwtToken;

  factory AuthenticateResponseDto.fromJson(Map<String, dynamic> json) => AuthenticateResponseDto(
        userId: json['userId'] as String? ?? '',
        userType: json['userType'] as int? ?? 0,
        userTheme: json['userTheme'] as int? ?? 0,
        isTwoFactorEnabled: json['isTwoFactorEnabled'] as bool? ?? false,
        requiresTwoFactor: json['requiresTwoFactor'] as bool? ?? false,
        twoFactorCodeSentTo: json['twoFactorCodeSentTo'] as String?,
        twoFactorCodeExpiresAt: json['twoFactorCodeExpiresAt'] != null
            ? DateTime.tryParse(json['twoFactorCodeExpiresAt'] as String)
            : null,
        jwtToken: json['jwtToken'] != null ? TokenResponse.fromJson(json['jwtToken'] as Map<String, dynamic>) : null,
      );
}

class TwoFactorStatus {
  TwoFactorStatus({required this.enabled, required this.email});

  final bool enabled;
  // masked address codes are sent to, e.g. "a**@example.com"
  final String email;

  factory TwoFactorStatus.fromJson(Map<String, dynamic> json) => TwoFactorStatus(
        enabled: json['enabled'] as bool? ?? false,
        email: json['email'] as String? ?? '',
      );
}

class AuthResponseDto {
  AuthResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.userType,
    required this.userTheme,
  });

  final String accessToken;
  final String refreshToken;
  final int userType;
  final int userTheme;

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) => AuthResponseDto(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
        userType: json['userType'] as int? ?? 0,
        userTheme: json['userTheme'] as int? ?? 0,
      );
}

class UserProfileDto {
  UserProfileDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.imageUrl,
    this.phoneNumber,
    this.organizerId,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? imageUrl;
  final String? phoneNumber;
  // The organizer profile this user belongs to, when they host events.
  final String? organizerId;

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => UserProfileDto(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        organizerId: json['organizerId'] as String?,
      );
}

class ResetPasswordRequest {
  ResetPasswordRequest({required this.email, required this.token, required this.newPassword});

  final String email;
  final String token;
  final String newPassword;

  Map<String, dynamic> toJson() => {'email': email, 'token': token, 'newPassword': newPassword};
}

class RegisterModel {
  RegisterModel({
    required this.fullName,
    required this.email,
    required this.password,
    this.phoneNumber,
    required this.type,
  });

  final String fullName;
  final String email;
  final String password;
  final String? phoneNumber;
  final int type;

  Map<String, dynamic> toRequestJson() {
    final trimmed = fullName.trim();
    final parts = trimmed.split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'userType': type,
    };
  }
}
