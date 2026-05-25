import 'package:flutter_test/flutter_test.dart';
import 'package:buta_app/features/splash/splash_screen.dart';

void main() {
  group('SplashScreen', () {
    test('クラスが存在する', () {
      expect(const SplashScreen(), isA<SplashScreen>());
    });
  });
}
