import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class AuthApiClient {
  final http.Client _http;
  AuthApiClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  Future<Map<String, dynamic>> login(String email, String password, bool rememberMe) async {
    final url = Uri.parse('${AppConfig.baseUrl}${AppConfig.loginEndpoint}');
    final response = await _http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'rememberMe': rememberMe}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    try {
      if (response.body.isNotEmpty && response.headers['content-type']?.contains('application/json') == true) {
        final err = jsonDecode(response.body);
        // Extraire le message d'erreur du backend
        final errorMessage = err['message'] ?? err['Message'] ?? 'Échec de connexion';
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) rethrow;
    }
    throw Exception('Échec de connexion (HTTP ${response.statusCode})');
  }

  Future<Map<String, dynamic>?> refresh(String refreshToken) async {
    final url = Uri.parse('${AppConfig.baseUrl}${AppConfig.refreshTokenEndpoint}');
    final response = await _http.post(
      url,
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $refreshToken'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  Future<bool> verifyTokenBlacklisted(String accessToken) async {
    final url = Uri.parse('${AppConfig.baseUrl}${AppConfig.verifyTokenEndpoint}');
    final response = await _http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return (data['isBlacklisted'] ?? false) as bool;
    }
    return false;
  }

  Future<void> serverLogout(String accessToken) async {
    final url = Uri.parse('${AppConfig.baseUrl}${AppConfig.logoutEndpoint}');
    await _http.post(url, headers: {'Authorization': 'Bearer $accessToken'});
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/forgot-password');
    final response = await _http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    try {
      if (response.body.isNotEmpty && response.headers['content-type']?.contains('application/json') == true) {
        final err = jsonDecode(response.body);
        final errorMessage = err['message'] ?? err['Message'] ?? 'Erreur lors de l\'envoi du code';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    throw Exception('Erreur lors de l\'envoi du code (HTTP ${response.statusCode})');
  }

  Future<Map<String, dynamic>> resetPassword(
    String email,
    String otpCode,
    String newPassword,
    String confirmPassword,
  ) async {
    final url = Uri.parse('${AppConfig.baseUrl}/auth/reset-password');
    final response = await _http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    try {
      if (response.body.isNotEmpty && response.headers['content-type']?.contains('application/json') == true) {
        final err = jsonDecode(response.body);
        final errorMessage = err['message'] ?? err['Message'] ?? 'Erreur lors de la réinitialisation';
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    throw Exception('Erreur lors de la réinitialisation (HTTP ${response.statusCode})');
  }
}


