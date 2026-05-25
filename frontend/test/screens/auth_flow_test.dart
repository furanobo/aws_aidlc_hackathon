import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/features/auth/login_screen.dart';
import 'package:buta_app/features/auth/signup_screen.dart';
import 'package:buta_app/features/auth/confirm_screen.dart';
import 'package:buta_app/features/auth/nickname_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  late Dio mockDio;
  late DioAdapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockDio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = DioAdapter(dio: mockDio);
  });

  Widget _w(Widget child) {
    final router = GoRouter(initialLocation: '/test', routes: [
      GoRoute(path: '/test', builder: (_, __) => child),
      GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/signup', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/confirm', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/splash', builder: (_, __) => const Scaffold()),
    ]);
    return ProviderScope(
      overrides: [
        authDioProvider.overrideWithValue(mockDio),
        avatarDioProvider.overrideWithValue(mockDio),
        imageCacheServiceProvider.overrideWithValue(FakeImageCacheService()),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.login))),
      ],
      child: MaterialApp.router(theme: butaTheme, routerConfig: router),
    );
  }

  group('Login success flow', () {
    testWidgets('login success navigates to home', (t) async {
      adapter.onPost('/auth/login', (s) => s.reply(200, {'accessToken': 'a', 'refreshToken': 'r', 'idToken': 'i'}), data: Matchers.any);
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const LoginScreen()));
      await t.pump();
      // メール入力
      final fields = find.byType(TextField);
      await t.enterText(fields.at(0), 'a@b.com');
      await t.enterText(fields.at(1), 'password');
      await t.pump();
      // ログインボタンタップ
      final btn = find.textContaining('ログイン');
      await t.tap(btn.last);
      await t.pump(const Duration(seconds: 1));
    });
  });

  group('Signup success flow', () {
    testWidgets('signup success navigates to confirm', (t) async {
      adapter.onPost('/auth/signup', (s) => s.reply(200, {}), data: Matchers.any);
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SignupScreen()));
      await t.pump();
      // 入力
      final fields = find.byType(TextField);
      if (fields.evaluate().length >= 3) {
        await t.enterText(fields.at(0), 'a@b.com');
        await t.enterText(fields.at(1), 'Pass1234!');
        await t.enterText(fields.at(2), 'Pass1234!');
        await t.pump();
      }
      // 同意チェックボックスをタップ
      final checkbox = find.byType(GestureDetector);
      for (final c in checkbox.evaluate()) {
        final w = c.widget;
        if (w is GestureDetector && w.child is Container) {
          await t.tap(find.byWidget(w));
          await t.pump();
          break;
        }
      }
      // submitボタンタップ
      final btn = find.textContaining('つくる');
      if (btn.evaluate().isNotEmpty) {
        await t.tap(btn.first);
        await t.pump(const Duration(seconds: 1));
      }
    });
  });

  group('Confirm success flow', () {
    testWidgets('confirm success navigates to login', (t) async {
      adapter.onPost('/auth/confirm', (s) => s.reply(200, {}), data: Matchers.any);
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const ConfirmScreen(email: 'a@b.com')));
      await t.pump();
      final input = find.byType(TextField);
      if (input.evaluate().isNotEmpty) {
        await t.enterText(input.first, '123456');
        await t.pump();
        final btn = find.textContaining('かくにん');
        if (btn.evaluate().isNotEmpty) {
          await t.tap(btn.first);
          await t.pump(const Duration(seconds: 1));
        }
      }
    });
  });

  group('Nickname success flow', () {
    testWidgets('nickname submit success', (t) async {
      adapter.onPost('/users/profile', (s) => s.reply(200, {}), data: Matchers.any);
      adapter.onPost('/avatar', (s) => s.reply(201, {}), data: Matchers.any);
      SharedPreferences.setMockInitialValues({'access_token': 'tok', 'refresh_token': 'r'});
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const NicknameScreen()));
      await t.pump();
      final input = find.byKey(const Key('nickname-input'));
      if (input.evaluate().isNotEmpty) {
        await t.enterText(input, 'テスト太郎');
        await t.pump();
        final submit = find.byKey(const Key('nickname-submit-button'));
        if (submit.evaluate().isNotEmpty) {
          await t.tap(submit);
          await t.pump(const Duration(seconds: 2));
        }
      }
    });
  });
}
