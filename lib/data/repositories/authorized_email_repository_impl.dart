import '../../domain/repositories/authorized_email_repository.dart';
import '../../domain/models/authorized_email_dto.dart';
import '../datasources/authorized_email_api_client.dart';
import '../datasources/authorized_email_hive_datasource.dart';
import '../datasources/settings_hive_datasource.dart';

/// Authorized email repository with intelligent Hive caching
/// 
/// Cache strategy:
/// 1. Try cache first if fresh (< 10 minutes)
/// 2. If cache miss or stale, fetch from API
/// 3. Save to cache for future use
/// 4. On API error, fallback to cache (offline support)
class AuthorizedEmailRepositoryImpl implements AuthorizedEmailRepository {
  final AuthorizedEmailApiClient _apiClient;
  final AuthorizedEmailHiveDataSource _hiveDataSource;
  final SettingsHiveDataSource _settingsDataSource;

  AuthorizedEmailRepositoryImpl({
    AuthorizedEmailApiClient? apiClient,
    AuthorizedEmailHiveDataSource? hiveDataSource,
    SettingsHiveDataSource? settingsDataSource,
  })  : _apiClient = apiClient ?? AuthorizedEmailApiClient(),
        _hiveDataSource = hiveDataSource ?? AuthorizedEmailHiveDataSource(),
        _settingsDataSource = settingsDataSource ?? SettingsHiveDataSource() {
    // Initialize Hive datasources if not already initialized
    if (hiveDataSource == null) {
      _hiveDataSource.init().catchError((e) {
        print('⚠️  Hive not initialized in EmailRepository: $e');
      });
    }
    if (settingsDataSource == null) {
      _settingsDataSource.init().catchError((e) {
        print('⚠️  Settings not initialized in EmailRepository: $e');
      });
    }
  }

  @override
  Future<List<AuthorizedEmailDto>> getAllAuthorizedEmails({
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Try cache first if fresh and not force refresh
      if (!forceRefresh && _hiveDataSource.isCacheFresh()) {
        print('✅ Loading emails from cache (${_hiveDataSource.getCacheAgeMinutes()}min old)');
        return _hiveDataSource.getAllEmails();
      }
      
      // 2. Cache is stale or force refresh - fetch from API
      print('📡 Fetching emails from API (cache ${forceRefresh ? "forced" : "stale"})');
      final emails = await _apiClient.getAllAuthorizedEmails();
      
      // 3. Save to cache for future use
      await _hiveDataSource.saveEmails(emails);
      await _settingsDataSource.setLastEmailSyncTime(DateTime.now());
      
      print('✅ Fetched and cached ${emails.length} authorized emails');
      return emails;
      
    } catch (e) {
      // 4. API failed - try to use cached data (offline support!)
      if (_hiveDataSource.hasCache()) {
        print('⚠️ API failed, using cached emails (${_hiveDataSource.getCacheAgeMinutes()}min old)');
        return _hiveDataSource.getAllEmails();
      }
      
      // No cache available, rethrow error
      throw Exception('Erreur dans le repository: $e');
    }
  }

  @override
  Future<AuthorizedEmailDto> addAuthorizedEmail(AddAuthorizedEmailDto dto) async {
    try {
      final email = await _apiClient.addAuthorizedEmail(dto);
      
      // Add to cache immediately for instant UI update
      await _hiveDataSource.saveEmail(email);
      
      return email;
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }

  @override
  Future<void> activateEmail(UpdateEmailStatusDto dto) async {
    try {
      await _apiClient.activateEmail(dto);
      
      // Update cache after successful activation
      final cachedEmail = _hiveDataSource.findByEmail(dto.email);
      if (cachedEmail != null) {
        // Refresh the entire cache to get updated status
        await getAllAuthorizedEmails(forceRefresh: true);
      }
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }

  @override
  Future<void> deactivateEmail(UpdateEmailStatusDto dto) async {
    try {
      await _apiClient.deactivateEmail(dto);
      
      // Update cache after successful deactivation
      final cachedEmail = _hiveDataSource.findByEmail(dto.email);
      if (cachedEmail != null) {
        // Refresh the entire cache to get updated status
        await getAllAuthorizedEmails(forceRefresh: true);
      }
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }

  @override
  Future<void> deleteAuthorizedEmail(String email) async {
    try {
      await _apiClient.deleteAuthorizedEmail(email);
      
      // Remove from cache immediately
      await _hiveDataSource.deleteEmailByAddress(email);
      
      print('✅ Deleted email from API and cache: $email');
    } catch (e) {
      throw Exception('Erreur dans le repository: $e');
    }
  }
  
  /// Check if an email exists (uses cache if available)
  Future<bool> emailExists(String email) async {
    // Try cache first for instant check
    if (_hiveDataSource.hasCache()) {
      return _hiveDataSource.emailExists(email);
    }
    
    // No cache - fetch all emails first
    await getAllAuthorizedEmails();
    return _hiveDataSource.emailExists(email);
  }
  
  /// Search emails (uses cache)
  Future<List<AuthorizedEmailDto>> searchEmails(String query) async {
    if (_hiveDataSource.hasCache()) {
      return _hiveDataSource.searchEmails(query);
    }
    
    // No cache - fetch all emails first
    await getAllAuthorizedEmails();
    return _hiveDataSource.searchEmails(query);
  }
  
  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return _hiveDataSource.getCacheStats();
  }
  
  /// Clear email cache manually
  Future<void> clearCache() async {
    await _hiveDataSource.clearCache();
  }
}
