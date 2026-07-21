import 'package:flutter_test/flutter_test.dart';
import 'package:sleep_sync/models/app_settings.dart';
import 'package:sleep_sync/state/app_state.dart';

void main() {
  test('eye comfort turns off exactly at the bedtime reminder time', () {
    final state = AppState();
    final settings = const AppSettings(
      bedtimeHour: 10,
      bedtimeMinute: 51,
      bedtimeEnabled: true,
    );

    expect(
      state.shouldApplyEyeComfortAt(
        DateTime(2024, 1, 1, 10, 50, 59),
        settings,
      ),
      isTrue,
    );

    expect(
      state.shouldApplyEyeComfortAt(
        DateTime(2024, 1, 1, 10, 51, 0),
        settings,
      ),
      isFalse,
    );
  });
}
