import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import 'widget_service.dart'; // ← IDAGDAG: palitan ng tamang path kung iba

/// Singleton notification + alarm service.
///
/// Bedtime reminder  → high-priority notification.
///                     Uses a custom system-ringtone sound when set,
///                     otherwise falls back to the bundled res/raw/bedtime_sound.
/// Wake-up alarm     → full-screen intent (shows even on lock screen,
///                     rings like an alarm on Android 13+).
///                     Uses a custom system-ringtone sound when set,
///                     otherwise falls back to the bundled res/raw/wakeup_sound.
/// Sleep goal alert  → notification 1 hour before bedtime (always uses
///                     the bedtime sound / custom bedtime sound).
///
/// Android custom-sound note:
///   Custom sounds are picked via Android's native RingtoneManager picker
///   (see RingtonePickerService / MainActivity.kt), which returns a
///   `content://` URI that NotificationManager can resolve directly — no
///   file copying or FileProvider setup needed. Because channels are cached
///   by Android once created, we use a dedicated channel per unique sound
///   URI (keyed on a hash of the URI) so picking a different sound always
///   gets its own channel without requiring an app reinstall.
class NotificationService {
  NotificationService._();
  factory NotificationService() => _instance;
  static final NotificationService _instance = NotificationService._();

  // ── Built-in channel IDs ───────────────────────────────────────────────────
  static const _bedtimeChannelId = 'sleep_bedtime_v5';
  static const _wakeChannelId = 'sleep_wakeup_alarm_v1';
  static const _goalChannelId = 'sleep_goal_v5';
  static const _channelName = 'Sleep reminders';
  static const _channelDesc = 'Bedtime, wake alarm, and sleep goal alerts';

  // ── Built-in sound file names (res/raw/, no extension) ────────────────────
  static const _bedtimeSoundRes = 'bedtime_sound';
  static const _wakeupSoundRes = 'wakeup_sound';

  // ── Notification IDs ───────────────────────────────────────────────────────
  static const _bedtimeId = 1000;
  static const _wakeId = 2000;
  static const _goalId = 3000;
  static const _testId = 9999;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  final _createdChannels = <String>{};

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    try {
      final zoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings:
          const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    if (Platform.isAndroid) await _createBuiltInChannels();
    _initialized = true;
  }

  // ── Built-in channels ──────────────────────────────────────────────────────

  Future<void> _createBuiltInChannels() async {
    final ap = _androidPlugin;
    if (ap == null) return;

    await ap.createNotificationChannel(
      const AndroidNotificationChannel(
        _bedtimeChannelId,
        'Bedtime Reminder',
        description: 'Nightly wind-down reminder',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_bedtimeSoundRes),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );

    await ap.createNotificationChannel(
      const AndroidNotificationChannel(
        _wakeChannelId,
        'Wake-Up Alarm',
        description: 'Morning wake-up alarm — rings on lock screen',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_wakeupSoundRes),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );

    await ap.createNotificationChannel(
      const AndroidNotificationChannel(
        _goalChannelId,
        'Sleep Goal Alert',
        description: '1-hour heads-up before bedtime',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound(_bedtimeSoundRes),
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      ),
    );

    _createdChannels
        .addAll([_bedtimeChannelId, _wakeChannelId, _goalChannelId]);
  }

  // ── Custom-sound channel (one per unique sound URI) ─────────────────────

  Future<String> _ensureCustomChannel({
    required String soundUri,
    required bool isAlarm,
  }) async {
    final hash = soundUri.hashCode.toRadixString(16);
    final channelId =
        isAlarm ? 'sleep_custom_alarm_$hash' : 'sleep_custom_bed_$hash';

    if (!_createdChannels.contains(channelId) && Platform.isAndroid) {
      final ap = _androidPlugin;
      if (ap != null) {
        await ap.createNotificationChannel(
          AndroidNotificationChannel(
            channelId,
            isAlarm ? 'Custom Wake-Up Alarm' : 'Custom Bedtime Reminder',
            description: isAlarm
                ? 'Morning alarm with custom sound'
                : 'Bedtime reminder with custom sound',
            importance: isAlarm ? Importance.max : Importance.high,
            playSound: true,
            sound: UriAndroidNotificationSound(soundUri),
            enableVibration: true,
            enableLights: true,
            showBadge: true,
          ),
        );
        _createdChannels.add(channelId);
      }
    }
    return channelId;
  }

  // ── Permission ─────────────────────────────────────────────────────────────

