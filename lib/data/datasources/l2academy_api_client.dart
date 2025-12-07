import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/models/l2academy_email_response.dart';

class L2AcademyApiClient {
  static const String baseUrl = 'https://www.l2macademy.com/wp-json/custom-api/v1';

  /// Vérifie si l'email existe dans la plateforme L2Academy
  Future<L2AcademyEmailResponse> checkEmail(String email) async {
    try {
      final uri = Uri.parse('$baseUrl/check-email?email=${Uri.encodeComponent(email)}');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout: Could not connect to L2Academy API');
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return L2AcademyEmailResponse.fromJson(jsonData);
      } else {
        throw Exception('Erreur HTTP: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Erreur lors de la vérification de l\'email sur L2Academy: $e');
    }
  }
}

