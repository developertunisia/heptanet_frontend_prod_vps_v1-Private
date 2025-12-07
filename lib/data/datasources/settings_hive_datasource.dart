import 'package:hive_flutter/hive_flutter.dart';

/// App settings and preferences storage with Hive
/// Much faster than SharedPreferences or FlutterSecureStorage for non-sensitive data
class SettingsHiveDataSource {
  static const String _boxName = 'app_settings';
  
  Box? _box;
  
  /// Initialize Hive and open the settings box
  Future<void> init() async {
    try {
      _box = await Hive.openBox(_boxName);
      print('✅ SettingsHiveDataSource initialized');
    } catch (e) {
      print('❌ Error initializing SettingsHiveDataSource: $e');
      rethrow;
    }
  }
  
  // ========== Sync Management ==========
  
  /// Save last sync time for users
  Future<void> setLastUserSyncTime(DateTime time) async {
    await _box?.put('last_user_sync', time.toIso8601String());
  }
  
  /// Get last user sync time
  DateTime? getLastUserSyncTime() {
    final time = _box?.get('last_user_sync') as String?;
    return time != null ? DateTime.tryParse(time) : null;
  }
  
  /// Save last sync time for authorized emails
  Future<void> setLastEmailSyncTime(DateTime time) async {
    await _box?.put('last_email_sync', time.toIso8601String());
  }
  
  /// Get last email sync time
  DateTime? getLastEmailSyncTime() {
    final time = _box?.get('last_email_sync') as String?;
    return time != null ? DateTime.tryParse(time) : null;
  }
  
  // ========== Theme Settings ==========
  
  /// Set theme mode (light, dark, system)
  Future<void> setThemeMode(String mode) async {
    await _box?.put('theme_mode', mode);
  }
  
  /// Get theme mode
  String getThemeMode() {
    return _box?.get('theme_mode', defaultValue: 'light') as String;
  }
  
  // ========== User Preferences ==========
  
  /// Set auto-sync enabled
  Future<void> setAutoSyncEnabled(bool enabled) async {
    await _box?.put('auto_sync_enabled', enabled);
  }
  
  /// Get auto-sync enabled
  bool getAutoSyncEnabled() {
    return _box?.get('auto_sync_enabled', defaultValue: true) as bool;
  }
  
  /// Set cache duration in minutes
  Future<void> setCacheDuration(int minutes) async {
    await _box?.put('cache_duration_minutes', minutes);
  }
  
  /// Get cache duration in minutes
  int getCacheDuration() {
    return _box?.get('cache_duration_minutes', defaultValue: 5) as int;
  }
  
  /// Set offline mode enabled
  Future<void> setOfflineModeEnabled(bool enabled) async {
    await _box?.put('offline_mode_enabled', enabled);
  }
  
  /// Get offline mode enabled
  bool getOfflineModeEnabled() {
    return _box?.get('offline_mode_enabled', defaultValue: false) as bool;
  }
  
  // ========== App State ==========
  
  /// Set first launch flag
  Future<void> setFirstLaunch(bool isFirst) async {
    await _box?.put('is_first_launch', isFirst);
  }
  
  /// Check if first launch
  bool isFirstLaunch() {
    return _box?.get('is_first_launch', defaultValue: true) as bool;
  }
  
  /// Set onboarding completed
  Future<void> setOnboardingCompleted(bool completed) async {
    await _box?.put('onboarding_completed', completed);
  }
  
  /// Check if onboarding completed
  bool isOnboardingCompleted() {
    return _box?.get('onboarding_completed', defaultValue: false) as bool;
  }
  
  // ========== Debug & Logging ==========
  
  /// Enable debug mode
  Future<void> setDebugMode(bool enabled) async {
    await _box?.put('debug_mode', enabled);
  }
  
  /// Check if debug mode enabled
  bool isDebugMode() {
    return _box?.get('debug_mode', defaultValue: false) as bool;
  }
  
  /// Save app version
  Future<void> setAppVersion(String version) async {
    await _box?.put('app_version', version);
  }
  
  /// Get app version
  String? getAppVersion() {
    return _box?.get('app_version') as String?;
  }
  
  // ========== General ==========
  
  /// Save a custom setting
  Future<void> setValue(String key, dynamic value) async {
    await _box?.put(key, value);
  }
  
  /// Get a custom setting
  dynamic getValue(String key, {dynamic defaultValue}) {
    return _box?.get(key, defaultValue: defaultValue);
  }
  
  /// Remove a setting
  Future<void> removeValue(String key) async {
    await _box?.delete(key);
  }
  
  /// Check if a key exists
  bool hasKey(String key) {
    return _box?.containsKey(key) ?? false;
  }
  
  /// Get all settings
  Map<String, dynamic> getAllSettings() {
    return Map<String, dynamic>.from(_box?.toMap() ?? {});
  }
  
  /// Clear all settings
  Future<void> clearAll() async {
    await _box?.clear();
    print('🗑️  All settings cleared');
  }
  
  /// Close the box
  void dispose() {
    _box?.close();
  }
}

