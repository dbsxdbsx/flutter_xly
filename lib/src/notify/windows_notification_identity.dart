import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;

import '../logger.dart';
import 'notify_enums.dart';

const _clsidShellLink = '{00021401-0000-0000-C000-000000000046}';
const _iidIShellLink = '{000214F9-0000-0000-C000-000000000046}';
const _iidIPersistFile = '{0000010B-0000-0000-C000-000000000046}';
const _iidIPropertyStore = '{886D8EEB-8CF2-4446-8D02-CDBA1DBDCF99}';
const _pkeyAppUserModelIdFmtid = '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}';

const _clsctxInprocServer = 0x1;
const _coinitApartmentThreaded = 0x2;
const _sOk = 0;
const _sFalse = 1;
const _rpcEChangedMode = -2147417850;
const _vtLpwstr = 31;
const _appModelErrorNoPackage = 15700;
const _hkeyCurrentUser = 0x80000001;
const _rrfRtRegDword = 0x00000010;
const _keySetValue = 0x0002;
const _regDword = 4;

/// Windows Toast 所需的桌面应用身份。
class WindowsNotificationIdentity {
  const WindowsNotificationIdentity({
    required this.appName,
    required this.appUserModelId,
    required this.guid,
    required this.executablePath,
    required this.shortcutPath,
    required this.hasPackageIdentity,
    this.iconPath,
  });

  final String appName;
  final String appUserModelId;
  final String guid;
  final String executablePath;
  final String shortcutPath;
  final String? iconPath;
  final bool hasPackageIdentity;
}

class WindowsNotificationSettingsSnapshot {
  const WindowsNotificationSettingsSnapshot({
    required this.globalToastEnabled,
    required this.appNotificationsEnabled,
    required this.showBanner,
    required this.showInActionCenter,
    required this.focusAssistMode,
  });

  final bool? globalToastEnabled;
  final bool? appNotificationsEnabled;
  final bool? showBanner;
  final bool? showInActionCenter;
  final MyNotifyWindowsFocusAssistMode focusAssistMode;

  bool get canShowNotifications {
    return globalToastEnabled != false &&
        appNotificationsEnabled != false &&
        showBanner != false &&
        focusAssistMode != MyNotifyWindowsFocusAssistMode.priorityOnly &&
        focusAssistMode != MyNotifyWindowsFocusAssistMode.alarmsOnly;
  }

  bool get focusAssistSuppressesNormalNotifications {
    return focusAssistMode == MyNotifyWindowsFocusAssistMode.priorityOnly ||
        focusAssistMode == MyNotifyWindowsFocusAssistMode.alarmsOnly;
  }

  List<String> get issues {
    final result = <String>[];
    if (globalToastEnabled == false) {
      result.add('Windows 全局通知已关闭');
    }
    if (appNotificationsEnabled == false) {
      result.add('当前应用通知已关闭');
    }
    if (showBanner == false) {
      result.add('当前应用通知横幅已关闭');
    }
    if (showInActionCenter == false) {
      result.add('当前应用通知中心记录已关闭');
    }
    switch (focusAssistMode) {
      case MyNotifyWindowsFocusAssistMode.priorityOnly:
        result.add('Windows 专注助手为“仅优先通知”，普通通知可能直接进入操作中心');
        break;
      case MyNotifyWindowsFocusAssistMode.alarmsOnly:
        result.add('Windows 专注助手为“仅限闹钟”，普通通知不会弹出横幅');
        break;
      case MyNotifyWindowsFocusAssistMode.unavailable:
      case MyNotifyWindowsFocusAssistMode.unknown:
      case MyNotifyWindowsFocusAssistMode.off:
        break;
    }
    return result;
  }
}

/// 为未打包的 Windows 桌面应用自动补齐 Toast 通知身份。
class WindowsNotificationIdentityManager {
  const WindowsNotificationIdentityManager._();

