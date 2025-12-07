import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class OtpApiClient {
  final String baseUrl;
  OtpApiClient({String? baseUrl}) : baseUrl = baseUrl ?? ApiConstants.baseUrl;

  Future<Map<String, dynamic>> sendOtp(String email, {String purpose = 'register'}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.otpSendEndpoint}');
    final res = await http.post(uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'purpose': purpose}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Échec envoi OTP: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> verifyOtp(String email, String code, {String purpose = 'register'}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.otpVerifyEndpoint}');
    final res = await http.post(uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'purpose': purpose, 'code': code}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 401) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Échec vérification OTP: ${res.statusCode} ${res.body}');
  }

  Future<Map<String, dynamic>> getStatus(String email, {String purpose = 'register'}) async {
    final uri = Uri.parse('$baseUrl${ApiConstants.otpStatusEndpoint}?email=$email&purpose=$purpose');
    final res = await http.get(uri, headers: {'Content-Type': 'application/json'});
    if (res.statusCode == 200) return jsonDecode(res.body) as Map<String, dynamic>;
    throw Exception('Échec status OTP: ${res.statusCode} ${res.body}');
  }
}