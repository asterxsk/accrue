/// How a habit is measured.
enum HabitKind {
  /// Done or not done, once a day.
  check,

  /// Time logged toward a session goal, in minutes.
  timer,

  /// Units counted toward a target.
  count;

  static HabitKind fromName(String? name) => HabitKind.values.firstWhere(
    (kind) => kind.name == name,
    orElse: () => HabitKind.check,
  );

  String get label => switch (this) {
    HabitKind.check => 'Check off',
    HabitKind.timer => 'Timer',
    HabitKind.count => 'Count',
  };

  String get description => switch (this) {
    HabitKind.check => "One tap when it's done",
    HabitKind.timer => 'Track minutes spent',
    HabitKind.count => 'Track units toward a target',
  };

  String get defaultIcon => switch (this) {
    HabitKind.check => 'check',
    HabitKind.timer => 'timer',
    HabitKind.count => 'water',
  };
}

class Habit {
  Habit({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    this.target = 1,
    this.unit = '',
    this.count = 0,
    this.seconds = 0,
    this.checked = false,
    this.badge = false,
    this.badgeText = '',
    this.badgeFg = '#FAF9F5',
    this.badgeStart = '#C96442',
    this.badgeEnd = '#A94E2E',
    this.step = 1,
    this.reminderMinutes,
    this.blockDistractions = true,
  });

  final String id;

  /// Editable from the habit page.
  String name;
  HabitKind kind;

  /// Name in the app's own icon set.
  String icon;

  /// Count target, or timer target in minutes.
  int target;

  /// Unit for count habits, e.g. "glasses". Empty means "times".
  String unit;

  /// Today's counted units. Fractional so a bottle can be 2.5.
  double count;

  /// Today's logged seconds.
  int seconds;

  /// Today's tick.
  bool checked;

  /// True when the mark is a short text badge instead of an icon.
  bool badge;

  /// One or two characters shown in the badge.
  String badgeText;

  /// Badge text colour and the two gradient stops behind it, as hex strings.
  String badgeFg;
  String badgeStart;
  String badgeEnd;

  /// How much one tap of + or − moves a counted habit (steps rarely go 1 by 1).
  double step;

  /// Daily reminder as minutes after midnight, or null when off.
  int? reminderMinutes;

  /// Timer habits only: draw the focus overlay over distracting apps.
  bool blockDistractions;

  bool get isTimer => kind == HabitKind.timer;

  bool get reminderOn => reminderMinutes != null;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'icon': icon,
    'target': target,
    'unit': unit,
    'count': count,
    'seconds': seconds,
    'checked': checked,
    'badge': badge,
    'badgeText': badgeText,
    'badgeFg': badgeFg,
    'badgeStart': badgeStart,
    'badgeEnd': badgeEnd,
    'step': step,
    'reminderMinutes': reminderMinutes,
    'blockDistractions': blockDistractions,
  };

  static Habit fromJson(Map<String, Object?> json) => Habit(
    id: json['id']! as String,
    name: json['name']! as String,
    kind: HabitKind.fromName(json['kind'] as String?),
    icon: (json['icon'] as String?) ?? 'check',
    target: (json['target'] as num?)?.toInt() ?? 1,
    unit: (json['unit'] as String?) ?? '',
    count: (json['count'] as num?)?.toDouble() ?? 0,
    seconds: (json['seconds'] as num?)?.toInt() ?? 0,
    checked: (json['checked'] as bool?) ?? false,
    badge: (json['badge'] as bool?) ?? false,
    badgeText: (json['badgeText'] as String?) ?? '',
    badgeFg: (json['badgeFg'] as String?) ?? '#FAF9F5',
    badgeStart: (json['badgeStart'] as String?) ?? '#C96442',
    badgeEnd: (json['badgeEnd'] as String?) ?? '#A94E2E',
    step: ((json['step'] as num?)?.toDouble() ?? 1).clamp(0.01, 100000),
    reminderMinutes: ((json['reminderMinutes'] as num?)?.toInt())?.clamp(
      0,
      1439,
    ),
    blockDistractions: (json['blockDistractions'] as bool?) ?? true,
  );
}

/// A routine is a named, ordered set of habits.
class Routine {
  Routine({required this.id, required this.name, required this.habitIds});

