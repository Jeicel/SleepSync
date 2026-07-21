import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Public entry-point
// ─────────────────────────────────────────────────────────────────────────────

/// Public result type — re-exported so reminders_screen.dart can import it.
/// [path] holds a `content://` URI string returned by Android's system
/// ringtone picker (not a file path). null = use the app's built-in default sound.
class SoundPickerResult {
  final String? path;
  const SoundPickerResult(this.path);
}

/// Shows the system ringtone picker (Android only).
/// Returns null if the user cancelled or this isn't Android.
Future<SoundPickerResult?> showSoundPicker(
  BuildContext context, {
  String? currentPath,
  required bool isAlarm,
}) async {
  if (!Platform.isAndroid) return null;

  final messenger = ScaffoldMessenger.of(context);

  try {
    final service = RingtonePickerService();
    final result = await service.pickRingtone(
      isAlarm: isAlarm,
      currentUri: currentPath,
    );

    if (!context.mounted) return null;
    return result != null ? SoundPickerResult(result.uri) : null;
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(
        content: Text('Could not open sound picker: $e'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────

class RingtonePickerResult {
  final String? uri;
  final String? title;
  RingtonePickerResult({this.uri, this.title});
}

class RingtonePickerService {
  static const _channel = MethodChannel('sleep_tracker/ringtone_picker');

  Future<RingtonePickerResult?> pickRingtone({
    required bool isAlarm,
    String? currentUri,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'pickRingtone',
        {'isAlarm': isAlarm, 'currentUri': currentUri ?? ''},
      );
      if (result == null) return null;
      return RingtonePickerResult(
        uri: result['uri'] as String?,
        title: result['title'] as String?,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getTitleForUri(String? uri) async {
    if (uri == null || !Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>(
        'getRingtoneTitle',
        {'uri': uri},
      );
    } catch (_) {
      return null;
    }
  }
}
