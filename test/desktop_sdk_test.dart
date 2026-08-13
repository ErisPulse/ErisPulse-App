// 版本排序（PEP 440 语义）单元测试：正式版排在预发布之前，
// 预发布按数字后缀排序（如 2.7.1.dev4 > 2.7.1.dev3）。
import 'package:erispulse_app/services/runtime/desktop_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DesktopSdk.compareVersions', () {
    test('正式版排在预发布之前', () {
      expect(DesktopSdk.compareVersions('2.7.1', '2.7.1.dev4'), greaterThan(0));
      expect(DesktopSdk.compareVersions('2.7.1.dev4', '2.7.1'), lessThan(0));
      expect(DesktopSdk.compareVersions('2.7.0', '2.7.0.dev5'), greaterThan(0));
    });

    test('预发布版本按数字后缀排序', () {
      expect(
        DesktopSdk.compareVersions('2.7.1.dev4', '2.7.1.dev3'),
        greaterThan(0),
      );
      expect(
        DesktopSdk.compareVersions('2.7.1.dev1', '2.7.1.dev0'),
        greaterThan(0),
      );
      expect(
        DesktopSdk.compareVersions('2.7.0.dev5', '2.7.0.dev3'),
        greaterThan(0),
      );
    });

    test('普通数字版本大小比较', () {
      expect(DesktopSdk.compareVersions('2.7.1', '2.7.0'), greaterThan(0));
      expect(DesktopSdk.compareVersions('2.6.3', '2.7.1'), lessThan(0));
      expect(DesktopSdk.compareVersions('2.7.1', '2.7.1'), 0);
    });

    test('降序列表：正式版在前，dev 依次在后', () {
      final versions = [
        '2.7.0',
        '2.7.1.dev4',
        '2.6.3',
        '2.7.1',
        '2.7.1.dev0',
        '2.7.0.dev5',
        '2.7.0.dev3',
        '2.7.1.dev3',
        '2.7.0.dev0',
      ];
      versions.sort((a, b) => DesktopSdk.compareVersions(b, a));
      expect(versions, [
        '2.7.1',
        '2.7.1.dev4',
        '2.7.1.dev3',
        '2.7.1.dev0',
        '2.7.0',
        '2.7.0.dev5',
        '2.7.0.dev3',
        '2.7.0.dev0',
        '2.6.3',
      ]);
    });
  });
}
