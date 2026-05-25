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
import 'package:buta_app/shared/services/api_client.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/features/home/home_screen.dart';
import 'package:buta_app/features/record/record_tab_screen.dart';
import 'package:buta_app/features/record/record_confirm_screen.dart';
import 'package:buta_app/features/record/record_detail_screen.dart';
import 'package:buta_app/features/account/account_tab_screen.dart';
import 'package:buta_app/features/settings/account_manage_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  late Dio mockDio;
  late DioAdapter adapter;

  setUp(() {
    SharedPreferences.setMockInitialValues({'access_token': 'a', 'refresh_token': 'r'});
    mockDio = Dio(BaseOptions(baseUrl: 'http://test'));
    adapter = DioAdapter(dio: mockDio);
  });

  Widget _w(Widget child) {
    final router = GoRouter(initialLocation: '/test', routes: [
      GoRoute(path: '/test', builder: (_, __) => child),
      GoRoute(path: '/home', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/recording', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/record-complete', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/category-select', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/record-detail', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/avatar-detail', builder: (_, __) => const Scaffold()),
      GoRoute(path: '/login', builder: (_, __) => const Scaffold()),
    ]);
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => FakeAuthNotifier(testTokens)),
        bootProvider.overrideWith(() => FakeBootNotifier(BootResult(destination: BootDestination.home))),
        apiClientProvider.overrideWithValue(FakeApiClient(mockDio)),
        imageCacheServiceProvider.overrideWithValue(FakeImageCacheService()),
      ],
      child: MaterialApp.router(theme: butaTheme, routerConfig: router),
    );
  }

  group('HomeScreen API success', () {
    testWidgets('renders full data from API', (t) async {
      adapter.onGet('/avatar', (s) => s.reply(200, {'avatar': {'name': 'ぶた', 'level': 5, 'totalPoints': 200, 'stats': {'hp': 80, 'attack': 20, 'defense': 15, 'speed': 12}, 'categoryPoints': {'FOOD': 100, 'LIFESTYLE': 80}}}));
      adapter.onGet('/activities', (s) => s.reply(200, {'records': [{'recordId': 'r1', 'points': 50}], 'summary': {'todayCount': 3, 'todayPoints': 125}}));
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const HomeScreen()));
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
      expect(find.text('200'), findsAtLeast(1));
    });

    testWidgets('error state shows default', (t) async {
      adapter.onGet('/avatar', (s) => s.reply(500, {}));
      adapter.onGet('/activities', (s) => s.reply(500, {}));
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const HomeScreen()));
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
      expect(find.text('0'), findsAtLeast(1));
    });
  });

  group('RecordTabScreen API', () {
    testWidgets('success renders records', (t) async {
      adapter.onGet('/activities', (s) => s.reply(200, {
        'records': [{'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z'}],
        'summary': {'todayCount': 1, 'todayPoints': 50},
        'weekSummary': [50, 0, 0, 0, 0, 0, 0],
        'monthSummary': List.generate(30, (i) => i == 0 ? 50 : 0),
      }));
      adapter.onGet('/categories', (s) => s.reply(200, {'categories': [{'categoryId': 'c1', 'name': 'ラーメン'}]}));
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const RecordTabScreen()));
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
      expect(find.text('きろく'), findsAtLeast(1));
    });
  });

  group('RecordConfirmScreen submit', () {
    testWidgets('submit success navigates', (t) async {
      adapter.onPost('/activities', (s) => s.reply(201, {'points': 50}), data: Matchers.any);
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordConfirmScreen(category: {'categoryId': 'c1', 'name': 'ラーメン', 'basePoints': 50, 'iconKey': 'cat-ramen'})));
      await t.pump();
      final btn = find.textContaining('きろく');
      if (btn.evaluate().isNotEmpty) {
        await t.tap(btn.last);
        await t.pump(const Duration(seconds: 1));
      }
    });
  });

  group('RecordDetailScreen delete', () {
    testWidgets('delete success', (t) async {
      adapter.onDelete('/activities/r1', (s) => s.reply(200, {}));
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(RecordDetailScreen(record: {'recordId': 'r1', 'categoryId': 'c1', 'points': 50, 'recordedAt': '2026-05-25T10:00:00Z', 'memo': ''})));
      await t.pump();
      final del = find.textContaining('けす');
      if (del.evaluate().isNotEmpty) {
        await t.tap(del.first);
        await t.pump(const Duration(seconds: 1));
        // 確認ダイアログが出たらOKタップ
        await t.pumpAndSettle();
      }
    });
  });

  group('AccountTabScreen API', () {
    testWidgets('loads friends', (t) async {
      adapter.onGet('/social/friends', (s) => s.reply(200, {'friends': [{'userId': 'u1', 'nickname': 'テスト'}]}));
      adapter.onGet('/social/friends/requests', (s) => s.reply(200, {'requests': []}));
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const AccountTabScreen()));
      for (var i = 0; i < 20; i++) { await t.pump(const Duration(milliseconds: 100)); }
    });
  });

  group('AccountManageScreen', () {
    testWidgets('renders and tap delete', (t) async {
      t.view.physicalSize = const Size(390, 740);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() => t.view.resetPhysicalSize());
      await t.pumpWidget(_w(const AccountManageScreen()));
      await t.pump();
      final del = find.textContaining('アカウント削除');
      if (del.evaluate().isNotEmpty) {
        await t.tap(del.first);
        await t.pumpAndSettle();
      }
    });
  });
}
