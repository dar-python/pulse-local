import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android release manifest allows internet access', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('manual APK workflow builds against the production Laravel URL', () {
    final workflow = File(
      '../.github/workflows/flutter_build_apk.yml',
    ).readAsStringSync();

    expect(
      workflow,
      contains(
        'flutter build apk --release --dart-define=LARAVEL_BASE_URL=https://foodpulse-zuniega-docil.duckdns.org',
      ),
    );
    expect(
      workflow,
      isNot(contains('--dart-define=LARAVEL_BASE_URL=http://127.0.0.1')),
    );
    expect(
      workflow,
      isNot(contains('--dart-define=LARAVEL_BASE_URL=http://localhost')),
    );
    expect(
      workflow,
      isNot(contains('--dart-define=LARAVEL_BASE_URL=http://10.0.2.2')),
    );
  });

  test('app config has a production-safe non-debug default URL', () {
    final appConfig = File(
      'lib/core/config/app_config.dart',
    ).readAsStringSync();

    expect(appConfig, contains('https://foodpulse-zuniega-docil.duckdns.org'));
    expect(appConfig, contains('kDebugMode'));
  });

  test('dotenv file is not bundled into release assets', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final mainDart = File('lib/main.dart').readAsStringSync();

    expect(pubspec, isNot(contains('- .env')));
    expect(mainDart, contains('isOptional: true'));
  });
}
