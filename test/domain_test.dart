import 'package:flutter_test/flutter_test.dart';
import 'package:focuspet/domain/models.dart';

void main() {
  group('reward calculation', () {
    test('uses preset normal rewards', () {
      final reward = calculateReward(25, FocusMode.normal);
      expect(reward.xp, 30);
      expect(reward.coins, 15);
    });

    test('applies deep focus bonus', () {
      final reward = calculateReward(60, FocusMode.deep);
      expect(reward.xp, 113);
      expect(reward.coins, 56);
    });
  });

  test('paused active session retains remaining duration', () {
    final session = ActiveSession(
      durationMinutes: 25,
      subject: 'Programming',
      mode: FocusMode.normal,
      endsAt: null,
      remainingWhenPaused: 300,
      pauseCount: 1,
    );
    expect(session.isPaused, isTrue);
    expect(session.remainingSeconds(), 300);
  });
}
