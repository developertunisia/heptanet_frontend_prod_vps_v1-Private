abstract class OtpRepository {
  Future<Map<String, dynamic>> sendOtp(String email, {String purpose});
  Future<Map<String, dynamic>> verifyOtp(String email, String code, {String purpose});
  Future<Map<String, dynamic>> getStatus(String email, {String purpose});
}