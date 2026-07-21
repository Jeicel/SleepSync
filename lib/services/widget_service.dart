import 'package:flutter/services.dart';

class WidgetService {
  static const MethodChannel _channel = MethodChannel('sleep_tracker/widget');

  /// Update the native app widgets. [type] should be 'readiness' or 'reminders'.
  /// [data] is a map of key->value strings (numbers will be stringified).
  static Future<bool> updateWidget(
      String type, Map<String, dynamic> data) async {
    try {
      final res = await _channel.invokeMethod('updateWidget', {
        'type': type,
        'data': data,
      });
      return res == true;
    } catch (e) {
      return false;
    }
  }
}
