import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/sleep_entry.dart';
import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entries = state.entries;
    final last7 = state.last7Entries;

    return Scaffold(
      backgroundColor: context.bgColor,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text('Insights',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Your sleep analytics',
                style: TextStyle(color: context.textSecondary, fontSize: 14)),
            const SizedBox(height: 20),
            if (entries.isEmpty)
              _NoDataCard()
            else ...[
              _AveragesCard(
                  entries: last7.isNotEmpty ? last7 : entries.take(7).toList()),
              const SizedBox(height: 14),
              _DurationTrendCard(entries: entries),
              const SizedBox(height: 14),
              _BestWorstCard(entries: entries),
              const SizedBox(height: 14),
              _ScoreTrendCard(
                entries: entries.length > 14
                    ? entries.sublist(0, 14).reversed.toList()
                    : entries.reversed.toList(),
              ),
              const SizedBox(height: 14),
              _StagesCard(
                  entries: last7.isNotEmpty ? last7 : entries.take(7).toList()),
              const SizedBox(height: 14),
              _AllTimeCard(entries: entries),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No data placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _NoDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(children: [
        const SizedBox(height: 28),
        Icon(Icons.bar_chart_rounded,
            size: 60, color: AppColors.purple.withValues(alpha: 0.45)),
        const SizedBox(height: 14),
        Text('No data yet',
            style: TextStyle(
                color: context.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Log a few nights of sleep to unlock your analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textSecondary, fontSize: 13)),
        const SizedBox(height: 28),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day averages
// ─────────────────────────────────────────────────────────────────────────────

class _AveragesCard extends StatelessWidget {
  final List<SleepEntry> entries;
  const _AveragesCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final avgDur = entries.map((e) => e.durationHours).reduce((a, b) => a + b) /
        entries.length;
    final avgScore =
        entries.map((e) => e.score).reduce((a, b) => a + b) / entries.length;
    final avgQual =
        entries.map((e) => e.quality).reduce((a, b) => a + b) / entries.length;
    final h = avgDur.floor();
    final m = ((avgDur - h) * 60).round();

    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('LAST 7 DAYS',
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(
              value: '${h}h ${m}m',
              label: 'Avg Duration',
              color: AppColors.purple),
          _Divider(),
          _MiniStat(
              value: avgScore.toStringAsFixed(0),
              label: 'Avg Score',
              color: AppColors.remGreen),
          _Divider(),
          _MiniStat(
              value: avgQual.toStringAsFixed(1),
              label: 'Avg Quality',
              color: AppColors.yellow),
        ]),
      ]),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _MiniStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: context.textSecondary, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: context.trackColor);
}

// ─────────────────────────────────────────────────────────────────────────────
// Best / worst night
// ─────────────────────────────────────────────────────────────────────────────

