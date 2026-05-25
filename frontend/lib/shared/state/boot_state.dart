import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:buta_app/shared/constants.dart';
import 'package:buta_app/shared/models/models.dart';
import 'package:buta_app/shared/services/cache_service.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';
import 'package:buta_app/shared/state/auth_state.dart';

enum AppBootStatus { checking, loadingData, done, error }

enum BootDestination { login, nickname, home }

/// DI: Connectivity check
final connectivityCheckProvider = Provider<Future<List<ConnectivityResult>> Function()>((ref) {
  return () => Connectivity().checkConnectivity();
});

/// DI: Boot用Dioプロバイダー
final bootAuthDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConstants.authApiBase)));
final bootAvatarDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConstants.avatarApiBase)));
final bootRecordingDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConstants.recordingApiBase)));
final bootSocialDioProvider = Provider<Dio>((ref) => Dio(BaseOptions(baseUrl: AppConstants.socialApiBase)));

class BootResult {
  final BootDestination destination;
  final UserProfile? profile;
  final Avatar? avatar;
  final RecordSummary? summary;
  final int pendingRequestCount;
  final bool isOffline;
  final String? avatarImagePath;
  final String? errorMessage;

  BootResult({
    required this.destination,
    this.profile,
    this.avatar,
    this.summary,
    this.pendingRequestCount = 0,
    this.isOffline = false,
    this.avatarImagePath,
    this.errorMessage,
  });
}

class BootNotifier extends AsyncNotifier<BootResult> {
  @override
  Future<BootResult> build() => _executeBoot();

  Future<BootResult> _executeBoot() async {
    final startTime = DateTime.now();

    final authState = ref.read(authStateProvider);
    final tokens = authState.value;
    if (tokens == null) {
      await _waitMinDuration(startTime);
      return BootResult(destination: BootDestination.login);
    }

    final connectivity = await ref.read(connectivityCheckProvider)();
    final isOffline = connectivity.contains(ConnectivityResult.none);
    if (isOffline) return _handleOffline(startTime);

    try {
      final profile = await _fetchProfile(tokens.accessToken);
      if (profile == null || !profile.hasNickname) {
        await _waitMinDuration(startTime);
        return BootResult(destination: BootDestination.nickname, profile: profile);
      }
      final results = await _fetchInitialData(tokens.accessToken, profile);
      await _waitMinDuration(startTime);
      return results;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final refreshed = await ref.read(authStateProvider.notifier).refreshToken();
        if (!refreshed) {
          await _waitMinDuration(startTime);
          return BootResult(destination: BootDestination.login);
        }
        return _executeBoot();
      }
      return _handleOffline(startTime);
    } catch (_) {
      return _handleOffline(startTime);
    }
  }

  Future<UserProfile?> _fetchProfile(String accessToken) async {
    final dio = ref.read(bootAuthDioProvider);
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
    try {
      final res = await dio.get('/users/me');
      return UserProfile.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<BootResult> _fetchInitialData(String accessToken, UserProfile profile) async {
    final cache = ref.read(cacheServiceProvider);
    final imageCache = ref.read(imageCacheServiceProvider);
    final avatarDio = ref.read(bootAvatarDioProvider);
    final recordingDio = ref.read(bootRecordingDioProvider);
    final socialDio = ref.read(bootSocialDioProvider);
    avatarDio.options.headers['Authorization'] = 'Bearer $accessToken';
    recordingDio.options.headers['Authorization'] = 'Bearer $accessToken';
    socialDio.options.headers['Authorization'] = 'Bearer $accessToken';

    final results = await Future.wait([
      _fetchAvatar(avatarDio),
      _fetchSummary(recordingDio),
      _fetchPendingCount(socialDio),
    ], eagerError: false);

    final avatar = results[0] as Avatar?;
    final summary = results[1] as RecordSummary?;
    final pendingCount = results[2] as int? ?? 0;

    await cache.saveProfile(profile);
    if (avatar != null) await cache.saveAvatar(avatar);
    if (summary != null) await cache.saveSummary(summary);

    String? imagePath;
    if (avatar != null) imagePath = await imageCache.getOrDownload(avatar.spriteSheetKey);
    _syncHealthData(recordingDio);

    return BootResult(destination: BootDestination.home, profile: profile, avatar: avatar, summary: summary, pendingRequestCount: pendingCount, avatarImagePath: imagePath);
  }

  Future<Avatar?> _fetchAvatar(Dio dio) async {
    try {
      final res = await dio.get('/avatar');
      return Avatar.fromJson(res.data['avatar'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          final r = await dio.post('/avatar', data: {'name': 'ぶたさん'});
          return Avatar.fromJson(r.data['avatar'] as Map<String, dynamic>);
        } catch (_) { return null; }
      }
      return null;
    }
  }

  Future<RecordSummary?> _fetchSummary(Dio dio) async {
    try {
      final res = await dio.get('/activities/summary', queryParameters: {'period': 'today'});
      return RecordSummary.fromJson(res.data as Map<String, dynamic>);
    } catch (_) { return null; }
  }

  Future<int> _fetchPendingCount(Dio dio) async {
    try {
      final res = await dio.get('/social/friends/requests');
      return (res.data['requests'] as List<dynamic>? ?? []).length;
    } catch (_) { return 0; }
  }

  void _syncHealthData(Dio dio) { dio.post('/health-sync', data: {'records': []}).ignore(); }

  Future<BootResult> _handleOffline(DateTime startTime) async {
    final cache = ref.read(cacheServiceProvider);
    final profile = await cache.loadProfile();
    final avatar = await cache.loadAvatar();
    final summary = await cache.loadSummary();

    if (profile != null) {
      String? imagePath;
      if (avatar != null) {
        final imageCache = ref.read(imageCacheServiceProvider);
        if (await imageCache.isCached(avatar.spriteSheetKey)) {
          imagePath = await imageCache.getOrDownload(avatar.spriteSheetKey);
        }
      }
      await _waitMinDuration(startTime);
      return BootResult(destination: BootDestination.home, profile: profile, avatar: avatar, summary: summary, isOffline: true, avatarImagePath: imagePath);
    }

    await _waitMinDuration(startTime);
    return BootResult(destination: BootDestination.home, isOffline: true, errorMessage: 'ネットワークに接続できません');
  }

  Future<void> _waitMinDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    if (elapsed < AppConstants.splashMinDuration) {
      await Future.delayed(AppConstants.splashMinDuration - elapsed);
    }
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _executeBoot());
  }
}

final bootProvider = AsyncNotifierProvider<BootNotifier, BootResult>(() => BootNotifier());
