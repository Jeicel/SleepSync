import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ── Relative imports — hindi depende sa package name sa pubspec.yaml ─────────
import 'screens/home_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/log_screen.dart';
import 'screens/reminders_screen.dart';
import 'state/app_state.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final state = AppState();

  runApp(
    ChangeNotifierProvider.value(
      value: state,
      child: const SleepTrackerApp(),
    ),
  );

  // Init after UI is up so plugin failures don't block launch
  Future.microtask(() async {
    try {
      await state.init();
    } catch (_) {}
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Root widget — reacts to dark-mode setting
// ─────────────────────────────────────────────────────────────────────────────

class SleepTrackerApp extends StatelessWidget {
  const SleepTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<AppState, bool>((s) => s.settings.isDarkMode);
    final applyEye =
        context.select<AppState, bool>((s) => s.shouldApplyEyeComfort());
    final warmth = context.select<AppState, double>((s) => s.eyeComfortWarmth);

    return MaterialApp(
      title: 'Sleep Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
      builder: (ctx, child) {
        return Stack(children: [
          if (child != null) child,
          // Warm tint overlay for eye comfort. IgnorePointer so interactions pass through.
          IgnorePointer(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: applyEye ? (warmth.clamp(0.0, 1.0)) : 0.0,
              child: Container(
                color: Color.fromRGBO(255, 138, 18, 0.35),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main shell — IndexedStack + bottom nav
// ─────────────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;

  // NOTE: hindi const — RemindersScreen ay StatefulWidget
  final _screens = const <Widget>[
    HomeScreen(),
    LogScreen(),
    InsightsScreen(),
    RemindersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 10, bottom: 18),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border(
          top: BorderSide(
            color: context.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: context.isDark ? 0.30 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: 'Home',
              index: 0,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.edit_note_rounded,
              label: 'Log',
              index: 1,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Insights',
              index: 2,
              currentIndex: currentIndex,
              onTap: onTap),
          _NavItem(
              icon: Icons.notifications_none_rounded,
              label: 'Reminders',
              index: 3,
              currentIndex: currentIndex,
              onTap: onTap),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == currentIndex;
    final color = selected ? AppColors.purple : context.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
