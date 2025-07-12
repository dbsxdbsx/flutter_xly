import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  test('GetStorage should be exported from xly package', () {
    // 测试GetStorage类是否可以从xly包中访问
    expect(GetStorage, isNotNull);
  });

  group('MyPlatform 平台检测测试', () {
    test('平台检测方法应该返回布尔值', () {
      // 测试所有平台检测方法都能正常调用并返回布尔值
      expect(MyPlatform.isDesktop, isA<bool>());
      expect(MyPlatform.isMobile, isA<bool>());
      expect(MyPlatform.isWeb, isA<bool>());
      expect(MyPlatform.isWindows, isA<bool>());
      expect(MyPlatform.isMacOS, isA<bool>());
      expect(MyPlatform.isLinux, isA<bool>());
      expect(MyPlatform.isAndroid, isA<bool>());
      expect(MyPlatform.isIOS, isA<bool>());
      expect(MyPlatform.isFuchsia, isA<bool>());
    });

    test('platformName应该返回字符串', () {
      // 测试platformName方法返回有效的平台名称
      final platformName = MyPlatform.platformName;
      expect(platformName, isA<String>());
      expect(platformName.isNotEmpty, isTrue);

      // 验证返回的平台名称是预期的值之一
      const validPlatforms = [
        'Web',
        'Windows',
        'macOS',
        'Linux',
        'Android',
        'iOS',
        'Fuchsia',
        'Unknown'
      ];
      expect(validPlatforms.contains(platformName), isTrue);
    });

    test('平台检测逻辑一致性', () {
      // 测试平台检测的逻辑一致性
      // 如果是桌面平台，那么应该是Windows、macOS或Linux之一
      if (MyPlatform.isDesktop) {
        expect(
          MyPlatform.isWindows || MyPlatform.isMacOS || MyPlatform.isLinux,
          isTrue,
          reason: '桌面平台应该是Windows、macOS或Linux之一',
        );
      }

      // 如果是移动平台，那么应该是Android、iOS或Fuchsia之一
      if (MyPlatform.isMobile) {
        expect(
          MyPlatform.isAndroid || MyPlatform.isIOS || MyPlatform.isFuchsia,
          isTrue,
          reason: '移动平台应该是Android、iOS或Fuchsia之一',
        );
      }

      // 桌面和移动平台不应该同时为true（除非是Web平台）
      if (!MyPlatform.isWeb) {
        expect(
          MyPlatform.isDesktop && MyPlatform.isMobile,
          isFalse,
          reason: '非Web平台不应该同时是桌面和移动平台',
        );
      }
    });
  });
}
