import '../models/authorized_email_dto.dart';

abstract class AuthorizedEmailRepository {
  Future<List<AuthorizedEmailDto>> getAllAuthorizedEmails({
    bool forceRefresh = false,
  });
  Future<AuthorizedEmailDto> addAuthorizedEmail(AddAuthorizedEmailDto dto);
  Future<void> activateEmail(UpdateEmailStatusDto dto);
  Future<void> deactivateEmail(UpdateEmailStatusDto dto);
  Future<void> deleteAuthorizedEmail(String email);
}

