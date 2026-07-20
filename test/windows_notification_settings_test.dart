import 'package:flutter_test/flutter_test.dart';
import 'package:xly/notify.dart';
import 'package:xly/src/notify/windows_notification_identity.dart';

WindowsNotificationSettingsSnapshot _snapshot({
  bool? global = true,
  bool? app = true,
  bool? banner = true,
  bool? actionCenter = true,
  MyNotifyWindowsFocusAssistMode focus = MyNotifyWindowsFocusAssistMode.off,
}) =>
    WindowsNotificationSettingsSnapshot(
      globalToastEnabled: global,
      appNotificationsEnabled: app,
      showBanner: banner,
      showInActionCenter: actionCenter,
      focusAssistMode: focus,
    );

void main() {
  group('Windows notification submission semantics', () {
    test('priority-only suppresses banner but still allows system submission',
        () {
      final status = _snapshot(
        focus: MyNotifyWindowsFocusAssistMode.priorityOnly,
      );

      expect(status.canSubmitNotifications, isTrue);
      expect(status.canShowBanner, isFalse);
      expect(status.focusAssistSuppressesNormalNotifications, isTrue);
    });

    test('action-center-only remains a valid delivery surface', () {
      final status = _snapshot(banner: false, actionCenter: true);

      expect(status.canSubmitNotifications, isTrue);
      expect(status.canShowBanner, isFalse);
    });

    test('banner-only remains a valid delivery surface', () {
      final status = _snapshot(banner: true, actionCenter: false);

      expect(status.canSubmitNotifications, isTrue);
      expect(status.canShowBanner, isTrue);
    });

    test('submission is unavailable only when all system surfaces are disabled',
        () {
      expect(
        _snapshot(banner: false, actionCenter: false).canSubmitNotifications,
        isFalse,
      );
      expect(
        _snapshot(global: false).canSubmitNotifications,
        isFalse,
      );
      expect(
        _snapshot(app: false).canSubmitNotifications,
        isFalse,
      );
    });
  });

  test('permission status reports submission separately from banner display',
      () {
    const status = MyNotifyPermissionStatus(
      platform: 'windows',
      canShowNotifications: true,
      windowsShowBanner: true,
      windowsShowInActionCenter: true,
      windowsFocusAssistMode: MyNotifyWindowsFocusAssistMode.priorityOnly,
      issues: ['Windows 专注助手为“仅优先通知”'],
    );

    expect(status.canSubmitNotifications, isTrue);
    expect(status.canShowBanner, isFalse);
    expect(status.summary, contains('系统通知可提交'));
  });
}
