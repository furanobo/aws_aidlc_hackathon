import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';

import '../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Dio mockAuthDio, mockAvatarDio;
  late DioAdapter authAdapter, avatarAdapter;

  setUp(() {
    mockAuthDio = Dio(BaseOptions(baseUrl: 'http://test'));
    mockAvatarDio = Dio(BaseOptions(baseUrl: 'http://test'));
    authAdapter = DioAdapter(dio: mockAuthDio);
    avatarAdapter = DioAdapter(dio: mockAvatarDio);
  });

  ProviderContainer c({Map<String, Object> prefs = const {}}) {
    SharedPreferences.setMockInitialValues(prefs);
    return ProviderContainer(overrides: [
      authDioProvider.overrideWithValue(mockAuthDio),
      avatarDioProvider.overrideWithValue(mockAvatarDio),
      imageCacheServiceProvider.overrideWithValue(FakeImageCacheService()),
    ]);
  }

  group('build', () {
    test('トークンなし→null', () async {
      final ct = c(); addTearDown(ct.dispose);
      expect(await ct.read(authStateProvider.future), isNull);
    });
    test('トークンあり→AuthTokens', () async {
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      final r = await ct.read(authStateProvider.future);
      expect(r!.accessToken, 'a');
    });
  });

  group('login', () {
    test('成功→true', () async {
      authAdapter.onPost('/auth/login', (s) => s.reply(200, {'accessToken': 'new', 'refreshToken': 'r', 'idToken': 'i'}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).login('a@b', 'p'), true);
      expect(ct.read(authStateProvider).value!.accessToken, 'new');
    });
    test('401→false', () async {
      authAdapter.onPost('/auth/login', (s) => s.reply(401, {'error': 'bad'}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).login('a@b', 'p'), false);
    });
  });

  group('signup', () {
    test('成功→true', () async {
      authAdapter.onPost('/auth/signup', (s) => s.reply(200, {}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).signup('a@b', 'p'), true);
    });
    test('失敗→false', () async {
      authAdapter.onPost('/auth/signup', (s) => s.reply(409, {}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).signup('a@b', 'p'), false);
    });
  });

  group('confirmSignup', () {
    test('成功→true', () async {
      authAdapter.onPost('/auth/confirm', (s) => s.reply(200, {}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).confirmSignup('a@b', '123456'), true);
    });
    test('失敗→false', () async {
      authAdapter.onPost('/auth/confirm', (s) => s.reply(400, {}), data: Matchers.any);
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).confirmSignup('a@b', '000'), false);
    });
  });

  group('refreshToken', () {
    test('null→false', () async {
      final ct = c(prefs: {'access_token': 'a'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).refreshToken(), false);
    });
    test('成功→true', () async {
      authAdapter.onPost('/auth/refresh', (s) => s.reply(200, {'accessToken': 'new', 'idToken': 'i'}), data: Matchers.any);
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).refreshToken(), true);
      expect(ct.read(authStateProvider).value!.accessToken, 'new');
    });
    test('失敗→false+logout', () async {
      authAdapter.onPost('/auth/refresh', (s) => s.reply(401, {}), data: Matchers.any);
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).refreshToken(), false);
      expect(ct.read(authStateProvider).value, isNull);
    });
  });

  group('logout', () {
    test('state→null', () async {
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      await ct.read(authStateProvider.notifier).logout();
      expect(ct.read(authStateProvider).value, isNull);
    });
  });

  group('createInitialAvatar', () {
    test('トークンなし→false', () async {
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).createInitialAvatar(), false);
    });
    test('成功→true', () async {
      avatarAdapter.onPost('/avatar', (s) => s.reply(201, {}), data: Matchers.any);
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).createInitialAvatar(), true);
    });
    test('409→true', () async {
      avatarAdapter.onPost('/avatar', (s) => s.reply(409, {}), data: Matchers.any);
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(await ct.read(authStateProvider.notifier).createInitialAvatar(), true);
    });
  });

  group('isLoggedInProvider', () {
    test('なし→false', () async {
      final ct = c(); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(ct.read(isLoggedInProvider), false);
    });
    test('あり→true', () async {
      final ct = c(prefs: {'access_token': 'a', 'refresh_token': 'r'}); addTearDown(ct.dispose);
      await ct.read(authStateProvider.future);
      expect(ct.read(isLoggedInProvider), true);
    });
  });
}
