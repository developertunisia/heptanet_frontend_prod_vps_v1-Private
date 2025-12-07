import '../models/email_check_response.dart';

abstract class EmailRepository {
  Future<EmailCheckResponse> checkEmail(String email);
}