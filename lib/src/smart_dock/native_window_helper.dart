import 'dart:ffi';
import 'dart:io';

import 'package:window_manager/window_manager.dart';

import '../logger.dart';

/// 原生窗口助手
///
/// 提供更精确的Windows API调用，解决智能停靠时的窗口激活问题
class NativeWindowHelper {
  static DynamicLibrary? _user32;
  static bool _initialized = false;

  /// 初始化原生库
  static void initialize() {
    if (_initialized || !Platform.isWindows) return;

    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _initialized = true;
      XlyLogger.info('原生窗口助手：已初始化');
    } catch (e) {
      XlyLogger.error('原生窗口助手：初始化失败', e);
    }
  }

  /// 设置窗口为智能停靠层级（在任务栏下方但在其他应用上方）
  ///
  /// 使用Windows API的 SetWindowPos 配合特殊的Z-order管理
  /// 解决智能停靠时的任务栏冲突和闪烁问题
  static Future<bool> setSmartDockLevel(bool enable) async {
    if (!Platform.isWindows || !_initialized || _user32 == null) {
      // 回退到标准方法
      await windowManager.setAlwaysOnTop(enable);
      return true;
    }

    try {
      // 获取当前窗口句柄
      final windowId = await windowManager.getId();
      final hwnd = Pointer<IntPtr>.fromAddress(windowId);

      // 定义Windows API常量
      // ignore: constant_identifier_names
      const int HWND_TOPMOST = -1;
      // ignore: constant_identifier_names
      const int HWND_NOTOPMOST = -2;
      // ignore: constant_identifier_names
      const int SWP_NOMOVE = 0x0002;
      // ignore: constant_identifier_names
      const int SWP_NOSIZE = 0x0001;
      // ignore: constant_identifier_names
      const int SWP_NOACTIVATE = 0x0010;
      // ignore: constant_identifier_names
      const int SWP_SHOWWINDOW = 0x0040;

      // 获取SetWindowPos函数
      final setWindowPos = _user32!.lookupFunction<
          Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
          int Function(int, int, int, int, int, int, int)>('SetWindowPos');

      int zOrder;
      if (enable) {
        // 智能停靠模式：设置为TOPMOST但会被任务栏覆盖
        // 这样既能显示在其他应用上方，又不会覆盖任务栏
        zOrder = HWND_TOPMOST;
      } else {
        // 禁用智能停靠：恢复正常层级
        zOrder = HWND_NOTOPMOST;
      }

      final result = setWindowPos(
        hwnd.address,
        zOrder,
        0, // x
        0, // y
        0, // width
        0, // height
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
      );

      if (result != 0) {
        XlyLogger.debug('原生窗口助手：成功设置智能停靠层级：$enable');
        return true;
      } else {
        XlyLogger.warning('原生窗口助手：设置智能停靠层级失败，回退到标准方法');
        await windowManager.setAlwaysOnTop(enable);
        return false;
      }
    } catch (e) {
      XlyLogger.warning('原生窗口助手：设置智能停靠层级出错：$e，回退到标准方法');
      await windowManager.setAlwaysOnTop(enable);
      return false;
    }
  }

  /// 设置窗口为置顶但不激活（保持兼容性）
  static Future<bool> setAlwaysOnTopNoActivate(bool alwaysOnTop) async {
    return await setSmartDockLevel(alwaysOnTop);
  }

  /// 显示窗口但不激活
  ///
  /// 使用 SW_SHOWNOACTIVATE 标志显示窗口
  static Future<bool> showWindowNoActivate() async {
    if (!Platform.isWindows || !_initialized || _user32 == null) {
      // 回退到标准方法
      await windowManager.show(inactive: true);
      return true;
    }

    try {
      // 获取当前窗口句柄
      final windowId = await windowManager.getId();
      final hwnd = Pointer<IntPtr>.fromAddress(windowId);

      // 定义Windows API常量
      // ignore: constant_identifier_names
      const int SW_SHOWNOACTIVATE = 4;

      // 获取ShowWindow函数
      final showWindow = _user32!.lookupFunction<Int32 Function(IntPtr, Int32),
          int Function(int, int)>('ShowWindow');

      final result = showWindow(hwnd.address, SW_SHOWNOACTIVATE);

      XlyLogger.debug('原生窗口助手：显示窗口（无激活）：$result');
      return result != 0;
    } catch (e) {
      XlyLogger.warning('原生窗口助手：显示窗口出错：$e，回退到标准方法');
      await windowManager.show(inactive: true);
      return false;
    }
  }

  /// 设置窗口在任务栏下方但在其他应用上方
  ///
  /// 这是解决智能停靠任务栏冲突的关键方法
  static Future<bool> setBelowTaskbarButAboveOthers() async {
    if (!Platform.isWindows || !_initialized || _user32 == null) {
      // 非Windows平台或初始化失败，使用标准方法
      await windowManager.setAlwaysOnTop(true);
      return true;
    }

    try {
      // 获取当前窗口句柄
      final windowId = await windowManager.getId();
      final hwnd = Pointer<IntPtr>.fromAddress(windowId);

      // 定义Windows API常量
      // ignore: constant_identifier_names
      const int HWND_TOPMOST = -1;
      // ignore: constant_identifier_names
      const int SWP_NOMOVE = 0x0002;
      // ignore: constant_identifier_names
      const int SWP_NOSIZE = 0x0001;
      // ignore: constant_identifier_names
      const int SWP_NOACTIVATE = 0x0010;
      // ignore: constant_identifier_names
      const int SWP_SHOWWINDOW = 0x0040;

      // 获取SetWindowPos函数
      final setWindowPos = _user32!.lookupFunction<
          Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
          int Function(int, int, int, int, int, int, int)>('SetWindowPos');

      // 第一步：设置为TOPMOST（这会让窗口在所有普通窗口之上）
      final result1 = setWindowPos(
        hwnd.address,
        HWND_TOPMOST,
        0,
        0,
        0,
        0,
        SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_SHOWWINDOW,
      );

      if (result1 != 0) {
        XlyLogger.debug('原生窗口助手：成功设置窗口在任务栏下方但在其他应用上方');
        return true;
      } else {
        XlyLogger.warning('原生窗口助手：设置窗口层级失败，回退到标准方法');
        await windowManager.setAlwaysOnTop(true);
        return false;
      }
    } catch (e) {
      XlyLogger.warning('原生窗口助手：设置窗口层级出错：$e，回退到标准方法');
      await windowManager.setAlwaysOnTop(true);
      return false;
    }
  }

  /// 设置窗口为不激活任务栏模式
  ///
  /// 使用 WS_EX_NOACTIVATE 扩展样式防止窗口激活系统任务栏
  /// 主要用于托盘模式下的智能停靠窗口
  static Future<bool> setNoActivateTaskbar(bool enable) async {
    if (!Platform.isWindows || !_initialized || _user32 == null) {
      XlyLogger.debug('原生窗口助手：非Windows平台或未初始化，跳过任务栏激活控制');
      return true;
    }

    try {
      // 获取当前窗口句柄
      final windowId = await windowManager.getId();
      final hwnd = Pointer<IntPtr>.fromAddress(windowId);

      // 定义Windows API常量
      // ignore: constant_identifier_names
      const int GWL_EXSTYLE = -20;
      // ignore: constant_identifier_names
      const int WS_EX_NOACTIVATE = 0x08000000;

      // 获取Windows API函数
      final getWindowLongPtr = _user32!.lookupFunction<
          IntPtr Function(IntPtr, Int32),
          int Function(int, int)>('GetWindowLongPtrW');
      final setWindowLongPtr = _user32!.lookupFunction<
          IntPtr Function(IntPtr, Int32, IntPtr),
          int Function(int, int, int)>('SetWindowLongPtrW');

      // 获取当前扩展样式
      final currentExStyle = getWindowLongPtr(hwnd.address, GWL_EXSTYLE);

      int newExStyle;
      if (enable) {
        // 添加 WS_EX_NOACTIVATE 样式
        newExStyle = currentExStyle | WS_EX_NOACTIVATE;
      } else {
        // 移除 WS_EX_NOACTIVATE 样式
        newExStyle = currentExStyle & ~WS_EX_NOACTIVATE;
      }

      final result = setWindowLongPtr(hwnd.address, GWL_EXSTYLE, newExStyle);

      if (result != 0) {
        XlyLogger.debug('原生窗口助手：成功设置不激活任务栏模式：$enable');
        return true;
      } else {
        XlyLogger.warning('原生窗口助手：设置不激活任务栏模式失败');
        return false;
      }
    } catch (e) {
      XlyLogger.error('原生窗口助手：设置不激活任务栏模式出错', e);
      return false;
    }
  }

  /// 清理资源
  static void dispose() {
    _user32 = null;
    _initialized = false;
  }
}
