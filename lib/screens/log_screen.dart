import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sleep_entry.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  DateTime _bedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).subtract(const Duration(days: 1));
  DateTime _wakeDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    // Initialize local sleep date from AppState after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final app = context.read<AppState>();
      setState(() {
        final sbed = app.selectedBedDate;
        final swake = app.selectedWakeDate;
        _bedDate = DateTime(sbed.year, sbed.month, sbed.day);
        _wakeDate = DateTime(swake.year, swake.month, swake.day);
      });
    });
  }

  double _quality = 7;
  int _mood = 3;
  final _notesCtrl = TextEditingController();
  String? _editingId;
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  void _startEditing(SleepEntry e) {
    setState(() {
      _editingId = e.id;
      _bedtime = TimeOfDay(hour: e.bedtime.hour, minute: e.bedtime.minute);
      _wakeTime = TimeOfDay(hour: e.wakeTime.hour, minute: e.wakeTime.minute);
      _bedDate = DateTime(e.bedtime.year, e.bedtime.month, e.bedtime.day);
      _wakeDate = DateTime(e.wakeTime.year, e.wakeTime.month, e.wakeTime.day);
      _quality = e.quality.toDouble();
      _mood = e.mood;
      _notesCtrl.text = e.notes;
    });
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Derived date/time ──────────────────────────────────────────────────────

  DateTime get _bedDateTime => DateTime(_bedDate.year, _bedDate.month,
      _bedDate.day, _bedtime.hour, _bedtime.minute);

  DateTime get _wakeDateTime => DateTime(_wakeDate.year, _wakeDate.month,
      _wakeDate.day, _wakeTime.hour, _wakeTime.minute);

  Duration get _duration => _wakeDateTime.difference(_bedDateTime);

  String get _durationLabel {
    final mins = _duration.inMinutes;
    if (mins <= 0) return '—';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  String _formatSleepDate(DateTime date) {
    final month = date.month;
    final day = date.day;
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${monthNames[month - 1]} $day';
  }

  String _formatWakeDate(DateTime date) {
    final weekday =
        ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
    return '$weekday • ${_formatSleepDate(date)}';
  }

  Future<void> _pickFilterStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _filterStartDate ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _filterStartDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickFilterEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterEndDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() =>
          _filterEndDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  List<SleepEntry> _getFilteredEntries(List<SleepEntry> entries) {
    if (_filterStartDate == null && _filterEndDate == null) return entries;
    final start = _filterStartDate ??
        DateTime.now().subtract(const Duration(days: 365 * 10));
    final end = _filterEndDate ?? DateTime.now();
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);
    return entries
        .where((e) => e.bedtime.isAfter(start) && e.bedtime.isBefore(endOfDay))
        .toList();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _pickTime({required bool isBedtime}) async {
    // Require choosing a date first — open date picker and cancel if not chosen
    final date = await _pickDate(isBed: isBedtime);
    if (date == null) return;
    if (!mounted) return;

    final initial = isBedtime ? _bedtime : _wakeTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isBedtime) {
        _bedtime = picked;
      } else {
        _wakeTime = picked;
      }
    });
  }

  Future<DateTime?> _pickDate({required bool isBed}) async {
    final appState = context.read<AppState>();
    final initial = isBed ? _bedDate : _wakeDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              Theme.of(ctx).colorScheme.copyWith(primary: AppColors.purple),
        ),
        child: child!,
      ),
    );
    if (picked == null) return null;
    setState(() {
      if (isBed) {
        _bedDate = picked;
      } else {
        _wakeDate = picked;
      }
    });
    if (isBed) {
      await appState.setSelectedBedDate(picked);
    } else {
      await appState.setSelectedWakeDate(picked);
    }
    return picked;
  }

  bool _intervalsOverlap(
    DateTime aStart,
    DateTime aEnd,
    DateTime bStart,
    DateTime bEnd,
  ) {
    return aStart.isBefore(bEnd) && bStart.isBefore(aEnd);
  }

  Future<void> _save() async {
    if (_duration.inMinutes <= 0 || _duration.inHours > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Check your bedtime and wake time — that duration looks off.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final appState = context.read<AppState>();
    if (_editingId == null) {
      final conflicts = appState.entries.any((e) {
        return _intervalsOverlap(
          e.bedtime,
          e.wakeTime,
          _bedDateTime,
          _wakeDateTime,
        );
      });
      if (conflicts) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'This sleep session overlaps an existing entry. Choose a different time or edit the existing log.'),
            backgroundColor: AppColors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    final entry = SleepEntry(
      id: _editingId ?? DateTime.now().microsecondsSinceEpoch.toString(),
      bedtime: _bedDateTime,
      wakeTime: _wakeDateTime,
      quality: _quality.round(),
      mood: _mood,
      notes: _notesCtrl.text.trim(),
    );

    if (_editingId != null) {
      await appState.updateEntry(entry);
    } else {
      await appState.addEntry(entry);
    }
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingId != null ? 'Entry updated!' : 'Sleep logged!'),
        backgroundColor:
            _editingId != null ? AppColors.purple : AppColors.remGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _quality = 7;
      _mood = 3;
      _notesCtrl.clear();
      _editingId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Log Sleep',
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Record last night to see your score.',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // ── Bedtime / wake time ────────────────────────────────────
              CardContainer(
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: _TimeTile(
                        icon: Icons.bedtime_rounded,
                        iconColor: AppColors.purple,
                        label: 'Bedtime',
                        time: state.formatTimeOfDay(_bedtime),
                        subtitle: _formatSleepDate(_bedDate),
                        onTap: () => _pickTime(isBedtime: true),
                        onSubtitleTap: () => _pickDate(isBed: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeTile(
                        icon: Icons.wb_sunny_rounded,
                        iconColor: AppColors.yellow,
                        label: 'Wake time',
                        time: state.formatTimeOfDay(_wakeTime),
                        subtitle: _formatWakeDate(_wakeDate),
                        onTap: () => _pickTime(isBedtime: false),
                        onSubtitleTap: () => _pickDate(isBed: false),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  const SizedBox(height: 14),
                  Divider(color: context.trackColor, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timelapse_rounded,
                          color: context.textSecondary, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Duration: $_durationLabel',
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ]),
              ),

              const SizedBox(height: 16),

              // ── Quality slider ─────────────────────────────────────────
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sleep Quality',
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_quality.round()}/10',
                            style: const TextStyle(
                                color: AppColors.purple,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.purple,
                        inactiveTrackColor: context.trackColor,
                        thumbColor: AppColors.purple,
                        overlayColor: AppColors.purple.withValues(alpha: 0.18),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _quality,
                        min: 1,
                        max: 10,
                        divisions: 9,
                        onChanged: (v) => setState(() => _quality = v),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // ── Mood selector ──────────────────────────────────────────
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wake-up Mood',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (i) {
                        const emojis = ['😩', '😴', '😐', '🙂', '😄'];
                        const labels = [
                          'Exhausted',
                          'Tired',
                          'Okay',
                          'Good',
                          'Rested'
                        ];
                        final moodValue = i + 1;
                        return _MoodOption(
                          emoji: emojis[i],
                          label: labels[i],
                          selected: _mood == moodValue,
                          onTap: () => setState(() => _mood = moodValue),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Notes ──────────────────────────────────────────────────
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes (optional)',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: 3,
                      style: TextStyle(color: context.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Anything that affected your sleep?',
                        hintStyle: TextStyle(color: context.textSecondary),
                        filled: true,
                        fillColor: context.trackColor.withValues(alpha: 0.4),
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.trackColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: context.trackColor),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(14)),
                          borderSide: BorderSide(color: AppColors.purple),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _editingId != null ? 'Update Entry' : 'Save Entry',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Past entries with filter
              CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Past entries',
                            style: TextStyle(
                                color: context.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8)),
                        if (_filterStartDate != null || _filterEndDate != null)
                          TextButton(
                            onPressed: () => setState(() {
                              _filterStartDate = null;
                              _filterEndDate = null;
                            }),
                            child: const Text('Clear'),
                          ),
                        TextButton.icon(
                          icon: const Icon(Icons.filter_list, size: 14),
                          label: const Text('Filter'),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (ctx) => Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Filter by date range',
                                        style: TextStyle(
                                            color: context.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('From',
                                                  style: TextStyle(
                                                      color:
                                                          context.textSecondary,
                                                      fontSize: 12)),
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: _pickFilterStartDate,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: context.bg2Color,
                                                    border: Border.all(
                                                        color:
                                                            AppColors.purple),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    _filterStartDate == null
                                                        ? 'Pick date'
                                                        : _formatSleepDate(
                                                            _filterStartDate!),
                                                    style: TextStyle(
                                                        color: context
                                                            .textPrimary),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('To',
                                                  style: TextStyle(
                                                      color:
                                                          context.textSecondary,
                                                      fontSize: 12)),
                                              const SizedBox(height: 6),
                                              GestureDetector(
                                                onTap: _pickFilterEndDate,
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: context.bg2Color,
                                                    border: Border.all(
                                                        color:
                                                            AppColors.purple),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    _filterEndDate == null
                                                        ? 'Pick date'
                                                        : _formatSleepDate(
                                                            _filterEndDate!),
                                                    style: TextStyle(
                                                        color: context
                                                            .textPrimary),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.purple,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text(
                                          'Apply',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            foregroundColor: AppColors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (state.entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No entries yet',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 13)),
                      )
                    else if (_getFilteredEntries(state.entries).isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('No entries in date range',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 13)),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _getFilteredEntries(state.entries).map((e) {
                          return Dismissible(
                            key: Key(e.id),
                            direction: DismissDirection.horizontal,
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                _startEditing(e);
                                return false;
                              }
                              return true;
                            },
                            dismissThresholds: const {
                              DismissDirection.startToEnd: 0.3,
                              DismissDirection.endToStart: 0.3,
                            },
                            background: Container(
                              color: AppColors.purple.withValues(alpha: 0.15),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.edit,
                                  color: AppColors.purple, size: 24),
                            ),
                            secondaryBackground: Container(
                              color: AppColors.red.withValues(alpha: 0.15),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline,
                                  color: AppColors.red, size: 24),
                            ),
                            onDismissed: (direction) async {
                              final appState = context.read<AppState>();
                              await appState.deleteEntry(e.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Entry moved to trash'),
                                    backgroundColor: AppColors.remGreen,
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                    action: SnackBarAction(
                                      label: 'Undo',
                                      onPressed: () async {
                                        await appState.restoreFromTrash(e.id);
                                      },
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_formatSleepDate(e.bedtime)} — ${e.durationLabel}',
                                    style: TextStyle(
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Score ${e.score} · ${e.moodEmoji} ${e.moodLabel}',
                                    style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String time;
  final String? subtitle;
  final VoidCallback? onSubtitleTap;
  final VoidCallback onTap;

  const _TimeTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.time,
    required this.onTap,
    this.subtitle,
    this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
            ]),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onSubtitleTap,
                child: Text(
                  subtitle!,
                  style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodOption extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MoodOption({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.purple.withValues(alpha: 0.18)
                  : context.trackColor.withValues(alpha: 0.4),
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.purple, width: 1.5)
                  : null,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.purple : context.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
