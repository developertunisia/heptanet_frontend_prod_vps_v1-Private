import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../domain/models/user_response_dto.dart';
import '../../core/constants.dart';

class UserLocalDataSource {
  final FlutterSecureStorage _storage;
  static const String _usersKey = 'cached_users';

  UserLocalDataSource({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveUsers(List<UserResponseDto> users) async {
    final jsonList = users.map((user) => user.toJson()).toList();
    await _storage.write(key: _usersKey, value: jsonEncode(jsonList));
  }

  Future<List<UserResponseDto>> getUsers() async {
    final json = await _storage.read(key: _usersKey);
    if (json == null) return [];
    try {
      final jsonList = jsonDecode(json) as List;
      return jsonList
          .map((item) => UserResponseDto.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearUsers() async {
    await _storage.delete(key: _usersKey);
  }
}

