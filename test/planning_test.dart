import 'package:flutter_test/flutter_test.dart';
import 'package:focuspet/domain/models.dart';
import 'package:focuspet/state/app_controller.dart';

Subject _mathSubject({int weeklyGoalMinutes = 120}) {
  final now = DateTime.now();
  return Subject(
    id: 'math',
    name: 'Math',
    colorValue: 0xFF4E68D8,
    iconCodePoint: 0xe80c,
    weeklyGoalMinutes: weeklyGoalMinutes,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('exam topics generate tasks without filling the daily plan', () async {
    final controller = AppController()..subjects.add(_mathSubject());
    await controller.addExam(
      subjectId: 'math',
      title: 'Algebra test',
      examDate: DateTime.now().add(const Duration(days: 2)),
      topics: ['quadratic equations', 'factoring'],
      importance: ExamImportance.critical,
    );

    await controller.generateTasksForExam(controller.exams.single);

    expect(controller.tasks.length, 3);
    expect(controller.tasks.map((task) => task.title),
        contains('Review quadratic equations'));
    expect(controller.dailyPlan, isEmpty);

    await controller.planTaskForToday(controller.tasks.first);
    expect(controller.dailyPlan.single.taskId, controller.tasks.first.id);
  });

  test('deleting an exam removes its generated study plan', () async {
    final controller = AppController()..subjects.add(_mathSubject());
    await controller.addExam(
      subjectId: 'math',
      title: 'Algebra test',
      examDate: DateTime.now().add(const Duration(days: 2)),
      topics: ['factoring'],
      importance: ExamImportance.important,
    );
    final exam = controller.exams.single;
    await controller.generateTasksForExam(exam);

    final deleted = await controller.deleteExam(exam);

    expect(deleted, isTrue);
    expect(controller.exams, isEmpty);
    expect(controller.tasks, isEmpty);
  });

  test('completed task session stores outcome and grants quality rewards',
      () async {
    final controller = AppController()
      ..subjects.add(_mathSubject(weeklyGoalMinutes: 25));
    await controller.addTask(
      subjectId: 'math',
      title: 'Solve equations',
      estimatedMinutes: 25,
      priority: TaskPriority.high,
      plannedDate: DateTime.now(),
    );
    final task = controller.tasks.single;
    await controller.startSession(
      minutes: 25,
      subjectId: 'math',
      taskId: task.id,
      mode: FocusMode.normal,
    );
    controller.activeSession!.endsAt =
        DateTime.now().subtract(const Duration(seconds: 1));

    final session = await controller.claimCompletedSession(
      markTaskDone: true,
      exercisesSolved: 8,
      correctAnswers: 6,
      confidenceLevel: 4,
      note: 'Review factoring again.',
    );

    expect(task.status, TaskStatus.done);
    expect(session!.taskId, task.id);
    expect(session.exercisesSolved, 8);
    expect(session.confidenceLevel, 4);
    expect(controller.totalXp, 100);
    expect(controller.coins, 65);
    expect(controller.dailyPlan, isEmpty);
  });

  test('manually planned study block is prioritized in today plan', () async {
    final controller = AppController()..subjects.add(_mathSubject());
    await controller.addTask(
      subjectId: 'math',
      title: 'Practice derivatives',
      estimatedMinutes: 60,
      priority: TaskPriority.medium,
      plannedDate: DateTime.now(),
    );

    final item = controller.dailyPlan.first;

    expect(controller.taskById(item.taskId)!.title, 'Practice derivatives');
    expect(item.recommendedMinutes, 60);
    expect(item.reason, 'Added to today\'s plan');
  });

  test('starting another session cannot replace an active timer', () async {
    final controller = AppController()..subjects.add(_mathSubject());
    final started = await controller.startSession(
      minutes: 25,
      subjectId: 'math',
      mode: FocusMode.normal,
    );
    final original = controller.activeSession;

    final secondStart = await controller.startSession(
      minutes: 60,
      subjectId: 'math',
      mode: FocusMode.deep,
    );

    expect(started, isTrue);
    expect(secondStart, isFalse);
    expect(controller.activeSession, same(original));
    expect(controller.activeSession!.durationMinutes, 25);
  });

  test('only manually planned tasks appear and can be skipped for today',
      () async {
    final controller = AppController()..subjects.add(_mathSubject());
    await controller.addTask(
      subjectId: 'math',
      title: 'Read chapter',
      estimatedMinutes: 25,
      priority: TaskPriority.medium,
    );
    expect(controller.dailyPlan, isEmpty);

    await controller.addTask(
      subjectId: 'math',
      title: 'Revise equations',
      estimatedMinutes: 25,
      priority: TaskPriority.medium,
      plannedDate: DateTime.now(),
    );
    final recommendation = controller.dailyPlan.first;

    await controller.skipPlanItem(recommendation);

    expect(
        controller.dailyPlan
            .any((item) => item.taskId == recommendation.taskId),
        isFalse);
  });

  test('logging and reviewing a mistake rewards learning from errors',
      () async {
    final controller = AppController()..subjects.add(_mathSubject());

    await controller.addMistake(
      subjectId: 'math',
      title: 'Sign error',
      description: 'Changed the sign incorrectly.',
      mistakeType: 'Calculation error',
      correction: 'Distribute the negative sign first.',
    );
    await controller.reviewMistake(controller.mistakes.single);

    expect(controller.unresolvedMistakeCount, 0);
    expect(controller.totalXp, 15);
    expect(controller.mistakes.single.reviewedAt, isNotNull);
  });
}
