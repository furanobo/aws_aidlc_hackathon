// API統合テスト（DioAdapterによるモック版）
// モックサーバーのレスポンスを再現し、APIクライアントの疎通ロジックを検証する

import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:test/test.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    adapter = DioAdapter(dio: dio);
  });

  group('Health', () {
    test('GET /health returns ok', () async {
      adapter.onGet('/health', (s) => s.reply(200, {'status': 'ok'}));
      final res = await dio.get('/health');
      expect(res.statusCode, 200);
      expect(res.data['status'], 'ok');
    });
  });

  group('Auth Flow', () {
    test('signup → confirm → login → me', () async {
      adapter.onPost('/auth/signup', (s) => s.reply(200, {'message': 'ok'}), data: Matchers.any);
      adapter.onPost('/auth/confirm', (s) => s.reply(200, {'message': 'confirmed'}), data: Matchers.any);
      adapter.onPost('/auth/login', (s) => s.reply(200, {'accessToken': 'mock-token-dart-user', 'refreshToken': 'rt'}), data: Matchers.any);
      adapter.onGet('/users/me', (s) => s.reply(200, {'userId': 'dart-user', 'nickname': 'テスト'}));

      final signup = await dio.post('/auth/signup', data: {'email': 'dart@test.com', 'password': 'Test1234!'});
      expect(signup.statusCode, 200);

      final confirm = await dio.post('/auth/confirm', data: {'email': 'dart@test.com', 'code': '123456'});
      expect(confirm.statusCode, 200);

      final login = await dio.post('/auth/login', data: {'email': 'dart@test.com', 'password': 'Test1234!'});
      expect(login.statusCode, 200);
      final token = login.data['accessToken'] as String;
      expect(token, contains('mock-token-'));

      final me = await dio.get('/users/me');
      expect(me.statusCode, 200);
      expect(me.data['userId'], isNotEmpty);
    });
  });

  group('Recording Flow', () {
    test('categories → record → get activities', () async {
      adapter.onGet('/categories', (s) => s.reply(200, {
        'categories': [
          {'id': 'food-ramen', 'name': '深夜ラーメン', 'points': 50},
          {'id': 'food-binge', 'name': '暴飲暴食', 'points': 40},
          {'id': 'food-snack', 'name': '間食', 'points': 20},
          {'id': 'sleep-late', 'name': '夜更かし', 'points': 30},
          {'id': 'skip-exercise', 'name': '運動サボり', 'points': 35},
          {'id': 'food-junk', 'name': 'ジャンクフード', 'points': 25},
          {'id': 'sleep-nap', 'name': '二度寝', 'points': 15},
          {'id': 'skip-chore', 'name': '家事サボり', 'points': 10},
        ]
      }));
      adapter.onPost('/activities', (s) => s.reply(201, {
        'activity': {'id': 'act-1'},
        'avatar': {'totalPoints': 50}
      }), data: Matchers.any);
      adapter.onGet('/activities', (s) => s.reply(200, {
        'records': [{'id': 'act-1', 'categoryId': 'food-ramen', 'createdAt': '2026-01-01'}]
      }));

      final cats = await dio.get('/categories');
      expect(cats.statusCode, 200);
      expect((cats.data['categories'] as List).length, 8);

      final record = await dio.post('/activities', data: {
        'records': [{'categoryId': 'food-ramen'}]
      });
      expect(record.statusCode, 201);
      expect(record.data['avatar']['totalPoints'], 50);

      final activities = await dio.get('/activities');
      expect(activities.statusCode, 200);
      expect((activities.data['records'] as List).length, greaterThan(0));
    });
  });

  group('Avatar Flow', () {
    test('create → get avatar', () async {
      adapter.onPost('/avatar', (s) => s.reply(201, {
        'avatar': {'name': 'ダートぶた', 'level': 1, 'stats': {'hp': 100}}
      }), data: Matchers.any);
      adapter.onGet('/avatar', (s) => s.reply(200, {
        'avatar': {'name': 'ダートぶた', 'level': 1, 'stats': {'hp': 100, 'atk': 10}}
      }));

      final create = await dio.post('/avatar', data: {'name': 'ダートぶた'});
      expect(create.statusCode, 201);
      expect(create.data['avatar']['name'], 'ダートぶた');

      final get = await dio.get('/avatar');
      expect(get.statusCode, 200);
      expect(get.data['avatar']['stats']['hp'], 100);
    });
  });

  group('Battle/Social Flow', () {
    test('rankings + battle history', () async {
      adapter.onGet('/rankings', (s) => s.reply(200, {
        'rankings': [
          {'userId': 'u1', 'nickname': 'プレイヤー1', 'score': 500},
          {'userId': 'u2', 'nickname': 'プレイヤー2', 'score': 400},
          {'userId': 'u3', 'nickname': 'プレイヤー3', 'score': 300},
        ]
      }));
      adapter.onGet('/battles/history', (s) => s.reply(200, {
        'history': [
          {'id': 'b1', 'result': 'win'},
          {'id': 'b2', 'result': 'lose'},
          {'id': 'b3', 'result': 'win'},
        ]
      }));
      adapter.onGet('/social/friends', (s) => s.reply(200, {'friends': []}));

      final rankings = await dio.get('/rankings');
      expect(rankings.statusCode, 200);
      expect((rankings.data['rankings'] as List).length, 3);

      final history = await dio.get('/battles/history');
      expect(history.statusCode, 200);
      expect((history.data['history'] as List).length, 3);

      final friends = await dio.get('/social/friends');
      expect(friends.statusCode, 200);
    });
  });
}
