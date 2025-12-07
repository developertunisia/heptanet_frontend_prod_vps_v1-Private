import 'package:flutter/material.dart';
import '../../../domain/models/user_response_dto.dart';
import '../../../data/repositories/user_repository_impl.dart';
import '../../../data/datasources/user_local_datasource.dart';
import '../../../core/constants.dart';

enum MemberFilter { all, users, admins }

class MembersViewModel extends ChangeNotifier {
  final UserRepositoryImpl _userRepository;
  final UserLocalDataSource _localDataSource;

  MembersViewModel({
    UserRepositoryImpl? userRepository,
    UserLocalDataSource? localDataSource,
  })  : _userRepository = userRepository ?? UserRepositoryImpl(),
        _localDataSource = localDataSource ?? UserLocalDataSource();

  final List<UserResponseDto> _members = [];
  final TextEditingController searchController = TextEditingController();

  MemberFilter _filter = MemberFilter.all;
  List<UserResponseDto> _filteredMembers = const [];
  bool _isLoading = false;
  String? _errorMessage;

  MemberFilter get filter => _filter;
  List<UserResponseDto> get members => List.unmodifiable(_filteredMembers);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadMembers({bool refresh = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      List<UserResponseDto> users;

      // Charger depuis le cache si disponible et pas de refresh
      if (!refresh) {
        users = await _localDataSource.getUsers();
        if (users.isNotEmpty) {
          _members
            ..clear()
            ..addAll(users);
          _applyFilters();
          _isLoading = false;
          notifyListeners();
        }
      }

      // Toujours charger depuis l'API pour avoir les données à jour
      users = await _userRepository.getAllUsers(excludeBlacklisted: true);
      
      // Sauvegarder dans le cache
      await _localDataSource.saveUsers(users);

      _members
        ..clear()
        ..addAll(users);
      _applyFilters();
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des membres: ${e.toString()}';
      
      // En cas d'erreur, essayer de charger depuis le cache
      final cachedUsers = await _localDataSource.getUsers();
      if (cachedUsers.isNotEmpty) {
        _members
          ..clear()
          ..addAll(cachedUsers);
        _applyFilters();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearMembers() {
    _members.clear();
    _filteredMembers = const [];
    notifyListeners();
  }

  void updateFilter(MemberFilter filter) {
    if (_filter == filter) return;
    _filter = filter;
    _applyFilters();
    notifyListeners();
  }

  void updateSearch(String value) {
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final query = searchController.text.trim().toLowerCase();

    _filteredMembers = _members
        .where((member) {
          if (AppRoles.isSuperAdmin(member)) {
            return false;
          }
          final matchesFilter = switch (_filter) {
            MemberFilter.all => true,
            MemberFilter.users => !AppRoles.isAdmin(member),
            MemberFilter.admins => AppRoles.isAdmin(member),
          };

          final fullName = '${member.firstName} ${member.lastName}';
          final matchesSearch = query.isEmpty ||
              fullName.toLowerCase().contains(query) ||
              member.email.toLowerCase().contains(query);

          return matchesFilter && matchesSearch;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
