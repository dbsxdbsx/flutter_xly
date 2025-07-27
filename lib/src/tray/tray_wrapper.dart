import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'my_tray.dart';

/// 托盘包装器组件
class MyTrayWrapper extends StatefulWidget {
  final Widget child;
  final bool enableMinimizeToTray;
  final String? defaultIcon;
  final String? defaultTooltip;
  final List<MyTrayMenuItem>? defaultMenuItems;

  const MyTrayWrapper({
    super.key,
    required this.child,
    this.enableMinimizeToTray = true,
    this.defaultIcon,
    this.defaultTooltip,
    this.defaultMenuItems,
  });

  @override
  State<MyTrayWrapper> createState() => _MyTrayWrapperState();
}

class _MyTrayWrapperState extends State<MyTrayWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeTray();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 初始化托盘
  Future<void> _initializeTray() async {
    if (!_isDesktop()) return;

    try {
      // MyTray现在通过构造函数自动初始化，无需手动调用initialize
      if (kDebugMode) {
        print('MyTrayWrapper: MyTray服务已注册并自动初始化');
      }
    } catch (e) {
      if (kDebugMode) {
        print('MyTrayWrapper: 初始化失败: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  /// 检查是否为桌面平台
  bool _isDesktop() {
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }
}
