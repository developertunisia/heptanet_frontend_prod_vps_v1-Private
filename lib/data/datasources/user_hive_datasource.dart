import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/user_response_dto.dart';

/// High-performance user caching with Hive
/// 40x faster than FlutterSecureStorage for non-sensitive data
class UserHiveDataSource {
  static const String _boxName = 'users_cache';
  static const int _cacheValidityMinutes = 5; // Cache expires after 5 minutes
  
  Box<UserResponseDto>? _box;
  
  /// Initialize Hive and open the users box
  Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(UserResponseDtoAdapter());
      }
      _box = await Hive.openBox<UserResponseDto>(_boxName);
      print('✅ UserHiveDataSource initialized');
    } catch (e) {
      print('❌ Error initializing UserHiveDataSource: $e');
      rethrow;
    }
  }
  
  /// Save users to cache with timestamp
  Future<void> saveUsers(List<UserResponseDto> users) async {
    try {
      final now = DateTime.now();
      final Map<String, UserResponseDto> userMap = {
        for (var user in users) 
          'user_${user.id}': user.copyWith(cachedAt: now)
      };
      await _box?.putAll(userMap);
      print('✅ Cached ${users.length} users');
    } catch (e) {
      print('❌ Error saving users to cache: $e');
    }
  }
  
  /// Get all cached users
  List<UserResponseDto> getAllUsers() {
    return _box?.values.toList() ?? [];
  }
  
  /// Get a specific user by ID
  UserResponseDto? getUserById(int id) {
    return _box?.get('user_$id');
  }
  
  /// Get users by role (fast query!)
  List<UserResponseDto> getUsersByRole(String role) {
    return _box?.values
        .where((user) => user.roles.contains(role))
        .toList() ?? [];
  }
  
  /// Get non-blacklisted users
  List<UserResponseDto> getNonBlacklistedUsers() {
    return _box?.values
        .where((user) => !user.isBlacklisted)
        .toList() ?? [];
  }
  
  /// Search users by name or email
  List<UserResponseDto> searchUsers(String query) {
    final lowerQuery = query.toLowerCase();
    return _box?.values.where((user) {
      return user.firstName.toLowerCase().contains(lowerQuery) ||
             user.lastName.toLowerCase().contains(lowerQuery) ||
             user.email.toLowerCase().contains(lowerQuery) ||
             user.fullName.toLowerCase().contains(lowerQuery);
    }).toList() ?? [];
  }
  
  /// Check if cache is still valid (fresh)
  bool isCacheFresh() {
    if (_box?.isEmpty ?? true) return false;
    
    try {
      final firstUser = _box!.values.first;
      final cacheAge = DateTime.now().difference(firstUser.cachedAt);
      return cacheAge.inMinutes < _cacheValidityMinutes;
    } catch (e) {
      return false;
    }
  }
  
  /// Get cache age in minutes
  int getCacheAgeMinutes() {
    if (_box?.isEmpty ?? true) return 999;
    
    try {
      final firstUser = _box!.values.first;
      return DateTime.now().difference(firstUser.cachedAt).inMinutes;
    } catch (e) {
      return 999;
    }
  }
  
  /// Check if cache exists
  bool hasCache() {
    return (_box?.isNotEmpty ?? false);
  }
  
  /// Clear all cached users
  Future<void> clearCache() async {
    await _box?.clear();
    print('🗑️  User cache cleared');
  }
  
  /// Update a single user in cache
  Future<void> updateUser(UserResponseDto user) async {
    await _box?.put('user_${user.id}', user.copyWith(cachedAt: DateTime.now()));
  }
  
  /// Delete a user from cache
  Future<void> deleteUser(int userId) async {
    await _box?.delete('user_$userId');
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalUsers': _box?.length ?? 0,
      'cacheAgeMinutes': getCacheAgeMinutes(),
      'isFresh': isCacheFresh(),
      'lastCacheTime': _box?.isNotEmpty ?? false 
          ? _box!.values.first.cachedAt.toIso8601String()
          : null,
    };
  }
  
  /// Close the box
  void dispose() {
    _box?.close();
  }
}

