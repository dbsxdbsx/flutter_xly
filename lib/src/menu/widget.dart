import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart'
    show kPrimaryMouseButton, kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../logger.dart';
import 'menu_models.dart';
import 'style.dart';

// ============================================================================
// 核心菜单管理器
// ============================================================================

/// 菜单管理器 - 负责菜单的显示和生命周期管理
class MyMenu {
  MyMenu._(); // 私有构造函数

  // 全局单例管理器
  static final _MenuStateManager _stateManager = _MenuStateManager();

  /// 显示右键菜单
  ///
  /// [context] - 上下文
  /// [position] - 菜单弹出位置（全局坐标）
  /// [menuElements] - 菜单项列表
  /// [animationStyle] - 动画样式
  /// [style] - 菜单样式
  static Future<void> show(
    BuildContext context,
    Offset position,
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.reveal,
    MyMenuStyle? style,
  }) async {
    style ??= MyMenuStyle.adaptive();
    return _stateManager.showMenu(
      context,
      _PointMenuPosition(position),
      menuElements,
      animationStyle: animationStyle,
      style: style,
      repositionOnSecondaryTap: true,
    );
  }

  /// 以现有控件的全局矩形为锚点显示菜单。
  ///
  /// 菜单优先显示在锚点下方：屏幕右半侧的锚点按右边缘对齐，
  /// 左半侧按左边缘对齐；下方空间不足时自动翻转到上方。
  /// [gap] 是菜单与锚点在垂直方向上的逻辑像素间距。
  ///
  /// 适合 AppBar、工具栏等已有按钮。右键菜单仍应使用 [show]，
  /// 直接以鼠标位置为锚点。
  static Future<void> showAnchored(
    BuildContext context,
    Rect anchorRect,
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.reveal,
    MyMenuStyle? style,
    double gap = 4,
    MyMenuAnchorOrigin anchorOrigin = MyMenuAnchorOrigin.edge,
  }) {
    assert(gap >= 0, 'gap 必须大于等于 0');
    style ??= MyMenuStyle.adaptive();
    return _stateManager.showMenu(
      context,
      _AnchoredMenuPosition(anchorRect, gap: gap, anchorOrigin: anchorOrigin),
      menuElements,
      animationStyle: animationStyle,
      style: style,
      repositionOnSecondaryTap: false,
    );
  }

  /// 计算菜单尺寸（公开方法，供内部使用）
  static Size calculateMenuSize(
    List<MyMenuElement> menuElements,
    MyMenuStyle style,
  ) {
    return _MenuSizeCalculator.calculate(menuElements, style);
  }

  /// 计算菜单位置（公开方法，供内部使用）
  static Offset calculateMenuPosition(
    BuildContext context,
    Offset position,
    Size menuSize, {
    bool isSubMenu = false,
    Size? parentMenuSize,
    double? alignedY,
    double? itemHeightHint,
  }) {
    return _MenuPositionCalculator.calculate(
      context,
      position,
      menuSize,
      isSubMenu: isSubMenu,
      parentMenuSize: parentMenuSize,
      alignedY: alignedY,
      itemHeightHint: itemHeightHint,
    );
  }

  /// 关闭所有菜单
  static void closeAll() {
    _stateManager.closeAll();
  }

  // 内部使用：获取活跃子菜单通知器
  static ValueNotifier<List<OverlayEntry>> get _activeSubMenus =>
      _stateManager.activeSubMenus;
}

class _ResolvedMenuPosition {
  final Offset offset;
  final Alignment growthAlignment;

  const _ResolvedMenuPosition({
    required this.offset,
    required this.growthAlignment,
  });
}

abstract class _MenuPosition {
  const _MenuPosition();

  _ResolvedMenuPosition resolve(
    BuildContext context,
    RenderBox overlayBox,
    Size menuSize,
  );
}

class _PointMenuPosition extends _MenuPosition {
  final Offset globalPosition;

  const _PointMenuPosition(this.globalPosition);

  @override
  _ResolvedMenuPosition resolve(
    BuildContext context,
    RenderBox overlayBox,
    Size menuSize,
  ) {
    final localPosition = overlayBox.globalToLocal(globalPosition);
    final offset = _MenuPositionCalculator.calculate(
      context,
      localPosition,
      menuSize,
    );
    return _ResolvedMenuPosition(
      offset: offset,
      growthAlignment: _MenuPositionCalculator.growthAlignment(
        offset & menuSize,
        Rect.fromCenter(center: localPosition, width: 0, height: 0),
      ),
    );
  }
}

class _AnchoredMenuPosition extends _MenuPosition {
  final Rect globalAnchorRect;
  final double gap;
  final MyMenuAnchorOrigin anchorOrigin;

  const _AnchoredMenuPosition(
    this.globalAnchorRect, {
    required this.gap,
    this.anchorOrigin = MyMenuAnchorOrigin.edge,
  });

