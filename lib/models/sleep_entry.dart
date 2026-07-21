/// One recorded sleep session.
class SleepEntry {
  final String id;
  final DateTime bedtime;
  final DateTime wakeTime;
  final int quality; // 1–10 user-rated
  final int mood; // 1–5 wake mood
  final String notes;
  final DateTime?
      deletedAt; // null if active, set to deletion timestamp if soft-deleted

  const SleepEntry({
    required this.id,
    required this.bedtime,
    required this.wakeTime,
    required this.quality,
    required this.mood,
    this.notes = '',
    this.deletedAt,
  });

  // ── Derived ──────────────────────────────────────────────────────────────

  double get durationHours => wakeTime.difference(bedtime).inMinutes / 60.0;

  String get durationLabel {
    final mins = wakeTime.difference(bedtime).inMinutes.abs();
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  /// Composite score 0–100.
  /// Duration (40 pts): optimal 7–9 h, linear ramp below/above.
  /// Quality  (35 pts): user rating / 10.
  /// Mood     (25 pts): wake mood / 5.
  int get score {
    final dur = durationHours;
    double durScore;
    if (dur >= 7 && dur <= 9) {
      durScore = 1.0;
    } else if (dur < 7) {
      durScore = (dur / 7.0).clamp(0.0, 1.0);
    } else {
      durScore = (1.0 - (dur - 9.0) / 3.0).clamp(0.0, 1.0);
    }
    return ((durScore * 40) + (quality / 10.0 * 35) + (mood / 5.0 * 25))
        .round()
        .clamp(0, 100);
  }

  String get scoreLabel {
    final s = score;
    if (s >= 85) return 'Excellent sleep';
    if (s >= 70) return 'Good sleep';
    if (s >= 55) return 'Fair sleep';
    return 'Poor sleep';
  }

  // Estimated sleep stages (simplified model)
  int get deepPercent => (15 + (quality / 10.0) * 8).round().clamp(15, 23);
  int get remPercent => (durationHours > 7 ? 25 : 20).clamp(20, 25);
  int get lightPercent => (100 - deepPercent - remPercent).clamp(0, 100);

  String get moodLabel {
    const labels = ['', 'Exhausted', 'Tired', 'Okay', 'Good', 'Rested'];
    return mood >= 1 && mood <= 5 ? labels[mood] : '—';
  }

  String get moodEmoji {
    const emojis = ['', '😩', '😴', '😐', '🙂', '😄'];
    return mood >= 1 && mood <= 5 ? emojis[mood] : '❓';
  }

  // ── Serialisation ─────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'bedtime': bedtime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'quality': quality,
        'mood': mood,
        'notes': notes,
        'deletedAt': deletedAt?.toIso8601String(),
      };

  factory SleepEntry.fromJson(Map<String, dynamic> j) => SleepEntry(
        id: j['id'] as String,
        bedtime: DateTime.parse(j['bedtime'] as String),
        wakeTime: DateTime.parse(j['wakeTime'] as String),
        quality: (j['quality'] as num).toInt(),
        mood: (j['mood'] as num).toInt(),
        notes: j['notes'] as String? ?? '',
        deletedAt: j['deletedAt'] != null
            ? DateTime.parse(j['deletedAt'] as String)
            : null,
      );

  /// Sentinel used to distinguish "argument not passed" from
  /// "argument explicitly passed as null" in [copyWith].
  static const _unset = Object();

  SleepEntry copyWith({
    String? id,
    DateTime? bedtime,
    DateTime? wakeTime,
    int? quality,
    int? mood,
    String? notes,
    Object? deletedAt = _unset,
  }) =>
      SleepEntry(
        id: id ?? this.id,
        bedtime: bedtime ?? this.bedtime,
        wakeTime: wakeTime ?? this.wakeTime,
        quality: quality ?? this.quality,
        mood: mood ?? this.mood,
        notes: notes ?? this.notes,
        deletedAt: identical(deletedAt, _unset)
            ? this.deletedAt
            : deletedAt as DateTime?,
      );
}
