import 'package:flutter/material.dart';
import '../../../domain/models/user_response_dto.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/datasources/user_local_datasource.dart';

class ManagementSetting {
  ManagementSetting({
    required this.label,
    required this.description,
    this.enabled = false,
  });

  final String label;
  final String description;
  bool enabled;
}

class ManagementViewModel extends ChangeNotifier {
  final UserRepositoryImpl _userRepository;
  final UserLocalDataSource _localDataSource;

  final List<ManagementSetting> _settings = [];
  final List<UserResponseDto> _users = [];
  bool _isLoadingUsers = false;
  String? _usersErrorMessage;

  ManagementViewModel({
    UserRepositoryImpl? userRepository,
    UserLocalDataSource? localDataSource,
  })  : _userRepository = userRepository ?? UserRepositoryImpl(),
        _localDataSource = localDataSource ?? UserLocalDataSource();

  List<ManagementSetting> get settings => List.unmodifiable(_settings);
  List<UserResponseDto> get users => List.unmodifiable(_users);
  bool get isLoadingUsers => _isLoadingUsers;
  String? get usersErrorMessage => _usersErrorMessage;

  void setSettings(List<ManagementSetting> settings) {
    _settings
      ..clear()
      ..addAll(settings);
    notifyListeners();
  }

  void toggle(ManagementSetting setting) {
    setting.enabled = !setting.enabled;
    notifyListeners();
  }

  void clear() {
    if (_settings.isEmpty) return;
    _settings.clear();
    notifyListeners();
  }

  Future<void> loadUsers({bool refresh = false}) async {
    if (_isLoadingUsers) return;

    _isLoadingUsers = true;
    _usersErrorMessage = null;
    notifyListeners();

    try {
      List<UserResponseDto> users;

      // Charger depuis le cache si disponible et pas de refresh
      if (!refresh) {
        users = await _localDataSource.getUsers();
        if (users.isNotEmpty) {
          _users
            ..clear()
            ..addAll(users);
          _isLoadingUsers = false;
          notifyListeners();
        }
      }

      // Toujours charger depuis l'API pour avoir les données à jour
      users = await _userRepository.getAllUsers(excludeBlacklisted: true);
      
      // Sauvegarder dans le cache
      await _localDataSource.saveUsers(users);

      _users
        ..clear()
        ..addAll(users);
    } catch (e) {
      _usersErrorMessage = 'Erreur lors du chargement des utilisateurs: ${e.toString()}';
      
      // En cas d'erreur, essayer de charger depuis le cache
      final cachedUsers = await _localDataSource.getUsers();
      if (cachedUsers.isNotEmpty) {
        _users
          ..clear()
          ..addAll(cachedUsers);
      }
    } finally {
      _isLoadingUsers = false;
      notifyListeners();
    }
  }

  void clearUsers() {
    _users.clear();
    notifyListeners();
  }
}