  @override
  _ResolvedMenuPosition resolve(
    BuildContext context,
    RenderBox overlayBox,
    Size menuSize,
  ) {
    final localAnchorRect = Rect.fromPoints(
      overlayBox.globalToLocal(globalAnchorRect.topLeft),
      overlayBox.globalToLocal(globalAnchorRect.bottomRight),
    );
    final offset = _MenuPositionCalculator.calculateAnchored(
      localAnchorRect,
      menuSize,
      overlayBox.size,
      gap: gap,
      anchorOrigin: anchorOrigin,
    );
    return _ResolvedMenuPosition(
      offset: offset,
      growthAlignment: _MenuPositionCalculator.growthAlignment(
        offset & menuSize,
        localAnchorRect,
      ),
    );
  }
}

// ============================================================================
// 菜单状态管理器
// ============================================================================

/// 菜单状态管理器 - 管理菜单的状态和生命周期
class _MenuStateManager {
  OverlayEntry? _mainMenuEntry;
  Completer<void>? _menuCompleter;
  LocalHistoryEntry? _historyEntry;
  ModalRoute<dynamic>? _historyRoute;
  MyMenuPopStyle _currentAnimationStyle = MyMenuPopStyle.reveal;

  // 活跃的子菜单列表
  final ValueNotifier<List<OverlayEntry>> activeSubMenus =
      ValueNotifier<List<OverlayEntry>>([]);

  // 主菜单矩形（用于避免子菜单与已有菜单重叠）
  Rect? mainMenuRect;

  // 活跃菜单矩形列表（与 activeSubMenus 一一对应）
  final ValueNotifier<List<Rect>> activeMenuRects =
      ValueNotifier<List<Rect>>([]);

  /// 显示菜单
  Future<void> showMenu(
    BuildContext context,
    _MenuPosition position,
    List<MyMenuElement> menuElements, {
    MyMenuPopStyle animationStyle = MyMenuPopStyle.reveal,
    required MyMenuStyle style,
    required bool repositionOnSecondaryTap,
  }) async {
    _currentAnimationStyle = animationStyle;
    closeAll(); // 关闭现有菜单
    _menuCompleter = Completer<void>();

    _showMainMenu(
      context,
      position,
      menuElements,
      style,
      repositionOnSecondaryTap: repositionOnSecondaryTap,
    );

    return _menuCompleter!.future;
  }

  /// 显示主菜单
  void _showMainMenu(
    BuildContext context,
    _MenuPosition position,
    List<MyMenuElement> menuElements,
    MyMenuStyle style, {
    required bool repositionOnSecondaryTap,
  }) {
    _mainMenuEntry = OverlayEntry(
      builder: (context) => _MenuOverlay(
        position: position,
        menuElements: menuElements,
        animationStyle: _currentAnimationStyle,
        style: style,
        repositionOnSecondaryTap: repositionOnSecondaryTap,
        onClose: _closeMainMenu,
        onItemSelected: (item) async {
          if (item.enabled && item.onTap != null) {
            _closeMainMenu();
            // 直接执行回调，无需 microtask 包装
            // Overlay 问题已通过在 App 根部包裹 Overlay 解决
            // 参考: https://github.com/jonataslaw/getx/issues/3425
            try {
              await item.onTap!();
            } catch (e, s) {
              XlyLogger.error('MyMenuItem.onTap error', e, s);
            }
          }
        },
        onLayoutRect: (rect) {
          mainMenuRect = rect;
        },
      ),
    );

    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    Overlay.of(context, rootOverlay: true).insert(_mainMenuEntry!);
    _addNavigationListener(context);
  }

  /// 添加导航监听器，路由变化时自动关闭菜单
  void _addNavigationListener(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null) {
      late final LocalHistoryEntry entry;
      entry = LocalHistoryEntry(
        impliesAppBarDismissal: false,
        onRemove: () {
          if (!identical(_historyEntry, entry)) return;
          _historyEntry = null;
          _historyRoute = null;
          _closeMainMenu(removeHistoryEntry: false);
        },
      );
      _historyEntry = entry;
      _historyRoute = route;
      route.addLocalHistoryEntry(entry);
    }
  }

  /// 关闭主菜单
  void _closeMainMenu({bool removeHistoryEntry = true}) {
    final canRemoveOverlay = _historyRoute?.isActive ?? true;
    if (canRemoveOverlay) {
      _mainMenuEntry?.remove();
    }
    _mainMenuEntry = null;
    final completer = _menuCompleter;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
    _menuCompleter = null;
    _closeAllSubMenus(removeEntries: canRemoveOverlay);
    mainMenuRect = null;

    if (removeHistoryEntry) {
      final historyEntry = _historyEntry;
      final historyRoute = _historyRoute;
      _historyEntry = null;
      _historyRoute = null;
      if (historyRoute?.isActive ?? false) {
        historyEntry?.remove();
      }
    }
  }

  /// 关闭所有子菜单
  void _closeAllSubMenus({bool removeEntries = true}) {
    if (removeEntries) {
      for (var entry in activeSubMenus.value) {
        entry.remove();
      }
    }
    activeSubMenus.value = [];
    activeMenuRects.value = [];
  }

  /// 关闭所有菜单
  void closeAll() {
    _closeMainMenu();
  }
}

