import 'dart:math' as math;

enum FocusMode { normal, pomodoro, deep }

extension FocusModeUi on FocusMode {
  String get label => switch (this) {
        FocusMode.normal => 'Normal',
        FocusMode.pomodoro => 'Pomodoro',
        FocusMode.deep => 'Deep Focus',
      };

  String get description => switch (this) {
        FocusMode.normal => 'Calm focus with standard rewards',
        FocusMode.pomodoro => 'Focus round followed by a short break',
        FocusMode.deep => 'Distraction warning and 25% bonus',
      };

  double get multiplier => switch (this) {
        FocusMode.normal => 1,
        FocusMode.pomodoro => 1.1,
        FocusMode.deep => 1.25,
      };
}

enum PetKind { robot, bunny, cat }

extension PetKindUi on PetKind {
  String get label => switch (this) {
        PetKind.robot => 'Robot',
        PetKind.bunny => 'Bunny',
        PetKind.cat => 'Cat',
      };
}

enum ItemCategory { hats, room, backgrounds, effects }

extension ItemCategoryUi on ItemCategory {
  String get label => switch (this) {
        ItemCategory.hats => 'Hats',
        ItemCategory.room => 'Room',
        ItemCategory.backgrounds => 'Backgrounds',
        ItemCategory.effects => 'Effects',
      };
}

enum TaskStatus { todo, inProgress, done }

extension TaskStatusUi on TaskStatus {
  String get label => switch (this) {
        TaskStatus.todo => 'To do',
        TaskStatus.inProgress => 'In progress',
        TaskStatus.done => 'Done',
      };
}

enum TaskPriority { low, medium, high }

extension TaskPriorityUi on TaskPriority {
  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.medium => 'Medium',
        TaskPriority.high => 'High',
      };
}

enum ExamImportance { normal, important, critical }

extension ExamImportanceUi on ExamImportance {
  String get label => switch (this) {
        ExamImportance.normal => 'Normal',
        ExamImportance.important => 'Important',
        ExamImportance.critical => 'Critical',
      };
}

