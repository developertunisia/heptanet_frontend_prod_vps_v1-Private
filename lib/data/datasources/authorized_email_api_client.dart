import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../domain/models/authorized_email_dto.dart';

class AuthorizedEmailApiClient {
  final String baseUrl;
  final FlutterSecureStorage _storage;

  AuthorizedEmailApiClient({
    String? baseUrl,
    FlutterSecureStorage? storage,
  })  : baseUrl = baseUrl ?? ApiConstants.baseUrl,
        _storage = storage ?? const FlutterSecureStorage();

  // Méthode helper pour obtenir les headers avec le token
  Future<Map<String, String>> _getHeaders() async {
    // Récupérer le token JWT depuis le secure storage
    final token = await _storage.read(key: AppConfig.tokenKey);
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    // Ajouter le token d'authentification si disponible
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      print('🔑 Token added to headers: ${token.substring(0, 20)}...'); // Debug
    } else {
      print('⚠️ No token found in storage!'); // Debug
    }
    
    return headers;
  }

  Future<List<AuthorizedEmailDto>> getAllAuthorizedEmails() async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.authorizedEmailsEndpoint}');
      
      print('🚀 Fetching authorized emails from: $uri');
      
      final response = await http.get(
        uri,
        headers: await _getHeaders(),  // ✅ Utiliser les headers avec token
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((item) => AuthorizedEmailDto.fromJson(item))
            .toList();
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching authorized emails: $e');
      rethrow;
    }
  }

  Future<AuthorizedEmailDto> addAuthorizedEmail(AddAuthorizedEmailDto dto) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.authorizedEmailsEndpoint}');
      
      print('🚀 Adding authorized email to: $uri');
      print('📤 Request body: ${json.encode(dto.toJson())}');
      
      final response = await http.post(
        uri,
        headers: await _getHeaders(),  // ✅ Utiliser les headers avec token
        body: json.encode(dto.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200 || response.statusCode == 204) {
        // Si la réponse est vide ou 204 No Content, créer un objet par défaut
        if (response.body.isEmpty || response.statusCode == 204) {
          print('✅ Email added successfully (no content returned)');
          return AuthorizedEmailDto(
            syncId: 0, // ID temporaire
            email: dto.email,
            isImported: dto.isImported,
            syncDate: DateTime.now(),
          );
        }
        
        // Sinon, parser la réponse JSON
        try {
          final jsonData = json.decode(response.body);
          return AuthorizedEmailDto.fromJson(jsonData);
        } catch (e) {
          print('⚠️ Error parsing response: $e');
          // Si le parsing échoue, retourner un objet par défaut
          return AuthorizedEmailDto(
            syncId: 0,
            email: dto.email,
            isImported: dto.isImported,
            syncDate: DateTime.now(),
          );
        }
      } else if (response.statusCode == 400) {
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Erreur lors de l\'ajout de l\'email');
        } catch (e) {
          throw Exception('Erreur lors de l\'ajout de l\'email: ${response.body}');
        }
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error adding authorized email: $e');
      rethrow;
    }
  }

  Future<void> activateEmail(UpdateEmailStatusDto dto) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.authorizedEmailsEndpoint}/activate');
      
      print('🚀 Activating email at: $uri');
      print('📤 Request body: ${json.encode(dto.toJson())}');
      
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(dto.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Email activated successfully');
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur lors de l\'activation');
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error activating email: $e');
      rethrow;
    }
  }

  Future<void> deactivateEmail(UpdateEmailStatusDto dto) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.authorizedEmailsEndpoint}/deactivate');
      
      print('🚀 Deactivating email at: $uri');
      print('📤 Request body: ${json.encode(dto.toJson())}');
      
      final response = await http.put(
        uri,
        headers: await _getHeaders(),
        body: json.encode(dto.toJson()),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Email deactivated successfully');
      } else if (response.statusCode == 400 || response.statusCode == 404) {
        final jsonData = json.decode(response.body);
        throw Exception(jsonData['message'] ?? 'Erreur lors de la désactivation');
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error deactivating email: $e');
      rethrow;
    }
  }

  Future<void> deleteAuthorizedEmail(String email) async {
    try {
      // URL encode the email to handle special characters like @ and .
      final encodedEmail = Uri.encodeComponent(email);
      final uri = Uri.parse('$baseUrl${ApiConstants.authorizedEmailsEndpoint}/$encodedEmail');
      
      print('🚀 Deleting authorized email at: $uri');
      
      final response = await http.delete(
        uri,
        headers: await _getHeaders(),  // ✅ Utiliser les headers avec token
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error deleting authorized email: $e');
      rethrow;
    }
  }
}