// ============================================================================
// 菜单尺寸计算器
// ============================================================================

/// 菜单尺寸计算器 - 负责计算菜单的尺寸
class _MenuSizeCalculator {
  _MenuSizeCalculator._();

  static Size calculate(
    List<MyMenuElement> menuElements,
    MyMenuStyle style, {
    double? rowHeightOverride,
    BuildContext? context,
  }) {
    double maxWidth = 0.0;
    double totalHeight = 0.0;

    for (var element in menuElements) {
      if (element is MyMenuItem) {
        // 计算实际所需宽度：文字宽度 + 图标/箭头 + 左右内边距
        final textWidth = _calculateTextWidth(
          element.text ?? '',
          style,
          context,
        );
        // 与 _MenuItemWidget 的外层 6.w + 内层 10.w 保持一致。
        final double horizontalPadding = 16.w + 16.w;
        final double iconAndGap =
            element.icon != null ? (18.sp + 10.w) : 0; // 图标尺寸+间距
        final double arrowWidth = element.hasSubMenu ? 18.sp : 0; // 右侧箭头
        final itemWidth =
            textWidth + iconAndGap + arrowWidth + horizontalPadding;

        maxWidth = max(maxWidth, itemWidth);

        // 高度采用 override（例如传入父项真实高度），未提供则退回样式值
        totalHeight += rowHeightOverride ?? style.itemHeight;
      } else if (element is MyMenuDivider) {
        totalHeight += element.margin.top.h +
            element.height.h * element.thicknessMultiplier +
            element.margin.bottom.h;
      }
    }

    final borderExtent = style.borderWidth * 2;
    return Size(
      maxWidth + borderExtent,
      totalHeight + borderExtent,
    );
  }

  static double _calculateTextWidth(
    String text,
    MyMenuStyle style,
    BuildContext? context,
  ) {
    final menuTextStyle = TextStyle(
      fontSize: style.fontSize,
      fontWeight: FontWeight.w400,
      height: 1.2,
      letterSpacing: 0,
    );
    final effectiveTextStyle = context == null
        ? menuTextStyle
        : DefaultTextStyle.of(context).style.merge(menuTextStyle);
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: effectiveTextStyle,
      ),
      maxLines: 1,
      textDirection:
          context == null ? TextDirection.ltr : Directionality.of(context),
      textScaler: context == null
          ? TextScaler.noScaling
          : MediaQuery.textScalerOf(context),
      locale: context == null ? null : Localizations.maybeLocaleOf(context),
    )..layout(minWidth: 0, maxWidth: double.infinity);

    return textPainter.width;
  }
}

// ============================================================================
// 菜单位置计算器
// ============================================================================

/// 菜单位置计算器 - 负责计算菜单的最佳显示位置
class _MenuPositionCalculator {
  _MenuPositionCalculator._();

  /// 计算菜单位置
  ///
  /// 策略：
  /// 1. 主菜单：优先在点击位置右下方显示
  /// 2. 如果右侧空间不足，尝试左侧
  /// 3. 如果下方空间不足，尝试上方
  /// 4. 确保菜单不会超出屏幕边界
  static Offset calculate(
    BuildContext context,
    Offset position,
    Size menuSize, {
    bool isSubMenu = false,
    Size? parentMenuSize,
    double? alignedY,
    double? itemHeightHint,
    List<Rect> avoidRects = const [],
    double? parentMenuLeft,
    double? parentMenuRight,
  }) {
    final screenSize = _getScreenSize(context);

    if (isSubMenu) {
      return _calculateSubMenuPosition(
        position,
        menuSize,
        screenSize,
        alignedY,
        parentMenuSize: parentMenuSize,
        itemHeightHint: itemHeightHint,
        avoidRects: avoidRects,
        parentMenuLeft: parentMenuLeft,
        parentMenuRight: parentMenuRight,
      );
    } else {
      return _calculateMainMenuPosition(
        position,
        menuSize,
        screenSize,
      );
    }
  }

  /// 获取屏幕尺寸
  static Size _getScreenSize(BuildContext context) {
    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常获取
    final overlay = Overlay.of(context, rootOverlay: true)
        .context
        .findRenderObject() as RenderBox;
    return overlay.size;
  }

  /// 返回需要固定不动的菜单边角；菜单从该边角朝最终放置方向展开。
  static Alignment growthAlignment(Rect menuRect, Rect sourceRect) {
    final horizontal = menuRect.center.dx < sourceRect.center.dx ? 1.0 : -1.0;
    final vertical = menuRect.center.dy < sourceRect.center.dy ? 1.0 : -1.0;
    return Alignment(horizontal, vertical);
  }

