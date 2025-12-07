import 'package:flutter/material.dart';
import '../../domain/repositories/authorized_email_repository.dart';
import '../../domain/models/authorized_email_dto.dart';
import '../../data/repositories/authorized_email_repository_impl.dart';

enum AuthorizedEmailStatus { initial, loading, success, error }

class AuthorizedEmailViewModel extends ChangeNotifier {
  final AuthorizedEmailRepository _repository;

  AuthorizedEmailStatus _status = AuthorizedEmailStatus.initial;
  List<AuthorizedEmailDto> _emails = [];
  String? _errorMessage;
  String _searchQuery = '';

  AuthorizedEmailStatus get status => _status;
  List<AuthorizedEmailDto> get emails => _filteredEmails;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;

  AuthorizedEmailViewModel({AuthorizedEmailRepository? repository})
      : _repository = repository ?? AuthorizedEmailRepositoryImpl();

  List<AuthorizedEmailDto> get _filteredEmails {
    if (_searchQuery.isEmpty) {
      return _emails;
    }
    return _emails
        .where((email) =>
            email.email.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> loadAuthorizedEmails() async {
    try {
      _status = AuthorizedEmailStatus.loading;
      _errorMessage = null;
      notifyListeners();

      _emails = await _repository.getAllAuthorizedEmails();
      _status = AuthorizedEmailStatus.success;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthorizedEmailStatus.error;
    } finally {
      notifyListeners();
    }
  }

  Future<bool> addAuthorizedEmail(String email) async {
    try {
      _status = AuthorizedEmailStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final dto = AddAuthorizedEmailDto(email: email);
      await _repository.addAuthorizedEmail(dto);
      
      // Recharger la liste complète pour avoir les données à jour du serveur
      await loadAuthorizedEmails();
      
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthorizedEmailStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleEmailStatus(AuthorizedEmailDto email) async {
    try {
      _status = AuthorizedEmailStatus.loading;
      _errorMessage = null;
      notifyListeners();

      final dto = UpdateEmailStatusDto(email: email.email);
      
      // If currently imported (active), deactivate it; otherwise activate it
      if (email.isImported) {
        await _repository.deactivateEmail(dto);
      } else {
        await _repository.activateEmail(dto);
      }
      
      // Update the email in the local list
      final index = _emails.indexWhere((e) => e.email == email.email);
      if (index != -1) {
        _emails[index] = AuthorizedEmailDto(
          syncId: email.syncId,
          email: email.email,
          isImported: !email.isImported,
          syncDate: email.syncDate,
        );
      }
      
      _status = AuthorizedEmailStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthorizedEmailStatus.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAuthorizedEmail(String email) async {
    try {
      _status = AuthorizedEmailStatus.loading;
      _errorMessage = null;
      notifyListeners();

      await _repository.deleteAuthorizedEmail(email);
      _emails.removeWhere((e) => e.email == email);
      
      _status = AuthorizedEmailStatus.success;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _status = AuthorizedEmailStatus.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _status = AuthorizedEmailStatus.initial;
    _emails = [];
    _errorMessage = null;
    _searchQuery = '';
    notifyListeners();
  }
}

