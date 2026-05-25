import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:buta_app/shared/theme.dart';
import 'package:buta_app/shared/state/auth_state.dart';
import 'package:buta_app/shared/state/boot_state.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/settings/settings_screen.dart';

import '../helpers/test_helpers.dart';

final _mockHomeData = {
  'avatar': {'name': 'ぶた', 'level': 3, 'totalPoints': 150, 'stats': {'hp': 60, 'attack': 15, 'defense': 12, 'speed': 11}, 'categoryPoints': {'FOOD': 80, 'LIFESTYLE': 50, 'MIXED': 20}},
  'records': [{'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z'}],
  'summary': {'todayCount': 3, 'todayPoints': 125},
};

final _mockRecords = {
  'records': [
    {'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z', 'memo': 'ラーメン'},
    {'recordId': 'r2', 'categoryId': 'c2', 'points': 35, 'recordedAt': '2026-05-25T11:00:00Z', 'memo': '夜ふかし'},
  ],
  'summary': {'todayCount': 2, 'todayPoints': 85},
  'weekSummary': [50, 35, 0, 0, 0, 0, 0],
  'monthSummary': List.generate(30, (i) => i < 2 ? 40 : 0),
};

Widget _w(Widget child) {
  final router = GoRouter(initialLocation: '/test', routes: [
    GoRoute(path: '/test', builder: (_, __) => child),
    GoRoute(path: '/recording', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/category-select', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/record-confirm', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/record-detail', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/avatar-detail', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/battle-history', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/friend-list', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/profile-edit', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/legal/terms', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/legal/privacy', builder: (_, __) => const Scaffold()),
    GoRoute(path: '/account-manage', builder: (_, __) => const Scaffold()),
  ]);
  return ProviderScope(
    overrides: [
      authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
      bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
    ],
    child: MaterialApp.router(theme: butaTheme, routerConfig: router),
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('HomeScreen with data', () {
    testWidgets('renders with mocked data', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
          homeDataProvider.overrideWith((ref) async => _mockHomeData),
        ],
        child: MaterialApp(theme: butaTheme, home: const HomeScreen()),
      ));
      // データロード完了を待つ
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
      expect(find.text('ぶたそだて'), findsOneWidget);
      expect(find.text('SCORE'), findsOneWidget);
      expect(find.text('150'), findsAtLeast(1)); // totalPoints
    });

    testWidgets('tap avatar area', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      final router = GoRouter(initialLocation: '/home', routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/avatar-detail', builder: (_, __) => const Scaffold()),
        GoRoute(path: '/recording', builder: (_, __) => const Scaffold()),
      ]);
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
          homeDataProvider.overrideWith((ref) async => _mockHomeData),
        ],
        child: MaterialApp.router(theme: butaTheme, routerConfig: router),
      ));
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
    });
  });

  group('RecordTabScreen with data', () {
    testWidgets('renders with mocked records', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
          recordsProvider.overrideWith((ref) async => _mockRecords),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('きろく'), findsAtLeast(1));
    });

    testWidgets('error state renders fallback', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(ProviderScope(
        overrides: [
          authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
          bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
          recordsProvider.overrideWith((ref) async => throw Exception('API error')),
        ],
        child: MaterialApp(theme: butaTheme, home: const RecordTabScreen()),
      ));
      for (var i = 0; i < 10; i++) { await t.pump(const Duration(milliseconds: 100)); }
      expect(find.text('きろく'), findsAtLeast(1));
    });
  });

  group('RecordConfirmScreen interaction', () {
    testWidgets('renders category info', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordConfirmScreen(category: {'categoryId': 'c1', 'name': 'ラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'})));
      await t.pump();
      expect(find.textContaining('ラーメン'), findsAtLeast(1));
    });

    testWidgets('tap submit button', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordConfirmScreen(category: {'categoryId': 'c1', 'name': 'ラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'})));
      await t.pump();
      // きろくする ボタンをタップ
      final btn = find.textContaining('きろく');
      if (btn.evaluate().isNotEmpty) {
        await t.tap(btn.last);
        await t.pump(const Duration(seconds: 1));
      }
    });
  });

  group('RecordDetailScreen', () {
    testWidgets('renders record info', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordDetailScreen(record: {'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z', 'memo': 'テスト'})));
      await t.pump();
      expect(find.byType(Scaffold), findsAtLeast(1));
    });

    testWidgets('tap delete button', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordDetailScreen(record: {'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z', 'memo': 'テスト'})));
      await t.pump();
      final del = find.textContaining('けす');
      if (del.evaluate().isNotEmpty) {
        await t.tap(del.first);
        await t.pumpAndSettle();
      }
    });
  });

  group('AccountTabScreen', () {
    testWidgets('renders', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const AccountTabScreen()));
      await t.pump();
      expect(find.textContaining('フレンド'), findsAtLeast(1));
    });
  });

  group('SettingsScreen', () {
    testWidgets('renders menu items', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const SettingsScreen()));
      await t.pump();
      expect(find.textContaining('ログアウト'), findsAtLeast(1));
    });
  });
}
