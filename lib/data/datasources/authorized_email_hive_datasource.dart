import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/authorized_email_dto.dart';

/// High-performance authorized email caching with Hive
class AuthorizedEmailHiveDataSource {
  static const String _boxName = 'authorized_emails_cache';
  static const int _cacheValidityMinutes = 10; // Cache expires after 10 minutes
  
  Box<AuthorizedEmailDto>? _box;
  
  /// Initialize Hive and open the authorized emails box
  Future<void> init() async {
    try {
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(AuthorizedEmailDtoAdapter());
      }
      _box = await Hive.openBox<AuthorizedEmailDto>(_boxName);
      print('✅ AuthorizedEmailHiveDataSource initialized');
    } catch (e) {
      print('❌ Error initializing AuthorizedEmailHiveDataSource: $e');
      rethrow;
    }
  }
  
  /// Save authorized emails to cache with timestamp
  Future<void> saveEmails(List<AuthorizedEmailDto> emails) async {
    try {
      final now = DateTime.now();
      final Map<String, AuthorizedEmailDto> emailMap = {
        for (var email in emails) 
          'email_${email.syncId}': email.copyWith(cachedAt: now)
      };
      await _box?.putAll(emailMap);
      print('✅ Cached ${emails.length} authorized emails');
    } catch (e) {
      print('❌ Error saving emails to cache: $e');
    }
  }
  
  /// Get all cached emails
  List<AuthorizedEmailDto> getAllEmails() {
    return _box?.values.toList() ?? [];
  }
  
  /// Find email by email address (fast lookup)
  AuthorizedEmailDto? findByEmail(String email) {
    try {
      return _box?.values.firstWhere(
        (e) => e.email.toLowerCase() == email.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
  
  /// Get imported emails only
  List<AuthorizedEmailDto> getImportedEmails() {
    return _box?.values
        .where((e) => e.isImported)
        .toList() ?? [];
  }
  
  /// Get manually added emails (not imported)
  List<AuthorizedEmailDto> getManualEmails() {
    return _box?.values
        .where((e) => !e.isImported)
        .toList() ?? [];
  }
  
  /// Search emails by partial match
  List<AuthorizedEmailDto> searchEmails(String query) {
    final lowerQuery = query.toLowerCase();
    return _box?.values
        .where((e) => e.email.toLowerCase().contains(lowerQuery))
        .toList() ?? [];
  }
  
  /// Check if an email exists in cache
  bool emailExists(String email) {
    return findByEmail(email) != null;
  }
  
  /// Check if cache is still valid (fresh)
  bool isCacheFresh() {
    if (_box?.isEmpty ?? true) return false;
    
    try {
      final firstEmail = _box!.values.first;
      final cacheAge = DateTime.now().difference(firstEmail.cachedAt);
      return cacheAge.inMinutes < _cacheValidityMinutes;
    } catch (e) {
      return false;
    }
  }
  
  /// Get cache age in minutes
  int getCacheAgeMinutes() {
    if (_box?.isEmpty ?? true) return 999;
    
    try {
      final firstEmail = _box!.values.first;
      return DateTime.now().difference(firstEmail.cachedAt).inMinutes;
    } catch (e) {
      return 999;
    }
  }
  
  /// Check if cache exists
  bool hasCache() {
    return (_box?.isNotEmpty ?? false);
  }
  
  /// Clear all cached emails
  Future<void> clearCache() async {
    await _box?.clear();
    print('🗑️  Authorized email cache cleared');
  }
  
  /// Add or update a single email in cache
  Future<void> saveEmail(AuthorizedEmailDto email) async {
    await _box?.put('email_${email.syncId}', email.copyWith(cachedAt: DateTime.now()));
  }
  
  /// Delete an email from cache by syncId
  Future<void> deleteEmailById(int syncId) async {
    await _box?.delete('email_$syncId');
  }
  
  /// Delete an email from cache by email address
  Future<void> deleteEmailByAddress(String email) async {
    final emailDto = findByEmail(email);
    if (emailDto != null) {
      await deleteEmailById(emailDto.syncId);
    }
  }
  
  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'totalEmails': _box?.length ?? 0,
      'importedCount': getImportedEmails().length,
      'manualCount': getManualEmails().length,
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

