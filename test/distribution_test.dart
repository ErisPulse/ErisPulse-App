import 'package:erispulse_app/services/distribution.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('default instance is official with fallback sources', () {
    final dist = Distribution.instance;
    expect(dist.isOfficial, isTrue);
    expect(dist.hasFirstLaunchContent, isFalse);
    expect(dist.displayTitle, 'ErisPulse-App');
    expect(dist.preinstalled, isEmpty);
  });

  test('parses custom manifest', () {
    final dist = Distribution.fromJsonForTest({
      'distribution': {
        'name': 'My ErisPulse',
        'vendor': 'Example Org',
        'homepage': 'https://example.com',
        'contact': 'mailto:ops@example.com',
      },
      'preinstalled': [
        {
          'name': 'ErisPulse-DashChat',
          'type': 'module',
          'version': '1.2.0',
          'description': 'inbox',
        },
        'invalid-entry-ignored',
      ],
      'notices': {
        'firstLaunch': 'Welcome!\nEnjoy.',
        'createInstance': 'Instance hint',
      },
      'defaults': {
        'downloadSource': 'ghfast',
        'pypiSource': 'custom',
        'pypiIndexUrl': 'https://mirror.example.com/simple',
        'pypiLabel': 'Mirror',
      },
      'download': {'releaseBase': 'https://dl.example.com/erispulse'},
    });

    expect(dist.isOfficial, isFalse);
    expect(dist.name, 'My ErisPulse');
    expect(dist.displayTitle, 'My ErisPulse');
    expect(dist.hasFirstLaunchContent, isTrue);
    expect(dist.preinstalled.single.name, 'ErisPulse-DashChat');
    expect(dist.preinstalled.single.version, '1.2.0');
    expect(dist.firstLaunchNotice, 'Welcome!\nEnjoy.');
    expect(dist.createInstanceNotice, 'Instance hint');
    expect(dist.defaultDownloadSource, 'ghfast');
    expect(dist.customPypiIndexUrl, 'https://mirror.example.com/simple');
    expect(dist.customPypiLabel, 'Mirror');
    expect(dist.releaseBase, 'https://dl.example.com/erispulse');
  });

  test('custom manifest with empty content still counts as official', () {
    final dist = Distribution.fromJsonForTest({
      'distribution': {'name': 'ErisPulse', 'vendor': 'ErisPulse Official'},
    });
    expect(dist.isOfficial, isTrue);
    expect(dist.hasFirstLaunchContent, isFalse);
  });

  test('blank strings fall back to null', () {
    final dist = Distribution.fromJsonForTest({
      'notices': {'firstLaunch': '   '},
      'defaults': {'pypiIndexUrl': ''},
    });
    expect(dist.firstLaunchNotice, isNull);
    expect(dist.customPypiIndexUrl, isNull);
  });
}
