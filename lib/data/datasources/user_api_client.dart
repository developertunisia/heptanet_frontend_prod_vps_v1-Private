import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../domain/models/register_user_dto.dart';
import '../../domain/models/user_response_dto.dart';
import '../../data/repositories/auth_repository_impl.dart';

class UserApiClient {
  final String baseUrl;
  final AuthRepositoryImpl _authRepository;

  UserApiClient({String? baseUrl, AuthRepositoryImpl? authRepository})
      : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _authRepository = authRepository ?? AuthRepositoryImpl();

  Future<UserResponseDto> registerUser(RegisterUserDto dto) async {
    try {
      // ApiConstants.registerUserEndpoint commence par /api, mais baseUrl l'inclut déjà
      final endpoint = ApiConstants.registerUserEndpoint.replaceFirst('/api', '');
      final uri = Uri.parse('$baseUrl$endpoint');
      
      // Add debug logging
      print('🚀 Sending registration request to: $uri');
      print('📤 Request body: ${json.encode(dto.toJson())}');
      
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(dto.toJson()),
      ).timeout(
        const Duration(seconds: 10), // 10 second timeout
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return UserResponseDto.fromJson(jsonData);
      } else if (response.statusCode == 400) {
        final jsonData = json.decode(response.body);
        // Extraire le message d'erreur du backend
        final errorMessage = jsonData['message'] ?? jsonData['Message'] ?? 'Erreur lors de l\'enregistrement';
        throw Exception(errorMessage);
      } else {
        // Essayer d'extraire un message d'erreur même pour les autres codes
        try {
          final jsonData = json.decode(response.body);
          final errorMessage = jsonData['message'] ?? jsonData['Message'];
          if (errorMessage != null) {
            throw Exception(errorMessage);
          }
        } catch (_) {}
        throw Exception('Erreur HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error during registration: $e');
      rethrow;
    }
  }

  /// Récupère tous les utilisateurs avec filtres optionnels
  Future<List<UserResponseDto>> getAllUsers({
    bool? excludeBlacklisted,
    String? roleName,
  }) async {
    try {
      final headers = await _authRepository.getAuthHeaders();
      headers['Content-Type'] = 'application/json';

      // Vérifier que le token d'authentification est présent
      if (!headers.containsKey('Authorization') || headers['Authorization']?.isEmpty == true) {
        print('❌ Token d\'authentification manquant');
        throw Exception('Token d\'authentification manquant. Veuillez vous reconnecter.');
      }

      final queryParams = <String, String>{};
      if (excludeBlacklisted != null) {
        queryParams['excludeBlacklisted'] = excludeBlacklisted.toString();
      }
      if (roleName != null && roleName.isNotEmpty) {
        queryParams['roleName'] = roleName;
      }

      final uri = Uri.parse('$baseUrl/Users').replace(queryParameters: queryParams);

      print('🔍 GET ${uri.toString()}');
      print('🔐 Auth header present: ${headers.containsKey('Authorization')}');

      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to server');
        },
      );

      print('📥 Response status: ${response.statusCode}');

      // Gérer les erreurs d'authentification avant de parser le JSON
      if (response.statusCode == 401) {
        print('❌ Unauthorized - Token may be expired or invalid');
        throw Exception('Non autorisé. Veuillez vous reconnecter.');
      }

      if (response.statusCode == 200) {
        try {
          // Vérifier que le body n'est pas vide
          if (response.body.isEmpty) {
            print('⚠️ Response body is empty');
            return [];
          }

          final jsonData = json.decode(response.body);
          
          // Vérifier que c'est bien une liste
          if (jsonData is! List) {
            print('❌ Response is not a list: ${jsonData.runtimeType}');
            throw Exception('Réponse invalide du serveur: format attendu est une liste');
          }

          // Parser chaque utilisateur avec gestion d'erreur individuelle
          final users = <UserResponseDto>[];
          for (var i = 0; i < jsonData.length; i++) {
            try {
              final item = jsonData[i];
              if (item is Map<String, dynamic>) {
                users.add(UserResponseDto.fromJson(item));
              } else {
                print('⚠️ Item at index $i is not a Map: ${item.runtimeType}');
              }
            } catch (e) {
              print('❌ Error parsing user at index $i: $e');
              print('❌ Problematic item: ${jsonData[i]}');
              // Continuer avec les autres utilisateurs même si un échoue
            }
          }

          print('✅ Successfully parsed ${users.length} users');
          return users;
        } catch (e) {
          print('❌ Error parsing response body: $e');
          print('❌ Response body: ${response.body}');
          rethrow;
        }
      } else {
        // Pour les autres codes d'erreur, ne pas essayer de parser le JSON
        print('❌ HTTP Error ${response.statusCode}: ${response.body}');
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error during getAllUsers: $e');
      rethrow;
    }
  }
}