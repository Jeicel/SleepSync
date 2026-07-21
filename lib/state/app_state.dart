import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sleep_entry.dart';
import '../models/app_settings.dart';
import '../services/notification_service.dart';
import '../services/widget_service.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final _storage = StorageService();
  final _notifications = NotificationService();
  Timer? _eyeComfortTimer;

  List<SleepEntry> _entries = [];
  AppSettings _settings = const AppSettings();
  bool _loading = true;
  DateTime? _selectedSleepDate;
  DateTime? _selectedBedDate;
  DateTime? _selectedWakeDate;

  // ── Public getters ────────────────────────────────────────────────────────

  /// Active entries (not deleted)
  List<SleepEntry> get entries =>
      List.unmodifiable(_entries.where((e) => e.deletedAt == null).toList());

  /// Deleted entries in trash (not yet auto-purged)
  List<SleepEntry> get deletedEntries =>
      List.unmodifiable(_entries.where((e) => e.deletedAt != null).toList());

  AppSettings get settings => _settings;
  bool get isLoading => _loading;

  SleepEntry? get lastEntry {
    final active = entries;
    return active.isEmpty ? null : active.first;
  }

  /// Entries whose wake time falls within the last 7 days, newest first.
  List<SleepEntry> get last7Entries {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return entries.where((e) => e.wakeTime.isAfter(cutoff)).take(7).toList();
  }

  /// Consecutive-day streak ending today or yesterday.
  int get currentStreak {
    if (entries.isEmpty) return 0;

    final today = _dateOnly(DateTime.now());
    final daySet = <DateTime>{};
    for (final e in entries) {
      daySet.add(_dateOnly(e.wakeTime));
    }

    // Allow streak to start from today or yesterday (log next morning)
    DateTime start = today;
    if (!daySet.contains(start)) {
      start = today.subtract(const Duration(days: 1));
      if (!daySet.contains(start)) return 0;
    }

    int streak = 0;
    DateTime check = start;
    while (daySet.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    try {
      await _notifications.init();
      _entries = await _storage.loadEntries();
      _settings = await _storage.loadSettings();
      _selectedSleepDate = await _storage.loadSelectedSleepDate();
      _selectedBedDate = await _storage.loadSelectedBedDate();
      _selectedWakeDate = await _storage.loadSelectedWakeDate();
      await _cleanupExpiredTrashItems(); // Auto-cleanup 7+ day old trash items
      await _notifications.sync(_settings);
      // Push initial readiness widget state
      _pushReadinessWidget();
    } finally {
      _loading = false;
      notifyListeners();
      _startEyeComfortTimer();
    }
  }

  void _startEyeComfortTimer() {
    _eyeComfortTimer?.cancel();
    _eyeComfortTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _eyeComfortTimer?.cancel();
    super.dispose();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> addEntry(SleepEntry entry) async {
    _entries
      ..insert(0, entry)
      ..sort((a, b) => b.bedtime.compareTo(a.bedtime));
    await _storage.saveEntries(_entries);
    notifyListeners();
    _pushReadinessWidget();
  }

  Future<void> updateEntry(SleepEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = entry;
      _entries.sort((a, b) => b.bedtime.compareTo(a.bedtime));
      await _storage.saveEntries(_entries);
      notifyListeners();
      _pushReadinessWidget();
    }
  }

  /// Soft delete: move entry to trash (set deletedAt timestamp)
  Future<void> deleteEntry(String id) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _entries[idx] = _entries[idx].copyWith(deletedAt: DateTime.now());
      await _storage.saveEntries(_entries);
      notifyListeners();
      _pushReadinessWidget();
    }
  }

  /// Restore entry from trash (clear deletedAt timestamp)
  Future<void> restoreFromTrash(String id) async {
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _entries[idx] = _entries[idx].copyWith(deletedAt: null);
      _entries.sort((a, b) => b.bedtime.compareTo(a.bedtime));
      await _storage.saveEntries(_entries);
      notifyListeners();
      _pushReadinessWidget();
    }
  }

  /// Hard delete: permanently remove entry from trash
  Future<void> permanentlyDeleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
    await _storage.saveEntries(_entries);
    notifyListeners();
  }

  /// Auto-cleanup: permanently delete entries older than 7 days in trash
  Future<void> _cleanupExpiredTrashItems() async {
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final initialCount = _entries.length;
    _entries.removeWhere(
        (e) => e.deletedAt != null && e.deletedAt!.isBefore(sevenDaysAgo));
    if (initialCount != _entries.length) {
      await _storage.saveEntries(_entries);
    }
  }

  Future<void> updateSettings(AppSettings s) async {
    _settings = s;
    try {
      await _storage.saveSettings(s);
      await _notifications.sync(_settings);
    } finally {
      notifyListeners();
      _startEyeComfortTimer();
      _pushReadinessWidget();
    }
  }

  Future<void> clearAllData() async {
    _entries = [];
    _settings = const AppSettings();
    _selectedSleepDate = null;
    _selectedBedDate = null;
    _selectedWakeDate = null;
    try {
      await _storage.clearAll();
      await _notifications.sync(_settings);
    } finally {
      notifyListeners();
    }
  }

  /// Selected date shown when logging sleep. Falls back to yesterday.
  DateTime get selectedSleepDate =>
      _selectedSleepDate ?? DateTime.now().subtract(const Duration(days: 1));

  Future<void> setSelectedSleepDate(DateTime d) async {
    _selectedSleepDate = DateTime(d.year, d.month, d.day);
    await _storage.saveSelectedSleepDate(_selectedSleepDate!);
    notifyListeners();
  }

  /// Selected bed date (date part used with bedtime).
  DateTime get selectedBedDate =>
      _selectedBedDate ?? DateTime.now().subtract(const Duration(days: 1));

  Future<void> setSelectedBedDate(DateTime d) async {
    _selectedBedDate = DateTime(d.year, d.month, d.day);
    await _storage.saveSelectedBedDate(_selectedBedDate!);
    notifyListeners();
  }

  /// Selected wake date (date part used with wake time). Defaults to today.
  DateTime get selectedWakeDate => _selectedWakeDate ?? DateTime.now();

  Future<void> setSelectedWakeDate(DateTime d) async {
    _selectedWakeDate = DateTime(d.year, d.month, d.day);
    await _storage.saveSelectedWakeDate(_selectedWakeDate!);
    notifyListeners();
  }
  // ── Notification permission helpers ───────────────────────────────────────
  // Exposed so RemindersScreen can show/hide the permission banner.

  Future<bool> hasNotificationPermission() => _notifications.hasPermission();
  Future<bool> requestNotificationPermission() =>
      _notifications.requestPermission();

  /// True only if the basic notification permission is missing. Used to
  /// decide which banner copy to show (vs. exact-alarm being the gap).
  Future<bool> hasBasicNotificationPermission() =>
      _notifications.hasNotificationPermission();

  /// True if exact-alarm scheduling is blocked — this is the permission
  /// that silently prevents bedtime/wake-up reminders from firing even
  /// when basic notification permission looks fine.
  Future<bool> hasExactAlarmPermission() =>
      _notifications.hasExactAlarmPermission();

  // ── Time formatting ───────────────────────────────────────────────────────

  String formatTime(DateTime dt) => _settings.use24HourTime
      ? '${_p2(dt.hour)}:${_p2(dt.minute)}'
      : '${_h12(dt.hour)}:${_p2(dt.minute)} ${dt.hour < 12 ? 'AM' : 'PM'}';

  String formatTimeOfDay(TimeOfDay t) => _settings.use24HourTime
      ? '${_p2(t.hour)}:${_p2(t.minute)}'
      : '${_h12(t.hour)}:${_p2(t.minute)} ${t.hour < 12 ? 'AM' : 'PM'}';

  // ── Eye comfort helpers ───────────────────────────────────────────────
  /// Returns whether the in-app eye comfort overlay should be applied now.
  /// It is enabled 30 minutes before the bedtime reminder time and turns off
  /// exactly when the reminder time arrives.
  bool shouldApplyEyeComfort() {
    return shouldApplyEyeComfortAt(DateTime.now(), _settings);
  }

  bool shouldApplyEyeComfortAt(DateTime now, AppSettings settings) {
    final bedtime = settings.bedtimeReminder;
    if (bedtime == null || !settings.bedtimeEnabled) return false;

    final currentMinutes = now.hour * 60 + now.minute;
    final bedtimeMinutes = bedtime.hour * 60 + bedtime.minute;
    final startMinutes = (bedtimeMinutes - 30 + 24 * 60) % (24 * 60);

    if (startMinutes <= bedtimeMinutes) {
      return currentMinutes >= startMinutes && currentMinutes < bedtimeMinutes;
    }

    return currentMinutes >= startMinutes || currentMinutes < bedtimeMinutes;
  }

  double get eyeComfortWarmth => _settings.eyeComfortWarmth;

  // ── Widget integration ─────────────────────────────────────────────────

  void _pushReadinessWidget() {
    try {
      final lastDuration = lastEntry?.durationLabel ?? '--';
      final lastWake =
          lastEntry != null ? formatTime(lastEntry!.wakeTime) : '--';
      final streakUnit = currentStreak == 1 ? 'day' : 'days';
      final streak = '$currentStreak $streakUnit';

      final target = '${_settings.sleepGoalHours.toStringAsFixed(1)}h';

      WidgetService.updateWidget('readiness', {
        'countdown': lastDuration,
        'target_goal': target,
        'last_wake': lastWake,
        'sleep_streak': streak,
      });
    } catch (_) {}
  }

  // ── Content helpers ───────────────────────────────────────────────────────

  String get greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  /// Returns a sleep tip based on last night's duration vs. goal.
  /// Falls back to a daily-rotating general tip when no entry exists.
  String get sleepTip {
    final entry = lastEntry;

    if (entry != null) {
      final dur = entry.durationHours;
      final goal = _settings.sleepGoalHours;

      if (dur < goal - 2) {
        return 'You only slept ${entry.durationLabel} — more than 2 hours below '
            'your ${goal.toStringAsFixed(1)}h goal. Chronic sleep debt raises cortisol '
            'and impairs memory. Try going to bed 30–60 minutes earlier tonight.';
      }
      if (dur < goal - 1) {
        return 'You got ${entry.durationLabel} last night — about '
            '${(goal - dur).toStringAsFixed(1)} hours short of your goal. '
            'Even a small deficit adds up over time. Dim the lights 30 minutes before bed to boost melatonin.';
      }
      if (dur < goal) {
        return 'Almost there! ${entry.durationLabel} is just under your '
            '${goal.toStringAsFixed(1)}h goal. Avoid screens in the last 30 minutes '
            'and stick to a consistent bedtime every night.';
      }
      if (dur <= goal + 1) {
        return 'Great job hitting your ${goal.toStringAsFixed(1)}h goal with '
            '${entry.durationLabel}! Consistency is key — keep the same wake time '
            'even on weekends to anchor your body clock.';
      }
      return 'You slept ${entry.durationLabel} — a bit more than usual. '
          'Occasional oversleeping can cause grogginess. Try to stay within '
          '1 hour of your ${goal.toStringAsFixed(1)}h goal for the best energy levels.';
    }

    // No entry yet — rotate through general tips daily
    const tips = [
      'Avoid screens at least 1 hour before bed. Blue light suppresses melatonin and delays sleep onset.',
      'Keep your bedroom cool — around 18–20 °C (65–68 °F) is ideal for deep, restorative sleep.',
      'Try to wake up at the same time every day, even on weekends, to anchor your internal body clock.',
      'Avoid caffeine after 2 PM. Its half-life is about 5 hours, so an afternoon coffee can disrupt sleep.',
      'A short 10–20 minute nap before 3 PM can boost alertness without affecting your night sleep.',
      'Alcohol may make you feel drowsy but it fragments sleep cycles and suppresses REM sleep.',
      'Getting morning sunlight within 30 minutes of waking helps set your circadian clock for the day.',
    ];
    return tips[DateTime.now().day % tips.length];
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static String _p2(int n) => n.toString().padLeft(2, '0');
  static int _h12(int h) => h % 12 == 0 ? 12 : h % 12;
}