  final String id;
  String name;
  List<String> habitIds;

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'habitIds': habitIds,
  };

  static Routine fromJson(Map<String, Object?> json) => Routine(
    id: json['id']! as String,
    name: json['name']! as String,
    habitIds: ((json['habitIds'] as List?) ?? const [])
        .whereType<String>()
        .toList(),
  );
}

/// A habit proposed during onboarding or in the habit-ideas sheet.
class HabitIdea {
  const HabitIdea({
    required this.key,
    required this.group,
    required this.name,
    required this.kind,
    required this.icon,
    required this.target,
    required this.unit,
    this.meta,
  });

  final String key;
  final String group;
  final String name;
  final HabitKind kind;
  final String icon;
  final int target;
  final String unit;

  /// The second line on a recommendation card; derived when absent.
  final String? meta;
}

/// The five habits onboarding offers by default.
const List<HabitIdea> starterHabits = [
  HabitIdea(
    key: 'water',
    group: 'Health',
    name: 'Water',
    kind: HabitKind.count,
    icon: 'water',
    target: 8,
    unit: 'glasses',
    meta: '8 glasses a day',
  ),
  HabitIdea(
    key: 'gym',
    group: 'Movement',
    name: 'Gym',
    kind: HabitKind.timer,
    icon: 'timer',
    target: 45,
    unit: 'min',
    meta: '45 minutes a day',
  ),
  HabitIdea(
    key: 'read',
    group: 'Mind',
    name: 'Read',
    kind: HabitKind.check,
    icon: 'book',
    target: 1,
    unit: '',
    meta: 'Once a day',
  ),
  HabitIdea(
    key: 'walk',
    group: 'Movement',
    name: 'Walk',
    kind: HabitKind.count,
    icon: 'walk',
    target: 8000,
    unit: 'steps',
    meta: '8,000 steps a day',
  ),
  HabitIdea(
    key: 'sleep',
    group: 'Health',
    name: 'Sleep by 11',
    kind: HabitKind.check,
    icon: 'moon',
    target: 1,
    unit: '',
    meta: 'Once a day',
  ),
];

/// The two routines onboarding offers, by starter-habit key.
const Map<String, List<String>> starterRoutines = {
  'morning': ['water', 'read'],
  'evening': ['walk', 'sleep'],
};

/// The browsable catalogue behind "Habit ideas".
const List<HabitIdea> habitIdeas = [
  HabitIdea(
    key: 'water',
    group: 'Health',
    name: 'Drink water',
    kind: HabitKind.count,
    icon: 'water',
    target: 8,
    unit: 'glasses',
  ),
  HabitIdea(
    key: 'sleep',
    group: 'Health',
    name: 'Sleep by 11',
    kind: HabitKind.check,
    icon: 'moon',
    target: 1,
    unit: '',
  ),
  HabitIdea(
    key: 'walk',
    group: 'Movement',
    name: 'Walk',
    kind: HabitKind.count,
    icon: 'walk',
    target: 8000,
    unit: 'steps',
  ),
  HabitIdea(
    key: 'gym',
    group: 'Movement',
    name: 'Gym',
    kind: HabitKind.timer,
    icon: 'timer',
    target: 45,
    unit: 'min',
  ),
  HabitIdea(
    key: 'stretch',
    group: 'Movement',
    name: 'Stretch',
    kind: HabitKind.timer,
    icon: 'up',
    target: 5,
    unit: 'min',
  ),
  HabitIdea(
    key: 'read',
    group: 'Mind',
    name: 'Read',
    kind: HabitKind.check,
    icon: 'book',
    target: 1,
    unit: '',
  ),
  HabitIdea(
    key: 'meditate',
    group: 'Mind',
    name: 'Meditate',
    kind: HabitKind.timer,
    icon: 'moon',
    target: 10,
    unit: 'min',
  ),
  HabitIdea(
    key: 'language',
    group: 'Mind',
    name: 'Practice a language',
    kind: HabitKind.timer,
    icon: 'book',
    target: 15,
    unit: 'min',
  ),
  HabitIdea(
    key: 'tidy',
    group: 'Home',
    name: 'Tidy for 10',
    kind: HabitKind.timer,
    icon: 'home',
    target: 10,
    unit: 'min',
  ),
  HabitIdea(
    key: 'bed',
    group: 'Home',
    name: 'Make the bed',
    kind: HabitKind.check,
    icon: 'home',
    target: 1,
    unit: '',
  ),
];
