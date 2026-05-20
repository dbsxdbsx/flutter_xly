part of '../../xly.dart';

mixin MyAppDocking {
  /// 停靠窗口到指定角落（简单对齐，不隐藏）
  ///
  /// [corner] 要停靠到的角落位置
  /// 返回 true 表示停靠成功，false 表示停靠失败
  ///
  /// **注意**: 此方法仅将窗口对齐到角落位置，不会隐藏窗口或提供鼠标交互。
  /// 如需类似QQ的智能停靠功能（自动隐藏/显示），请使用 [setSmartEdgeDocking]。
  ///
  /// 此方法会自动检测屏幕工作区域，避开任务栏。
  ///
  /// 使用场景：
  /// - 简单的窗口定位需求
  /// - 不需要隐藏/显示交互的场景
  /// - 一次性窗口位置调整
  ///
  /// 示例：
  /// ```dart
  /// // 将窗口对齐到左上角
  /// await MyApp.dockToCorner(WindowCorner.topLeft);
  /// ```
  static Future<bool> dockToCorner(WindowCorner corner) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 获取DPI缩放因子来修正位置精度
      final scaleFactor = display.scaleFactor ?? 1.0;

      // 计算边框偏移量（Windows窗口可能有不可见边框）
      // 在高DPI环境下，通常需要微调更多像素来达到完美贴边
      // 根据用户反馈，增加偏移量以获得更好的贴边效果
      final edgeOffset = scaleFactor > 1.0 ? 16.0 / scaleFactor : 10.0;

      // 顶部边缘需要额外的偏移，因为Windows标题栏区域的处理方式不同
      // final topEdgeOffset = scaleFactor > 1.0 ? 20.0 / scaleFactor : 14.0;
      XlyLogger.debug('scaleFactor: $scaleFactor, edgeOffset: $edgeOffset');
      final topEdgeOffset = edgeOffset - 0.95 * edgeOffset;

      late Offset position;
      switch (corner) {
        case WindowCorner.topLeft:
          position = Offset(
            workAreaPosition.dx - edgeOffset,
            workAreaPosition.dy - topEdgeOffset,
          );
          break;
        case WindowCorner.topRight:
          position = Offset(
            workAreaPosition.dx +
                workArea.width -
                windowSize.width +
                edgeOffset,
            workAreaPosition.dy - topEdgeOffset,
          );
          break;
        case WindowCorner.bottomLeft:
          position = Offset(
            workAreaPosition.dx - edgeOffset,
            workAreaPosition.dy +
                workArea.height -
                windowSize.height +
                edgeOffset,
          );
          break;
        case WindowCorner.bottomRight:
          position = Offset(
            workAreaPosition.dx +
                workArea.width -
                windowSize.width +
                edgeOffset,
            workAreaPosition.dy +
                workArea.height -
                windowSize.height +
                edgeOffset,
          );
          break;
      }

      // 确保位置值是整数，避免亚像素定位问题
      final adjustedPosition = Offset(
        position.dx.roundToDouble(),
        position.dy.roundToDouble(),
      );

      await windowManager.setPosition(adjustedPosition);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 启用窗口边缘停靠功能（类似QQ的停靠行为）
  ///
  /// [edge] 要停靠到的边缘位置
  /// [visibleWidth] 停靠时可见的窗口宽度（像素），默认为5像素
  /// [hoverDelay] 鼠标悬停多久后显示窗口（毫秒），默认300毫秒
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此功能会：
  /// 1. 将窗口移动到指定边缘，大部分隐藏，只留小部分可见
  /// 2. 监听鼠标位置，当鼠标悬停在可见部分时显示完整窗口
  /// 3. 当鼠标离开窗口区域时，重新隐藏到边缘
  static Future<bool> enableEdgeDocking({
    required WindowEdge edge,
    double visibleWidth = 5.0,
    int hoverDelay = 300,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置
      Offset dockPosition;
      switch (edge) {
        case WindowEdge.left:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          break;
        case WindowEdge.right:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          break;
        case WindowEdge.top:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy - windowSize.height + visibleWidth,
          );
          break;
        case WindowEdge.bottom:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy + workArea.height - visibleWidth,
          );
          break;
      }

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      // 启动鼠标位置监听
      _startMousePositionMonitoring(
        edge: edge,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleWidth: visibleWidth,
        hoverDelay: hoverDelay,
        workAreaPosition: workAreaPosition,
        workArea: workArea,
      );

      return true;
    } catch (e) {
      XlyLogger.error('启用边缘停靠失败', e);
      return false;
    }
  }

  /// 禁用窗口边缘停靠功能
  static void disableEdgeDocking() {
    _mouseMonitorTimer?.cancel();
    _mouseMonitorTimer = null;
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _isEdgeDockingEnabled = false;

    // 停止智能停靠管理器
    SmartDockManager.stopAll();
  }

  // 私有变量用于鼠标监听
  static Timer? _mouseMonitorTimer;
  static Timer? _hoverTimer;
  static bool _isEdgeDockingEnabled = false;
  static bool _isWindowExpanded = false;
  static Offset? _dockPosition;
  static Offset? _expandPosition;

  /// 开始监听鼠标位置
  static void _startMousePositionMonitoring({
    required WindowEdge edge,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleWidth,
    required int hoverDelay,
    required Offset workAreaPosition,
    required Size workArea,
  }) {
    _isEdgeDockingEnabled = true;
    _dockPosition = dockPosition;

    // 计算展开位置
    switch (edge) {
      case WindowEdge.left:
        _expandPosition = Offset(workAreaPosition.dx, dockPosition.dy);
        break;
      case WindowEdge.right:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          dockPosition.dy,
        );
        break;
      case WindowEdge.top:
        _expandPosition = Offset(dockPosition.dx, workAreaPosition.dy);
        break;
      case WindowEdge.bottom:
        _expandPosition = Offset(
          dockPosition.dx,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
    }

    // 定期检查鼠标位置（每100毫秒检查一次）
    _mouseMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkMousePosition(
        edge: edge,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleWidth: visibleWidth,
        hoverDelay: hoverDelay,
      ),
    );
  }

  /// 检查鼠标位置并处理窗口显示/隐藏
  static void _checkMousePosition({
    required WindowEdge edge,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleWidth,
    required int hoverDelay,
  }) async {
    if (!_isEdgeDockingEnabled) return;

    try {
      // 获取当前鼠标位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      // 计算可见区域的边界
      Rect visibleArea;
      switch (edge) {
        case WindowEdge.left:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - visibleWidth,
            dockPosition.dy,
            visibleWidth,
            windowSize.height,
          );
          break;
        case WindowEdge.right:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            visibleWidth,
            windowSize.height,
          );
          break;
        case WindowEdge.top:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy + windowSize.height - visibleWidth,
            windowSize.width,
            visibleWidth,
          );
          break;
        case WindowEdge.bottom:
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            windowSize.width,
            visibleWidth,
          );
          break;
      }

      // 检查鼠标是否在可见区域内
      final isMouseInVisibleArea = visibleArea.contains(mousePosition);

      if (isMouseInVisibleArea && !_isWindowExpanded) {
        // 鼠标进入可见区域，启动悬停计时器
        _hoverTimer?.cancel();
        _hoverTimer = Timer(Duration(milliseconds: hoverDelay), () {
          _expandWindow();
        });
      } else if (!isMouseInVisibleArea && _isWindowExpanded) {
        // 鼠标离开窗口区域，检查是否需要收缩
        final windowArea = Rect.fromLTWH(
          _expandPosition!.dx,
          _expandPosition!.dy,
          windowSize.width,
          windowSize.height,
        );

        if (!windowArea.contains(mousePosition)) {
          _hoverTimer?.cancel();
          _collapseWindow();
        }
      }
    } catch (e) {
      XlyLogger.error('检查鼠标位置时出错', e);
    }
  }

  /// 展开窗口
  static Future<void> _expandWindow() async {
    if (_expandPosition == null) return;

    try {
      await windowManager.setPosition(_expandPosition!);
      _isWindowExpanded = true;
    } catch (e) {
      XlyLogger.error('展开窗口时出错', e);
    }
  }

  /// 收缩窗口到停靠位置
  static Future<void> _collapseWindow() async {
    if (_dockPosition == null) return;

    try {
      await windowManager.setPosition(_dockPosition!);
      _isWindowExpanded = false;
    } catch (e) {
      XlyLogger.error('收缩窗口时出错', e);
    }
  }

  /// 获取当前鼠标位置（相对于屏幕）
  static Future<Offset?> _getMousePosition() async {
    try {
      // 使用screen_retriever包获取真实的鼠标光标位置
      final cursorPosition = await screenRetriever.getCursorScreenPoint();
      return cursorPosition;
    } catch (e) {
      XlyLogger.error('获取鼠标位置失败', e);
      return null;
    }
  }

  /// 简化版边缘停靠功能（基于窗口焦点事件）
  ///
  /// [edge] 要停靠到的边缘位置
  /// [visibleWidth] 停靠时可见的窗口宽度（像素），默认为5像素
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此版本使用窗口焦点事件来控制显示/隐藏，更简单但功能略有限制
  static Future<bool> enableSimpleEdgeDocking({
    required WindowEdge edge,
    double visibleWidth = 5.0,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置
      Offset dockPosition;
      Offset expandPosition;

      switch (edge) {
        case WindowEdge.left:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          expandPosition = Offset(workAreaPosition.dx, dockPosition.dy);
          break;
        case WindowEdge.right:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - visibleWidth,
            workAreaPosition.dy + (workArea.height - windowSize.height) / 2,
          );
          expandPosition = Offset(
            workAreaPosition.dx + workArea.width - windowSize.width,
            dockPosition.dy,
          );
          break;
        case WindowEdge.top:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy - windowSize.height + visibleWidth,
          );
          expandPosition = Offset(dockPosition.dx, workAreaPosition.dy);
          break;
        case WindowEdge.bottom:
          dockPosition = Offset(
            workAreaPosition.dx + (workArea.width - windowSize.width) / 2,
            workAreaPosition.dy + workArea.height - visibleWidth,
          );
          expandPosition = Offset(
            dockPosition.dx,
            workAreaPosition.dy + workArea.height - windowSize.height,
          );
          break;
      }

      // 保存位置信息
      _dockPosition = dockPosition;
      _expandPosition = expandPosition;
      _isEdgeDockingEnabled = true;
      _isWindowExpanded = false;

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      return true;
    } catch (e) {
      XlyLogger.error('启用简单边缘停靠失败', e);
      return false;
    }
  }

  /// 手动展开停靠的窗口
  static Future<void> expandDockedWindow() async {
    if (!_isEdgeDockingEnabled || _isWindowExpanded) return;
    await _expandWindow();
  }

  /// 手动收缩窗口到停靠位置
  static Future<void> collapseDockedWindow() async {
    if (!_isEdgeDockingEnabled || !_isWindowExpanded) return;
    await _collapseWindow();
  }

  /// 切换停靠窗口的展开/收缩状态
  static Future<void> toggleDockedWindow() async {
    if (!_isEdgeDockingEnabled) return;

    if (_isWindowExpanded) {
      await collapseDockedWindow();
    } else {
      await expandDockedWindow();
    }
  }

  /// 启用角落停靠功能（类似QQ的角落停靠行为）
  ///
  /// [corner] 要停靠到的角落位置
  /// [visibleSize] 停靠时可见的窗口尺寸（像素），默认为20x20像素
  /// [hoverDelay] 鼠标悬停多久后显示窗口（毫秒），默认300毫秒
  /// 返回 true 表示启用成功，false 表示启用失败
  ///
  /// 此功能会：
  /// 1. 将窗口移动到指定角落，大部分隐藏，只留小部分可见
  /// 2. 监听鼠标位置，当鼠标悬停在可见部分时显示完整窗口
  /// 3. 当鼠标离开窗口区域时，重新隐藏到角落
  static Future<bool> enableCornerDocking({
    required WindowCorner corner,
    double visibleSize = 20.0,
    int hoverDelay = 300,
  }) async {
    if (!MyPlatform.isDesktop) return false;

    try {
      final display = await screenRetriever.getPrimaryDisplay();
      if (display.visiblePosition == null || display.visibleSize == null) {
        return false;
      }

      final windowSize = await windowManager.getSize();
      final workArea = display.visibleSize!;
      final workAreaPosition = display.visiblePosition!;

      // 计算停靠位置（角落位置，大部分隐藏）
      // 角落停靠时露出一个L形区域，比正方形更容易找到
      final cornerVisibleWidth = visibleSize * 2; // 水平方向可见宽度
      final cornerVisibleHeight = visibleSize; // 垂直方向可见高度

      Offset dockPosition;
      switch (corner) {
        case WindowCorner.topLeft:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + cornerVisibleWidth,
            workAreaPosition.dy - windowSize.height + cornerVisibleHeight,
          );
          break;
        case WindowCorner.topRight:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - cornerVisibleWidth,
            workAreaPosition.dy - windowSize.height + cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomLeft:
          dockPosition = Offset(
            workAreaPosition.dx - windowSize.width + cornerVisibleWidth,
            workAreaPosition.dy + workArea.height - cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomRight:
          dockPosition = Offset(
            workAreaPosition.dx + workArea.width - cornerVisibleWidth,
            workAreaPosition.dy + workArea.height - cornerVisibleHeight,
          );
          break;
      }

      // 移动窗口到停靠位置
      await windowManager.setPosition(dockPosition);

      // 启动鼠标位置监听
      _startCornerMousePositionMonitoring(
        corner: corner,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleSize: visibleSize,
        hoverDelay: hoverDelay,
        workAreaPosition: workAreaPosition,
        workArea: workArea,
      );

      return true;
    } catch (e) {
      XlyLogger.error('启用角落停靠失败', e);
      return false;
    }
  }

  /// 启用/禁用智能停靠机制（类似QQ的智能停靠功能）
  ///
  /// [enabled] 是否启用智能停靠
  /// [visibleWidth] 停靠时可见的宽度（默认5像素）
  ///
  /// **与 [dockToCorner] 的区别**：
  /// - [dockToCorner]: 仅对齐到角落，不隐藏，无鼠标交互
  /// - [setSmartEdgeDocking]: 自动检测 + 智能隐藏 + 鼠标交互
  ///
  /// **智能停靠行为**：
  /// 1. **自动检测**: 监听窗口拖拽，当窗口超出屏幕边界时自动触发
  /// 2. **两步式停靠**: 先对齐到目标位置，再根据鼠标位置智能隐藏
  /// 3. **智能判断**:
  ///    - 窗口同时超出两个相邻边界（如左边和上边）→ 角落停靠
  ///    - 窗口只超出一个边界 → 边缘停靠
  /// 4. **鼠标交互**: 鼠标悬停显示完整窗口，离开后自动隐藏
  ///
  /// **使用场景**：
  /// - 需要类似QQ的智能停靠体验
  /// - 希望窗口能自动隐藏以节省屏幕空间
  /// - 需要鼠标悬停交互的应用
  ///
  /// **示例**：
  /// ```dart
  /// // 启用智能停靠
  /// await MyApp.setSmartEdgeDocking(enabled: true, visibleWidth: 8.0);
  ///
  /// // 禁用智能停靠
  /// await MyApp.setSmartEdgeDocking(enabled: false);
  /// ```
  static Future<void> setSmartEdgeDocking({
    required bool enabled,
    double visibleWidth = 5.0,
  }) async {
    await SmartDockManager.setSmartEdgeDocking(
      enabled: enabled,
      visibleWidth: visibleWidth,
    );
  }

  /// 获取智能边缘停靠的启用状态
  static bool isSmartDockingEnabled() {
    return SmartDockManager.isSmartDockingEnabled();
  }

  /// 开始监听角落停靠的鼠标位置
  static void _startCornerMousePositionMonitoring({
    required WindowCorner corner,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleSize,
    required int hoverDelay,
    required Offset workAreaPosition,
    required Size workArea,
  }) {
    _isEdgeDockingEnabled = true;
    _dockPosition = dockPosition;

    // 计算展开位置（完整显示在角落）
    switch (corner) {
      case WindowCorner.topLeft:
        _expandPosition = Offset(workAreaPosition.dx, workAreaPosition.dy);
        break;
      case WindowCorner.topRight:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy,
        );
        break;
      case WindowCorner.bottomLeft:
        _expandPosition = Offset(
          workAreaPosition.dx,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
      case WindowCorner.bottomRight:
        _expandPosition = Offset(
          workAreaPosition.dx + workArea.width - windowSize.width,
          workAreaPosition.dy + workArea.height - windowSize.height,
        );
        break;
    }

    // 定期检查鼠标位置（每100毫秒检查一次）
    _mouseMonitorTimer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) => _checkCornerMousePosition(
        corner: corner,
        dockPosition: dockPosition,
        windowSize: windowSize,
        visibleSize: visibleSize,
        hoverDelay: hoverDelay,
      ),
    );
  }

  /// 检查角落停靠的鼠标位置
  static void _checkCornerMousePosition({
    required WindowCorner corner,
    required Offset dockPosition,
    required Size windowSize,
    required double visibleSize,
    required int hoverDelay,
  }) async {
    if (!_isEdgeDockingEnabled) return;

    try {
      // 获取当前鼠标位置
      final mousePosition = await _getMousePosition();
      if (mousePosition == null) return;

      // 计算可见区域的边界（角落的L形区域）
      // 创建一个更大的矩形区域，便于鼠标悬停
      final cornerVisibleWidth = visibleSize * 2;
      final cornerVisibleHeight = visibleSize;

      Rect visibleArea;
      switch (corner) {
        case WindowCorner.topLeft:
          // 左上角：露出右下角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - cornerVisibleWidth,
            dockPosition.dy + windowSize.height - cornerVisibleHeight,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.topRight:
          // 右上角：露出左下角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy + windowSize.height - cornerVisibleHeight,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomLeft:
          // 左下角：露出右上角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx + windowSize.width - cornerVisibleWidth,
            dockPosition.dy,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
        case WindowCorner.bottomRight:
          // 右下角：露出左上角的矩形区域
          visibleArea = Rect.fromLTWH(
            dockPosition.dx,
            dockPosition.dy,
            cornerVisibleWidth,
            cornerVisibleHeight,
          );
          break;
      }

      // 检查鼠标是否在可见区域内
      final isMouseInVisibleArea = visibleArea.contains(mousePosition);

      if (isMouseInVisibleArea && !_isWindowExpanded) {
        // 鼠标进入可见区域，启动悬停计时器
        _hoverTimer?.cancel();
        _hoverTimer = Timer(Duration(milliseconds: hoverDelay), () {
          _expandWindow();
        });
      } else if (!isMouseInVisibleArea && _isWindowExpanded) {
        // 鼠标离开窗口区域，检查是否需要收缩
        final windowArea = Rect.fromLTWH(
          _expandPosition!.dx,
          _expandPosition!.dy,
          windowSize.width,
          windowSize.height,
        );

        if (!windowArea.contains(mousePosition)) {
          _hoverTimer?.cancel();
          _collapseWindow();
        }
      }
    } catch (e) {
      XlyLogger.error('检查角落鼠标位置时出错', e);
    }
  }
}