  /// 计算锚定菜单的位置。
  ///
  /// [anchorOrigin] 控制菜单相对于锚点的起始对齐策略：
  /// - [MyMenuAnchorOrigin.edge]：从锚点边缘弹出（传统下拉）。
  /// - [MyMenuAnchorOrigin.center]：从锚点中心象限引出（田字格模式），
  ///   菜单起始角对准锚点中心，朝展开方向生长。
  static Offset calculateAnchored(
    Rect anchorRect,
    Size menuSize,
    Size screenSize, {
    required double gap,
    MyMenuAnchorOrigin anchorOrigin = MyMenuAnchorOrigin.edge,
  }) {
    if (anchorOrigin == MyMenuAnchorOrigin.center) {
      return _calculateAnchoredCenter(anchorRect, menuSize, screenSize, gap);
    }
    return _calculateAnchoredEdge(anchorRect, menuSize, screenSize, gap);
  }

  /// 边缘对齐：菜单从锚点对应边缘弹出（传统下拉）。
  static Offset _calculateAnchoredEdge(
    Rect anchorRect,
    Size menuSize,
    Size screenSize,
    double gap,
  ) {
    final alignToEnd = anchorRect.center.dx >= screenSize.width / 2;
    final startX = anchorRect.left;
    final endX = anchorRect.right - menuSize.width;
    final preferredX = alignToEnd ? endX : startX;
    final alternateX = alignToEnd ? startX : endX;

    bool fitsHorizontally(double x) =>
        x >= 0 && x + menuSize.width <= screenSize.width;

    double x = preferredX;
    if (!fitsHorizontally(x) && fitsHorizontally(alternateX)) {
      x = alternateX;
    }
    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));

    final belowY = anchorRect.bottom + gap;
    final aboveY = anchorRect.top - gap - menuSize.height;
    final fitsBelow = belowY + menuSize.height <= screenSize.height;
    final fitsAbove = aboveY >= 0;

    double y;
    if (fitsBelow) {
      y = belowY;
    } else if (fitsAbove) {
      y = aboveY;
    } else {
      final belowSpace = max(0, screenSize.height - anchorRect.bottom - gap);
      final aboveSpace = max(0, anchorRect.top - gap);
      y = belowSpace >= aboveSpace ? belowY : aboveY;
    }
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));

    return Offset(x, y);
  }

  /// 中心象限对齐（田字格模式）：菜单起始角对准锚点中心。
  ///
  /// 根据可用空间判断展开方向，然后让菜单的对应角
  /// 与锚点中心对齐（加上 gap 偏移），形成"从象限生长"的视觉效果。
  static Offset _calculateAnchoredCenter(
    Rect anchorRect,
    Size menuSize,
    Size screenSize,
    double gap,
  ) {
    final cx = anchorRect.center.dx;
    final cy = anchorRect.center.dy;

    final spaceRight = screenSize.width - cx;
    final spaceLeft = cx;
    final spaceBelow = screenSize.height - cy;
    final spaceAbove = cy;

    final expandRight = spaceRight >= menuSize.width || spaceRight >= spaceLeft;
    final expandDown =
        spaceBelow >= menuSize.height || spaceBelow >= spaceAbove;

    double x;
    if (expandRight) {
      x = cx + gap;
    } else {
      x = cx - gap - menuSize.width;
    }

    double y;
    if (expandDown) {
      y = cy + gap;
    } else {
      y = cy - gap - menuSize.height;
    }

    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));

    return Offset(x, y);
  }

  /// 计算主菜单位置
  static Offset _calculateMainMenuPosition(
    Offset clickPosition,
    Size menuSize,
    Size screenSize,
  ) {
    double x = clickPosition.dx;
    double y = clickPosition.dy;

    // 水平位置计算
    final rightSpace = screenSize.width - clickPosition.dx;
    final leftSpace = clickPosition.dx;

    if (rightSpace >= menuSize.width) {
      // 右侧有足够空间
      x = clickPosition.dx;
    } else if (leftSpace >= menuSize.width) {
      // 左侧有足够空间
      x = clickPosition.dx - menuSize.width;
    } else {
      // 两侧都不够，选择空间较大的一侧
      if (rightSpace >= leftSpace) {
        x = max(0, screenSize.width - menuSize.width);
      } else {
        x = 0;
      }
    }

    // 垂直位置计算
    final bottomSpace = screenSize.height - clickPosition.dy;
    final topSpace = clickPosition.dy;

    if (bottomSpace >= menuSize.height) {
      // 下方有足够空间
      y = clickPosition.dy;
    } else if (topSpace >= menuSize.height) {
      // 上方有足够空间
      y = clickPosition.dy - menuSize.height;
    } else {
      // 上下都不够，靠下对齐
      y = max(0, screenSize.height - menuSize.height);
    }

    // 边界保护
    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));

    return Offset(x, y);
  }

  /// 计算子菜单位置
  static Offset _calculateSubMenuPosition(
    Offset parentPosition,
    Size menuSize,
    Size screenSize,
    double? alignedY, {
    Size? parentMenuSize,
    double? itemHeightHint,
    List<Rect> avoidRects = const [],
    double? parentMenuLeft,
    double? parentMenuRight,
  }) {
    // 与父菜单之间保留一个水平间隙，避免视觉重叠
    final double gap = 0.w; // 去除主菜单与子菜单间隙，紧贴对齐

    // 条目位于菜单边框内部；优先使用父菜单的真实外边缘，避免 1px
    // 边框重叠被误判为碰撞并错误翻转到另一侧。
    final double fallbackParentRight = parentPosition.dx;
    final double fallbackParentLeft = parentMenuSize != null
        ? fallbackParentRight - parentMenuSize.width
        : fallbackParentRight;
    final double effectiveParentRight = parentMenuRight ?? fallbackParentRight;
    final double effectiveParentLeft = parentMenuLeft ?? fallbackParentLeft;

    // 计算左右可用空间（需扣除 gap）
    final double rightSpace = screenSize.width - (effectiveParentRight + gap);
    final double leftSpace = effectiveParentLeft - gap;

    // 先计算两个候选位置
    final double candidateRightX = effectiveParentRight + gap;
    final double candidateLeftX = effectiveParentLeft - gap - menuSize.width;

    // 先按可用空间选择一侧；候选点会先夹进可视区，再参与碰撞判断。
    final preferRight = rightSpace >= menuSize.width ||
        (leftSpace < menuSize.width && rightSpace >= leftSpace);
    final double rightBound = max(0.0, screenSize.width - menuSize.width);
    final double boundedRightX =
        candidateRightX.clamp(0.0, rightBound).toDouble();
    final double boundedLeftX =
        candidateLeftX.clamp(0.0, rightBound).toDouble();
    double x = preferRight ? boundedRightX : boundedLeftX;

    // 垂直对齐策略：
    // 1) 首选让子菜单的顶部与当前条目的顶部对齐；
    // 2) 若到底部溢出，则尝试让子菜单底部与当前条目的底部对齐；
    // 3) 最后做屏幕裁剪（clamp）。
    final double itemTop = alignedY ?? parentPosition.dy;
    final double parentItemHeight = parentMenuSize?.height ?? 0;
    // 为避免高度估算差异导致的1px上下偏移，这里直接使用父项的实际高度来对齐
    final double firstRowHeight = parentItemHeight;

    // 以“条目中心 == 子菜单第一行中心”为默认策略，保证水平线对齐
    double y = itemTop + parentItemHeight / 2 - firstRowHeight / 2;

    // 若底部溢出，退化为“与父项底部对齐”的策略
    if (y + menuSize.height > screenSize.height) {
      final double itemBottom = itemTop + parentItemHeight;
      y = itemBottom - menuSize.height;
    }

    // 对齐到像素边界，减少亚像素渲染导致的轻微错位
    y = y.roundToDouble();
    final double bottomBound = max(0.0, screenSize.height - menuSize.height);
    y = y.clamp(0.0, bottomBound).toDouble();

    // 再做重叠避让：若与任一已有菜单矩形重叠，则尝试另一侧
    bool overlapsAt(Offset p) {
      final rect = Rect.fromLTWH(p.dx, p.dy, menuSize.width, menuSize.height);
      for (final r in avoidRects) {
        if (rect.overlaps(r)) return true;
      }
      return false;
    }

    final Offset rightPos = Offset(boundedRightX, y);
    final Offset leftPos = Offset(boundedLeftX, y);

    final bool rightOverlap = overlapsAt(rightPos);
    final bool leftOverlap = overlapsAt(leftPos);

    if (preferRight && rightOverlap && !leftOverlap) {
      x = boundedLeftX;
    } else if (!preferRight && leftOverlap && !rightOverlap) {
      x = boundedRightX;
    }

    // 若最终位置仍然重叠，则沿垂直方向做智能避让（先向下，后向上），直到不重叠或到达边界
    if (overlapsAt(Offset(x, y))) {
      final double topBound = 0.0;
      final double step =
          max(4.w, (parentItemHeight > 0 ? parentItemHeight : 24.h) / 2);
      const int maxIter = 40; // 安全上限
      for (int i = 1; i <= maxIter; i++) {
        final double tryDown = y + i * step;
        if (tryDown <= bottomBound && !overlapsAt(Offset(x, tryDown))) {
          y = tryDown;
          break;
        }
        final double tryUp = y - i * step;
        if (tryUp >= topBound && !overlapsAt(Offset(x, tryUp))) {
          y = tryUp;
          break;
        }
      }
    }

    // 若仍重叠，则进行横向多跳避让（先向左再向右），必要时再做一次微量垂直调整
    if (overlapsAt(Offset(x, y))) {
      final double leftBound = 0.0;
      final double hStep = max(8.w, menuSize.width * 0.25);
      const int hMaxIter = 20;
      bool resolved = false;
      for (int i = 1; i <= hMaxIter; i++) {
        final double tryLeft = max(leftBound, x - i * hStep);
        if (!overlapsAt(Offset(tryLeft, y))) {
          x = tryLeft;
          resolved = true;
          break;
        }
        final double tryRight = min(rightBound, x + i * hStep);
        if (!overlapsAt(Offset(tryRight, y))) {
          x = tryRight;
          resolved = true;
          break;
        }
      }
      if (!resolved) {
        // 在新x附近再尝试一次垂直小步避让
        final double topBound = 0.0;
        final double vStep =
            max(4.w, (parentItemHeight > 0 ? parentItemHeight : 24.h) / 2);
        for (int i = 1; i <= 20; i++) {
          final double tryDown = y + i * vStep;
          if (tryDown <= bottomBound && !overlapsAt(Offset(x, tryDown))) {
            y = tryDown;
            resolved = true;
            break;
          }
          final double tryUp = y - i * vStep;
          if (tryUp >= topBound && !overlapsAt(Offset(x, tryUp))) {
            y = tryUp;
            resolved = true;
            break;
          }
        }
      }
    }

    // 最终边界保护
    y = y.clamp(0.0, max(0, screenSize.height - menuSize.height));
    x = x.clamp(0.0, max(0, screenSize.width - menuSize.width));

    return Offset(x, y);
  }
}