class _BestWorstCard extends StatelessWidget {
  final List<SleepEntry> entries;
  const _BestWorstCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(entries)..sort((a, b) => b.score.compareTo(a.score));
    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('HIGHLIGHTS',
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 16),
        _HighlightRow(
            icon: '🏆',
            label: 'Best night',
            entry: sorted.first,
            color: AppColors.remGreen),
        const SizedBox(height: 12),
        _HighlightRow(
            icon: '😴',
            label: 'Needs improvement',
            entry: sorted.last,
            color: AppColors.red),
      ]),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  final String icon;
  final String label;
  final SleepEntry entry;
  final Color color;
  const _HighlightRow(
      {required this.icon,
      required this.label,
      required this.entry,
      required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(color: context.textSecondary, fontSize: 12)),
            Text('${entry.durationLabel} · Score ${entry.score}',
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12)),
          child: Text('${entry.score}',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sleep duration trend — Weekly / Monthly toggle
// ─────────────────────────────────────────────────────────────────────────────

enum _DurationRange { weekly, monthly }

class _DurationTrendCard extends StatefulWidget {
  final List<SleepEntry> entries; // newest → oldest (as stored in AppState)
  const _DurationTrendCard({required this.entries});

  @override
  State<_DurationTrendCard> createState() => _DurationTrendCardState();
}

class _DurationTrendCardState extends State<_DurationTrendCard> {
  _DurationRange _range = _DurationRange.weekly;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Last 7 calendar days, oldest → newest. Each bucket holds the average
  /// duration for that day (usually 0 or 1 entries, but averages if more).
  List<_Bucket> _weeklyBuckets() {
    final today = _dateOnly(DateTime.now());
    final buckets = <_Bucket>[];
    for (int i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayEntries = widget.entries.where((e) {
        final d = _dateOnly(e.wakeTime);
        return d == day;
      }).toList();
      final avg = dayEntries.isEmpty
          ? 0.0
          : dayEntries.map((e) => e.durationHours).reduce((a, b) => a + b) /
              dayEntries.length;
      buckets.add(_Bucket(
        label: _weekdayLabel(day.weekday),
        hours: avg,
        hasData: dayEntries.isNotEmpty,
      ));
    }
    return buckets;
  }

  /// Last ~5 calendar weeks (Mon–Sun), oldest → newest. Each bucket holds
  /// the average duration of nights logged in that week.
  List<_Bucket> _monthlyBuckets() {
    final today = _dateOnly(DateTime.now());
    // Find the Monday of the current week, then go back 4 more weeks.
    final currentWeekStart = today.subtract(Duration(days: today.weekday - 1));
    final buckets = <_Bucket>[];
    for (int i = 4; i >= 0; i--) {
      final weekStart = currentWeekStart.subtract(Duration(days: i * 7));
      final weekEnd = weekStart.add(const Duration(days: 7));
      final weekEntries = widget.entries.where((e) {
        final d = _dateOnly(e.wakeTime);
        return !d.isBefore(weekStart) && d.isBefore(weekEnd);
      }).toList();
      final avg = weekEntries.isEmpty
          ? 0.0
          : weekEntries.map((e) => e.durationHours).reduce((a, b) => a + b) /
              weekEntries.length;
      buckets.add(_Bucket(
        label: 'W${5 - i}',
        sublabel: '${weekStart.month}/${weekStart.day}',
        hours: avg,
        hasData: weekEntries.isNotEmpty,
      ));
    }
    return buckets;
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return labels[(weekday - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    final buckets =
        _range == _DurationRange.weekly ? _weeklyBuckets() : _monthlyBuckets();
    final withData = buckets.where((b) => b.hasData).toList();
    final avg = withData.isEmpty
        ? 0.0
        : withData.map((b) => b.hours).reduce((a, b) => a + b) /
            withData.length;
    final maxHours = buckets.map((b) => b.hours).fold<double>(0, math.max);
    final chartMax = maxHours <= 0 ? 9.0 : (maxHours < 9 ? 9.0 : maxHours + 1);

    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SLEEP DURATION',
                style: TextStyle(
                    color: context.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8)),
            _RangeToggle(
              range: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              withData.isEmpty ? '—' : '${avg.toStringAsFixed(1)}h',
              style: const TextStyle(
                  color: AppColors.purple,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 6),
            Text(
              _range == _DurationRange.weekly
                  ? 'avg this week'
                  : 'avg over 5 weeks',
              style: TextStyle(color: context.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: buckets.map((b) {
              final frac =
                  b.hasData ? (b.hours / chartMax).clamp(0.03, 1.0) : 0.0;
              final barColor = !b.hasData
                  ? context.trackColor
                  : (b.hours >= 7 && b.hours <= 9)
                      ? AppColors.remGreen
                      : (b.hours < 7 ? AppColors.yellow : AppColors.deepBlue);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        b.hasData ? b.hours.toStringAsFixed(1) : '',
                        style: TextStyle(
                            color: context.textSecondary, fontSize: 9),
                      ),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 80 * frac + (b.hasData ? 0 : 2),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(b.label,
                          style: TextStyle(
                              color: context.textSecondary, fontSize: 10)),
                      if (b.sublabel != null)
                        Text(b.sublabel!,
                            style: TextStyle(
                                color: context.textSecondary
                                    .withValues(alpha: 0.7),
                                fontSize: 8)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        if (withData.isEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'No nights logged in this period yet.',
            style: TextStyle(color: context.textSecondary, fontSize: 12),
          ),
        ],
      ]),
    );
  }
}

class _Bucket {
  final String label;
  final String? sublabel;
  final double hours;
  final bool hasData;
  const _Bucket({
    required this.label,
    this.sublabel,
    required this.hours,
    required this.hasData,
  });
}

class _RangeToggle extends StatelessWidget {
  final _DurationRange range;
  final ValueChanged<_DurationRange> onChanged;
  const _RangeToggle({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.trackColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _ToggleSeg(
          label: 'Weekly',
          selected: range == _DurationRange.weekly,
          onTap: () => onChanged(_DurationRange.weekly),
        ),
        _ToggleSeg(
          label: 'Monthly',
          selected: range == _DurationRange.monthly,
          onTap: () => onChanged(_DurationRange.monthly),
        ),
      ]),
    );
  }
}

class _ToggleSeg extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ToggleSeg(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.textSecondary,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Score trend bar chart
// ─────────────────────────────────────────────────────────────────────────────

class _ScoreTrendCard extends StatelessWidget {
  final List<SleepEntry> entries; // oldest → newest
  const _ScoreTrendCard({required this.entries});

  static Color _scoreColor(int s) {
    if (s >= 85) return AppColors.remGreen;
    if (s >= 70) return AppColors.purple;
    if (s >= 55) return AppColors.yellow;
    return AppColors.red;
  }

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SCORE TREND',
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 16),
        SizedBox(
          height: 88,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: entries.map((e) {
              final frac = (e.score / 100).clamp(0.05, 1.0);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: 60 * frac,
                          decoration: BoxDecoration(
                              color: _scoreColor(e.score),
                              borderRadius: BorderRadius.circular(6)),
                        ),
                        const SizedBox(height: 5),
                        Text('${e.score}',
                            style: TextStyle(
                                color: context.textSecondary, fontSize: 9)),
                      ]),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Average sleep stages
// ─────────────────────────────────────────────────────────────────────────────

class _StagesCard extends StatelessWidget {
  final List<SleepEntry> entries;
  const _StagesCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final avgDeep = entries.map((e) => e.deepPercent).reduce((a, b) => a + b) /
        entries.length;
    final avgRem = entries.map((e) => e.remPercent).reduce((a, b) => a + b) /
        entries.length;
    final avgLight =
        entries.map((e) => e.lightPercent).reduce((a, b) => a + b) /
            entries.length;

    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('AVG SLEEP STAGES',
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 16),
        _StageBar(label: 'Deep', pct: avgDeep / 100, color: AppColors.deepBlue),
        const SizedBox(height: 12),
        _StageBar(label: 'REM', pct: avgRem / 100, color: AppColors.remGreen),
        const SizedBox(height: 12),
        _StageBar(
            label: 'Light', pct: avgLight / 100, color: AppColors.lightPurple),
      ]),
    );
  }
}

