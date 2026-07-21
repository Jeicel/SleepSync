import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/sleep_entry.dart';
import '../theme/app_colors.dart';

class DailyGreetingDialog extends StatelessWidget {
  final String greeting;
  final SleepEntry? lastEntry;
  final VoidCallback onClose;

  const DailyGreetingDialog({
    required this.greeting,
    required this.lastEntry,
    required this.onClose,
    super.key,
  });

  String _getMotivationalMessage() {
    if (lastEntry == null) {
      return 'Log your first sleep to track your progress!';
    }

    final dur = lastEntry!.durationHours;
    final goal = 8.0; // Default goal, could be passed in

    if (dur >= goal) {
      return '✨ Great sleep! You\'re on track. Keep it up!';
    }
    if (dur >= goal - 1) {
      return '👍 Good effort! Just under goal. Rest well tonight.';
    }
    if (dur >= goal - 2) {
      return '😴 You\'re catching up! Aim for ${goal.toStringAsFixed(1)}h tonight.';
    }
    return '⚠️ Sleep debt detected. Prioritize rest tonight!';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blurred background
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
        // Dialog
        Center(
          child: SingleChildScrollView(
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: _getCardColor(context),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting
                      Text(
                        greeting,
                        style: TextStyle(
                          color: _getTextPrimary(context),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Sleep Summary
                      if (lastEntry != null) ...[
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _getBgColor(context),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Last Night',
                                        style: TextStyle(
                                          color: _getTextSecondary(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lastEntry!.durationLabel,
                                        style: TextStyle(
                                          color: _getTextPrimary(context),
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Quality',
                                        style: TextStyle(
                                          color: _getTextSecondary(context),
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${lastEntry!.quality}/10',
                                        style: TextStyle(
                                          color: AppColors.yellow,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Motivational message
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.purple.withValues(alpha: 0.3),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _getMotivationalMessage(),
                          style: TextStyle(
                            color: _getTextPrimary(context),
                            fontSize: 13,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Close button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: onClose,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromRGBO(140, 123, 255, 1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Start Your Day',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Local color helpers to avoid conflicts with app theme extensions
Color _getCardColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF1A1A2E) : Colors.white;
}

Color _getBgColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF0F0F23) : const Color(0xFFF5F5F7);
}

Color _getTextPrimary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? Colors.white : Colors.black;
}

Color _getTextSecondary(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? const Color(0xFF888888) : const Color(0xFF666666);
}
