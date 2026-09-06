import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheKeys {
  CacheKeys._();

  static const String dashboard = 'cache.dashboard';
  static const String attendanceHourly = 'cache.attendance_hourly';
  static const String attendanceSummary = 'cache.attendance_summary';
  static const String marks = 'cache.marks';
  static const String subjects = 'cache.subjects';
  static const String profile = 'cache.profile';
}

/// Result returned by the versioned fetch methods on services.
class FetchResult<T> {
  const FetchResult({required this.data, required this.changed});

  final T data;

  /// True when the freshly fetched payload differs from the cached version,
  /// meaning the UI should update even if it is already showing cached data.
  final bool changed;
}

/// Lightweight offline cache that stores the last known payload for each
/// endpoint along with a stable version hash. On every fetch the new payload
/// is compared against the stored version so that screens can re-render only
/// when the underlying data actually changed.
class DataCache {
  DataCache._();

  static final DataCache instance = DataCache._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static String versionOf(String raw) {
    // MD5 of the serialized payload: deterministic and stable on every
    // platform (including web), unlike a platform-specific hash.
    return md5.convert(utf8.encode(raw)).toString();
  }

  String _versionKey(String key) => '$key._version';
  String _rawKey(String key) => '$key._raw';

  Future<void> save(String key, dynamic data) async {
    final sp = await _sp;
    final raw = jsonEncode(data);
    await sp.setString(_rawKey(key), raw);
    await sp.setString(_versionKey(key), versionOf(raw));
  }

  Future<dynamic> load(String key) async {
    final raw = await loadRaw(key);
    if (raw == null) return null;
    return jsonDecode(raw);
  }

  Future<String?> loadRaw(String key) async {
    final sp = await _sp;
    return sp.getString(_rawKey(key));
  }

  Future<String?> loadVersion(String key) async {
    final sp = await _sp;
    return sp.getString(_versionKey(key));
  }

  /// Compares a fresh payload against the cached version.
  Future<bool> isChanged(String key, dynamic newData) async {
    final sp = await _sp;
    final currentVersion = sp.getString(_versionKey(key));
    if (currentVersion == null) return true;
    return currentVersion != versionOf(jsonEncode(newData));
  }

  Future<void> clearAll() async {
    final sp = await _sp;
    for (final key in [CacheKeys.dashboard, CacheKeys.attendanceHourly, CacheKeys.attendanceSummary, CacheKeys.marks, CacheKeys.subjects, CacheKeys.profile]) {
      await sp.remove(_rawKey(key));
      await sp.remove(_versionKey(key));
    }
  }
}