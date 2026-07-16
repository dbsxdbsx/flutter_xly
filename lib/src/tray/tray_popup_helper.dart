import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:window_manager/window_manager.dart';

import '../logger.dart';
import 'my_tray.dart';

// ─── FFI Struct 定义 ───

final class _WinPoint extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

final class _WinRect extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

final class _WinAppBarData extends Struct {
  @Uint32()
  external int cbSize;
  @IntPtr()
  external int hWnd;
  @Uint32()
  external int uCallbackMessage;
  @Uint32()
  external int uEdge;
  external _WinRect rc;
  @IntPtr()
  external int lParam;
}

// ─── Windows 常量 ───

const int _mfString = 0x0000;
const int _mfSeparator = 0x0800;
const int _mfPopup = 0x0010;
const int _mfGrayed = 0x0001;

const int _tpmLeftAlign = 0x0000;
const int _tpmRightAlign = 0x0008;
const int _tpmTopAlign = 0x0000;
const int _tpmBottomAlign = 0x0020;
const int _tpmReturnCmd = 0x0100;
const int _tpmRightButton = 0x0002;

const int _abmGetTaskbarPos = 0x0005;
const int _smCxScreen = 0;
const int _wmNull = 0x0000;

// ─── FFI 函数签名 ───

typedef _CreatePopupMenuNative = IntPtr Function();
typedef _CreatePopupMenuDart = int Function();

typedef _AppendMenuWNative = Int32 Function(
    IntPtr hMenu, Uint32 uFlags, UintPtr uIDNewItem, Pointer<Utf16> lpNewItem);
typedef _AppendMenuWDart = int Function(
    int hMenu, int uFlags, int uIDNewItem, Pointer<Utf16> lpNewItem);

typedef _TrackPopupMenuNative = Int32 Function(IntPtr hMenu, Uint32 uFlags,
    Int32 x, Int32 y, Int32 nReserved, IntPtr hWnd, Pointer<Void> prcRect);
typedef _TrackPopupMenuDart = int Function(int hMenu, int uFlags, int x, int y,
    int nReserved, int hWnd, Pointer<Void> prcRect);

typedef _DestroyMenuNative = Int32 Function(IntPtr hMenu);
typedef _DestroyMenuDart = int Function(int hMenu);

typedef _GetCursorPosNative = Int32 Function(Pointer<_WinPoint> lpPoint);
typedef _GetCursorPosDart = int Function(Pointer<_WinPoint> lpPoint);

typedef _SetForegroundWindowNative = Int32 Function(IntPtr hWnd);
typedef _SetForegroundWindowDart = int Function(int hWnd);

typedef _PostMessageWNative = Int32 Function(
    IntPtr hWnd, Uint32 msg, UintPtr wParam, IntPtr lParam);
typedef _PostMessageWDart = int Function(
    int hWnd, int msg, int wParam, int lParam);

typedef _GetSystemMetricsNative = Int32 Function(Int32 nIndex);
typedef _GetSystemMetricsDart = int Function(int nIndex);

typedef _SHAppBarMessageNative = UintPtr Function(
    Uint32 dwMessage, Pointer<_WinAppBarData> pData);
typedef _SHAppBarMessageDart = int Function(
    int dwMessage, Pointer<_WinAppBarData> pData);

/// Windows 原生弹出菜单助手——根据任务栏位置智能选择弹出方向。
///
/// 替代 tray_manager 的 `popUpContextMenu`（其 `TrackPopupMenu` 对齐标志
/// 硬编码为 `TPM_BOTTOMALIGN | TPM_LEFTALIGN`，在任务栏非底部时菜单会被遮挡）。
///
/// 本类通过 `SHAppBarMessage(ABM_GETTASKBARPOS)` 检测任务栏位于哪条屏幕边缘，
/// 动态选择 `TPM_*ALIGN` 组合，确保菜单始终朝远离任务栏的方向展开：
///
/// | 任务栏位置 | 水平对齐 | 垂直对齐 | 菜单展开方向 |
/// |-----------|---------|---------|------------|
/// | 底部 | LEFT | BOTTOM | 向上 + 向右 |
/// | 右侧 | RIGHT | BOTTOM | 向上 + 向左 |
/// | 顶部 | LEFT | TOP | 向下 + 向右 |
/// | 左侧 | LEFT | BOTTOM | 向上 + 向右 |
///
/// 仅 Windows 可用；其他平台应继续使用 tray_manager 原生弹出。
class TrayPopupHelper {
  static DynamicLibrary? _user32;
  static DynamicLibrary? _shell32;
  static bool _initialized = false;

