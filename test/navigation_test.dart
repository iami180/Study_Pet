import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focuspet/main.dart';
import 'package:focuspet/domain/models.dart';
import 'package:focuspet/state/app_controller.dart';

void main() {
  testWidgets('active timer route closes when no session exists',
      (tester) async {
    final controller = AppController();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ActiveFocusScreen(controller: controller),
              ),
            ),
            child: const Text('Open timer'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open timer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Open timer'), findsOneWidget);
    expect(find.text('No active session.'), findsNothing);
  });

  testWidgets('cancelling a timer returns to the previous screen',
      (tester) async {
    final controller = AppController()
      ..activeSession = ActiveSession(
        durationMinutes: 25,
        subject: 'Programming',
        mode: FocusMode.deep,
        endsAt: DateTime.now().add(const Duration(minutes: 25)),
      );
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ActiveFocusScreen(controller: controller),
              ),
            ),
            child: const Text('Open timer'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open timer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Cancel session'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(controller.activeSession, isNull);
    expect(find.text('Open timer'), findsOneWidget);
    expect(find.text('No active session.'), findsNothing);
  });
}
