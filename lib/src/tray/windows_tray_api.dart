import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:win32/win32.dart';
import 'package:window_manager/window_manager.dart';

/// Windows 托盘 API 封装（原生实现）
///
/// 使用Windows Shell API直接实现系统托盘功能
class WindowsTrayApi {
  static bool _isInitialized = false;
  static String? _currentIconPath;
  static const int _trayId = 1;
  static int? _hwnd;
  static const int wmTrayIcon = WM_USER + 1;

  // 托盘点击事件回调
  static void Function()? _onTrayIconClick;
  static void Function()? _onTrayIconRightClick;

  /// 初始化托盘
  static bool initialize() {
    if (!Platform.isWindows) return false;
    if (_isInitialized) return true;

    try {
      // 获取当前窗口句柄
      _hwnd = GetActiveWindow();
      if (_hwnd == 0) {
        // 如果获取不到活动窗口，尝试获取前台窗口
        _hwnd = GetForegroundWindow();
      }

      if (_hwnd == 0) {
        if (kDebugMode) {
          print('WindowsTrayApi: 无法获取窗口句柄');
        }
        return false;
      }

      _isInitialized = true;
      if (kDebugMode) {
        print('WindowsTrayApi: 初始化成功，窗口句柄: $_hwnd');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 初始化失败: $e');
      }
      return false;
    }
  }

