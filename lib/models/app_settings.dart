import 'package:flutter/material.dart';

class AppSettings {
  final bool isDarkMode;
  final bool use24HourTime;
  final double sleepGoalHours;
  final String userName;
  final List<bool> activeDays;

  // Reminders stored as nullable hour/minute ints for easy JSON serialisation
  final DateTime? bedtimeDate;
  final DateTime? wakeDate;
  final int? bedtimeHour;
  final int? bedtimeMinute;
  final int? wakeHour;
  final int? wakeMinute;
  final bool bedtimeEnabled;
  final bool wakeEnabled;

  // Custom sound file paths (null = use built-in default)
  final String? bedtimeSound;
  final String? wakeSound;
  final double eyeComfortWarmth; // 0.0 - 1.0

  const AppSettings({
    this.isDarkMode = true,
    this.use24HourTime = false,
    this.sleepGoalHours = 8.0,
    this.userName = 'Jeicel',
    this.activeDays = const [true, true, true, true, true, true, true],
    this.bedtimeDate,
    this.wakeDate,
    this.bedtimeHour,
    this.bedtimeMinute,
    this.wakeHour,
    this.wakeMinute,
    this.bedtimeEnabled = false,
    this.wakeEnabled = false,
    this.bedtimeSound,
    this.wakeSound,
    this.eyeComfortWarmth = 0.35,
  });

  TimeOfDay? get bedtimeReminder => bedtimeHour != null
      ? TimeOfDay(hour: bedtimeHour!, minute: bedtimeMinute ?? 0)
      : null;

  TimeOfDay? get wakeReminder => wakeHour != null
      ? TimeOfDay(hour: wakeHour!, minute: wakeMinute ?? 0)
      : null;

  DateTime? get bedtimeReminderDate => bedtimeDate;
  DateTime? get wakeReminderDate => wakeDate;

  AppSettings copyWith({
    bool? isDarkMode,
    bool? use24HourTime,
    double? sleepGoalHours,
    String? userName,
    List<bool>? activeDays,
    DateTime? bedtimeDate,
    DateTime? wakeDate,
    int? bedtimeHour,
    int? bedtimeMinute,
    int? wakeHour,
    int? wakeMinute,
    bool? bedtimeEnabled,
    bool? wakeEnabled,
    String? bedtimeSound,
    String? wakeSound,
    double? eyeComfortWarmth,
    // Explicit clear flags so callers can set a field back to null
    bool clearBedtime = false,
    bool clearWake = false,
    bool clearBedtimeSound = false,
    bool clearWakeSound = false,
  }) =>
      AppSettings(
        isDarkMode: isDarkMode ?? this.isDarkMode,
        use24HourTime: use24HourTime ?? this.use24HourTime,
        sleepGoalHours: sleepGoalHours ?? this.sleepGoalHours,
        userName: userName ?? this.userName,
        activeDays: activeDays ?? this.activeDays,
        bedtimeDate: bedtimeDate ?? this.bedtimeDate,
        wakeDate: wakeDate ?? this.wakeDate,
        bedtimeHour: clearBedtime ? null : (bedtimeHour ?? this.bedtimeHour),
        bedtimeMinute:
            clearBedtime ? null : (bedtimeMinute ?? this.bedtimeMinute),
        wakeHour: clearWake ? null : (wakeHour ?? this.wakeHour),
        wakeMinute: clearWake ? null : (wakeMinute ?? this.wakeMinute),
        bedtimeEnabled: bedtimeEnabled ?? this.bedtimeEnabled,
        wakeEnabled: wakeEnabled ?? this.wakeEnabled,
        bedtimeSound:
            clearBedtimeSound ? null : (bedtimeSound ?? this.bedtimeSound),
        wakeSound: clearWakeSound ? null : (wakeSound ?? this.wakeSound),
        eyeComfortWarmth: eyeComfortWarmth ?? this.eyeComfortWarmth,
      );

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'use24HourTime': use24HourTime,
        'sleepGoalHours': sleepGoalHours,
        'userName': userName,
        'activeDays': activeDays,
        'bedtimeDate': bedtimeDate?.toIso8601String(),
        'wakeDate': wakeDate?.toIso8601String(),
        'bedtimeHour': bedtimeHour,
        'bedtimeMinute': bedtimeMinute,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
        'bedtimeEnabled': bedtimeEnabled,
        'wakeEnabled': wakeEnabled,
        'bedtimeSound': bedtimeSound,
        'wakeSound': wakeSound,
        'eyeComfortWarmth': eyeComfortWarmth,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        isDarkMode: j['isDarkMode'] as bool? ?? true,
        use24HourTime: j['use24HourTime'] as bool? ?? false,
        sleepGoalHours: (j['sleepGoalHours'] as num?)?.toDouble() ?? 8.0,
        userName: j['userName'] as String? ?? 'Jeicel',
        activeDays: (j['activeDays'] as List<dynamic>?)
                ?.map((v) => v as bool)
                .toList() ??
            const [true, true, true, true, true, true, true],
        bedtimeDate: j['bedtimeDate'] != null
            ? DateTime.tryParse(j['bedtimeDate'] as String)
            : null,
        wakeDate: j['wakeDate'] != null
            ? DateTime.tryParse(j['wakeDate'] as String)
            : null,
        bedtimeHour: j['bedtimeHour'] as int?,
        bedtimeMinute: j['bedtimeMinute'] as int?,
        wakeHour: j['wakeHour'] as int?,
        wakeMinute: j['wakeMinute'] as int?,
        bedtimeEnabled: j['bedtimeEnabled'] as bool? ?? false,
        wakeEnabled: j['wakeEnabled'] as bool? ?? false,
        bedtimeSound: j['bedtimeSound'] as String?,
        wakeSound: j['wakeSound'] as String?,
        eyeComfortWarmth: (j['eyeComfortWarmth'] as num?)?.toDouble() ?? 0.35,
      );
}