class _StageBar extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;
  const _StageBar(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(color: context.textSecondary, fontSize: 12)),
          Text('${(pct * 100).round()}%',
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: context.trackColor,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// All-time stats
// ─────────────────────────────────────────────────────────────────────────────

class _AllTimeCard extends StatelessWidget {
  final List<SleepEntry> entries;
  const _AllTimeCard({required this.entries});

  @override
  Widget build(BuildContext context) {
    final avgDur = entries.map((e) => e.durationHours).reduce((a, b) => a + b) /
        entries.length;
    final avgScore =
        entries.map((e) => e.score).reduce((a, b) => a + b) / entries.length;
    final h = avgDur.floor();
    final m = ((avgDur - h) * 60).round();

    return CardContainer(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('ALL TIME',
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
        const SizedBox(height: 16),
        Row(children: [
          _MiniStat(
              value: '${entries.length}',
              label: 'Nights Logged',
              color: AppColors.purple),
          _Divider(),
          _MiniStat(
              value: '${h}h ${m}m',
              label: 'Avg Duration',
              color: AppColors.deepBlue),
          _Divider(),
          _MiniStat(
              value: avgScore.toStringAsFixed(0),
              label: 'Avg Score',
              color: AppColors.remGreen),
        ]),
      ]),
    );
  }
}
