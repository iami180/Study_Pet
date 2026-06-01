import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import '../services/notification_service.dart';

class AppController extends ChangeNotifier {
  static const _storageKey = 'focuspet_progress_v1';

  SharedPreferences? _prefs;
  bool ready = false;
  bool onboarded = false;
  bool darkMode = false;
  bool notificationsEnabled = false;
  bool vibrationEnabled = true;
  int reminderHour = 18;
  int reminderMinute = 0;
  String userName = 'Marci';
  String petName = 'Lumi';
  PetKind petKind = PetKind.robot;
  int totalXp = 0;
  int coins = 25;
  int currentStreak = 0;
  int longestStreak = 0;
  String? lastFocusDate;
  ActiveSession? activeSession;
  final List<FocusSession> sessions = [];
  final List<Subject> subjects = [];
  final List<StudyTask> tasks = [];
  final List<Exam> exams = [];
  final List<Mistake> mistakes = [];
  final Set<String> purchasedItems = {'starter_desk'};
  final Map<ItemCategory, String?> equipped = {
    ItemCategory.hats: null,
    ItemCategory.room: null,
    ItemCategory.backgrounds: null,
    ItemCategory.effects: null,
  };
  final Set<String> claimedQuestKeys = {};
  final Set<String> claimedWeeklyGoalKeys = {};
  final Set<String> skippedPlanKeys = {};

