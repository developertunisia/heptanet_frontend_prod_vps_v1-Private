import '../models/auth_model.dart';

abstract class AuthRepository {
  User? get currentUser;
  bool get isLoggedIn;

  Future<LoginResponse> login(String email, String password, {bool rememberMe});
  Future<bool> checkAuthStatus();
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  bool isTokenExpired(String token);
  DateTime? getTokenExpiration(String token);
  Future<String?> refreshAccessToken();
  Future<bool> checkBlacklistStatus(String token);
  Future<void> logout();
  Future<String?> getSavedEmail();
  Future<void> clearSavedEmail();
  Future<Map<String, String>> getAuthHeaders();
  Future<String> forgotPassword(String email);
  Future<String> resetPassword(String email, String otpCode, String newPassword, String confirmPassword);
}


