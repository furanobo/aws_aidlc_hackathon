import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/services/cache_service.dart';
import 'package:buta_app/shared/models/models.dart';

void main() {
  late CacheService cache;
  setUp(() { SharedPreferences.setMockInitialValues({}); cache = CacheService(); });

  group('Profile', () {
    test('save→load', () async {
      await cache.saveProfile(UserProfile(userId: 'u1', nickname: 'n', email: 'e', authProvider: 'EMAIL', createdAt: 'c'));
      final p = await cache.loadProfile();
      expect(p!.userId, 'u1');
    });
    test('未保存→null', () async => expect(await cache.loadProfile(), isNull));
  });

  group('Avatar', () {
    test('save→load', () async {
      await cache.saveAvatar(Avatar(avatarId: 'a1', userId: 'u1', name: 'n', totalPoints: 0, level: 1, evolutionStage: 1, stats: AvatarStats(hp: 50, attack: 10, defense: 10, speed: 10), skillIds: [], spriteSheetKey: 'sp'));
      final a = await cache.loadAvatar();
      expect(a!.avatarId, 'a1');
    });
    test('未保存→null', () async => expect(await cache.loadAvatar(), isNull));
  });

  group('Summary', () {
    test('save→load(今日)', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await cache.saveSummary(RecordSummary(todayCount: 3, todayPoints: 45, date: today));
      final s = await cache.loadSummary();
      expect(s!.todayCount, 3);
    });
    test('古い日付→null', () async {
      await cache.saveSummary(RecordSummary(todayCount: 1, todayPoints: 10, date: '2020-01-01'));
      expect(await cache.loadSummary(), isNull);
    });
  });

  group('clearAll', () {
    test('全削除', () async {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await cache.saveProfile(UserProfile(userId: 'u1', nickname: 'n', email: '', authProvider: '', createdAt: ''));
      await cache.saveSummary(RecordSummary(todayCount: 1, todayPoints: 1, date: today));
      await cache.clearAll();
      expect(await cache.loadProfile(), isNull);
      expect(await cache.loadSummary(), isNull);
    });
  });
}