  int get level => totalXp ~/ 120 + 1;
  int get xpIntoLevel => totalXp % 120;
  int get xpForNextLevel => 120;
  double get levelProgress => xpIntoLevel / xpForNextLevel;
  bool get hasActiveSession => activeSession != null;
  int get unresolvedMistakeCount =>
      mistakes.where((mistake) => !mistake.isResolved).length;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_storageKey);
    if (raw != null) _readJson(jsonDecode(raw) as Map<String, dynamic>);
    _seedSubjectsIfNeeded();
    _linkLegacySessions();
    _expireStreakIfNeeded();
    skippedPlanKeys
        .removeWhere((key) => !key.startsWith('${dayKey(DateTime.now())}:'));
    ready = true;
    notifyListeners();
    _runNotification(NotificationService.instance.initialize());
  }

  Future<void> finishOnboarding(PetKind choice) async {
    petKind = choice;
    onboarded = true;
    await _saveAndNotify();
  }

  Subject subjectById(String id) =>
      subjects.firstWhere((subject) => subject.id == id);

  Subject? optionalSubject(String? id) {
    if (id == null) return null;
    for (final subject in subjects) {
      if (subject.id == id) return subject;
    }
    return null;
  }

  StudyTask? taskById(String? id) {
    if (id == null) return null;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<bool> startSession({
    required int minutes,
    required String subjectId,
    required FocusMode mode,
    String? taskId,
  }) async {
    if (activeSession != null) return false;
    final subject = subjectById(subjectId);
    activeSession = ActiveSession(
      durationMinutes: minutes,
      subject: subject.name,
      subjectId: subject.id,
      taskId: taskId,
      mode: mode,
      endsAt: DateTime.now().add(Duration(minutes: minutes)),
    );
    final task = taskById(taskId);
    if (task != null && task.status == TaskStatus.todo) {
      task.status = TaskStatus.inProgress;
    }
    await _saveAndNotify();
    if (notificationsEnabled) {
      _runNotification(NotificationService.instance
          .scheduleSessionComplete(activeSession!.endsAt!));
    }
    return true;
  }

  Future<bool> pauseSession() async {
    final session = activeSession;
    if (session == null || session.isPaused || session.pauseCount >= 3) {
      return false;
    }
    session.remainingWhenPaused = session.remainingSeconds();
    session.endsAt = null;
    session.pauseCount += 1;
    await _saveAndNotify();
    _runNotification(NotificationService.instance.cancelSessionComplete());
    return true;
  }

  Future<void> resumeSession() async {
    final session = activeSession;
    if (session == null || !session.isPaused) return;
    session.endsAt = DateTime.now().add(
      Duration(seconds: session.remainingWhenPaused!),
    );
    session.remainingWhenPaused = null;
    await _saveAndNotify();
    if (notificationsEnabled) {
      _runNotification(NotificationService.instance
          .scheduleSessionComplete(session.endsAt!));
    }
  }

  Future<void> cancelSession() async {
    activeSession = null;
    await _saveAndNotify();
    _runNotification(NotificationService.instance.cancelSessionComplete());
  }

  SessionReward? get pendingReward {
    final session = activeSession;
    if (session == null || session.remainingSeconds() > 0) return null;
    return calculateReward(session.durationMinutes, session.mode);
  }

  Future<FocusSession?> claimCompletedSession({
    bool markTaskDone = false,
    int? exercisesSolved,
    int? correctAnswers,
    int? confidenceLevel,
    String? note,
  }) async {
    final active = activeSession;
    final reward = pendingReward;
    if (active == null || reward == null) return null;
    final completed = FocusSession(
      id: active.id,
      plannedMinutes: active.durationMinutes,
      actualMinutes: active.durationMinutes,
      subject: active.subject,
      subjectId: active.subjectId,
      taskId: active.taskId,
      mode: active.mode,
      startedAt: active.startedAt,
      finishedAt: DateTime.now(),
      rewardXp: reward.xp,
      rewardCoins: reward.coins,
      wasPaused: active.pauseCount > 0,
      exercisesSolved: exercisesSolved,
      correctAnswers: correctAnswers,
      confidenceLevel: confidenceLevel,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
    );
    final oldLevel = level;
    sessions.add(completed);
    totalXp += reward.xp;
    coins += reward.coins;
    if (markTaskDone) {
      final task = taskById(active.taskId);
      if (task != null && task.status != TaskStatus.done) {
        task.status = TaskStatus.done;
        task.completedAt = DateTime.now();
        totalXp += task.examId == null ? 20 : 30;
        coins += 5;
      }
    }
    _applyStreak(completed.finishedAt);
    final subject = optionalSubject(active.subjectId);
    if (subject != null) {
      final goalKey = '${dayKey(_mondayOf(DateTime.now()))}:${subject.id}';
      if (weeklyMinutesForSubject(subject.id) >= subject.weeklyGoalMinutes &&
          claimedWeeklyGoalKeys.add(goalKey)) {
        totalXp += 50;
        coins += 20;
      }
    }
    activeSession = null;
    if (level > oldLevel) coins += 50;
    await _saveAndNotify();
    _runNotification(NotificationService.instance.cancelSessionComplete());
    return completed;
  }

  List<FocusSession> get todaySessions => sessions
      .where((session) => sameDay(session.finishedAt, DateTime.now()))
      .toList();

  int get todayMinutes =>
      todaySessions.fold(0, (sum, session) => sum + session.actualMinutes);

  int get todaySessionCount => todaySessions.length;

  int get totalMinutes =>
      sessions.fold(0, (sum, session) => sum + session.actualMinutes);

  List<int> get weeklyMinutes {
    final start = _mondayOf(DateTime.now());
    return List.generate(7, (index) {
      final day = start.add(Duration(days: index));
      return sessions
          .where((session) => sameDay(session.finishedAt, day))
          .fold(0, (sum, session) => sum + session.actualMinutes);
    });
  }

  int weeklyMinutesForSubject(String subjectId) => sessions
      .where((session) =>
          session.subjectId == subjectId &&
          !session.finishedAt.isBefore(_mondayOf(DateTime.now())))
      .fold(0, (sum, session) => sum + session.actualMinutes);

  int get bestDayMinutes {
    final totals = <String, int>{};
    for (final session in sessions) {
      totals.update(
          dayKey(session.finishedAt), (value) => value + session.actualMinutes,
          ifAbsent: () => session.actualMinutes);
    }
    return totals.values.fold(0, math.max);
  }

  Map<String, int> get subjectMinutes {
    final totals = <String, int>{};
    for (final session in sessions) {
      totals.update(session.subject, (value) => value + session.actualMinutes,
          ifAbsent: () => session.actualMinutes);
    }
    return totals;
  }

  Exam? nextExamForSubject(String subjectId) {
    final upcoming = exams
        .where((exam) =>
            exam.subjectId == subjectId &&
            !_dateOnly(exam.examDate).isBefore(_dateOnly(DateTime.now())))
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  List<Exam> get upcomingExams {
    final list = exams
        .where((exam) =>
            !_dateOnly(exam.examDate).isBefore(_dateOnly(DateTime.now())))
        .toList()
      ..sort((a, b) => a.examDate.compareTo(b.examDate));
    return list;
  }

  List<DailyPlanItem> get dailyPlan {
    final now = DateTime.now();
    final plannedTasks = tasks
        .where((task) =>
            task.status != TaskStatus.done &&
            task.plannedDate != null &&
            sameDay(task.plannedDate!, now))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return plannedTasks
        .map((task) => DailyPlanItem(
              subjectId: task.subjectId,
              taskId: task.id,
              recommendedMinutes: task.estimatedMinutes,
              reason: 'Added to today\'s plan',
              priorityScore: 0,
            ))
        .where((item) => !skippedPlanKeys.contains(_planKey(item)))
        .toList();
  }

  Future<void> skipPlanItem(DailyPlanItem item) async {
    skippedPlanKeys.add(_planKey(item));
    await _saveAndNotify();
  }

  List<DailyQuest> get dailyQuests {
    final today = dayKey(DateTime.now());
    return [
      DailyQuest(
        id: 'one_session',
        title: 'Complete 1 focus session',
        current: todaySessionCount.clamp(0, 1),
        target: 1,
        rewardXp: 20,
        rewardCoins: 10,
        claimed: claimedQuestKeys.contains('$today:one_session'),
      ),
      DailyQuest(
        id: 'one_task',
        title: 'Complete 1 task',
        current: tasks.any((task) =>
                task.completedAt != null &&
                sameDay(task.completedAt!, DateTime.now()))
            ? 1
            : 0,
        target: 1,
        rewardXp: 25,
        rewardCoins: 15,
        claimed: claimedQuestKeys.contains('$today:one_task'),
      ),
      DailyQuest(
        id: 'review_mistake',
        title: 'Review 1 mistake',
        current: mistakes.any((mistake) =>
                mistake.reviewedAt != null &&
                sameDay(mistake.reviewedAt!, DateTime.now()))
            ? 1
            : 0,
        target: 1,
        rewardXp: 20,
        rewardCoins: 10,
        claimed: claimedQuestKeys.contains('$today:review_mistake'),
      ),
    ];
  }

  bool get hasClaimableQuest =>
      dailyQuests.any((quest) => quest.complete && !quest.claimed);

  Future<void> claimQuest(DailyQuest quest) async {
    if (!quest.complete || quest.claimed) return;
    claimedQuestKeys.add('${dayKey(DateTime.now())}:${quest.id}');
    totalXp += quest.rewardXp;
    coins += quest.rewardCoins;
    await _saveAndNotify();
  }

  Future<void> addSubject({
    required String name,
    required int colorValue,
    required int iconCodePoint,
    required int weeklyGoalMinutes,
  }) async {
    if (name.trim().isEmpty) return;
    final now = DateTime.now();
    subjects.add(Subject(
      id: _newId('subject'),
      name: name.trim(),
      colorValue: colorValue,
      iconCodePoint: iconCodePoint,
      weeklyGoalMinutes: weeklyGoalMinutes,
      createdAt: now,
      updatedAt: now,
    ));
    await _saveAndNotify();
  }

  Future<void> updateSubject(Subject subject) async {
    subject.updatedAt = DateTime.now();
    await _saveAndNotify();
  }

  Future<bool> deleteSubject(Subject subject) async {
    if (subjects.length <= 1 ||
        tasks.any((task) => task.subjectId == subject.id) ||
        exams.any((exam) => exam.subjectId == subject.id) ||
        sessions.any((session) => session.subjectId == subject.id)) {
      return false;
    }
    subjects.remove(subject);
    await _saveAndNotify();
    return true;
  }

  Future<void> addTask({
    required String subjectId,
    required String title,
    String description = '',
    required int estimatedMinutes,
    required TaskPriority priority,
    DateTime? dueDate,
    DateTime? plannedDate,
    String? examId,
  }) async {
    if (title.trim().isEmpty) return;
    tasks.add(StudyTask(
      id: _newId('task'),
      subjectId: subjectId,
      title: title.trim(),
      description: description.trim(),
      estimatedMinutes: estimatedMinutes,
      status: TaskStatus.todo,
      priority: priority,
      dueDate: dueDate,
      createdAt: DateTime.now(),
      plannedDate: plannedDate,
      examId: examId,
    ));
    await _saveAndNotify();
  }

  Future<void> updateTask(StudyTask task) async {
    await _saveAndNotify();
  }

  Future<bool> deleteTask(StudyTask task) async {
    if (activeSession?.taskId == task.id) return false;
    tasks.remove(task);
    await _saveAndNotify();
    return true;
  }

  Future<void> markTaskDone(StudyTask task) async {
    if (task.status == TaskStatus.done) return;
    task.status = TaskStatus.done;
    task.completedAt = DateTime.now();
    totalXp += task.examId == null ? 20 : 30;
    coins += 5;
    await _saveAndNotify();
  }

  Future<void> planTaskForToday(StudyTask task) async {
    if (task.status == TaskStatus.done) return;
    task.plannedDate = DateTime.now();
    await _saveAndNotify();
  }

  Future<void> addExam({
    required String subjectId,
    required String title,
    required DateTime examDate,
    required List<String> topics,
    required ExamImportance importance,
  }) async {
    if (title.trim().isEmpty) return;
    final now = DateTime.now();
    exams.add(Exam(
      id: _newId('exam'),
      subjectId: subjectId,
      title: title.trim(),
      examDate: examDate,
      topics: topics.where((topic) => topic.trim().isNotEmpty).toList(),
      importance: importance,
      createdAt: now,
      updatedAt: now,
    ));
    await _saveAndNotify();
  }

  Future<bool> deleteExam(Exam exam) async {
    final relatedTasks = tasks.where((task) => task.examId == exam.id).toList();
    if (activeSession != null &&
        relatedTasks.any((task) => task.id == activeSession!.taskId)) {
      return false;
    }
    tasks.removeWhere((task) => task.examId == exam.id);
    exams.remove(exam);
    await _saveAndNotify();
    return true;
  }

  Future<void> generateTasksForExam(Exam exam) async {
    for (final topic in exam.topics) {
      if (!tasks.any(
          (task) => task.examId == exam.id && task.title.contains(topic))) {
        await addTask(
          subjectId: exam.subjectId,
          title: 'Review $topic',
          description: 'Prepare for ${exam.title}',
          estimatedMinutes: 25,
          priority: TaskPriority.high,
          dueDate: exam.examDate.subtract(const Duration(days: 1)),
          examId: exam.id,
        );
      }
    }
    if (!tasks.any((task) =>
        task.examId == exam.id && task.title.startsWith('Final review'))) {
      await addTask(
        subjectId: exam.subjectId,
        title: 'Final review before ${exam.title}',
        estimatedMinutes: 30,
        priority: TaskPriority.high,
        dueDate: exam.examDate.subtract(const Duration(days: 1)),
        examId: exam.id,
      );
    }
  }

  Future<void> addMistake({
    required String subjectId,
    String? taskId,
    String? sessionId,
    required String title,
    required String description,
    required String mistakeType,
    required String correction,
  }) async {
    if (title.trim().isEmpty) return;
    mistakes.add(Mistake(
      id: _newId('mistake'),
      subjectId: subjectId,
      taskId: taskId,
      sessionId: sessionId,
      title: title.trim(),
      description: description.trim(),
      mistakeType: mistakeType,
      correction: correction.trim(),
      createdAt: DateTime.now(),
    ));
    totalXp += 5;
    await _saveAndNotify();
  }

  Future<void> reviewMistake(Mistake mistake) async {
    if (mistake.isResolved) return;
    mistake.isResolved = true;
    mistake.reviewedAt = DateTime.now();
    totalXp += 10;
    await _saveAndNotify();
  }

  Future<bool> purchase(ShopItem item) async {
    if (purchasedItems.contains(item.id) || coins < item.price) return false;
    coins -= item.price;
    purchasedItems.add(item.id);
    await _saveAndNotify();
    return true;
  }

  Future<void> equip(ShopItem item) async {
    if (!purchasedItems.contains(item.id)) return;
    equipped[item.category] = item.id;
    await _saveAndNotify();
  }

  Future<void> unequip(ShopItem item) async {
    if (equipped[item.category] == item.id) {
      equipped[item.category] = null;
      await _saveAndNotify();
    }
  }

  bool isEquipped(ShopItem item) => equipped[item.category] == item.id;

  Future<bool> feedPet() async {
    if (coins < 10) return false;
    coins -= 10;
    await _saveAndNotify();
    return true;
  }

  Future<void> renamePet(String name) async {
    if (name.trim().isEmpty) return;
    petName = name.trim();
    await _saveAndNotify();
  }

  Future<void> updateUserName(String name) async {
    if (name.trim().isEmpty) return;
    userName = name.trim();
    await _saveAndNotify();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _saveAndNotify();
  }

  Future<bool> setNotifications(bool value) async {
    if (value && !await NotificationService.instance.requestPermission()) {
      return false;
    }
    notificationsEnabled = value;
    if (value) {
      await NotificationService.instance
          .scheduleDailyReminder(reminderHour, reminderMinute);
    } else {
      await NotificationService.instance.cancelDailyReminder();
      await NotificationService.instance.cancelSessionComplete();
    }
    await _saveAndNotify();
    return true;
  }

  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour = hour;
    reminderMinute = minute;
    if (notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(hour, minute);
    }
    await _saveAndNotify();
  }

  Future<void> setVibration(bool value) async {
    vibrationEnabled = value;
    await _saveAndNotify();
  }

  Future<void> resetProgress() async {
    sessions.clear();
    tasks.clear();
    exams.clear();
    mistakes.clear();
    totalXp = 0;
    coins = 25;
    currentStreak = 0;
    longestStreak = 0;
    lastFocusDate = null;
    activeSession = null;
    purchasedItems
      ..clear()
      ..add('starter_desk');
    equipped.updateAll((_, __) => null);
    claimedQuestKeys.clear();
    claimedWeeklyGoalKeys.clear();
    skippedPlanKeys.clear();
    await _saveAndNotify();
    _runNotification(NotificationService.instance.cancelSessionComplete());
  }

  void _applyStreak(DateTime completion) {
    final date = dayKey(completion);
    if (lastFocusDate == date) return;
    if (lastFocusDate == null) {
      currentStreak = 1;
    } else {
      final previous = _parseDayKey(lastFocusDate!);
      final days = _dateOnly(completion).difference(previous).inDays;
      currentStreak = days == 1 ? currentStreak + 1 : 1;
    }
    longestStreak = math.max(longestStreak, currentStreak);
    lastFocusDate = date;
  }

  void _expireStreakIfNeeded() {
    if (lastFocusDate == null) return;
    if (_dateOnly(DateTime.now())
            .difference(_parseDayKey(lastFocusDate!))
            .inDays >
        1) {
      currentStreak = 0;
    }
  }

  // Parse a dayKey string ("2025-01-15") into a local DateTime at midnight.
  DateTime _parseDayKey(String key) {
    final parts = key.split('-');
    return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
  DateTime _mondayOf(DateTime date) =>
      _dateOnly(date).subtract(Duration(days: date.weekday - 1));
  String _newId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  String _planKey(DailyPlanItem item) =>
      '${dayKey(DateTime.now())}:${item.taskId ?? 'subject_${item.subjectId}'}';

  Future<void> _saveAndNotify() async {
    await _prefs?.setString(_storageKey, jsonEncode(_toJson()));
    notifyListeners();
  }

  void _runNotification(Future<void> task) {
    unawaited(task.catchError((Object _) {}));
  }

  Map<String, dynamic> _toJson() => {
        'onboarded': onboarded,
        'darkMode': darkMode,
        'notificationsEnabled': notificationsEnabled,
        'vibrationEnabled': vibrationEnabled,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'userName': userName,
        'petName': petName,
        'petKind': petKind.name,
        'totalXp': totalXp,
        'coins': coins,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastFocusDate': lastFocusDate,
        'activeSession': activeSession?.toJson(),
        'sessions': sessions.map((session) => session.toJson()).toList(),
        'subjects': subjects.map((subject) => subject.toJson()).toList(),
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'exams': exams.map((exam) => exam.toJson()).toList(),
        'mistakes': mistakes.map((mistake) => mistake.toJson()).toList(),
        'purchasedItems': purchasedItems.toList(),
        'equipped': {
          for (final entry in equipped.entries) entry.key.name: entry.value,
        },
        'claimedQuestKeys': claimedQuestKeys.toList(),
        'claimedWeeklyGoalKeys': claimedWeeklyGoalKeys.toList(),
        'skippedPlanKeys': skippedPlanKeys.toList(),
      };

  void _readJson(Map<String, dynamic> json) {
    onboarded = (json['onboarded'] as bool?) ?? false;
    darkMode = (json['darkMode'] as bool?) ?? false;
    notificationsEnabled = (json['notificationsEnabled'] as bool?) ?? false;
    vibrationEnabled = (json['vibrationEnabled'] as bool?) ?? true;
    reminderHour = (json['reminderHour'] as int?) ?? 18;
    reminderMinute = (json['reminderMinute'] as int?) ?? 0;
    userName = (json['userName'] as String?) ?? 'Marci';
    petName = (json['petName'] as String?) ?? 'Lumi';
    petKind = PetKind.values.byName((json['petKind'] as String?) ?? 'robot');
    totalXp = (json['totalXp'] as int?) ?? 0;
    coins = (json['coins'] as int?) ?? 25;
    currentStreak = (json['currentStreak'] as int?) ?? 0;
    longestStreak = (json['longestStreak'] as int?) ?? 0;
    lastFocusDate = json['lastFocusDate'] as String?;
    final active = json['activeSession'];
    activeSession =
        active is Map<String, dynamic> ? ActiveSession.fromJson(active) : null;
    sessions
      ..clear()
      ..addAll(((json['sessions'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(FocusSession.fromJson));
    subjects
      ..clear()
      ..addAll(((json['subjects'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Subject.fromJson));
    tasks
      ..clear()
      ..addAll(((json['tasks'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(StudyTask.fromJson));
    exams
      ..clear()
      ..addAll(((json['exams'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Exam.fromJson));
    mistakes
      ..clear()
      ..addAll(((json['mistakes'] as List<dynamic>?) ?? const [])
          .cast<Map<String, dynamic>>()
          .map(Mistake.fromJson));
    purchasedItems
      ..clear()
      ..addAll(
          ((json['purchasedItems'] as List<dynamic>?) ?? const ['starter_desk'])
              .cast<String>());
    final savedEquipped = json['equipped'] as Map<String, dynamic>?;
    if (savedEquipped != null) {
      for (final category in ItemCategory.values) {
        equipped[category] = savedEquipped[category.name] as String?;
      }
    }
    claimedQuestKeys
      ..clear()
      ..addAll(((json['claimedQuestKeys'] as List<dynamic>?) ?? const [])
          .cast<String>());
    claimedWeeklyGoalKeys
      ..clear()
      ..addAll(((json['claimedWeeklyGoalKeys'] as List<dynamic>?) ?? const [])
          .cast<String>());
    skippedPlanKeys
      ..clear()
      ..addAll(((json['skippedPlanKeys'] as List<dynamic>?) ?? const [])
          .cast<String>());
  }

  void _seedSubjectsIfNeeded() {
    if (subjects.isNotEmpty) return;
    final now = DateTime.now();
    // iconCodePoint values: 0xe80c=calculate, 0xe865=language, 0xe86f=code,
    // 0xe80f=science. Any other value renders as book_outlined (default).
    const values = [
      ('math', 'Math', 0xFF4E68D8, 0xe80c, 120),
      ('english', 'English', 0xFF47C3A4, 0xe865, 90),
      ('programming', 'Programming', 0xFFFF8068, 0xe86f, 150),
      ('physics', 'Physics', 0xFFFFC24C, 0xe80f, 90),
      ('history', 'History', 0xFF8896A8, 0x0001, 60),
    ];
    for (final value in values) {
      subjects.add(Subject(
        id: value.$1,
        name: value.$2,
        colorValue: value.$3,
        iconCodePoint: value.$4,
        weeklyGoalMinutes: value.$5,
        createdAt: now,
        updatedAt: now,
      ));
    }
  }

  void _linkLegacySessions() {
    // Legacy sessions remain readable by text subject; new entries use IDs.
  }
}