  static late _CreatePopupMenuDart _createPopupMenu;
  static late _AppendMenuWDart _appendMenuW;
  static late _TrackPopupMenuDart _trackPopupMenu;
  static late _DestroyMenuDart _destroyMenu;
  static late _GetCursorPosDart _getCursorPos;
  static late _SetForegroundWindowDart _setForegroundWindow;
  static late _PostMessageWDart _postMessageW;
  static late _GetSystemMetricsDart _getSystemMetrics;
  static late _SHAppBarMessageDart _shAppBarMessage;

  /// 是否初始化成功且可用
  static bool get isAvailable => _initialized;

  /// 初始化：加载 user32 / shell32 并查找所有函数指针。
  ///
  /// 非 Windows 平台直接跳过；初始化失败时 [isAvailable] 保持 false，
  /// 调用方应回退到 tray_manager 的默认弹出。
  static void initialize() {
    if (_initialized || !Platform.isWindows) return;

    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _shell32 = DynamicLibrary.open('shell32.dll');

      _createPopupMenu = _user32!
          .lookupFunction<_CreatePopupMenuNative, _CreatePopupMenuDart>(
              'CreatePopupMenu');
      _appendMenuW = _user32!
          .lookupFunction<_AppendMenuWNative, _AppendMenuWDart>('AppendMenuW');
      _trackPopupMenu = _user32!
          .lookupFunction<_TrackPopupMenuNative, _TrackPopupMenuDart>(
              'TrackPopupMenu');
      _destroyMenu = _user32!
          .lookupFunction<_DestroyMenuNative, _DestroyMenuDart>('DestroyMenu');
      _getCursorPos = _user32!
          .lookupFunction<_GetCursorPosNative, _GetCursorPosDart>(
              'GetCursorPos');
      _setForegroundWindow = _user32!
          .lookupFunction<_SetForegroundWindowNative, _SetForegroundWindowDart>(
              'SetForegroundWindow');
      _postMessageW = _user32!
          .lookupFunction<_PostMessageWNative, _PostMessageWDart>(
              'PostMessageW');
      _getSystemMetrics = _user32!
          .lookupFunction<_GetSystemMetricsNative, _GetSystemMetricsDart>(
              'GetSystemMetrics');
      _shAppBarMessage = _shell32!
          .lookupFunction<_SHAppBarMessageNative, _SHAppBarMessageDart>(
              'SHAppBarMessage');

      _initialized = true;
      XlyLogger.info('TrayPopupHelper: 初始化成功');
    } catch (e) {
      XlyLogger.error('TrayPopupHelper: 初始化失败，将回退到 tray_manager 弹出', e);
    }
  }

  /// 检测任务栏边缘并返回对应的 `TPM_*ALIGN` 标志组合。
  static int _getSmartFlags() {
    final pAbd = calloc<_WinAppBarData>();
    try {
      pAbd.ref.cbSize = sizeOf<_WinAppBarData>();
      final ok = _shAppBarMessage(_abmGetTaskbarPos, pAbd);
      if (ok == 0) return _tpmBottomAlign | _tpmLeftAlign; // 检测失败用默认值

      final rc = pAbd.ref.rc;
      final screenW = _getSystemMetrics(_smCxScreen);
      final tbWidth = rc.right - rc.left;

      if (tbWidth >= screenW) {
        // 任务栏水平横跨整个屏幕宽度 → 在顶部或底部
        return (rc.top <= 0)
            ? (_tpmTopAlign | _tpmLeftAlign) // 顶部
            : (_tpmBottomAlign | _tpmLeftAlign); // 底部
      } else {
        // 任务栏垂直 → 在左侧或右侧
        return (rc.left <= 0)
            ? (_tpmBottomAlign | _tpmLeftAlign) // 左侧
            : (_tpmBottomAlign | _tpmRightAlign); // 右侧（关键修复）
      }
    } finally {
      calloc.free(pAbd);
    }
  }

  /// 从 [MyTrayMenuItem] 列表构建原生 HMENU，返回菜单句柄和 ID→条目映射。
  static (int hMenu, Map<int, MyTrayMenuItem> idMap) _buildNativeMenu(
    List<MyTrayMenuItem> items,
  ) {
    final hMenu = _createPopupMenu();
    final idMap = <int, MyTrayMenuItem>{};
    var nextId = 1;

    void addItems(int menu, List<MyTrayMenuItem> menuItems) {
      for (final item in menuItems) {
        if (item.isSeparator) {
          _appendMenuW(menu, _mfSeparator, 0, nullptr.cast());
          continue;
        }

        if (item.submenu != null && item.submenu!.isNotEmpty) {
          // 子菜单：递归构建
          final subMenu = _createPopupMenu();
          addItems(subMenu, item.submenu!);

          var flags = _mfString | _mfPopup;
          if (!item.enabled) flags |= _mfGrayed;

          final label = item.label.toNativeUtf16(allocator: malloc);
          _appendMenuW(menu, flags, subMenu, label);
          malloc.free(label);
        } else {
          // 叶节点
          final id = nextId++;
          idMap[id] = item;

          var flags = _mfString;
          if (!item.enabled) flags |= _mfGrayed;

          final label = item.label.toNativeUtf16(allocator: malloc);
          _appendMenuW(menu, flags, id, label);
          malloc.free(label);
        }
      }
    }

    addItems(hMenu, items);
    return (hMenu, idMap);
  }

  /// 在光标位置弹出智能定位的原生右键菜单。
  ///
  /// 此方法会阻塞 Dart 线程直到用户选中菜单项或关闭菜单
  /// （与 tray_manager 的行为一致）。选中后自动调用对应
  /// [MyTrayMenuItem.onTap] 回调。
  static Future<void> showPopup(List<MyTrayMenuItem> items) async {
    if (!_initialized) return;

    final (hMenu, idMap) = _buildNativeMenu(items);
    final pPoint = calloc<_WinPoint>();

    try {
      _getCursorPos(pPoint);
      final x = pPoint.ref.x;
      final y = pPoint.ref.y;

      final windowId = await windowManager.getId();

      final flags = _getSmartFlags() | _tpmReturnCmd | _tpmRightButton;

      // SetForegroundWindow 解决点击菜单外区域时菜单不关闭的问题
      _setForegroundWindow(windowId);

      // TrackPopupMenu 阻塞至用户选择或关闭；TPM_RETURNCMD 使其返回被选条目 ID
      final selectedId = _trackPopupMenu(
        hMenu,
        flags,
        x,
        y,
        0,
        windowId,
        nullptr,
      );

      // WM_NULL 确保菜单关闭后焦点正确恢复
      _postMessageW(windowId, _wmNull, 0, 0);

      if (selectedId > 0 && idMap.containsKey(selectedId)) {
        final item = idMap[selectedId]!;
        if (item.onTap != null && item.enabled) {
          try {
            await item.onTap!();
          } catch (e, s) {
            XlyLogger.error('TrayPopupHelper: 菜单项回调错误', e, s);
          }
        }
      }
    } finally {
      calloc.free(pPoint);
      _destroyMenu(hMenu);
    }
  }

  /// 释放资源
  static void dispose() {
    _user32 = null;
    _shell32 = null;
    _initialized = false;
  }
}
