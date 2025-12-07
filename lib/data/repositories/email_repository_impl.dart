import '../../domain/repositories/email_repository.dart';
import '../../domain/models/email_check_response.dart';
import '../datasources/email_api_client.dart';
import '../datasources/l2academy_api_client.dart';

class EmailRepositoryImpl implements EmailRepository {
  final EmailApiClient _apiClient;
  final L2AcademyApiClient _l2AcademyApiClient;

  EmailRepositoryImpl({
    EmailApiClient? apiClient,
    L2AcademyApiClient? l2AcademyApiClient,
  })  : _apiClient = apiClient ?? EmailApiClient(),
        _l2AcademyApiClient = l2AcademyApiClient ?? L2AcademyApiClient();

  @override
  Future<EmailCheckResponse> checkEmail(String email) async {
    try {
      // ÉTAPE 1 : Vérifier d'abord via l'API externe L2Academy
      try {
        final l2AcademyResponse = await _l2AcademyApiClient.checkEmail(email);
        
        // Si l'email existe dans L2Academy (exists = true), retourner directement
        if (l2AcademyResponse.exists == true) {
          return EmailCheckResponse(
            exists: true,
            email: email,
          );
        }
      } catch (e) {
        // Si l'API externe échoue, continuer avec la vérification interne
        // On log l'erreur mais on ne bloque pas le processus
        print('⚠️ Erreur lors de la vérification L2Academy: $e');
        // Continuer avec la vérification interne
      }

      // ÉTAPE 2 : Si non trouvé dans L2Academy, vérifier dans notre base de données
      return await _apiClient.checkEmail(email);
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }
}