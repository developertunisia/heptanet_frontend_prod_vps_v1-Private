import 'package:jwt_decoder/jwt_decoder.dart';
import '../../domain/models/auth_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_client.dart';
import '../datasources/auth_local_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiClient _api;
  final AuthLocalDataSource _local;

  User? _currentUser;

  AuthRepositoryImpl({AuthApiClient? apiClient, AuthLocalDataSource? local})
    : _api = apiClient ?? AuthApiClient(),
      _local = local ?? AuthLocalDataSource();

  @override
  User? get currentUser => _currentUser;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  Future<LoginResponse> login(
    String email,
    String password, {
    bool rememberMe = false,
  }) async {
    final data = await _api.login(email, password, rememberMe);
    final login = LoginResponse.fromJson(data);
    await _local.saveTokens(
      accessToken: login.accessToken,
      refreshToken: login.refreshToken,
    );
    _currentUser = login.user;
    await _local.saveUser(login.user);
    await _local.setSavedEmail(rememberMe ? email : null);
    return login;
  }

  @override
  Future<bool> checkAuthStatus() async {
    final token = await getAccessToken();
    if (token == null) return false;
    if (isTokenExpired(token)) {
      await refreshAccessToken();
      return true;
    }
    _currentUser = await _local.getUser();
    return true;
  }

  @override
  Future<String?> getAccessToken() => _local.getAccessToken();

  @override
  Future<String?> getRefreshToken() => _local.getRefreshToken();

  @override
  bool isTokenExpired(String token) {
    try {
      return JwtDecoder.isExpired(token);
    } catch (_) {
      return true;
    }
  }

  @override
  DateTime? getTokenExpiration(String token) {
    try {
      return JwtDecoder.getExpirationDate(token);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> refreshAccessToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return null;
    final res = await _api.refresh(refreshToken);
    final newAccessToken = res?['accessToken'] ?? res?['access_token'];
    if (newAccessToken != null) {
      final tokenValue = newAccessToken is String
          ? newAccessToken
          : newAccessToken.toString();
      if (tokenValue.isNotEmpty) {
        await _local.saveTokens(accessToken: tokenValue);
        return tokenValue;
      }
    }
    await logout();
    return null;
  }

  @override
  Future<bool> checkBlacklistStatus(String token) async {
    final isBlacklisted = await _api.verifyTokenBlacklisted(token);
    if (isBlacklisted) {
      await logout();
      throw Exception('Votre compte a été blacklisté');
    }
    return false;
  }

  @override
  Future<void> logout() async {
    final token = await getAccessToken();
    if (token != null) {
      try {
        await _api.serverLogout(token);
      } catch (_) {}
    }
    await _local.clearAllButEmail();
    _currentUser = null;
  }

  @override
  Future<String?> getSavedEmail() => _local.getSavedEmail();

  @override
  Future<void> clearSavedEmail() => _local.setSavedEmail(null);

  @override
  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    if (token != null && !isTokenExpired(token)) {
      return {'Authorization': 'Bearer $token'};
    }
    final newToken = await refreshAccessToken();
    if (newToken != null) {
      return {'Authorization': 'Bearer $newToken'};
    }
    return {};
  }

  @override
  Future<String> forgotPassword(String email) async {
    final data = await _api.forgotPassword(email);
    return data['message'] ?? 'Code envoyé avec succès';
  }

  @override
  Future<String> resetPassword(
    String email,
    String otpCode,
    String newPassword,
    String confirmPassword,
  ) async {
    final data = await _api.resetPassword(email, otpCode, newPassword, confirmPassword);
    return data['message'] ?? 'Mot de passe réinitialisé avec succès';
  }
}
