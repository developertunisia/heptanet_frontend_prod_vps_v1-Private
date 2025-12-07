import '../models/register_user_dto.dart';
import '../models/user_response_dto.dart';

abstract class UserRepository {
  Future<UserResponseDto> registerUser(RegisterUserDto dto);
  Future<List<UserResponseDto>> getAllUsers({
    bool? excludeBlacklisted,
    String? roleName,
    bool forceRefresh = false,
  });
}