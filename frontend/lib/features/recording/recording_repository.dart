import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:buta_app/shared/api_client.dart';
import 'package:buta_app/features/recording/models.dart';

final recordingRepositoryProvider = Provider<RecordingRepository>((ref) {
  return RecordingRepository(ref.read(apiClientProvider));
});

class RecordingRepository {
  final ApiClient _api;
  static const _maxOfflineCache = 50;

  RecordingRepository(this._api);

  Future<List<ActivityCategory>> getCategories() async {
    if (ApiClient.mockMode) {
      return [
        ActivityCategory(categoryId: 'food_late_ramen', name: '深夜ラーメン', type: CategoryType.food, basePoints: 12, iconKey: 'ramen', sortOrder: 1),
        ActivityCategory(categoryId: 'food_binge', name: '暴飲暴食', type: CategoryType.food, basePoints: 12, iconKey: 'binge', sortOrder: 2),
        ActivityCategory(categoryId: 'food_snack', name: '間食', type: CategoryType.food, basePoints: 12, iconKey: 'snack', sortOrder: 3),
        ActivityCategory(categoryId: 'food_junkfood', name: 'ジャンクフード', type: CategoryType.food, basePoints: 12, iconKey: 'junk', sortOrder: 4),
        ActivityCategory(categoryId: 'life_stay_up', name: '夜更かし', type: CategoryType.lifestyle, basePoints: 10, iconKey: 'night', sortOrder: 5),
        ActivityCategory(categoryId: 'life_oversleep', name: '二度寝', type: CategoryType.lifestyle, basePoints: 10, iconKey: 'sleep', sortOrder: 6),
        ActivityCategory(categoryId: 'life_skip_exercise', name: '運動サボり', type: CategoryType.lifestyle, basePoints: 10, iconKey: 'couch', sortOrder: 7),
        ActivityCategory(categoryId: 'life_binge_watch', name: 'だらだら動画視聴', type: CategoryType.lifestyle, basePoints: 10, iconKey: 'tv', sortOrder: 8),
      ];
    }
    final response = await _api.get('/categories');
    final list = response.data['categories'] as List;
    return list.map((e) => ActivityCategory.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> createRecord({
    required String categoryId,
    String? memo,
    String? recordedAt,
  }) async {
    if (ApiClient.mockMode) {
      return {'offline': false, 'recordId': const Uuid().v4(), 'mock': true};
    }
    final connectivity = await Connectivity().checkConnectivity();
    final recordId = const Uuid().v4();
    final now = recordedAt ?? DateTime.now().toIso8601String();

    if (connectivity.contains(ConnectivityResult.none)) {
      // Offline: save to Hive
      final box = await Hive.openBox('pending_records');
      if (box.length >= _maxOfflineCache) {
        await box.deleteAt(0); // FIFO
      }
      await box.put(recordId, {
        'recordId': recordId,
        'categoryId': categoryId,
        'memo': memo,
        'recordedAt': now,
        'syncStatus': 'PENDING',
      });
      return {'offline': true, 'recordId': recordId};
    }

    final response = await _api.post('/activities', data: {
      'categoryId': categoryId,
      'memo': memo,
      'recordedAt': now,
      'recordId': recordId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> syncPendingRecords() async {
    final box = await Hive.openBox('pending_records');
    if (box.isEmpty) return {'synced': 0};

    final records = box.values.map((e) => e as Map).toList();
    final payload = records.map((r) => {
      'recordId': r['recordId'],
      'categoryId': r['categoryId'],
      'memo': r['memo'],
      'recordedAt': r['recordedAt'],
    }).toList();
    final response = await _api.post('/activities/batch', data: {
      'records': payload,
    });

    await box.clear();
    return response.data;
  }

  Future<Map<String, dynamic>> getRecords({
    int limit = 20,
    String? cursor,
    String? categoryId,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    if (categoryId != null) params['categoryId'] = categoryId;
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;

    final query = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final response = await _api.get('/activities?$query');
    return response.data;
  }

  Future<void> deleteRecord(String recordId) async {
    await _api.post('/activities/$recordId'); // DELETE via api_client extension needed
  }

  Future<Map<String, dynamic>> getSummary({String period = 'today'}) async {
    final response = await _api.get('/activities/summary?period=$period');
    return response.data;
  }
}
