import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ringtone_picker_service.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with WidgetsBindingObserver {
  bool? _hasPermission;
  bool _exactAlarmMissing = false;
  final _ringtones = RingtonePickerService();

  // Cache of content-URI -> human-readable title (e.g. "Chimes"), resolved
  // asynchronously since the system only gives us the URI synchronously.
  final Map<String, String> _soundTitles = {};

  // Day-of-week toggles: index 0=Mon … 6=Sun
  List<bool> _activeDays = List.filled(7, true);
  static const _dayLabels = ['M', 'T', 'W', 'TH', 'F', 'ST', 'S'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    _resolveExistingTitles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<AppState>().settings;
      setState(() => _activeDays = List.of(settings.activeDays));
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Exact-alarm permission is granted from a system Settings screen, not
    // from an in-app dialog — there's no callback when the user comes back.
    // Re-check whenever the app resumes so the banner clears once granted.
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _resolveExistingTitles() async {
    final settings = context.read<AppState>().settings;
    await _ensureTitleResolved(settings.bedtimeSound);
    await _ensureTitleResolved(settings.wakeSound);
  }

  Future<void> _ensureTitleResolved(String? uri) async {
    if (uri == null || _soundTitles.containsKey(uri)) return;
    final title = await _ringtones.getTitleForUri(uri);
    if (!mounted) return;
    if (title != null) {
      setState(() => _soundTitles[uri] = title);
    }
  }

  String _soundLabelFor(String? uri) {
    if (uri == null) return 'Default sound';
    return _soundTitles[uri] ?? 'Custom sound';
  }

  Future<void> _checkPermission() async {
    final state = context.read<AppState>();
    final basicOk = await state.hasBasicNotificationPermission();
    final exactOk = await state.hasExactAlarmPermission();
    if (!mounted) return;
    setState(() {
      _hasPermission = basicOk && exactOk;
      _exactAlarmMissing = basicOk && !exactOk;
    });
  }

  Future<void> _requestPermission() async {
    final granted =
        await context.read<AppState>().requestNotificationPermission();
    if (mounted) {
      // requestPermission() may have just launched a system Settings screen
      // for exact alarms with no immediate result — re-check properly
      // instead of trusting a single boolean.
      await _checkPermission();
    }
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _exactAlarmMissing
                ? 'Turn on "Alarms & reminders" for this app in Settings so reminders can fire on time.'
                : 'Permission denied — enable notifications in device Settings.',
          ),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── Drum / spinner time picker ─────────────────────────────────────────────

  Future<TimeOfDay?> _pickTime(TimeOfDay initial) async {
    final use24h = context.read<AppState>().settings.use24HourTime;
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DrumTimePicker(
        initial: initial,
        use24Hour: use24h,
      ),
    );
  }

  // ── Sound picker ───────────────────────────────────────────────────────────

  Future<void> _pickSound({required bool isBedtime}) async {
    final state = context.read<AppState>();
    final settings = state.settings;
    final currentPath = isBedtime ? settings.bedtimeSound : settings.wakeSound;

    if (!mounted) return;

    // SoundPickerResult(path) → custom file chosen
    // SoundPickerResult(null) → user tapped "Use Default"
    // null                   → sheet dismissed without a decision
    final result = await showSoundPicker(
      context,
      currentPath: currentPath,
      isAlarm: !isBedtime,
    );

    if (!mounted) return;
    if (result is SoundPickerResult) {
      if (isBedtime) {
        await state.updateSettings(result.path == null
            ? settings.copyWith(clearBedtimeSound: true)
            : settings.copyWith(bedtimeSound: result.path));
      } else {
        await state.updateSettings(result.path == null
            ? settings.copyWith(clearWakeSound: true)
            : settings.copyWith(wakeSound: result.path));
      }
      if (result.path != null) {
        await _ensureTitleResolved(result.path);
      }
    }
  }

  // ── Snack ──────────────────────────────────────────────────────────────────

  void _showSnack(bool enabled, String type, TimeOfDay? time) {
    if (!mounted) return;
    final msg = enabled && time != null
        ? '$type reminder set — fires daily at ${_fmt(time)}'
        : '$type reminder cancelled';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: enabled ? AppColors.remGreen : context.cardColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _fmt(TimeOfDay t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  String _scheduleLabel(List<bool> activeDays) {
    final selectedIndexes = <int>[];
    for (var i = 0; i < activeDays.length; i++) {
      if (activeDays[i]) selectedIndexes.add(i);
    }
    if (selectedIndexes.isEmpty) return 'No days selected';
    if (selectedIndexes.length == 7) return 'Scheduled — repeats daily';

    final labels = ['M', 'T', 'W', 'TH', 'F', 'ST', 'S'];
    final days = selectedIndexes.map((index) => labels[index]).join(' ');
    return 'Scheduled — $days';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Reminders',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Daily bedtime & wake-up alarms',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),

            if (_hasPermission == false) ...[
              _PermissionBanner(
                exactAlarmMissing: _exactAlarmMissing,
                onGrant: _requestPermission,
              ),
              const SizedBox(height: 14),
            ],

            // ── Bedtime reminder ────────────────────────────────────────────
            _ReminderCard(
              icon: Icons.bedtime_rounded,
              iconColor: AppColors.deepBlue,
              title: 'Bedtime Reminder',
              subtitle: 'Wind down at the same time every night',
              enabled: settings.bedtimeEnabled,
              timeLabel: settings.bedtimeReminder != null
                  ? state.formatTimeOfDay(settings.bedtimeReminder!)
                  : 'Tap to set',
              soundLabel: _soundLabelFor(settings.bedtimeSound),
              repeatLabel: _scheduleLabel(settings.activeDays),
              permissionGranted: _hasPermission ?? true,
              onToggle: (v) async {
                if (v && _hasPermission == false) {
                  await _requestPermission();
                  if (_hasPermission == false) return;
                }
                await state
                    .updateSettings(settings.copyWith(bedtimeEnabled: v));
                _showSnack(v, 'Bedtime', settings.bedtimeReminder);
              },
              onTimeTap: () async {
                final tod = await _pickTime(
                  settings.bedtimeReminder ??
                      const TimeOfDay(hour: 22, minute: 30),
                );
                if (tod != null && mounted) {
                  await state.updateSettings(settings.copyWith(
                    bedtimeHour: tod.hour,
                    bedtimeMinute: tod.minute,
                    bedtimeEnabled: true,
                  ));
                  _showSnack(true, 'Bedtime', tod);
                }
              },
              onSoundTap: () => _pickSound(isBedtime: true),
            ),

            const SizedBox(height: 14),

            // ── Wake-up alarm ───────────────────────────────────────────────
            _ReminderCard(
              icon: Icons.alarm_rounded,
              iconColor: AppColors.yellow,
              title: 'Wake-Up Alarm',
              subtitle: 'Rings on your lock screen like a real alarm',
              enabled: settings.wakeEnabled,
              timeLabel: settings.wakeReminder != null
                  ? state.formatTimeOfDay(settings.wakeReminder!)
                  : 'Tap to set',
              soundLabel: _soundLabelFor(settings.wakeSound),
              repeatLabel: _scheduleLabel(settings.activeDays),
              permissionGranted: _hasPermission ?? true,
              onToggle: (v) async {
                if (v && _hasPermission == false) {
                  await _requestPermission();
                  if (_hasPermission == false) return;
                }
                await state.updateSettings(settings.copyWith(wakeEnabled: v));
                _showSnack(v, 'Wake-up', settings.wakeReminder);
              },
              onTimeTap: () async {
                final tod = await _pickTime(
                  settings.wakeReminder ?? const TimeOfDay(hour: 6, minute: 30),
                );
                if (tod != null && mounted) {
                  await state.updateSettings(settings.copyWith(
                    wakeHour: tod.hour,
                    wakeMinute: tod.minute,
                    wakeEnabled: true,
                  ));
                  _showSnack(true, 'Wake-up', tod);
                }
              },
              onSoundTap: () => _pickSound(isBedtime: false),
            ),

            const SizedBox(height: 14),

            // ── Day-of-week selector ────────────────────────────────────────
            CardContainer(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.calendar_today_rounded,
                          color: AppColors.purple, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Text('Active Days',
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (i) {
                      final on = _activeDays[i];
                      return GestureDetector(
                        onTap: () async {
                          final updatedDays = List<bool>.from(_activeDays);
                          updatedDays[i] = !on;
                          setState(() => _activeDays = updatedDays);
                          await state.updateSettings(
                            settings.copyWith(activeDays: updatedDays),
                          );
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: on
                                ? AppColors.purple
                                : context.trackColor.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _dayLabels[i],
                            style: TextStyle(
                              color: on ? Colors.white : context.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Reminders fire only on the selected days.',
                    style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 12,
                        height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drum / spinner time picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _DrumTimePicker extends StatefulWidget {
  final TimeOfDay initial;
  final bool use24Hour;

  const _DrumTimePicker({required this.initial, required this.use24Hour});

  @override
  State<_DrumTimePicker> createState() => _DrumTimePickerState();
}

class _DrumTimePickerState extends State<_DrumTimePicker> {
  late int _hour; // 0–23 (24h) or 1–12 (12h display)
  late int _minute; // 0–59
  late bool _isAm;

  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _amPmCtrl;

  @override
  void initState() {
    super.initState();
    _minute = widget.initial.minute;
    _isAm = widget.initial.hour < 12;

    if (widget.use24Hour) {
      _hour = widget.initial.hour;
      _hourCtrl = FixedExtentScrollController(initialItem: _hour);
    } else {
      _hour = widget.initial.hour % 12 == 0 ? 12 : widget.initial.hour % 12;
      _hourCtrl = FixedExtentScrollController(initialItem: _hour - 1);
    }
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _amPmCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _amPmCtrl.dispose();
    super.dispose();
  }

  TimeOfDay get _result {
    if (widget.use24Hour) return TimeOfDay(hour: _hour, minute: _minute);
    int h = _hour % 12;
    if (!_isAm) h += 12;
    return TimeOfDay(hour: h, minute: _minute);
  }

  Widget _wheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required String Function(int) label,
    required ValueChanged<int> onSelected,
    double width = 76,
  }) {
    return SizedBox(
      width: width,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 52,
        diameterRatio: 1.5,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: (ctx, i) => Center(
            child: Text(
              label(i),
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.trackColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Set Time',
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // Wheels
          Stack(
            alignment: Alignment.center,
            children: [
              // Selection highlight
              Container(
                height: 52,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hour wheel
                  if (widget.use24Hour)
                    _wheel(
                      controller: _hourCtrl,
                      itemCount: 24,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onSelected: (i) => setState(() => _hour = i),
                    )
                  else
                    _wheel(
                      controller: _hourCtrl,
                      itemCount: 12,
                      label: (i) => (i + 1).toString().padLeft(2, '0'),
                      onSelected: (i) => setState(() => _hour = i + 1),
                    ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 2),
                    child: Text(':',
                        style: TextStyle(
                            color: AppColors.purple,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ),

                  // Minute wheel
                  _wheel(
                    controller: _minuteCtrl,
                    itemCount: 60,
                    label: (i) => i.toString().padLeft(2, '0'),
                    onSelected: (i) => setState(() => _minute = i),
                  ),

                  // AM / PM wheel
                  if (!widget.use24Hour) ...[
                    const SizedBox(width: 6),
                    _wheel(
                      controller: _amPmCtrl,
                      itemCount: 2,
                      label: (i) => i == 0 ? 'AM' : 'PM',
                      onSelected: (i) => setState(() => _isAm = i == 0),
                      width: 60,
                    ),
                  ],
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.trackColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                child: Text('Cancel',
                    style: TextStyle(color: context.textSecondary)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _result),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                child: const Text('Set',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reminder card
// ─────────────────────────────────────────────────────────────────────────────

class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool enabled;
  final String timeLabel;
  final String soundLabel;
  final String repeatLabel;
  final bool permissionGranted;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTimeTap;
  final VoidCallback onSoundTap;

  const _ReminderCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.timeLabel,
    required this.soundLabel,
    required this.repeatLabel,
    required this.permissionGranted,
    required this.onToggle,
    required this.onTimeTap,
    required this.onSoundTap,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(children: [
        // Header row
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
            ]),
          ),
          Switch(
              value: enabled,
              onChanged: onToggle,
              activeThumbColor: AppColors.purple),
        ]),

        const SizedBox(height: 14),

        // Time row
        _TappableRow(
          icon: Icons.access_time_rounded,
          label: 'Time',
          value: timeLabel,
          enabled: enabled,
          accentColor: AppColors.purple,
          onTap: onTimeTap,
        ),

        const SizedBox(height: 10),

        // Sound row
        _TappableRow(
          icon: Icons.music_note_rounded,
          label: 'Sound',
          value: soundLabel,
          enabled: enabled,
          accentColor: AppColors.remGreen,
          onTap: onSoundTap,
        ),

        // Scheduled badge
        if (enabled) ...[
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.remGreen, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              repeatLabel,
              style: const TextStyle(
                  color: AppColors.remGreen,
                  fontSize: 11,
                  fontWeight: FontWeight.w500),
            ),
          ]),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tappable row (time / sound)
// ─────────────────────────────────────────────────────────────────────────────

class _TappableRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool enabled;
  final Color accentColor;
  final VoidCallback onTap;

  const _TappableRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? accentColor.withValues(alpha: 0.09)
              : context.trackColor.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Icon(icon,
              size: 16, color: enabled ? accentColor : context.textSecondary),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(color: context.textSecondary, fontSize: 13)),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: enabled ? accentColor : context.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right_rounded,
              color: context.textSecondary, size: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Permission banner
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onGrant;
  final bool exactAlarmMissing;
  const _PermissionBanner({
    required this.onGrant,
    this.exactAlarmMissing = false,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppColors.red.withValues(alpha: 0.15),
              shape: BoxShape.circle),
          child: const Icon(Icons.notifications_off_rounded,
              color: AppColors.red, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              exactAlarmMissing
                  ? 'Exact alarms are off'
                  : 'Notifications blocked',
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              exactAlarmMissing
                  ? 'Turn on "Alarms & reminders" for this app so reminders fire on time.'
                  : 'Grant permission so reminders can ring.',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ]),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onGrant,
          style: TextButton.styleFrom(
            backgroundColor: AppColors.purple.withValues(alpha: 0.14),
            foregroundColor: AppColors.purple,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: const Text('Allow',
              style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}
