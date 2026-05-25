import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio authDio, avatarDio, recordingDio, socialDio;
  late DioAdapter authA, avatarA, recordingA, socialA;

  setUp(() {
    authDio = Dio(BaseOptions(baseUrl: 'http://t'));
    avatarDio = Dio(BaseOptions(baseUrl: 'http://t'));
    recordingDio = Dio(BaseOptions(baseUrl: 'http://t'));
    socialDio = Dio(BaseOptions(baseUrl: 'http://t'));
    authA = DioAdapter(dio: authDio);
    avatarA = DioAdapter(dio: avatarDio);
    recordingA = DioAdapter(dio: recordingDio);
    socialA = DioAdapter(dio: socialDio);
  });

  ProviderContainer ct({Map<String, Object> prefs = const {}, bool online = true, bool hasToken = false}) {
    SharedPreferences.setMockInitialValues(prefs);
    return ProviderContainer(overrides: [
      bootAuthDioProvider.overrideWithValue(authDio),
      bootAvatarDioProvider.overrideWithValue(avatarDio),
      bootRecordingDioProvider.overrideWithValue(recordingDio),
      bootSocialDioProvider.overrideWithValue(socialDio),
      authDioProvider.overrideWithValue(authDio),
      avatarDioProvider.overrideWithValue(avatarDio),
      connectivityCheckProvider.overrideWithValue(() async => online ? [ConnectivityResult.wifi] : [ConnectivityResult.none]),
      imageCacheServiceProvider.overrideWithValue(FakeImageCacheService()),
      if (hasToken) authStateProvider.overrideWith(() => _TokenAuth()),
    ]);
  }

  group('トークンなし', () {
    test('→login', () async {
      final c = ct(); addTearDown(c.dispose);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.login);
    });
  });

  group('オフライン', () {
    test('キャッシュなし→home(offline)', () async {
      final c = ct(online: false, hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.home);
      expect(r.isOffline, true);
    });

    test('キャッシュあり→home(offline)+profile', () async {
      final c = ct(prefs: {
        'cache_profile': '{"userId":"u1","nickname":"n","email":"e","authProvider":"EMAIL","createdAt":"c"}',
      }, online: false, hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.home);
      expect(r.isOffline, true);
      expect(r.profile!.nickname, 'n');
    });
  });

  group('オンライン', () {
    test('プロフィール404→nickname', () async {
      authA.onGet('/users/me', (s) => s.reply(404, {}));
      final c = ct(hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.nickname);
    });

    test('ニックネーム未設定→nickname', () async {
      authA.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1', 'email': 'e', 'authProvider': 'EMAIL', 'createdAt': 'c'}));
      final c = ct(hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.nickname);
    });

    test('正常→home', () async {
      authA.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1', 'nickname': 'n', 'email': 'e', 'authProvider': 'EMAIL', 'createdAt': 'c'}));
      avatarA.onGet('/avatar', (s) => s.reply(200, {'avatar': {'avatarId': 'a1', 'userId': 'u1', 'name': 'p', 'totalPoints': 100, 'level': 5, 'evolutionStage': 2, 'stats': {'hp': 80, 'attack': 20, 'defense': 15, 'speed': 12}, 'skillIds': [], 'spriteSheetKey': 'sp'}}));
      recordingA.onGet('/activities/summary', (s) => s.reply(200, {'todayCount': 3, 'todayPoints': 45, 'date': '2026-05-25'}));
      socialA.onGet('/social/friends/requests', (s) => s.reply(200, {'requests': [{'id': '1'}]}));
      recordingA.onPost('/health-sync', (s) => s.reply(200, {}), data: Matchers.any);
      final c = ct(hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.home);
      expect(r.profile!.nickname, 'n');
      expect(r.avatar!.level, 5);
      expect(r.summary!.todayCount, 3);
      expect(r.pendingRequestCount, 1);
    });

    test('401+リフレッシュ失敗→login', () async {
      authA.onGet('/users/me', (s) => s.reply(401, {}));
      authA.onPost('/auth/refresh', (s) => s.reply(401, {}), data: Matchers.any);
      final c = ct(hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.login);
    });

    test('アバター404→自動作成', () async {
      authA.onGet('/users/me', (s) => s.reply(200, {'userId': 'u1', 'nickname': 'n', 'email': 'e', 'authProvider': 'EMAIL', 'createdAt': 'c'}));
      avatarA.onGet('/avatar', (s) => s.reply(404, {}));
      avatarA.onPost('/avatar', (s) => s.reply(201, {'avatar': {'avatarId': 'a1', 'userId': 'u1', 'name': 'new', 'totalPoints': 0, 'level': 1, 'evolutionStage': 1, 'stats': {'hp': 50, 'attack': 10, 'defense': 10, 'speed': 10}, 'skillIds': [], 'spriteSheetKey': 'sp'}}), data: Matchers.any);
      recordingA.onGet('/activities/summary', (s) => s.reply(500, {}));
      socialA.onGet('/social/friends/requests', (s) => s.reply(500, {}));
      recordingA.onPost('/health-sync', (s) => s.reply(200, {}), data: Matchers.any);
      final c = ct(hasToken: true); addTearDown(c.dispose);
      await c.read(authStateProvider.future);
      c.invalidate(bootProvider);
      final r = await c.read(bootProvider.future);
      expect(r.destination, BootDestination.home);
      expect(r.avatar!.name, 'new');
    });
  });

  group('retry', () {
    test('再実行', () async {
      final c = ct(); addTearDown(c.dispose);
      await c.read(bootProvider.future);
      await c.read(bootProvider.notifier).retry();
      expect(c.read(bootProvider).value!.destination, BootDestination.login);
    });
  });
}

class _TokenAuth extends AuthStateNotifier {
  @override Future<AuthTokens?> build() async => AuthTokens(accessToken: 'tok', refreshToken: 'r');
}
