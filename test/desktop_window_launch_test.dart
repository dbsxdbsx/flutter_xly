import 'package:flutter_test/flutter_test.dart';
import 'package:xly/app.dart';

void main() {
  group('DesktopWindowLaunch.resolve', () {
    test('默认：桌面、要显示、无叠层 → 初始化阶段出示', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: true,
        showWindowOnInit: true,
        hasSplash: false,
      );
      expect(launch.showDuringWindowInit, isTrue);
      expect(launch.showAfterFirstFrame, isFalse);
      expect(launch.stayHidden, isFalse);
    });

    test('有启动叠层时默认等首帧再出示', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: true,
        showWindowOnInit: true,
        hasSplash: true,
      );
      expect(launch.showDuringWindowInit, isFalse);
      expect(launch.showAfterFirstFrame, isTrue);
      expect(launch.stayHidden, isFalse);
    });

    test('显式 defer 即使没有叠层也等首帧', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: true,
        showWindowOnInit: true,
        hasSplash: false,
        deferShowUntilFirstFrame: true,
      );
      expect(launch.showDuringWindowInit, isFalse);
      expect(launch.showAfterFirstFrame, isTrue);
    });

    test('显式关闭 defer 时有叠层也立即出示', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: true,
        showWindowOnInit: true,
        hasSplash: true,
        deferShowUntilFirstFrame: false,
      );
      expect(launch.showDuringWindowInit, isTrue);
      expect(launch.showAfterFirstFrame, isFalse);
    });

    test('showWindowOnInit=false 保持隐藏，忽略 defer 与叠层', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: true,
        showWindowOnInit: false,
        hasSplash: true,
        deferShowUntilFirstFrame: true,
      );
      expect(launch.showDuringWindowInit, isFalse);
      expect(launch.showAfterFirstFrame, isFalse);
      expect(launch.stayHidden, isTrue);
    });

    test('非桌面不走窗口出示', () {
      final launch = DesktopWindowLaunch.resolve(
        isDesktop: false,
        showWindowOnInit: true,
        hasSplash: true,
      );
      expect(launch.showDuringWindowInit, isFalse);
      expect(launch.showAfterFirstFrame, isFalse);
      expect(launch.stayHidden, isTrue);
    });
  });
}