  /// 添加托盘图标（原生实现）
  static bool addTrayIcon(String iconPath, {String? tooltip}) {
    if (!_isInitialized || _hwnd == null) return false;

    try {
      // 验证图标文件存在性
      if (!File(iconPath).existsSync()) {
        if (kDebugMode) {
          print('WindowsTrayApi: 图标文件不存在: $iconPath');
        }
        return false;
      }

      // 加载图标
      final iconPathPtr = iconPath.toNativeUtf16();
      final hIcon = LoadImage(
        0, // hInst
        iconPathPtr, // name
        GDI_IMAGE_TYPE.IMAGE_ICON, // type
        0, // cx
        0, // cy
        IMAGE_FLAGS.LR_LOADFROMFILE | IMAGE_FLAGS.LR_DEFAULTSIZE, // fuLoad
      );

      calloc.free(iconPathPtr);

      if (hIcon == 0) {
        if (kDebugMode) {
          print('WindowsTrayApi: 加载图标失败: $iconPath');
        }
        return false;
      }

      // 创建NOTIFYICONDATA结构
      final nid = calloc<NOTIFYICONDATA>();
      nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
      nid.ref.hWnd = _hwnd!;
      nid.ref.uID = _trayId;
      nid.ref.uFlags = NOTIFY_ICON_DATA_FLAGS.NIF_ICON |
          NOTIFY_ICON_DATA_FLAGS.NIF_MESSAGE |
          NOTIFY_ICON_DATA_FLAGS.NIF_TIP;
      nid.ref.uCallbackMessage = wmTrayIcon;
      nid.ref.hIcon = hIcon;

      // 设置工具提示 - 暂时跳过，先让基本功能工作
      // TODO: 实现tooltip设置

      // 添加托盘图标
      final result = Shell_NotifyIcon(NOTIFY_ICON_MESSAGE.NIM_ADD, nid);
      calloc.free(nid);

      if (result != 0) {
        _currentIconPath = iconPath;
        if (kDebugMode) {
          print('WindowsTrayApi: 托盘图标已添加: $iconPath');
          if (tooltip != null) {
            print('WindowsTrayApi: 工具提示: $tooltip');
          }
        }
        return true;
      } else {
        if (kDebugMode) {
          print('WindowsTrayApi: Shell_NotifyIcon 调用失败');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 添加托盘图标失败: $e');
      }
      return false;
    }
  }

  /// 更新托盘图标（原生实现）
  static bool updateTrayIcon(String iconPath) {
    if (!_isInitialized || _hwnd == null) return false;

    try {
      // 验证图标文件存在性
      if (!File(iconPath).existsSync()) {
        if (kDebugMode) {
          print('WindowsTrayApi: 图标文件不存在: $iconPath');
        }
        return false;
      }

      // 加载新图标
      final iconPathPtr = iconPath.toNativeUtf16();
      final hIcon = LoadImage(
        0,
        iconPathPtr,
        GDI_IMAGE_TYPE.IMAGE_ICON,
        0,
        0,
        IMAGE_FLAGS.LR_LOADFROMFILE | IMAGE_FLAGS.LR_DEFAULTSIZE,
      );

      calloc.free(iconPathPtr);

      if (hIcon == 0) {
        if (kDebugMode) {
          print('WindowsTrayApi: 加载新图标失败: $iconPath');
        }
        return false;
      }

      // 更新托盘图标
      final nid = calloc<NOTIFYICONDATA>();
      nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
      nid.ref.hWnd = _hwnd!;
      nid.ref.uID = _trayId;
      nid.ref.uFlags = NOTIFY_ICON_DATA_FLAGS.NIF_ICON;
      nid.ref.hIcon = hIcon;

      final result = Shell_NotifyIcon(NOTIFY_ICON_MESSAGE.NIM_MODIFY, nid);
      calloc.free(nid);

      if (result != 0) {
        _currentIconPath = iconPath;
        if (kDebugMode) {
          print('WindowsTrayApi: 托盘图标已更新: $iconPath');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('WindowsTrayApi: 更新托盘图标失败');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 更新托盘图标失败: $e');
      }
      return false;
    }
  }

  /// 显示托盘通知（模拟实现）
  static bool showNotification(String title, String message) {
    if (!_isInitialized) return false;

    try {
      if (kDebugMode) {
        print('WindowsTrayApi: 托盘通知 - $title: $message');
      }

      // 这里可以集成其他通知库，如 flutter_local_notifications
      // 或者使用 Windows Toast 通知

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 显示通知失败: $e');
      }
      return false;
    }
  }

  /// 删除托盘图标（原生实现）
  static bool removeTrayIcon() {
    if (!_isInitialized || _hwnd == null) return false;

    try {
      // 删除托盘图标
      final nid = calloc<NOTIFYICONDATA>();
      nid.ref.cbSize = sizeOf<NOTIFYICONDATA>();
      nid.ref.hWnd = _hwnd!;
      nid.ref.uID = _trayId;

      final result = Shell_NotifyIcon(NOTIFY_ICON_MESSAGE.NIM_DELETE, nid);
      calloc.free(nid);

      if (result != 0) {
        _currentIconPath = null;
        if (kDebugMode) {
          print('WindowsTrayApi: 托盘图标已删除');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('WindowsTrayApi: 删除托盘图标失败');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 删除托盘图标失败: $e');
      }
      return false;
    }
  }

  /// 隐藏窗口
  static bool hideWindow() {
    try {
      windowManager.hide();

      if (kDebugMode) {
        print('WindowsTrayApi: 窗口已隐藏');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 隐藏窗口失败: $e');
      }
      return false;
    }
  }

  /// 显示窗口
  static bool showWindow() {
    try {
      windowManager.show();
      windowManager.focus();

      if (kDebugMode) {
        print('WindowsTrayApi: 窗口已显示');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 显示窗口失败: $e');
      }
      return false;
    }
  }

  /// 设置托盘图标点击回调
  static void setOnTrayIconClick(void Function()? callback) {
    _onTrayIconClick = callback;
  }

  /// 设置托盘图标右键点击回调
  static void setOnTrayIconRightClick(void Function()? callback) {
    _onTrayIconRightClick = callback;
  }

  /// 处理托盘图标消息
  static bool handleTrayMessage(int message, int wParam, int lParam) {
    if (!_isInitialized || message != wmTrayIcon) return false;

    try {
      // 检查是否是我们的托盘图标
      if (wParam != _trayId) return false;

      // 处理不同的鼠标事件
      switch (lParam) {
        case WM_LBUTTONUP: // 左键单击
          if (_onTrayIconClick != null) {
            _onTrayIconClick!();
            if (kDebugMode) {
              print('WindowsTrayApi: 处理托盘图标左键点击');
            }
          }
          return true;

        case WM_RBUTTONUP: // 右键单击
          if (_onTrayIconRightClick != null) {
            _onTrayIconRightClick!();
            if (kDebugMode) {
              print('WindowsTrayApi: 处理托盘图标右键点击');
            }
          }
          return true;

        case WM_LBUTTONDBLCLK: // 左键双击
          if (_onTrayIconClick != null) {
            _onTrayIconClick!();
            if (kDebugMode) {
              print('WindowsTrayApi: 处理托盘图标左键双击');
            }
          }
          return true;

        default:
          return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('WindowsTrayApi: 处理托盘消息失败: $e');
      }
      return false;
    }
  }

  /// 清理资源
  static void cleanup() {
    if (_isInitialized) {
      removeTrayIcon();
      _isInitialized = false;
      _currentIconPath = null;
      _hwnd = null;
      _onTrayIconClick = null;
      _onTrayIconRightClick = null;

      if (kDebugMode) {
        print('WindowsTrayApi: 资源已清理');
      }
    }
  }

  /// 获取当前图标路径
  static String? get currentIconPath => _currentIconPath;

  /// 检查是否已初始化
  static bool get isInitialized => _isInitialized;
}