class Subject {
  Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.weeklyGoalMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String name;
  int colorValue;
  int iconCodePoint;
  int weeklyGoalMinutes;
  final DateTime createdAt;
  DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'weeklyGoalMinutes': weeklyGoalMinutes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['colorValue'] as int,
        iconCodePoint: json['iconCodePoint'] as int,
        weeklyGoalMinutes: json['weeklyGoalMinutes'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class StudyTask {
  StudyTask({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.status,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
    this.plannedDate,
    this.completedAt,
    this.examId,
  });

  final String id;
  String subjectId;
  String title;
  String description;
  int estimatedMinutes;
  TaskStatus status;
  TaskPriority priority;
  DateTime? dueDate;
  final DateTime createdAt;
  DateTime? plannedDate;
  DateTime? completedAt;
  final String? examId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'description': description,
        'estimatedMinutes': estimatedMinutes,
        'status': status.name,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'plannedDate': plannedDate?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'examId': examId,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        description: (json['description'] as String?) ?? '',
        estimatedMinutes: json['estimatedMinutes'] as int,
        status: TaskStatus.values.byName(json['status'] as String),
        priority: TaskPriority.values.byName(json['priority'] as String),
        dueDate: json['dueDate'] == null
            ? null
            : DateTime.parse(json['dueDate'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        plannedDate: json['plannedDate'] == null
            ? null
            : DateTime.parse(json['plannedDate'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
        examId: json['examId'] as String?,
      );
}

class Exam {
  Exam({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.examDate,
    required this.topics,
    required this.importance,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String subjectId;
  String title;
  DateTime examDate;
  List<String> topics;
  ExamImportance importance;
  final DateTime createdAt;
  DateTime updatedAt;

  int get daysLeft => DateTime(examDate.year, examDate.month, examDate.day)
      .difference(DateTime.now().copyWith(
          hour: 0, minute: 0, second: 0, millisecond: 0, microsecond: 0))
      .inDays;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'title': title,
        'examDate': examDate.toIso8601String(),
        'topics': topics,
        'importance': importance.name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        title: json['title'] as String,
        examDate: DateTime.parse(json['examDate'] as String),
        topics: (json['topics'] as List<dynamic>).cast<String>(),
        importance: ExamImportance.values.byName(json['importance'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class Mistake {
  Mistake({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.mistakeType,
    required this.correction,
    required this.createdAt,
    this.taskId,
    this.sessionId,
    this.reviewedAt,
    this.isResolved = false,
  });

  final String id;
  final String subjectId;
  final String? taskId;
  final String? sessionId;
  String title;
  String description;
  String mistakeType;
  String correction;
  final DateTime createdAt;
  DateTime? reviewedAt;
  bool isResolved;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'taskId': taskId,
        'sessionId': sessionId,
        'title': title,
        'description': description,
        'mistakeType': mistakeType,
        'correction': correction,
        'createdAt': createdAt.toIso8601String(),
        'reviewedAt': reviewedAt?.toIso8601String(),
        'isResolved': isResolved,
      };

  factory Mistake.fromJson(Map<String, dynamic> json) => Mistake(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        taskId: json['taskId'] as String?,
        sessionId: json['sessionId'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        mistakeType: json['mistakeType'] as String,
        correction: json['correction'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        reviewedAt: json['reviewedAt'] == null
            ? null
            : DateTime.parse(json['reviewedAt'] as String),
        isResolved: (json['isResolved'] as bool?) ?? false,
      );
}

class DailyPlanItem {
  const DailyPlanItem({
    required this.subjectId,
    required this.recommendedMinutes,
    required this.reason,
    required this.priorityScore,
    this.taskId,
  });

  final String subjectId;
  final String? taskId;
  final int recommendedMinutes;
  final String reason;
  final int priorityScore;
}

class SessionReward {
  const SessionReward({required this.xp, required this.coins});

  final int xp;
  final int coins;
}

class ProfileInfo {
  const ProfileInfo({
    required this.id,
    required this.userName,
    required this.petName,
    required this.petKind,
    required this.level,
    required this.active,
  });

  final String id;
  final String userName;
  final String petName;
  final PetKind petKind;
  final int level;
  final bool active;
}

SessionReward calculateReward(int minutes, FocusMode mode) {
  final baseXp = switch (minutes) {
    15 => 15,
    25 => 30,
    45 => 60,
    60 => 90,
    _ => math.max(minutes, 5),
  };
  final baseCoins = switch (minutes) {
    15 => 8,
    25 => 15,
    45 => 30,
    60 => 45,
    _ => math.max((minutes / 2).round(), 3),
  };
  return SessionReward(
    xp: (baseXp * mode.multiplier).round(),
    coins: (baseCoins * mode.multiplier).round(),
  );
}

class ActiveSession {
  ActiveSession({
    required this.durationMinutes,
    required this.subject,
    required this.mode,
    required this.endsAt,
    this.subjectId,
    this.taskId,
    String? id,
    DateTime? startedAt,
    this.remainingWhenPaused,
    this.pauseCount = 0,
  })  : id = id ?? 'session_${DateTime.now().microsecondsSinceEpoch}',
        startedAt = startedAt ?? DateTime.now();

  final String id;
  final int durationMinutes;
  final String subject;
  final String? subjectId;
  final String? taskId;
  final FocusMode mode;
  final DateTime startedAt;
  DateTime? endsAt;
  int? remainingWhenPaused;
  int pauseCount;

  bool get isPaused => endsAt == null;

  int remainingSeconds([DateTime? at]) {
    if (isPaused) {
      return remainingWhenPaused ?? durationMinutes * 60;
    }
    return math.max(0, endsAt!.difference(at ?? DateTime.now()).inSeconds);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'durationMinutes': durationMinutes,
        'subject': subject,
        'subjectId': subjectId,
        'taskId': taskId,
        'mode': mode.name,
        'startedAt': startedAt.toIso8601String(),
        'endsAt': endsAt?.toIso8601String(),
        'remainingWhenPaused': remainingWhenPaused,
        'pauseCount': pauseCount,
      };

  factory ActiveSession.fromJson(Map<String, dynamic> json) => ActiveSession(
        id: json['id'] as String?,
        durationMinutes: json['durationMinutes'] as int,
        subject: json['subject'] as String,
        subjectId: json['subjectId'] as String?,
        taskId: json['taskId'] as String?,
        mode: FocusMode.values.byName(json['mode'] as String),
        startedAt: json['startedAt'] == null
            ? DateTime.now()
            : DateTime.parse(json['startedAt'] as String),
        endsAt: json['endsAt'] == null
            ? null
            : DateTime.parse(json['endsAt'] as String),
        remainingWhenPaused: json['remainingWhenPaused'] as int?,
        pauseCount: (json['pauseCount'] as int?) ?? 0,
      );
}

class FocusSession {
  FocusSession({
    required this.id,
    required this.plannedMinutes,
    required this.actualMinutes,
    required this.subject,
    required this.mode,
    required this.startedAt,
    required this.finishedAt,
    required this.rewardXp,
    required this.rewardCoins,
    required this.wasPaused,
    this.subjectId,
    this.taskId,
    this.exercisesSolved,
    this.correctAnswers,
    this.confidenceLevel,
    this.note,
  });

  final String id;
  final int plannedMinutes;
  final int actualMinutes;
  final String subject;
  final String? subjectId;
  final String? taskId;
  final FocusMode mode;
  final DateTime startedAt;
  final DateTime finishedAt;
  final int rewardXp;
  final int rewardCoins;
  final bool wasPaused;
  final int? exercisesSolved;
  final int? correctAnswers;
  final int? confidenceLevel;
  final String? note;

  int get durationMinutes => actualMinutes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'plannedMinutes': plannedMinutes,
        'actualMinutes': actualMinutes,
        'durationMinutes': actualMinutes,
        'subject': subject,
        'subjectId': subjectId,
        'taskId': taskId,
        'mode': mode.name,
        'startedAt': startedAt.toIso8601String(),
        'finishedAt': finishedAt.toIso8601String(),
        'rewardXp': rewardXp,
        'rewardCoins': rewardCoins,
        'wasPaused': wasPaused,
        'exercisesSolved': exercisesSolved,
        'correctAnswers': correctAnswers,
        'confidenceLevel': confidenceLevel,
        'note': note,
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: (json['id'] as String?) ??
            'legacy_${DateTime.parse(json['finishedAt'] as String).microsecondsSinceEpoch}',
        plannedMinutes:
            (json['plannedMinutes'] as int?) ?? json['durationMinutes'] as int,
        actualMinutes:
            (json['actualMinutes'] as int?) ?? json['durationMinutes'] as int,
        subject: json['subject'] as String,
        subjectId: json['subjectId'] as String?,
        taskId: json['taskId'] as String?,
        mode: FocusMode.values.byName(json['mode'] as String),
        startedAt: json['startedAt'] == null
            ? DateTime.parse(json['finishedAt'] as String)
            : DateTime.parse(json['startedAt'] as String),
        finishedAt: DateTime.parse(json['finishedAt'] as String),
        rewardXp: json['rewardXp'] as int,
        rewardCoins: json['rewardCoins'] as int,
        wasPaused: json['wasPaused'] as bool,
        exercisesSolved: json['exercisesSolved'] as int?,
        correctAnswers: json['correctAnswers'] as int?,
        confidenceLevel: json['confidenceLevel'] as int?,
        note: json['note'] as String?,
      );
}

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
  });

  final String id;
  final String name;
  final ItemCategory category;
  final int price;
}

const shopCatalog = [
  ShopItem(
      id: 'blue_cap', name: 'Blue Cap', category: ItemCategory.hats, price: 70),
  ShopItem(
      id: 'grad_cap',
      name: 'Graduation Cap',
      category: ItemCategory.hats,
      price: 130),
  ShopItem(
      id: 'headphones',
      name: 'Headphones',
      category: ItemCategory.hats,
      price: 180),
  ShopItem(
      id: 'lamp', name: 'Study Lamp', category: ItemCategory.room, price: 90),
  ShopItem(
      id: 'plant', name: 'Desk Plant', category: ItemCategory.room, price: 110),
  ShopItem(
      id: 'bookshelf',
      name: 'Bookshelf',
      category: ItemCategory.room,
      price: 170),
  ShopItem(
      id: 'library',
      name: 'Library',
      category: ItemCategory.backgrounds,
      price: 200),
  ShopItem(
      id: 'space',
      name: 'Space Room',
      category: ItemCategory.backgrounds,
      price: 260),
  ShopItem(
      id: 'sparkle',
      name: 'Sparkle Aura',
      category: ItemCategory.effects,
      price: 120),
  ShopItem(
      id: 'rain',
      name: 'Rain Window',
      category: ItemCategory.effects,
      price: 160),
];

class DailyQuest {
  const DailyQuest({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.rewardXp,
    required this.rewardCoins,
    required this.claimed,
  });

  final String id;
  final String title;
  final int current;
  final int target;
  final int rewardXp;
  final int rewardCoins;
  final bool claimed;

  bool get complete => current >= target;
}

String dayKey(DateTime value) {
  final date = value.toLocal();
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

bool sameDay(DateTime a, DateTime b) => dayKey(a) == dayKey(b);

String formatMinutes(int value) {
  final hours = value ~/ 60;
  final minutes = value % 60;
  if (hours == 0) return '${minutes}m';
  if (minutes == 0) return '${hours}h';
  return '${hours}h ${minutes}m';
}
