import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../domain/models/auth_model.dart';

class AuthLocalDataSource {
  final FlutterSecureStorage _storage;
  AuthLocalDataSource({FlutterSecureStorage? storage}) : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    if (accessToken != null) {
      await _storage.write(key: AppConfig.tokenKey, value: accessToken);
    } else {
      await _storage.delete(key: AppConfig.tokenKey);
    }

    if (refreshToken != null) {
      await _storage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
    } else {
      await _storage.delete(key: AppConfig.refreshTokenKey);
    }
  }

  Future<void> saveUser(User user) async {
    await _storage.write(key: AppConfig.userKey, value: jsonEncode(user.toJson()));
  }

  Future<String?> getAccessToken() => _storage.read(key: AppConfig.tokenKey);
  Future<String?> getRefreshToken() => _storage.read(key: AppConfig.refreshTokenKey);
  Future<String?> getSavedEmail() => _storage.read(key: AppConfig.savedEmailKey);
  Future<void> setSavedEmail(String? email) async {
    if (email == null) {
      await _storage.delete(key: AppConfig.savedEmailKey);
    } else {
      await _storage.write(key: AppConfig.savedEmailKey, value: email);
    }
  }

  Future<User?> getUser() async {
    final json = await _storage.read(key: AppConfig.userKey);
    if (json == null) return null;
    final map = jsonDecode(json) as Map<String, dynamic>;
    return User.fromJson(map);
  }

  Future<void> clearAllButEmail() async {
    await _storage.delete(key: AppConfig.tokenKey);
    await _storage.delete(key: AppConfig.refreshTokenKey);
    await _storage.delete(key: AppConfig.userKey);
  }
}
