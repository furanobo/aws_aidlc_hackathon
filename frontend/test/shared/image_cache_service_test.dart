import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/shared/services/image_cache_service.dart';

void main() {
  late Directory tempDir;
  late ImageCacheService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('img_cache_test_');
    service = ImageCacheService(() async => tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('resolveImageUrl', () {
    expect(service.resolveImageUrl('sprites/s1/d'), contains('sprites/s1/d.png'));
  });

  test('isCached: ファイルなし → false', () async {
    expect(await service.isCached('nonexistent'), false);
  });

  test('isCached: ファイルあり → true', () async {
    final dir = Directory('${tempDir.path}/sprites');
    await dir.create(recursive: true);
    await File('${dir.path}/test_key.png').writeAsBytes([1, 2, 3]);
    expect(await service.isCached('test/key'), true);
  });

  test('getOrDownload: キャッシュ済み → パス返却', () async {
    final dir = Directory('${tempDir.path}/sprites');
    await dir.create(recursive: true);
    final f = File('${dir.path}/cached_key.png');
    await f.writeAsBytes([1, 2, 3]);
    final path = await service.getOrDownload('cached/key');
    expect(path, f.path);
  });

  test('getOrDownload: ダウンロード失敗 → null', () async {
    final path = await service.getOrDownload('invalid/url/key');
    expect(path, isNull);
  });

  test('clearAll: ディレクトリ削除', () async {
    final dir = Directory('${tempDir.path}/sprites');
    await dir.create(recursive: true);
    await File('${dir.path}/x.png').writeAsBytes([1]);
    await service.clearAll();
    expect(await dir.exists(), false);
  });

  test('clearAll: ディレクトリなしでもエラーなし', () async {
    await expectLater(service.clearAll(), completes);
  });
}
