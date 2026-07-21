import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sleep_entry.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';
import '../widgets/legend_dot.dart';
import '../widgets/score_ring_painter.dart';
import '../widgets/daily_greeting_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _greetingChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGreeting();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Needed because entries load asynchronously — this recheck fires
    // once loading finishes. Guarded by _greetingChecked so it can
    // never fire again after that.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowGreeting();
    });
  }

  void _checkAndShowGreeting() {
    if (_greetingChecked) return;

    final state = context.read<AppState>();
    if (state.isLoading) return; // data not loaded yet — wait for next call

    if (state.lastEntry != null) {
      _greetingChecked = true;
      _showDailyGreeting();
    } else {
      _greetingChecked = true; // no entries at all — nothing to show, ever
    }
  }

  void _showDailyGreeting() {
    if (!mounted) return;
    final state = context.read<AppState>();
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => DailyGreetingDialog(
        greeting: state.greeting,
        lastEntry: state.lastEntry,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entry = state.lastEntry;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.bgColor, context.bg2Color],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HomeHeader(state: state),
                const SizedBox(height: 20),
                if (entry != null) ...[
                  _ScoreCard(entry: entry, state: state),
                  const SizedBox(height: 14),
                  _StatsRow(entry: entry, streak: state.currentStreak),
                  const SizedBox(height: 14),
                  _WeekCard(
                    entries: state.last7Entries,
                    goalHours: state.settings.sleepGoalHours,
                  ),
                ] else
                  _EmptyState(),
                const SizedBox(height: 14),
                _TipCard(text: state.sleepTip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final AppState state;
  const _HomeHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${state.greeting}, ${state.settings.userName}',
                style: TextStyle(color: context.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                "Last night's sleep",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              Icons.settings_rounded,
              color: context.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score card
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final SleepEntry entry;
  final AppState state;
  const _ScoreCard({required this.entry, required this.state});

  static Color _scoreColor(int s) {
    if (s >= 85) return AppColors.remGreen;
    if (s >= 70) return AppColors.purple;
    if (s >= 55) return AppColors.yellow;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor(entry.score);
    return CardContainer(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(80, 80),
                  painter: ScoreRingPainter(
                    percent: entry.score / 100,
                    progressColor: color,
                    trackColor: context.trackColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${entry.score}',
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'score',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.scoreLabel,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.durationLabel} · Woke at ${state.formatTime(entry.wakeTime)}',
                  style: TextStyle(color: context.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    LegendDot(
                        color: AppColors.deepBlue,
                        label: 'Deep ${entry.deepPercent}%'),
                    LegendDot(
                        color: AppColors.remGreen,
                        label: 'REM ${entry.remPercent}%'),
                    LegendDot(
                        color: AppColors.lightPurple,
                        label: 'Light ${entry.lightPercent}%'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat tiles row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final SleepEntry entry;
  final int streak;
  const _StatsRow({required this.entry, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          _StatTile(
              icon: Icons.access_time_filled_rounded,
              iconColor: AppColors.purple,
              value: entry.durationLabel,
              label: 'Duration'),
          const SizedBox(width: 12),
          _StatTile(
              icon: Icons.local_fire_department_rounded,
              iconColor: AppColors.yellow,
              value: '$streak days',
              label: 'Streak'),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          _StatTile(
              icon: Icons.sentiment_satisfied_alt_rounded,
              iconColor: AppColors.remGreen,
              value: entry.moodLabel,
              label: 'Wake mood'),
          const SizedBox(width: 12),
          _StatTile(
              icon: Icons.star_rounded,
              iconColor: AppColors.yellow,
              value: '${entry.quality} / 10',
              label: 'Quality'),
        ]),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _StatTile(
      {required this.icon,
      required this.iconColor,
      required this.value,
      required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CardContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _WeekCard extends StatelessWidget {
  final List<SleepEntry> entries;
  final double goalHours;
  const _WeekCard({required this.entries, required this.goalHours});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    // Build a slot for each of the past 7 days (Mon → today)
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    const labels = ['M', 'T', 'W', 'TH', 'F', 'ST', 'S'];

    // Map date → best duration that day
    final dayMap = <DateTime, double>{};
    for (final e in entries) {
      final d = DateTime(e.wakeTime.year, e.wakeTime.month, e.wakeTime.day);
      if (!dayMap.containsKey(d) || e.durationHours > dayMap[d]!) {
        dayMap[d] = e.durationHours;
      }
    }

    final slots = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final hours = dayMap[day] ?? 0.0;
      return _DaySlot(
          day: day,
          hours: hours,
          isToday: i == 6,
          label: labels[day.weekday - 1]);
    });

    final validHours = slots.map((s) => s.hours).where((h) => h > 0);
    final avg = validHours.isEmpty
        ? 0.0
        : validHours.reduce((a, b) => a + b) / validHours.length;
    final avgH = avg.floor();
    final avgM = ((avg - avgH) * 60).round();
    final maxH = [goalHours, ...slots.map((s) => s.hours)]
            .reduce((a, b) => a > b ? a : b) +
        0.5;

    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('THIS WEEK',
              style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                validHours.isEmpty ? 'No data' : 'Avg ${avgH}h ${avgM}m',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                'Goal: ${goalHours.toStringAsFixed(0)}h',
                style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 108,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: slots.map((slot) {
                final frac =
                    maxH > 0 ? (slot.hours / maxH).clamp(0.0, 1.0) : 0.0;
                final barH =
                    slot.hours > 0 ? (72 * frac).clamp(8.0, 72.0) : 4.0;
                final color = slot.hours == 0
                    ? context.trackColor
                    : slot.isToday
                        ? AppColors.purple
                        : slot.hours >= goalHours
                            ? AppColors.remGreen.withValues(alpha: 0.75)
                            : AppColors.red.withValues(alpha: 0.75);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (slot.hours > 0)
                          Text(
                            '${slot.hours.toStringAsFixed(1)}h',
                            style: TextStyle(
                              color: slot.isToday
                                  ? AppColors.purple
                                  : context.textSecondary,
                              fontSize: 8,
                            ),
                          ),
                        const SizedBox(height: 2),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: barH,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          slot.label,
                          style: TextStyle(
                            color: slot.isToday
                                ? AppColors.purple
                                : context.textSecondary,
                            fontSize: 12,
                            fontWeight: slot.isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaySlot {
  final DateTime day;
  final double hours;
  final bool isToday;
  final String label;
  const _DaySlot(
      {required this.day,
      required this.hours,
      required this.isToday,
      required this.label});
}

// ─────────────────────────────────────────────────────────────────────────────
// Tip card
// ─────────────────────────────────────────────────────────────────────────────

class _TipCard extends StatelessWidget {
  final String text;
  const _TipCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: const Icon(Icons.wb_sunny_rounded,
                color: AppColors.yellow, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SLEEP TIP',
                    style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8)),
                const SizedBox(height: 6),
                Text(text,
                    style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 13,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Icon(Icons.bedtime_outlined,
              size: 60, color: AppColors.purple.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Text('No sleep logged yet',
              style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Tap the Log tab below to record your first sleep session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
