import 'dart:convert';

/// Mirrors `src/lib/jwt.ts` — decodes claims out of a JWT without verifying
/// the signature (the backend is the source of truth; this is only used to
/// read `exp` and display claims client-side).
class JwtUtils {
  JwtUtils._();

  static Map<String, dynamic> parseClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length < 2) return {};
    try {
      final normalized = base64Url.normalize(parts[1]);
      final json = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return decoded;
    } catch (_) {
      return {};
    }
  }

  static bool isExpired(String jwt) {
    try {
      final claims = parseClaims(jwt);
      final exp = claims['exp'];
      if (exp == null) return true;
      final expMs = (exp is int ? exp : int.parse(exp.toString())) * 1000;
      return expMs <= DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      return true;
    }
  }
}