  static Future<WindowsNotificationIdentity?> prepare({
    String? appName,
    String? appUserModelId,
    String? guid,
    String? iconPath,
  }) async {
    if (!Platform.isWindows) return null;

    final packageInfo = await _getPackageInfo();
    final executablePath = Platform.resolvedExecutable;
    final effectiveAppName = _firstNonBlank([
      appName,
      packageInfo?.appName,
      path.basenameWithoutExtension(executablePath),
      'XLY App',
    ]);
    final effectiveAumid = appUserModelId ??
        _buildAppUserModelId(
          packageName: packageInfo?.packageName,
          executablePath: executablePath,
        );
    final effectiveGuid =
        _normalizeGuid(guid ?? _deterministicGuid(effectiveAumid));
    final effectiveIconPath = _resolveIconPath(iconPath, executablePath);
    final shortcutPath = _buildShortcutPath(effectiveAppName);
    final hasPackageIdentity = _hasPackageIdentity();

    XlyLogger.diagnostic(
      'MyNotify(Windows): 开始自动准备系统通知身份，AUMID=$effectiveAumid, '
      'appName=$effectiveAppName, packageIdentity=$hasPackageIdentity',
    );

    _setCurrentProcessAppUserModelId(effectiveAumid);
    await _createStartMenuShortcut(
      appName: effectiveAppName,
      appUserModelId: effectiveAumid,
      executablePath: executablePath,
      shortcutPath: shortcutPath,
      iconPath: effectiveIconPath,
    );
    _ensurePerAppNotificationDefaults(effectiveAumid);

    if (!hasPackageIdentity) {
      XlyLogger.diagnostic(
        'MyNotify(Windows): 当前应用不是 MSIX/package identity 模式，'
        '即时 Toast 可用；cancel/getActiveNotifications 等历史通知能力受 Windows 限制。',
      );
    }

    logNotificationSettings(effectiveAumid);

    return WindowsNotificationIdentity(
      appName: effectiveAppName,
      appUserModelId: effectiveAumid,
      guid: effectiveGuid,
      executablePath: executablePath,
      shortcutPath: shortcutPath,
      iconPath: effectiveIconPath,
      hasPackageIdentity: hasPackageIdentity,
    );
  }

  static void logNotificationSettings(String appUserModelId) {
    if (!Platform.isWindows) return;

    final snapshot = inspectNotificationSettings(appUserModelId);
    if (snapshot.globalToastEnabled == false) {
      XlyLogger.diagnostic(
        r'MyNotify(Windows): 检测到 Windows 全局通知已关闭 '
        r'(HKCU\Software\Microsoft\Windows\CurrentVersion\PushNotifications\ToastEnabled=0)，'
        '系统不会显示右下角 Toast 横幅。请打开 Windows 设置 > 系统 > 通知。',
      );
    } else if (snapshot.globalToastEnabled == true) {
      XlyLogger.diagnostic('MyNotify(Windows): Windows 全局通知开关已开启。');
    } else {
      XlyLogger.diagnostic(
        'MyNotify(Windows): 未读取到 Windows 全局通知开关，将继续尝试显示 Toast。',
      );
    }

    if (snapshot.appNotificationsEnabled == false) {
      XlyLogger.diagnostic(
        'MyNotify(Windows): 检测到当前应用通知已被 Windows 单独关闭，'
        'AUMID=$appUserModelId；请在 Windows 设置 > 系统 > 通知中打开该应用通知。',
      );
    }

    if (snapshot.showBanner == false) {
      XlyLogger.diagnostic(
        'MyNotify(Windows): 当前应用的通知横幅已被 Windows 单独关闭，'
        'AUMID=$appUserModelId；请在该应用通知设置中打开“显示通知横幅”。',
      );
    }

    switch (snapshot.focusAssistMode) {
      case MyNotifyWindowsFocusAssistMode.off:
        XlyLogger.diagnostic('MyNotify(Windows): Windows 专注助手已关闭。');
        break;
      case MyNotifyWindowsFocusAssistMode.priorityOnly:
        XlyLogger.diagnostic(
          'MyNotify(Windows): Windows 专注助手当前为“仅优先通知”，'
          '普通 Toast 可能不会显示右下角横幅。',
        );
        break;
      case MyNotifyWindowsFocusAssistMode.alarmsOnly:
        XlyLogger.diagnostic(
          'MyNotify(Windows): Windows 专注助手当前为“仅限闹钟”，'
          '普通 Toast 不会显示右下角横幅。',
        );
        break;
      case MyNotifyWindowsFocusAssistMode.unavailable:
      case MyNotifyWindowsFocusAssistMode.unknown:
        XlyLogger.diagnostic('MyNotify(Windows): 未能确认 Windows 专注助手状态。');
        break;
    }
  }

  static WindowsNotificationSettingsSnapshot inspectNotificationSettings(
    String appUserModelId,
  ) {
    bool? readBool(String subKey, String valueName) {
      final value = _readRegistryDword(subKey, valueName);
      if (value == null) return null;
      return value != 0;
    }

    final appSubKey =
        'Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings\\$appUserModelId';
    return WindowsNotificationSettingsSnapshot(
      globalToastEnabled: readBool(
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
      ),
      appNotificationsEnabled: readBool(appSubKey, 'Enabled'),
      showBanner: readBool(appSubKey, 'ShowBanner'),
      showInActionCenter: readBool(appSubKey, 'ShowInActionCenter'),
      focusAssistMode: inspectFocusAssistMode(),
    );
  }