// ============================================================================
// UI组件
// ============================================================================

/// 菜单覆盖层 - 全屏透明层+菜单内容
class _MenuOverlay extends StatelessWidget {
  final _MenuPosition position;
  final List<MyMenuElement> menuElements;
  final MyMenuPopStyle animationStyle;
  final MyMenuStyle style;
  final bool repositionOnSecondaryTap;
  final VoidCallback onClose;
  final Function(MyMenuItem) onItemSelected;
  final ValueChanged<Rect> onLayoutRect;

  const _MenuOverlay({
    required this.position,
    required this.menuElements,
    required this.animationStyle,
    required this.style,
    required this.repositionOnSecondaryTap,
    required this.onClose,
    required this.onItemSelected,
    required this.onLayoutRect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final overlayBox = Overlay.of(context, rootOverlay: true)
            .context
            .findRenderObject() as RenderBox;

        final menuSize = _MenuSizeCalculator.calculate(
          menuElements,
          style,
          context: context,
        );
        final resolvedPosition = position.resolve(
          context,
          overlayBox,
          menuSize,
        );
        final adjustedPosition = resolvedPosition.offset;
        // 当前菜单的矩形区域（Overlay 本地坐标）
        final Rect menuRect = Rect.fromLTWH(
          adjustedPosition.dx,
          adjustedPosition.dy,
          menuSize.width,
          menuSize.height,
        );
        // 将主菜单矩形上报至管理器，供后续子菜单避让
        onLayoutRect(menuRect);

        return Stack(
          children: [
            // 全屏透明点击层 - 使用Listener处理右键点击以允许事件传播
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  final Offset lp = event.localPosition;
                  final bool outside = !menuRect.contains(lp);

                  // 仅右键菜单支持在新的鼠标位置重开；锚定菜单只关闭。
                  if ((event.buttons & kSecondaryMouseButton) != 0 && outside) {
                    if (repositionOnSecondaryTap) {
                      MyMenu.show(
                        context,
                        event.position,
                        menuElements,
                        animationStyle: animationStyle,
                        style: style,
                      );
                    } else {
                      onClose();
                    }
                    return;
                  }

                  // 左键：点在菜单外 → 按下即关闭（避免 onTap 的延迟）
                  if ((event.buttons & kPrimaryMouseButton) != 0 && outside) {
                    onClose();
                    return;
                  }

                  // 其它情况（或点在菜单内）不处理，交由子组件
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onClose, // 左键点击空白处关闭
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            // 菜单内容：定位结果同时决定展开时固定的边角。
            Positioned(
              left: adjustedPosition.dx,
              top: adjustedPosition.dy,
              child: GestureDetector(
                onTap: () {}, // 防止点击菜单时关闭
                child: _MenuContent(
                  menuElements: menuElements,
                  onItemSelected: onItemSelected,
                  style: style,
                  animationStyle: animationStyle,
                  growthAlignment: resolvedPosition.growthAlignment,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 动画包装器 - 负责菜单弹出动画
class _AnimatedMenuWrapper extends StatefulWidget {
  final Widget child;
  final MyMenuPopStyle animationStyle;
  final Alignment growthAlignment;

  const _AnimatedMenuWrapper({
    required this.child,
    required this.animationStyle,
    required this.growthAlignment,
  });

  @override
  State<_AnimatedMenuWrapper> createState() => _AnimatedMenuWrapperState();
}

class _AnimatedMenuWrapperState extends State<_AnimatedMenuWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _animation = _createAnimation();
    _controller.forward();
  }

  Animation<double> _createAnimation() {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return Tween<double>(begin: 0.8, end: 1.0).animate(curve);
      case MyMenuPopStyle.fade:
      case MyMenuPopStyle.slideFromTop:
      case MyMenuPopStyle.slideFromRight:
      case MyMenuPopStyle.reveal:
        return Tween<double>(begin: 0.0, end: 1.0).animate(curve);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.animationStyle) {
      case MyMenuPopStyle.scale:
        return ScaleTransition(
          scale: _animation,
          alignment: widget.growthAlignment,
          child: widget.child,
        );
      case MyMenuPopStyle.fade:
        return FadeTransition(
          opacity: _animation,
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromTop:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.1),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
      case MyMenuPopStyle.slideFromRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(_animation),
          child: widget.child,
        );
      case MyMenuPopStyle.reveal:
        return AnimatedBuilder(
          animation: _animation,
          child: widget.child,
          builder: (context, child) {
            if (_animation.value >= 1) return child!;
            return ClipRect(
              clipper: _DirectionalRevealClipper(
                progress: _animation.value,
                growthAlignment: widget.growthAlignment,
              ),
              child: child,
            );
          },
        );
    }
  }
}

class _DirectionalRevealClipper extends CustomClipper<Rect> {
  final double progress;
  final Alignment growthAlignment;

  const _DirectionalRevealClipper({
    required this.progress,
    required this.growthAlignment,
  });

  @override
  Rect getClip(Size size) {
    final resolvedProgress = progress.clamp(0.0, 1.0);
    final width = size.width * resolvedProgress;
    final height = size.height * resolvedProgress;
    final left =
        (size.width - width) * ((growthAlignment.x + 1) / 2).clamp(0.0, 1.0);
    final top =
        (size.height - height) * ((growthAlignment.y + 1) / 2).clamp(0.0, 1.0);
    return Rect.fromLTWH(left, top, width, height);
  }

  @override
  bool shouldReclip(_DirectionalRevealClipper oldClipper) {
    return progress != oldClipper.progress ||
        growthAlignment != oldClipper.growthAlignment;
  }
}

/// 菜单内容 - 菜单的主体UI
class _MenuContent extends StatelessWidget {
  final List<MyMenuElement> menuElements;
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final MyMenuPopStyle animationStyle;
  final Alignment growthAlignment;
  final int level;

  const _MenuContent({
    required this.menuElements,
    required this.onItemSelected,
    required this.style,
    required this.growthAlignment,
    this.animationStyle = MyMenuPopStyle.reveal,
    this.level = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<OverlayEntry>>(
      valueListenable: MyMenu._activeSubMenus,
      builder: (context, _, __) {
        final menuBody = IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: menuElements.map((element) {
              if (element is MyMenuItem) {
                return _MenuItemWidget(
                  item: element,
                  onItemSelected: onItemSelected,
                  style: style,
                  animationStyle: animationStyle,
                  level: level,
                );
              } else if (element is MyMenuDivider) {
                return element.build(context);
              }
              return const SizedBox.shrink();
            }).toList(),
          ),
        );
        final animatedBody = animationStyle == MyMenuPopStyle.reveal
            ? menuBody
            : _AnimatedMenuWrapper(
                animationStyle: animationStyle,
                growthAlignment: growthAlignment,
                child: menuBody,
              );
        final shadowDecoration = BoxDecoration(
          borderRadius: BorderRadius.circular(style.borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.05 * style.shadowRatio,
              ),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.14 * style.shadowRatio,
              ),
              blurRadius: 24,
              spreadRadius: -5,
              offset: const Offset(0, 8),
            ),
          ],
        );
        final material = ClipRRect(
          borderRadius: BorderRadius.circular(style.borderRadius),
          child: BackdropFilter(
            // 默认 srcOver；定向展开仅做裁剪，不创建透明 saveLayer。
            // 其它动画保留在滤镜内部，避免影响背景采样。
            filter: ImageFilter.blur(
              sigmaX: style.blurSigma,
              sigmaY: style.blurSigma,
              tileMode: TileMode.clamp,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: style.surfaceColor,
                borderRadius: BorderRadius.circular(style.borderRadius),
                border: Border.all(
                  color: style.borderColor,
                  width: style.borderWidth,
                ),
              ),
              child: animatedBody,
            ),
          ),
        );
        // 仅裁剪磨砂材质，阴影保持稳定，避免动画末帧突然跳出。
        final animatedMaterial = animationStyle == MyMenuPopStyle.reveal
            ? _AnimatedMenuWrapper(
                animationStyle: animationStyle,
                growthAlignment: growthAlignment,
                child: material,
              )
            : material;
        return Container(
          decoration: shadowDecoration,
          child: animatedMaterial,
        );
      },
    );
  }
}

