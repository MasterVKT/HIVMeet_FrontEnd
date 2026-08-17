import 'package:flutter_test/flutter_test.dart';
import 'package:hivmeet/domain/entities/interaction_history.dart';

void main() {
  group('InteractionStats', () {
    test('matchRate uses likes + super likes as denominator', () {
      const stats = InteractionStats(
        totalLikes: 10,
        totalSuperLikes: 5,
        totalDislikes: 7,
        totalMatches: 3,
        likeToMatchRatio: 0.0,
        totalInteractionsToday: 2,
        dailyLimit: 50,
        remainingToday: 48,
      );

      expect(stats.totalAllLikes, 15);
      expect(stats.matchRate, closeTo(20.0, 0.001));
    });

    test('weekInteractions stays null when backend does not provide it', () {
      const stats = InteractionStats(
        totalLikes: 1,
        totalSuperLikes: 0,
        totalDislikes: 1,
        totalMatches: 0,
        likeToMatchRatio: 0.0,
        totalInteractionsToday: 1,
        totalInteractionsWeek: null,
        dailyLimit: 50,
        remainingToday: 49,
      );

      expect(stats.weekInteractions, isNull);
    });
  });
}