  static MyNotifyWindowsFocusAssistMode inspectFocusAssistMode() {
    if (!Platform.isWindows) return MyNotifyWindowsFocusAssistMode.unavailable;
    return _queryFocusAssistModeByWnf();
  }

  static WindowsNotificationSettingsSnapshot ensureNotificationSettingsEnabled(
    String appUserModelId, {
    bool includeGlobalWindowsSetting = true,
  }) {
    if (includeGlobalWindowsSetting) {
      final current = _readRegistryDword(
        r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
        'ToastEnabled',
      );
      if (current != 1 &&
          _writeRegistryDword(
            r'Software\Microsoft\Windows\CurrentVersion\PushNotifications',
            'ToastEnabled',
            1,
          )) {
        XlyLogger.diagnostic('MyNotify(Windows): 已开启 Windows 全局 Toast 通知开关。');
      }
    }

    final subKey =
        'Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings\\$appUserModelId';
    for (final entry in const {
      'Enabled': '当前应用通知',
      'ShowBanner': '当前应用通知横幅',
      'ShowInActionCenter': '当前应用通知中心记录',
    }.entries) {
      if (_writeRegistryDword(subKey, entry.key, 1)) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 已请求开启 ${entry.value}：${entry.key}=1。'
          'AUMID=$appUserModelId',
        );
      }
    }

    return inspectNotificationSettings(appUserModelId);
  }

  static Future<bool> openSystemNotificationSettings() async {
    return _openWindowsSettingsUri(
      'ms-settings:notifications',
      failureMessage: '打开系统通知设置失败',
    );
  }

  static Future<bool> openSystemFocusAssistSettings() async {
    return _openWindowsSettingsUri(
      'ms-settings:quiethours',
      failureMessage: '打开专注助手设置失败',
    );
  }

  static Future<bool> _openWindowsSettingsUri(
    String uri, {
    required String failureMessage,
  }) async {
    if (!Platform.isWindows) return false;
    try {
      final result = await Process.run('explorer.exe', [uri]);
      return result.exitCode == 0;
    } catch (e) {
      XlyLogger.diagnostic('MyNotify(Windows): $failureMessage: $e');
      return false;
    }
  }

  static Future<PackageInfo?> _getPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (e) {
      XlyLogger.diagnostic(
          'MyNotify(Windows): 读取 PackageInfo 失败，将使用 EXE 名称兜底: $e');
      return null;
    }
  }

  static String _buildAppUserModelId({
    required String? packageName,
    required String executablePath,
  }) {
    final seed = _firstNonBlank([
      packageName,
      path.basenameWithoutExtension(executablePath),
      'app',
    ]);
    final sanitized = _sanitizeAumid(seed);
    return sanitized.contains('.') ? sanitized : 'xly.$sanitized';
  }

  static String _sanitizeAumid(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[^A-Za-z0-9.]+'), '.')
        .replaceAll(RegExp(r'\.+'), '.')
        .replaceAll(RegExp(r'^\.|\.$'), '')
        .toLowerCase();
    if (sanitized.isEmpty) return 'xly.app';
    return sanitized.length > 120 ? sanitized.substring(0, 120) : sanitized;
  }

  static String _deterministicGuid(String seed) {
    final bytes = <int>[
      ..._hash32Bytes('xly-notify-guid-1:$seed'),
      ..._hash32Bytes('xly-notify-guid-2:$seed'),
      ..._hash32Bytes('xly-notify-guid-3:$seed'),
      ..._hash32Bytes('xly-notify-guid-4:$seed'),
    ];

    // 标记为 RFC 4122 version 5 / variant 1，便于诊断工具识别为标准 GUID。
    bytes[6] = (bytes[6] & 0x0f) | 0x50;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    String hex(int value) => value.toRadixString(16).padLeft(2, '0');
    final text = bytes.map(hex).join();
    return '${text.substring(0, 8)}-'
        '${text.substring(8, 12)}-'
        '${text.substring(12, 16)}-'
        '${text.substring(16, 20)}-'
        '${text.substring(20, 32)}';
  }

  static List<int> _hash32Bytes(String value) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(value)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return [
      (hash >> 24) & 0xff,
      (hash >> 16) & 0xff,
      (hash >> 8) & 0xff,
      hash & 0xff,
    ];
  }

  static String _normalizeGuid(String guid) {
    return guid.replaceAll('{', '').replaceAll('}', '').toLowerCase();
  }

  static String? _resolveIconPath(String? iconPath, String executablePath) {
    if (iconPath != null &&
        iconPath.isNotEmpty &&
        File(iconPath).existsSync()) {
      return iconPath;
    }
    return File(executablePath).existsSync() ? executablePath : null;
  }

  static String _buildShortcutPath(String appName) {
    final appData = Platform.environment['APPDATA'];
    final base = appData == null || appData.isEmpty
        ? path.dirname(Platform.resolvedExecutable)
        : path.join(appData, 'Microsoft', 'Windows', 'Start Menu', 'Programs');
    final fileName = _sanitizeFileName(appName);
    return path.join(base, '$fileName.lnk');
  }

  static String _sanitizeFileName(String value) {
    final sanitized =
        value.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
    return sanitized.isEmpty ? 'XLY App' : sanitized;
  }

  static String _firstNonBlank(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) return value.trim();
    }
    return 'XLY App';
  }

  static void _setCurrentProcessAppUserModelId(String appUserModelId) {
    final shell32 = DynamicLibrary.open('shell32.dll');
    final setCurrentProcessExplicitAppUserModelId = shell32.lookupFunction<
        Int32 Function(Pointer<Utf16> appId),
        int Function(
            Pointer<Utf16> appId)>('SetCurrentProcessExplicitAppUserModelID');

    final appIdPtr = appUserModelId.toNativeUtf16(allocator: calloc);
    try {
      final hr = setCurrentProcessExplicitAppUserModelId(appIdPtr);
      if (_failed(hr)) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 绑定进程 AUMID 失败，HRESULT=0x${_hrHex(hr)}；'
          'Windows 可能无法把 Toast 归属到当前应用。',
        );
      } else {
        XlyLogger.diagnostic('MyNotify(Windows): 已绑定进程 AUMID: $appUserModelId');
      }
    } catch (e) {
      XlyLogger.diagnostic(
          'MyNotify(Windows): 调用 SetCurrentProcessExplicitAppUserModelID 失败: $e');
    } finally {
      calloc.free(appIdPtr);
    }
  }

  static Future<void> _createStartMenuShortcut({
    required String appName,
    required String appUserModelId,
    required String executablePath,
    required String shortcutPath,
    required String? iconPath,
  }) async {
    try {
      await Directory(path.dirname(shortcutPath)).create(recursive: true);
      _createShortcutWithAppUserModelId(
        appName: appName,
        appUserModelId: appUserModelId,
        executablePath: executablePath,
        shortcutPath: shortcutPath,
        iconPath: iconPath,
      );
      XlyLogger.diagnostic(
        'MyNotify(Windows): 已创建/刷新开始菜单快捷方式并写入 AUMID: $shortcutPath',
      );
    } catch (e, stackTrace) {
      XlyLogger.error(
        'MyNotify(Windows): 自动创建开始菜单快捷方式失败，系统 Toast 可能无法显示',
        e,
        stackTrace,
      );
    }
  }

  static void _createShortcutWithAppUserModelId({
    required String appName,
    required String appUserModelId,
    required String executablePath,
    required String shortcutPath,
    required String? iconPath,
  }) {
    final ole32 = DynamicLibrary.open('ole32.dll');
    final coInitializeEx = ole32.lookupFunction<
        Int32 Function(Pointer<Void> pvReserved, Uint32 dwCoInit),
        int Function(Pointer<Void> pvReserved, int dwCoInit)>('CoInitializeEx');
    final coUninitialize = ole32
        .lookupFunction<Void Function(), void Function()>('CoUninitialize');
    final coCreateInstance = ole32.lookupFunction<
        Int32 Function(
          Pointer<_GUID> rclsid,
          Pointer<Void> pUnkOuter,
          Uint32 dwClsContext,
          Pointer<_GUID> riid,
          Pointer<Pointer<_COMObject>> ppv,
        ),
        int Function(
          Pointer<_GUID> rclsid,
          Pointer<Void> pUnkOuter,
          int dwClsContext,
          Pointer<_GUID> riid,
          Pointer<Pointer<_COMObject>> ppv,
        )>('CoCreateInstance');
    final clsidFromString = ole32.lookupFunction<
        Int32 Function(Pointer<Utf16> lpsz, Pointer<_GUID> pclsid),
        int Function(
            Pointer<Utf16> lpsz, Pointer<_GUID> pclsid)>('CLSIDFromString');

    final initHr = coInitializeEx(nullptr, _coinitApartmentThreaded);
    final shouldUninitialize = initHr == _sOk || initHr == _sFalse;
    if (_failed(initHr) && initHr != _rpcEChangedMode) {
      throw StateError('CoInitializeEx failed: 0x${_hrHex(initHr)}');
    }

    Pointer<_COMObject>? shellLink;
    Pointer<_COMObject>? propertyStore;
    Pointer<_COMObject>? persistFile;

    try {
      final clsid = _guidFromString(_clsidShellLink, clsidFromString);
      final iidShellLink = _guidFromString(_iidIShellLink, clsidFromString);
      final shellLinkOut = calloc<Pointer<_COMObject>>();
      try {
        final hr = coCreateInstance(
          clsid,
          nullptr,
          _clsctxInprocServer,
          iidShellLink,
          shellLinkOut,
        );
        if (_failed(hr)) {
          throw StateError(
              'CoCreateInstance(ShellLink) failed: 0x${_hrHex(hr)}');
        }
        shellLink = shellLinkOut.value;
      } finally {
        calloc.free(clsid);
        calloc.free(iidShellLink);
        calloc.free(shellLinkOut);
      }

      _shellLinkSetString(shellLink, 20, executablePath);
      _shellLinkSetString(shellLink, 11, '');
      _shellLinkSetString(shellLink, 9, path.dirname(executablePath));
      _shellLinkSetString(shellLink, 7, appName);
      if (iconPath != null) {
        _shellLinkSetIconLocation(shellLink, iconPath, 0);
      }

      propertyStore =
          _queryInterface(shellLink, _iidIPropertyStore, clsidFromString);
      _propertyStoreSetAppUserModelId(
        propertyStore,
        appUserModelId,
        clsidFromString,
      );

      persistFile =
          _queryInterface(shellLink, _iidIPersistFile, clsidFromString);
      _persistFileSave(persistFile, shortcutPath);
    } finally {
      if (persistFile != null) _release(persistFile);
      if (propertyStore != null) _release(propertyStore);
      if (shellLink != null) _release(shellLink);
      if (shouldUninitialize) coUninitialize();
    }
  }

  static Pointer<_COMObject> _queryInterface(
    Pointer<_COMObject> object,
    String iid,
    _ClsidFromString clsidFromString,
  ) {
    final iidPtr = _guidFromString(iid, clsidFromString);
    final out = calloc<Pointer<_COMObject>>();
    try {
      final queryInterface = (object.ref.lpVtbl + 0)
          .value
          .cast<
              NativeFunction<
                  Int32 Function(
                    Pointer<Void>,
                    Pointer<_GUID>,
                    Pointer<Pointer<_COMObject>>,
                  )>>()
          .asFunction<
              int Function(
                Pointer<Void>,
                Pointer<_GUID>,
                Pointer<Pointer<_COMObject>>,
              )>();
      final hr = queryInterface(object.cast<Void>(), iidPtr, out);
      if (_failed(hr)) {
        throw StateError('QueryInterface($iid) failed: 0x${_hrHex(hr)}');
      }
      return out.value;
    } finally {
      calloc.free(iidPtr);
      calloc.free(out);
    }
  }

  static void _shellLinkSetString(
    Pointer<_COMObject> shellLink,
    int vtableIndex,
    String value,
  ) {
    final valuePtr = value.toNativeUtf16(allocator: calloc);
    try {
      final method = (shellLink.ref.lpVtbl + vtableIndex)
          .value
          .cast<NativeFunction<Int32 Function(Pointer<Void>, Pointer<Utf16>)>>()
          .asFunction<int Function(Pointer<Void>, Pointer<Utf16>)>();
      final hr = method(shellLink.cast<Void>(), valuePtr);
      if (_failed(hr)) {
        throw StateError(
            'IShellLink method $vtableIndex failed: 0x${_hrHex(hr)}');
      }
    } finally {
      calloc.free(valuePtr);
    }
  }

  static void _shellLinkSetIconLocation(
    Pointer<_COMObject> shellLink,
    String iconPath,
    int iconIndex,
  ) {
    final valuePtr = iconPath.toNativeUtf16(allocator: calloc);
    try {
      final method = (shellLink.ref.lpVtbl + 17)
          .value
          .cast<
              NativeFunction<
                  Int32 Function(
                    Pointer<Void>,
                    Pointer<Utf16>,
                    Int32,
                  )>>()
          .asFunction<int Function(Pointer<Void>, Pointer<Utf16>, int)>();
      final hr = method(shellLink.cast<Void>(), valuePtr, iconIndex);
      if (_failed(hr)) {
        throw StateError('IShellLink.setIconLocation failed: 0x${_hrHex(hr)}');
      }
    } finally {
      calloc.free(valuePtr);
    }
  }

  static void _propertyStoreSetAppUserModelId(
    Pointer<_COMObject> propertyStore,
    String appUserModelId,
    _ClsidFromString clsidFromString,
  ) {
    final key = calloc<_PROPERTYKEY>();
    final value = calloc<_PROPVARIANT>();
    final valuePtr = appUserModelId.toNativeUtf16(allocator: calloc);
    try {
      final fmtid = _guidFromString(_pkeyAppUserModelIdFmtid, clsidFromString);
      key.ref.fmtid = fmtid.ref;
      key.ref.pid = 5;
      calloc.free(fmtid);

      value.ref.vt = _vtLpwstr;
      value.ref.pwszVal = valuePtr;

      final setValue = (propertyStore.ref.lpVtbl + 6)
          .value
          .cast<
              NativeFunction<
                  Int32 Function(
                    Pointer<Void>,
                    Pointer<_PROPERTYKEY>,
                    Pointer<_PROPVARIANT>,
                  )>>()
          .asFunction<
              int Function(
                Pointer<Void>,
                Pointer<_PROPERTYKEY>,
                Pointer<_PROPVARIANT>,
              )>();
      final commit = (propertyStore.ref.lpVtbl + 7)
          .value
          .cast<NativeFunction<Int32 Function(Pointer<Void>)>>()
          .asFunction<int Function(Pointer<Void>)>();

      final setHr = setValue(propertyStore.cast<Void>(), key, value);
      if (_failed(setHr)) {
        throw StateError(
            'IPropertyStore.setValue(AUMID) failed: 0x${_hrHex(setHr)}');
      }
      final commitHr = commit(propertyStore.cast<Void>());
      if (_failed(commitHr)) {
        throw StateError('IPropertyStore.commit failed: 0x${_hrHex(commitHr)}');
      }
    } finally {
      calloc.free(valuePtr);
      calloc.free(value);
      calloc.free(key);
    }
  }

  static void _persistFileSave(
      Pointer<_COMObject> persistFile, String shortcutPath) {
    final pathPtr = shortcutPath.toNativeUtf16(allocator: calloc);
    try {
      final save = (persistFile.ref.lpVtbl + 6)
          .value
          .cast<
              NativeFunction<
                  Int32 Function(Pointer<Void>, Pointer<Utf16>, Int32)>>()
          .asFunction<int Function(Pointer<Void>, Pointer<Utf16>, int)>();
      final hr = save(persistFile.cast<Void>(), pathPtr, 1);
      if (_failed(hr)) {
        throw StateError('IPersistFile.save failed: 0x${_hrHex(hr)}');
      }
    } finally {
      calloc.free(pathPtr);
    }
  }

  static Pointer<_GUID> _guidFromString(
    String value,
    _ClsidFromString clsidFromString,
  ) {
    final guidPtr = calloc<_GUID>();
    final textPtr = value.toNativeUtf16(allocator: calloc);
    try {
      final hr = clsidFromString(textPtr, guidPtr);
      if (_failed(hr)) {
        throw FormatException('Invalid GUID: $value, HRESULT=0x${_hrHex(hr)}');
      }
      return guidPtr;
    } finally {
      calloc.free(textPtr);
    }
  }

  static void _release(Pointer<_COMObject> object) {
    final release = (object.ref.lpVtbl + 2)
        .value
        .cast<NativeFunction<Uint32 Function(Pointer<Void>)>>()
        .asFunction<int Function(Pointer<Void>)>();
    release(object.cast<Void>());
  }

  static bool _hasPackageIdentity() {
    try {
      final kernel32 = DynamicLibrary.open('kernel32.dll');
      final getCurrentPackageFullName = kernel32.lookupFunction<
          Int32 Function(Pointer<Uint32> packageFullNameLength,
              Pointer<Utf16> packageFullName),
          int Function(Pointer<Uint32> packageFullNameLength,
              Pointer<Utf16> packageFullName)>('GetCurrentPackageFullName');
      final length = calloc<Uint32>();
      try {
        final result = getCurrentPackageFullName(length, nullptr);
        return result != _appModelErrorNoPackage;
      } finally {
        calloc.free(length);
      }
    } catch (_) {
      return false;
    }
  }

  static int? _readRegistryDword(String subKey, String valueName) {
    try {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final regGetValue = advapi32.lookupFunction<
          Int32 Function(
            IntPtr hkey,
            Pointer<Utf16> lpSubKey,
            Pointer<Utf16> lpValue,
            Uint32 dwFlags,
            Pointer<Uint32> pdwType,
            Pointer<Void> pvData,
            Pointer<Uint32> pcbData,
          ),
          int Function(
            int hkey,
            Pointer<Utf16> lpSubKey,
            Pointer<Utf16> lpValue,
            int dwFlags,
            Pointer<Uint32> pdwType,
            Pointer<Void> pvData,
            Pointer<Uint32> pcbData,
          )>('RegGetValueW');

      final subKeyPtr = subKey.toNativeUtf16(allocator: calloc);
      final valueNamePtr = valueName.toNativeUtf16(allocator: calloc);
      final type = calloc<Uint32>();
      final data = calloc<Uint32>();
      final dataSize = calloc<Uint32>()..value = sizeOf<Uint32>();
      try {
        final result = regGetValue(
          _hkeyCurrentUser,
          subKeyPtr,
          valueNamePtr,
          _rrfRtRegDword,
          type,
          data.cast<Void>(),
          dataSize,
        );
        if (result != 0) return null;
        return data.value;
      } finally {
        calloc.free(dataSize);
        calloc.free(data);
        calloc.free(type);
        calloc.free(valueNamePtr);
        calloc.free(subKeyPtr);
      }
    } catch (_) {
      return null;
    }
  }

  static void _ensurePerAppNotificationDefaults(String appUserModelId) {
    final subKey =
        'Software\\Microsoft\\Windows\\CurrentVersion\\Notifications\\Settings\\$appUserModelId';

    void ensureEnabled(String valueName, String description) {
      final current = _readRegistryDword(subKey, valueName);
      if (current == 0) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): $description 已被用户或系统策略关闭，'
          '不会自动覆盖。AUMID=$appUserModelId',
        );
        return;
      }
      if (current == null && _writeRegistryDword(subKey, valueName, 1)) {
        XlyLogger.diagnostic(
          'MyNotify(Windows): 已为当前应用初始化通知设置：$valueName=1 '
          '($description)。AUMID=$appUserModelId',
        );
      }
    }

    ensureEnabled('Enabled', '当前应用通知');
    ensureEnabled('ShowBanner', '当前应用通知横幅');
    ensureEnabled('ShowInActionCenter', '当前应用通知中心记录');
  }

  static bool _writeRegistryDword(String subKey, String valueName, int value) {
    try {
      final advapi32 = DynamicLibrary.open('advapi32.dll');
      final regCreateKeyEx = advapi32.lookupFunction<
          Int32 Function(
            IntPtr hKey,
            Pointer<Utf16> lpSubKey,
            Uint32 reserved,
            Pointer<Utf16> lpClass,
            Uint32 options,
            Uint32 samDesired,
            Pointer<Void> lpSecurityAttributes,
            Pointer<IntPtr> phkResult,
            Pointer<Uint32> lpdwDisposition,
          ),
          int Function(
            int hKey,
            Pointer<Utf16> lpSubKey,
            int reserved,
            Pointer<Utf16> lpClass,
            int options,
            int samDesired,
            Pointer<Void> lpSecurityAttributes,
            Pointer<IntPtr> phkResult,
            Pointer<Uint32> lpdwDisposition,
          )>('RegCreateKeyExW');
      final regSetValueEx = advapi32.lookupFunction<
          Int32 Function(
            IntPtr hKey,
            Pointer<Utf16> lpValueName,
            Uint32 reserved,
            Uint32 dwType,
            Pointer<Uint8> lpData,
            Uint32 cbData,
          ),
          int Function(
            int hKey,
            Pointer<Utf16> lpValueName,
            int reserved,
            int dwType,
            Pointer<Uint8> lpData,
            int cbData,
          )>('RegSetValueExW');
      final regCloseKey = advapi32.lookupFunction<Int32 Function(IntPtr hKey),
          int Function(int hKey)>('RegCloseKey');

      final subKeyPtr = subKey.toNativeUtf16(allocator: calloc);
      final valueNamePtr = valueName.toNativeUtf16(allocator: calloc);
      final openedKey = calloc<IntPtr>();
      final disposition = calloc<Uint32>();
      final data = calloc<Uint32>()..value = value;
      try {
        final createResult = regCreateKeyEx(
          _hkeyCurrentUser,
          subKeyPtr,
          0,
          nullptr,
          0,
          _keySetValue,
          nullptr,
          openedKey,
          disposition,
        );
        if (createResult != 0) return false;

        final setResult = regSetValueEx(
          openedKey.value,
          valueNamePtr,
          0,
          _regDword,
          data.cast<Uint8>(),
          sizeOf<Uint32>(),
        );
        return setResult == 0;
      } finally {
        if (openedKey.value != 0) regCloseKey(openedKey.value);
        calloc.free(data);
        calloc.free(disposition);
        calloc.free(openedKey);
        calloc.free(valueNamePtr);
        calloc.free(subKeyPtr);
      }
    } catch (_) {
      return false;
    }
  }

  // Windows 没有公开的 Focus Assist 三态 API；这里仅作为诊断读取，
  // 查询失败时返回 unknown，不把内部实现细节暴露成强依赖。
  static MyNotifyWindowsFocusAssistMode _queryFocusAssistModeByWnf() {
    try {
      final ntdll = DynamicLibrary.open('ntdll.dll');
      final ntQueryWnfStateData = ntdll.lookupFunction<
          Int32 Function(
            Pointer<_WNFStateName> stateName,
            Pointer<Void> typeId,
            Pointer<Void> explicitScope,
            Pointer<Uint32> changeStamp,
            Pointer<Void> buffer,
            Pointer<Uint32> bufferSize,
          ),
          int Function(
            Pointer<_WNFStateName> stateName,
            Pointer<Void> typeId,
            Pointer<Void> explicitScope,
            Pointer<Uint32> changeStamp,
            Pointer<Void> buffer,
            Pointer<Uint32> bufferSize,
          )>('NtQueryWnfStateData');

      final stateName = calloc<_WNFStateName>();
      final changeStamp = calloc<Uint32>();
      final buffer = calloc<Uint32>();
      final bufferSize = calloc<Uint32>()..value = sizeOf<Uint32>();
      try {
        stateName.ref.data[0] = 0xA3BF1C75;
        stateName.ref.data[1] = 0x0D83063E;

        final status = ntQueryWnfStateData(
          stateName,
          nullptr,
          nullptr,
          changeStamp,
          buffer.cast<Void>(),
          bufferSize,
        );
        if (status < 0) {
          XlyLogger.diagnostic(
            'MyNotify(Windows): 查询专注助手 WNF 状态失败，NTSTATUS=0x${_hrHex(status)}',
          );
          return MyNotifyWindowsFocusAssistMode.unknown;
        }

        return switch (buffer.value) {
          0 => MyNotifyWindowsFocusAssistMode.off,
          1 => MyNotifyWindowsFocusAssistMode.priorityOnly,
          2 => MyNotifyWindowsFocusAssistMode.alarmsOnly,
          _ => MyNotifyWindowsFocusAssistMode.unknown,
        };
      } finally {
        calloc.free(bufferSize);
        calloc.free(buffer);
        calloc.free(changeStamp);
        calloc.free(stateName);
      }
    } catch (e) {
      XlyLogger.diagnostic('MyNotify(Windows): 查询专注助手状态失败: $e');
      return MyNotifyWindowsFocusAssistMode.unknown;
    }
  }

  static bool _failed(int hr) => hr < 0;

  static String _hrHex(int hr) {
    final unsigned = hr < 0 ? 0x100000000 + hr : hr;
    return unsigned.toRadixString(16).padLeft(8, '0');
  }
}

typedef _ClsidFromString = int Function(
    Pointer<Utf16> lpsz, Pointer<_GUID> pclsid);

base class _COMObject extends Struct {
  external Pointer<Pointer<Void>> lpVtbl;
}

base class _WNFStateName extends Struct {
  @Array(2)
  external Array<Uint32> data;
}

base class _GUID extends Struct {
  @Uint32()
  external int data1;

  @Uint16()
  external int data2;

  @Uint16()
  external int data3;

  @Array(8)
  external Array<Uint8> data4;
}

base class _PROPERTYKEY extends Struct {
  external _GUID fmtid;

  @Uint32()
  external int pid;
}

base class _PROPVARIANT extends Struct {
  @Uint16()
  external int vt;

  @Uint16()
  external int reserved1;

  @Uint16()
  external int reserved2;

  @Uint16()
  external int reserved3;

  external Pointer<Utf16> pwszVal;
}