/// 菜单项组件
class _MenuItemWidget extends StatefulWidget {
  final MyMenuItem item;
  final Function(MyMenuItem) onItemSelected;
  final MyMenuStyle style;
  final MyMenuPopStyle animationStyle;
  final int level;

  const _MenuItemWidget({
    required this.item,
    required this.onItemSelected,
    required this.style,
    required this.animationStyle,
    required this.level,
  });

  @override
  State<_MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<_MenuItemWidget> {
  @override
  Widget build(BuildContext context) {
    final itemColor = widget.item.enabled ? Colors.black87 : Colors.black38;
    final VoidCallback? onTap = !widget.item.enabled
        ? null
        : widget.item.hasSubMenu
            ? () => _showSubMenu(context)
            : () => widget.onItemSelected(widget.item);

    // 外层高度与尺寸计算器保持一致；hover 仅在内部圆角区域绘制。
    return SizedBox(
      height: widget.style.itemHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          child: InkWell(
            borderRadius: BorderRadius.circular(7),
            onTap: onTap,
            canRequestFocus: widget.item.enabled,
            onHover: widget.item.enabled
                ? (isHovering) {
                    if (isHovering) {
                      _handleHover(context);
                    }
                  }
                : null,
            highlightColor: widget.style.focusColor.withValues(alpha: 0.07),
            splashColor: widget.style.focusColor.withValues(alpha: 0.03),
            hoverColor: widget.style.focusColor.withValues(alpha: 0.04),
            child: MouseRegion(
              cursor: widget.item.enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.forbidden,
              onEnter: (_) => _handleHover(context),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.item.icon != null) ...[
                      Icon(
                        widget.item.icon,
                        color: itemColor,
                        size: 18.sp,
                      ),
                      SizedBox(width: 10.w),
                    ],
                    Expanded(
                      child: Text(
                        widget.item.text ?? '',
                        style: TextStyle(
                          color: itemColor,
                          fontSize: widget.style.fontSize,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (widget.item.hasSubMenu)
                      Icon(
                        Icons.arrow_right,
                        color: itemColor,
                        size: 18.sp,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 处理悬停事件
  void _handleHover(BuildContext context) {
    if (!widget.item.enabled) {
      _closeSubMenusAfterLevel(widget.level);
    } else if (widget.item.hasSubMenu) {
      _showSubMenu(context);
    } else {
      _closeSubMenusAfterLevel(widget.level);
    }
  }

  /// 显示子菜单
  void _showSubMenu(BuildContext context) {
    // 移除当前级别之后的所有子菜单
    _closeSubMenusAfterLevel(widget.level);

    // 🔧 关键修复：使用 Overlay 作为 ancestor 进行坐标转换
    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    final overlayBox = Overlay.of(context, rootOverlay: true)
        .context
        .findRenderObject() as RenderBox;
    final itemBox = context.findRenderObject() as RenderBox;

    // 获取菜单项在 Overlay 坐标系中的位置
    final itemPositionInOverlay =
        itemBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final menuSize = _MenuSizeCalculator.calculate(
      widget.item.subItems!,
      widget.style,
      rowHeightOverride: itemBox.size.height,
      context: context,
    );

    // 子菜单相邻但不重叠
    final subMenuPosition = Offset(
      itemPositionInOverlay.dx + itemBox.size.width,
      itemPositionInOverlay.dy,
    );

    // 已有菜单矩形用于避让
    final state = MyMenu._stateManager;
    final List<Rect> avoidRects = [
      if (state.mainMenuRect != null) state.mainMenuRect!,
      ...state.activeMenuRects.value,
    ];

    // 优先取最近一级子菜单矩形，否则使用主菜单矩形。
    final Rect? parentMenuRect = state.activeMenuRects.value.isNotEmpty
        ? state.activeMenuRects.value.last
        : state.mainMenuRect;

    final adjustedPosition = _MenuPositionCalculator.calculate(
      context,
      subMenuPosition,
      menuSize,
      isSubMenu: true,
      parentMenuSize: itemBox.size, // 传入父菜单项尺寸，用于更精准对齐
      alignedY: itemPositionInOverlay.dy,
      itemHeightHint: widget.style.itemHeight,
      avoidRects: avoidRects,
      parentMenuLeft: parentMenuRect?.left,
      parentMenuRight: parentMenuRect?.right,
    );

    // 创建子菜单覆盖层（不再做额外边框修正，直接使用条目顶部对齐）
    final Rect subRect = Rect.fromLTWH(
      adjustedPosition.dx,
      adjustedPosition.dy,
      menuSize.width,
      menuSize.height,
    );
    final parentItemRect = itemPositionInOverlay & itemBox.size;
    final growthAlignment = _MenuPositionCalculator.growthAlignment(
      subRect,
      parentItemRect,
    );

    final subMenuEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: adjustedPosition.dx,
        top: adjustedPosition.dy,
        child: _MenuContent(
          menuElements: widget.item.subItems!,
          onItemSelected: widget.onItemSelected,
          style: widget.style,
          animationStyle: widget.animationStyle,
          growthAlignment: growthAlignment,
          level: widget.level + 1,
        ),
      ),
    );

    // 使用 rootOverlay 确保在 Dialog/BottomSheet 内也能正常显示
    Overlay.of(context, rootOverlay: true).insert(subMenuEntry);
    MyMenu._activeSubMenus.value = [
      ...MyMenu._activeSubMenus.value,
      subMenuEntry,
    ];
    state.activeMenuRects.value = [
      ...state.activeMenuRects.value,
      subRect,
    ];
  }

  /// 关闭指定级别之后的所有子菜单
  void _closeSubMenusAfterLevel(int level) {
    final activeSubMenus = MyMenu._activeSubMenus;
    final updatedList = List<OverlayEntry>.from(activeSubMenus.value);

    while (updatedList.length > level) {
      final lastEntry = updatedList.removeLast();
      lastEntry.remove();
    }

    // 同步移除对应的矩形
    final rects = MyMenu._stateManager.activeMenuRects;
    final updatedRects = List<Rect>.from(rects.value);
    while (updatedRects.length > level) {
      updatedRects.removeLast();
    }
    rects.value = updatedRects;

    activeSubMenus.value = updatedList;
  }
}
