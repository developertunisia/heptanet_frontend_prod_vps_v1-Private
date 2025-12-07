import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';
import '../../domain/models/email_check_response.dart';

class EmailApiClient {
  final String baseUrl;

  EmailApiClient({String? baseUrl}) 
      : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<EmailCheckResponse> checkEmail(String email) async {
    try {
      final uri = Uri.parse('$baseUrl${ApiConstants.checkEmailEndpoint}/$email');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EmailCheckResponse.fromJson(jsonData);
      } else {
        // Essayer d'extraire un message d'erreur du backend
        try {
          final jsonData = json.decode(response.body);
          final errorMessage = jsonData['message'] ?? jsonData['Message'];
          if (errorMessage != null) {
            throw Exception(errorMessage);
          }
        } catch (e) {
          if (e is Exception && !e.toString().contains('Erreur')) rethrow;
        }
        if (response.statusCode == 500) {
          throw Exception('Erreur serveur. Veuillez réessayer plus tard.');
        } else {
          throw Exception('Erreur lors de la vérification de l\'email (HTTP ${response.statusCode})');
        }
      }
    } catch (e) {
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la vérification de l\'email: $e');
    }
  }
}