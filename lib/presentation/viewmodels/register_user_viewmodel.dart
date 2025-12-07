import 'package:flutter/material.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/models/register_user_dto.dart';
import '../../domain/models/user_response_dto.dart';
import '../../data/repositories/user_repository_impl.dart';

enum RegisterUserStatus { initial, loading, success, error }

class RegisterUserViewModel extends ChangeNotifier {
  final UserRepository _repository;

  RegisterUserStatus _status = RegisterUserStatus.initial;
  UserResponseDto? _user;
  String? _errorMessage;

  RegisterUserStatus get status => _status;
  UserResponseDto? get user => _user;
  String? get errorMessage => _errorMessage;

  RegisterUserViewModel({UserRepository? repository})
      : _repository = repository ?? UserRepositoryImpl();

  Future<void> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String whatsAppNumber,
    String? roleName, // Optionnel - backend assignera "Utilisateur" par défaut
    required String password,
  }) async {
    try {
      _status = RegisterUserStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final dto = RegisterUserDto(
        firstName: firstName,
        lastName: lastName,
        email: email,
        whatsAppNumber: whatsAppNumber,
        roleName: roleName, // Peut être null
        password: password,
        confirmPassword: password,
      );

      _user = await _repository.registerUser(dto);
      _status = RegisterUserStatus.success;
    } catch (e) {
      // Extraire le message d'erreur proprement
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      // Si le message est vide ou générique, utiliser un message par défaut
      if (errorMsg.isEmpty || errorMsg == 'null') {
        errorMsg = 'Erreur lors de l\'inscription. Veuillez vérifier vos informations.';
      }
      _errorMessage = errorMsg;
      _status = RegisterUserStatus.error;
    } finally {
      notifyListeners();
    }
  }

  void reset() {
    _status = RegisterUserStatus.initial;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}