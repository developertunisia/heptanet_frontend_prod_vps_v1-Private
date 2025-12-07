import 'package:flutter/material.dart';
import '../../domain/models/email_check_response.dart';
import '../../domain/repositories/email_repository.dart';
import '../../data/repositories/email_repository_impl.dart';

enum EmailCheckStatus { initial, loading, success, error }

class EmailCheckViewModel extends ChangeNotifier {
  final EmailRepository _repository;
  
  EmailCheckStatus _status = EmailCheckStatus.initial;
  EmailCheckResponse? _response;
  String? _errorMessage;

  // Getters
  EmailCheckStatus get status => _status;
  EmailCheckResponse? get response => _response;
  String? get errorMessage => _errorMessage;
  bool get isEmailValid => _response?.exists ?? false;

  EmailCheckViewModel({EmailRepository? repository})
      : _repository = repository ?? EmailRepositoryImpl();

  /// Vérifie si l'email existe (en deux étapes : L2Academy puis base de données interne)
  Future<void> checkEmail(String email) async {
    if (email.isEmpty) {
      _errorMessage = 'Veuillez entrer un email';
      _status = EmailCheckStatus.error;
      notifyListeners();
      return;
    }

    try {
      _status = EmailCheckStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _response = await _repository.checkEmail(email);
      _status = EmailCheckStatus.success;
    } catch (e) {
      // Extraire le message d'erreur proprement
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.isEmpty || errorMsg == 'null') {
        errorMsg = 'Erreur lors de la vérification de l\'email. Veuillez réessayer.';
      }
      _errorMessage = errorMsg;
      _status = EmailCheckStatus.error;
    } finally {
      notifyListeners();
    }
  }

  /// Réinitialise le statut
  void reset() {
    _status = EmailCheckStatus.initial;
    _response = null;
    _errorMessage = null;
    notifyListeners();
  }
}