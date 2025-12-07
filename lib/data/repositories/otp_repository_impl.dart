import '../../domain/repositories/otp_repository.dart';
import '../datasources/otp_api_client.dart';

class OtpRepositoryImpl implements OtpRepository {
  final OtpApiClient _api;
  OtpRepositoryImpl({OtpApiClient? apiClient}) : _api = apiClient ?? OtpApiClient();

  @override
  Future<Map<String, dynamic>> sendOtp(String email, {String purpose = 'register'}) =>
      _api.sendOtp(email, purpose: purpose);

  @override
  Future<Map<String, dynamic>> verifyOtp(String email, String code, {String purpose = 'register'}) =>
      _api.verifyOtp(email, code, purpose: purpose);

  @override
  Future<Map<String, dynamic>> getStatus(String email, {String purpose = 'register'}) =>
      _api.getStatus(email, purpose: purpose);
}