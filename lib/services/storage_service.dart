import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sleep_entry.dart';
import '../models/app_settings.dart';

class StorageService {
  static const _entriesKey = 'sleep_entries_v1';
  static const _settingsKey = 'app_settings_v1';
  static const _selectedDateKey = 'selected_sleep_date_v1';
  static const _selectedBedDateKey = 'selected_bed_date_v1';
  static const _selectedWakeDateKey = 'selected_wake_date_v1';

  // ── Entries ───────────────────────────────────────────────────────────────

  Future<List<SleepEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_entriesKey);
      if (raw == null || raw.isEmpty) return [];

      final list = jsonDecode(raw) as List<dynamic>;
      final entries = <SleepEntry>[];
      for (final item in list) {
        try {
          entries.add(SleepEntry.fromJson(item as Map<String, dynamic>));
        } catch (_) {
          // Skip any single malformed entry; don't crash the whole load
        }
      }
      entries.sort((a, b) => b.bedtime.compareTo(a.bedtime));
      return entries;
    } catch (_) {
      return []; // Corrupt storage — return empty rather than crash
    }
  }

  Future<bool> saveEntries(List<SleepEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      return await prefs.setString(_entriesKey, json);
    } catch (_) {
      return false;
    }
  }

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_settingsKey);
      if (raw == null || raw.isEmpty) return const AppSettings();
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<bool> saveSettings(AppSettings s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_settingsKey, jsonEncode(s.toJson()));
    } catch (_) {
      return false;
    }
  }

  // ── Selected sleep date ─────────────────────────────────────────────────

  Future<DateTime?> loadSelectedSleepDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_selectedDateKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveSelectedSleepDate(DateTime d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_selectedDateKey, d.toIso8601String());
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> loadSelectedBedDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_selectedBedDateKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveSelectedBedDate(DateTime d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_selectedBedDateKey, d.toIso8601String());
    } catch (_) {
      return false;
    }
  }

  Future<DateTime?> loadSelectedWakeDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_selectedWakeDateKey);
      if (raw == null || raw.isEmpty) return null;
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  Future<bool> saveSelectedWakeDate(DateTime d) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_selectedWakeDateKey, d.toIso8601String());
    } catch (_) {
      return false;
    }
  }

  // ── Clear ─────────────────────────────────────────────────────────────────

  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_entriesKey);
      await prefs.remove(_settingsKey);
      return true;
    } catch (_) {
      return false;
    }
  }
}
