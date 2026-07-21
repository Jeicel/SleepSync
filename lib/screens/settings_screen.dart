import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import '../theme/app_colors.dart';
import '../widgets/card_container.dart';
import 'trash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: context.read<AppState>().settings.userName,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final state = context.read<AppState>();
    state.updateSettings(state.settings.copyWith(userName: name));
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Name updated!'),
        backgroundColor: AppColors.remGreen,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'All sleep entries and settings will be permanently deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete everything',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AppState>().clearAllData();
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final settings = state.settings;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Settings',
            style: TextStyle(
                color: context.textPrimary, fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // ── Profile ─────────────────────────────────────────────────────
          const _SectionLabel('PROFILE'),
          CardContainer(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Your Name',
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: TextStyle(color: context.textPrimary),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) => _saveName(),
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: TextStyle(color: context.textSecondary),
                  filled: true,
                  fillColor: context.trackColor.withValues(alpha: 0.4),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.trackColor)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.trackColor)),
                  focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: AppColors.purple)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.check_rounded,
                        color: AppColors.purple),
                    onPressed: _saveName,
                  ),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 22),

          // ── Appearance ──────────────────────────────────────────────────
          const _SectionLabel('APPEARANCE'),
          CardContainer(
            child: Column(children: [
              _ToggleRow(
                icon: Icons.dark_mode_rounded,
                iconColor: AppColors.purple,
                title: 'Dark Mode',
                value: settings.isDarkMode,
                onChanged: (v) =>
                    state.updateSettings(settings.copyWith(isDarkMode: v)),
              ),
              Divider(color: context.trackColor, height: 24),
              _ToggleRow(
                icon: Icons.schedule_rounded,
                iconColor: AppColors.deepBlue,
                title: '24-Hour Time',
                subtitle: settings.use24HourTime
                    ? 'Showing e.g. 22:30'
                    : 'Showing e.g. 10:30 PM',
                value: settings.use24HourTime,
                onChanged: (v) =>
                    state.updateSettings(settings.copyWith(use24HourTime: v)),
              ),
              Divider(color: context.trackColor, height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Eye comfort',
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                          'Applies a warm tint automatically from 30 minutes before your bedtime reminder.',
                          style: TextStyle(
                              color: context.textSecondary, fontSize: 12)),
                    ]),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      settings.bedtimeReminder != null &&
                              settings.bedtimeEnabled
                          ? 'Bedtime reminder set for ${state.formatTimeOfDay(settings.bedtimeReminder!)}'
                          : 'Enable your bedtime reminder to use eye comfort.',
                      style: TextStyle(
                          color: settings.bedtimeReminder != null &&
                                  settings.bedtimeEnabled
                              ? context.textPrimary
                              : context.textSecondary,
                          fontSize: 13),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Warmth',
                            style: TextStyle(color: context.textSecondary)),
                        Text('${(settings.eyeComfortWarmth * 100).round()}%',
                            style: TextStyle(color: context.textPrimary)),
                      ],
                    ),
                    Slider(
                      value: settings.eyeComfortWarmth,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      onChanged: (v) => state.updateSettings(
                          settings.copyWith(eyeComfortWarmth: v)),
                    ),
                  ],
                ),
              ),
            ]),
          ),

          const SizedBox(height: 22),

          // ── Sleep goal ──────────────────────────────────────────────────
          const _SectionLabel('SLEEP GOAL'),
          CardContainer(
            child: Column(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppColors.remGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.bedtime_outlined,
                          color: AppColors.remGreen, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Text('Nightly Goal',
                        style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ]),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.remGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${settings.sleepGoalHours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                          color: AppColors.remGreen,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.remGreen,
                  inactiveTrackColor: context.trackColor,
                  thumbColor: AppColors.remGreen,
                  overlayColor: AppColors.remGreen.withValues(alpha: 0.18),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: settings.sleepGoalHours,
                  min: 5.0,
                  max: 10.0,
                  divisions: 10,
                  onChanged: (v) => state
                      .updateSettings(settings.copyWith(sleepGoalHours: v)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('5h',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 11)),
                  Text('10h',
                      style: TextStyle(
                          color: context.textSecondary, fontSize: 11)),
                ],
              ),
            ]),
          ),

          const SizedBox(height: 22),

          // ── Data ────────────────────────────────────────────────────────
          const _SectionLabel('DATA'),
          CardContainer(
            child: Column(children: [
              _InfoRow(
                icon: Icons.nights_stay_rounded,
                iconColor: AppColors.purple,
                title: 'Nights Logged',
                trailing: '${state.entries.length}',
              ),
              Divider(color: context.trackColor, height: 24),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrashScreen()),
                  );
                },
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: AppColors.remGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.remGreen, size: 17),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Trash',
                            style: TextStyle(
                                color: AppColors.remGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.w500)),
                        Text(
                          state.deletedEntries.isEmpty
                              ? 'No deleted items'
                              : '${state.deletedEntries.length} item${state.deletedEntries.length == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.textSecondary),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  'Items in Trash are permanently deleted after 7 days. You can restore or permanently delete items from the Trash screen.',
                  style: TextStyle(color: context.textSecondary, fontSize: 12),
                ),
              ),
              Divider(color: context.trackColor, height: 24),
              GestureDetector(
                onTap: _confirmClearAll,
                behavior: HitTestBehavior.opaque,
                child: Row(children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.delete_forever_rounded,
                        color: AppColors.red, size: 17),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Clear All Data',
                        style: TextStyle(
                            color: AppColors.red,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: context.textSecondary),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 32),
          Center(
            child: Text('Sleep Tracker v1.0.0',
                style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable row widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8)),
      );
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500)),
            if (subtitle != null)
              Text(subtitle!,
                  style: TextStyle(color: context.textSecondary, fontSize: 12)),
          ]),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple),
      ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String trailing;

  const _InfoRow(
      {required this.icon,
      required this.iconColor,
      required this.title,
      required this.trailing});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(title,
                style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500))),
        Text(trailing,
            style: TextStyle(
                color: context.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
      ]);
}
