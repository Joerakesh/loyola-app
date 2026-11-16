import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';
import '../models/college_announcement.dart';

class CollegeUpdatesService {
  CollegeUpdatesService(this._apiClient);

  static const _calendarCacheTtl = Duration(minutes: 30);
  static const _announcementVersionKey = 'college_updates.announcement_version';
  static const _announcementDataKey = 'college_updates.announcements';

  final ApiClient _apiClient;
  final Map<String, Timer> _calendarExpiryTimers = {};

  Future<Map<String, dynamic>> fetchUpdates({bool refresh = false}) async {
    final response = await _apiClient.dio.get(
      ApiConstants.collegeUpdates,
      queryParameters: refresh ? {'refresh': 1} : null,
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic> || payload['status'] != 'success') {
      throw Exception(
        payload is Map && payload['message'] != null
            ? payload['message'].toString()
            : 'Unable to load college updates',
      );
    }

    final data = payload['data'];
    if (data is! Map) {
      throw Exception('The college updates API returned an invalid response');
    }

    final updates = data.cast<String, dynamic>();
    await _applyAnnouncementVersion(updates);
    return updates;
  }

  /// Keeps the locally displayed notices when the archive version is unchanged.
  /// A changed version replaces the cached notices with the new server snapshot.
  Future<void> _applyAnnouncementVersion(Map<String, dynamic> updates) async {
    final version = int.tryParse(updates['announcementVersion']?.toString() ?? '');
    final remoteAnnouncements = updates['announcements'];
    if (version == null || remoteAnnouncements is! List) return;

    final preferences = await SharedPreferences.getInstance();
    final cachedVersion = preferences.getInt(_announcementVersionKey);
    final cachedRaw = preferences.getString(_announcementDataKey);

    if (cachedVersion == version && cachedRaw != null) {
      try {
        final cached = jsonDecode(cachedRaw);
        if (cached is List) {
          updates['announcements'] = cached;
          return;
        }
      } catch (_) {
        // Replace malformed local data with the valid API response below.
      }
    }

    await preferences.setString(_announcementDataKey, jsonEncode(remoteAnnouncements));
    await preferences.setInt(_announcementVersionKey, version);
  }

  Future<List<CollegeAnnouncement>> fetchAnnouncements({bool refresh = false}) async {
    final updates = await fetchUpdates(refresh: refresh);
    final rawAnnouncements = updates['announcements'];
    if (rawAnnouncements is! List) return const [];

    return rawAnnouncements
        .whereType<Map>()
        .map((item) => CollegeAnnouncement.fromJson(item.cast<String, dynamic>()))
        .where((item) => item.title.isNotEmpty && item.url.isNotEmpty)
        .toList(growable: false);
  }

  Future<Map<String, dynamic>> fetchCalendarMonth({
    required int year,
    required int month,
    bool refresh = false,
  }) async {
    final cacheKey =
        'cache.college_calendar.$year-${month.toString().padLeft(2, '0')}';
    final preferences = await SharedPreferences.getInstance();

    if (!refresh) {
      final rawCache = preferences.getString(cacheKey);
      if (rawCache != null) {
        try {
          final cached = jsonDecode(rawCache);
          final expiresAt = cached is Map
              ? int.tryParse(cached['expiresAt']?.toString() ?? '')
              : null;
          final data = cached is Map ? cached['data'] : null;
          if (expiresAt != null &&
              expiresAt > DateTime.now().millisecondsSinceEpoch &&
              data is Map) {
            return data.cast<String, dynamic>();
          }
        } catch (_) {
          // Discard malformed or expired cache and fetch a fresh response.
        }
        _calendarExpiryTimers.remove(cacheKey)?.cancel();
        await preferences.remove(cacheKey);
      }
    }

    final response = await _apiClient.dio.get(
      ApiConstants.collegeCalendar,
      queryParameters: {
        'year': year,
        'month': month,
        if (refresh) 'refresh': 1,
      },
    );

    final payload = response.data;
    if (payload is! Map<String, dynamic> || payload['status'] != 'success') {
      throw Exception(
        payload is Map && payload['message'] != null
            ? payload['message'].toString()
            : 'Unable to load the requested academic calendar month',
      );
    }

    final data = payload['data'];
    if (data is! Map) {
      throw Exception('The academic calendar API returned an invalid response');
    }

    final calendar = data.cast<String, dynamic>();
    final expiresAt = DateTime.now().add(_calendarCacheTtl);
    final encodedCache = jsonEncode({
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'data': calendar,
    });
    await preferences.setString(cacheKey, encodedCache);

    _calendarExpiryTimers.remove(cacheKey)?.cancel();
    _calendarExpiryTimers[cacheKey] = Timer(_calendarCacheTtl, () {
      unawaited(_removeCalendarCache(cacheKey, encodedCache));
    });

    return calendar;
  }

  Future<void> _removeCalendarCache(String key, String expectedValue) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString(key) == expectedValue) {
      await preferences.remove(key);
    }
    _calendarExpiryTimers.remove(key);
  }
}
