import '../../domain/repositories/user_repository.dart';
import '../../domain/models/register_user_dto.dart';
import '../../domain/models/user_response_dto.dart';
import '../datasources/user_api_client.dart';
import '../datasources/user_hive_datasource.dart';
import '../datasources/settings_hive_datasource.dart';

/// User repository with intelligent Hive caching
/// 
/// Cache strategy:
/// 1. Try cache first if fresh (< 5 minutes)
/// 2. If cache miss or stale, fetch from API
/// 3. Save to cache for future use
/// 4. On API error, fallback to cache (offline support)
class UserRepositoryImpl implements UserRepository {
  final UserApiClient _apiClient;
  final UserHiveDataSource _hiveDataSource;
  final SettingsHiveDataSource _settingsDataSource;

  UserRepositoryImpl({
    UserApiClient? apiClient,
    UserHiveDataSource? hiveDataSource,
    SettingsHiveDataSource? settingsDataSource,
  })  : _apiClient = apiClient ?? UserApiClient(),
        _hiveDataSource = hiveDataSource ?? UserHiveDataSource(),
        _settingsDataSource = settingsDataSource ?? SettingsHiveDataSource() {
    // Initialize Hive datasources if not already initialized
    if (hiveDataSource == null) {
      _hiveDataSource.init().catchError((e) {
        print('⚠️  Hive not initialized in UserRepository: $e');
      });
    }
    if (settingsDataSource == null) {
      _settingsDataSource.init().catchError((e) {
        print('⚠️  Settings not initialized in UserRepository: $e');
      });
    }
  }

  @override
  Future<UserResponseDto> registerUser(RegisterUserDto dto) async {
    try {
      final user = await _apiClient.registerUser(dto);
      
      // Add new user to cache
      await _hiveDataSource.updateUser(user);
      
      return user;
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }

  @override
  Future<List<UserResponseDto>> getAllUsers({
    bool? excludeBlacklisted,
    String? roleName,
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Try cache first if fresh and not force refresh
      if (!forceRefresh && _hiveDataSource.isCacheFresh()) {
        print('✅ Loading users from cache (${_hiveDataSource.getCacheAgeMinutes()}min old)');
        var users = _hiveDataSource.getAllUsers();
        
        // Apply filters on cached data (super fast!)
        if (excludeBlacklisted == true) {
          users = users.where((u) => !u.isBlacklisted).toList();
        }
        if (roleName != null && roleName.isNotEmpty) {
          users = _hiveDataSource.getUsersByRole(roleName);
        }
        
        return users;
      }
      
      // 2. Cache is stale or force refresh - fetch from API
      print('📡 Fetching users from API (cache ${forceRefresh ? "forced" : "stale"})');
      final users = await _apiClient.getAllUsers(
        excludeBlacklisted: excludeBlacklisted,
        roleName: roleName,
      );
      
      // 3. Save to cache for future use
      await _hiveDataSource.saveUsers(users);
      await _settingsDataSource.setLastUserSyncTime(DateTime.now());
      
      print('✅ Fetched and cached ${users.length} users');
      return users;
      
    } catch (e) {
      // 4. API failed - try to use cached data (offline support!)
      if (_hiveDataSource.hasCache()) {
        print('⚠️ API failed, using cached data (${_hiveDataSource.getCacheAgeMinutes()}min old)');
        var users = _hiveDataSource.getAllUsers();
        
        // Apply filters even on cached fallback data
        if (excludeBlacklisted == true) {
          users = users.where((u) => !u.isBlacklisted).toList();
        }
        if (roleName != null && roleName.isNotEmpty) {
          users = _hiveDataSource.getUsersByRole(roleName);
        }
        
        return users;
      }
      
      // No cache available, rethrow error
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }
  
  /// Search users (uses cache if available)
  Future<List<UserResponseDto>> searchUsers(String query) async {
    // Try to use cache first for instant search
    if (_hiveDataSource.hasCache()) {
      return _hiveDataSource.searchUsers(query);
    }
    
    // No cache - fetch all users first
    await getAllUsers();
    return _hiveDataSource.searchUsers(query);
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _hiveDataSource.getCacheStats();
  }
  
  /// Clear user cache manually
  Future<void> clearCache() async {
    await _hiveDataSource.clearCache();
  }
}