  Future<bool> hasNotificationPermission() async {
    if (Platform.isAndroid) {
      final granted = await _androidPlugin?.areNotificationsEnabled();
      return granted ?? true;
    }
    if (Platform.isIOS) {
      final settings = await _iosPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    return true;
  }

  Future<bool> hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final ap = _androidPlugin;
    if (ap == null) return true;
    try {
      return await ap.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> hasPermission() async {
    if (Platform.isIOS) {
      final settings = await _iosPlugin?.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    if (Platform.isAndroid) {
      final notif = await hasNotificationPermission();
      final exact = await hasExactAlarmPermission();
      return notif && exact;
    }
    return true;
  }

  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final ap = _androidPlugin;
      if (ap != null && !(await hasExactAlarmPermission())) {
        await ap.requestExactAlarmsPermission();
      }
      await ap?.requestNotificationsPermission();
      return hasPermission();
    }
    if (Platform.isIOS) {
      final result = await _iosPlugin?.requestPermissions(
          alert: true, badge: true, sound: true);
      return result ?? false;
    }
    return false;
  }

  // ── Test notification (instant) ────────────────────────────────────────────

  Future<void> showTestNotification({
    bool isBedtime = true,
    String? customSoundPath,
  }) async {
    await init();

    final AndroidNotificationDetails androidDetails;
    final DarwinNotificationDetails iosDetails;

    if (customSoundPath != null && Platform.isAndroid) {
      final channelId = await _ensureCustomChannel(
        soundUri: customSoundPath,
        isAlarm: !isBedtime,
      );
      androidDetails = AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: isBedtime ? Importance.high : Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: !isBedtime,
        icon: '@mipmap/ic_launcher',
        sound: UriAndroidNotificationSound(customSoundPath),
      );
      iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
    } else {
      final channelId = isBedtime ? _bedtimeChannelId : _wakeChannelId;
      final soundRes = isBedtime ? _bedtimeSoundRes : _wakeupSoundRes;
      androidDetails = AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDesc,
        importance: isBedtime ? Importance.high : Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: !isBedtime,
        icon: '@mipmap/ic_launcher',
        sound: RawResourceAndroidNotificationSound(soundRes),
      );
      iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: '$soundRes.aiff',
      );
    }

    await _plugin.show(
      id: _testId,
      title: isBedtime ? '🌙 Test — Bedtime Sound' : '⏰ Test — Wake-Up Alarm',
      body: isBedtime
          ? 'If you hear a custom sound, it is working!'
          : 'This is how your morning alarm will ring.',
      notificationDetails:
          NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  // ── Sync (called whenever settings change) ─────────────────────────────────

  Future<void> sync(AppSettings settings) async {
    // Skip on unsupported platforms (Windows, Web, etc.)
    if (!Platform.isAndroid && !Platform.isIOS) return;

    await init();
    await _plugin.cancelAll();

    final selectedDays = settings.activeDays;
    final hasSelectedDays = selectedDays.any((d) => d);

    // ── Bedtime reminder
    if (settings.bedtimeEnabled &&
        settings.bedtimeHour != null &&
        hasSelectedDays) {
      for (var i = 0; i < selectedDays.length; i++) {
        if (!selectedDays[i]) continue;
        await _schedule(
          id: _bedtimeId + i,
          hour: settings.bedtimeHour!,
          minute: settings.bedtimeMinute ?? 0,
          title: '🌙 Bedtime Reminder',
          body: 'Time to wind down and protect your sleep goal of '
              '${settings.sleepGoalHours.toStringAsFixed(1)} hours.',
          isAlarm: false,
          customSoundPath: settings.bedtimeSound,
          fallbackChannelId: _bedtimeChannelId,
          fallbackSoundRes: _bedtimeSoundRes,
          dayOfWeek: i + 1,
        );
      }
    }

    // ── Wake-up alarm
    if (settings.wakeEnabled && settings.wakeHour != null && hasSelectedDays) {
      for (var i = 0; i < selectedDays.length; i++) {
        if (!selectedDays[i]) continue;
        await _schedule(
          id: _wakeId + i,
          hour: settings.wakeHour!,
          minute: settings.wakeMinute ?? 0,
          title: '⏰ Wake-Up Alarm',
          body: 'Good morning! Open Sleep Tracker and log last night\'s sleep.',
          isAlarm: true,
          customSoundPath: settings.wakeSound,
          fallbackChannelId: _wakeChannelId,
          fallbackSoundRes: _wakeupSoundRes,
          dayOfWeek: i + 1,
        );
      }
    }

    // ── Sleep goal alert (1 hour before bedtime, always uses bedtime sound)
    if (settings.bedtimeEnabled &&
        settings.bedtimeHour != null &&
        hasSelectedDays) {
      final alertHour = (settings.bedtimeHour! + 23) % 24;
      final alertMinute = settings.bedtimeMinute ?? 0;
      for (var i = 0; i < selectedDays.length; i++) {
        if (!selectedDays[i]) continue;
        await _schedule(
          id: _goalId + i,
          hour: alertHour,
          minute: alertMinute,
          title: '🎯 Sleep Goal Alert',
          body:
              'Tonight\'s goal is ${settings.sleepGoalHours.toStringAsFixed(1)} hours. '
              'Start winding down now.',
          isAlarm: false,
          customSoundPath: settings.bedtimeSound, // share bedtime sound
          fallbackChannelId: _goalChannelId,
          fallbackSoundRes: _bedtimeSoundRes,
          dayOfWeek: i + 1,
        );
      }
    }

    // ── Sync reminders widget ───────────────────────────────────────────────
    // Keys here become "${type}_$key" on the native side, so they must match
    // exactly what RemindersWidgetProvider reads:
    //   reminders_bedtime, reminders_wake, reminders_eye_comfort
    try {
      String formatTime(int hour, int minute) {
        final h12 = hour % 12 == 0 ? 12 : hour % 12;
        final period = hour < 12 ? 'AM' : 'PM';
        final m = minute.toString().padLeft(2, '0');
        return '$h12:$m $period';
      }

      // Eye comfort = 30 minutes before bedtime, using bedtimeEnabled as
      // its toggle (no separate setting/notification for this yet).
      String eyeComfortDisplay() {
        if (!settings.bedtimeEnabled || settings.bedtimeHour == null) {
          return 'Off';
        }
        final bedMinute = settings.bedtimeMinute ?? 0;
        var totalMinutes = settings.bedtimeHour! * 60 + bedMinute - 30;
        if (totalMinutes < 0) totalMinutes += 24 * 60; // wrap to previous day
        final h = totalMinutes ~/ 60;
        final m = totalMinutes % 60;
        return formatTime(h, m);
      }

      await WidgetService.updateWidget('reminders', {
        'bedtime': settings.bedtimeEnabled && settings.bedtimeHour != null
            ? formatTime(settings.bedtimeHour!, settings.bedtimeMinute ?? 0)
            : 'Off',
        'wake': settings.wakeEnabled && settings.wakeHour != null
            ? formatTime(settings.wakeHour!, settings.wakeMinute ?? 0)
            : 'Off',
        'eye_comfort': eyeComfortDisplay(),
      });
    } catch (e) {
      // ignore: avoid_print
      print('NotificationService: failed to update reminders widget: $e');
    }
  }

  // ── Internal scheduler ─────────────────────────────────────────────────────

  Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required bool isAlarm,
    required String? customSoundPath,
    required String fallbackChannelId,
    required String fallbackSoundRes,
    int? dayOfWeek,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled;
    if (dayOfWeek != null) {
      scheduled = _nextScheduledWeekday(now, dayOfWeek, hour, minute);
    } else {
      scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!scheduled.isAfter(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
    }

    final AndroidNotificationSound androidSound;
    final String channelId;

    if (customSoundPath != null && Platform.isAndroid) {
      channelId = await _ensureCustomChannel(
        soundUri: customSoundPath,
        isAlarm: isAlarm,
      );
      androidSound = UriAndroidNotificationSound(customSoundPath);
    } else {
      channelId = fallbackChannelId;
      androidSound = RawResourceAndroidNotificationSound(fallbackSoundRes);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: isAlarm ? Importance.max : Importance.high,
      priority: isAlarm ? Priority.max : Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: isAlarm,
      category: isAlarm
          ? AndroidNotificationCategory.alarm
          : AndroidNotificationCategory.reminder,
      icon: '@mipmap/ic_launcher',
      sound: androidSound,
    );

    final iosSound = customSoundPath == null ? '$fallbackSoundRes.aiff' : null;

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel:
          isAlarm ? InterruptionLevel.timeSensitive : InterruptionLevel.active,
      sound: iosSound,
    );

    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: scheduled,
        notificationDetails:
            NotificationDetails(android: androidDetails, iOS: iosDetails),
        androidScheduleMode: isAlarm
            ? AndroidScheduleMode.alarmClock
            : AndroidScheduleMode.exactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: dayOfWeek == null
            ? DateTimeComponents.time
            : DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e) {
      // ignore: avoid_print
      print('NotificationService: failed to schedule id=$id: $e');
    }
  }

  tz.TZDateTime _nextScheduledWeekday(
    tz.TZDateTime now,
    int dayOfWeek,
    int hour,
    int minute,
  ) {
    final currentWeekday = now.weekday;
    var daysToAdd = (dayOfWeek - currentWeekday) % DateTime.daysPerWeek;
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    ).add(Duration(days: daysToAdd));
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: DateTime.daysPerWeek));
    }
    return scheduled;
  }

  // ── Convenience accessors ──────────────────────────────────────────────────

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  IOSFlutterLocalNotificationsPlugin? get _iosPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
}
