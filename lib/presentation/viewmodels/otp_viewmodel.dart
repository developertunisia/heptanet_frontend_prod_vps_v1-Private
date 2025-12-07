import 'package:flutter/material.dart';
import '../../domain/repositories/otp_repository.dart';
import '../../data/repositories/otp_repository_impl.dart';

enum OtpStatus { idle, sending, sent, verifying, success, error }

class OtpViewModel extends ChangeNotifier {
  final OtpRepository _repo;
  OtpStatus _status = OtpStatus.idle;
  String? _error;
  int _cooldown = 0;

  OtpStatus get status => _status;
  String? get error => _error;
  int get cooldown => _cooldown;

  OtpViewModel({OtpRepository? repository}) : _repo = repository ?? OtpRepositoryImpl();

  Future<void> send(String email) async {
    try {
      _status = OtpStatus.sending; _error = null; notifyListeners();
      final res = await _repo.sendOtp(email);
      _status = OtpStatus.sent;
      _cooldown = (res['cooldownSeconds'] ?? 60) as int;
    } catch (e) {
      _status = OtpStatus.error;
      // Extraire le message d'erreur proprement
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.isEmpty || errorMsg == 'null') {
        errorMsg = 'Erreur lors de l\'envoi du code. Veuillez réessayer.';
      }
      _error = errorMsg;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> verify(String email, String code) async {
    try {
      _status = OtpStatus.verifying; _error = null; notifyListeners();
      final res = await _repo.verifyOtp(email, code);
      final valid = res['valid'] == true;
      _status = valid ? OtpStatus.success : OtpStatus.error;
      if (!valid) {
        final errorMsg = res['message']?.toString() ?? res['Message']?.toString();
        _error = errorMsg ?? 'Code OTP invalide ou expiré. Veuillez réessayer.';
      }
      return valid;
    } catch (e) {
      _status = OtpStatus.error;
      // Extraire le message d'erreur proprement
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.isEmpty || errorMsg == 'null') {
        errorMsg = 'Erreur lors de l\'envoi du code. Veuillez réessayer.';
      }
      _error = errorMsg;
      return false;
    } finally {
      notifyListeners();
    }
  }
}