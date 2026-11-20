import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/desktop_window_gestures.dart';

/// 尾部（右侧）新增或变化时 [MyHorizontalScrollerController.notifyTrailingChange] 的视图策略。
enum MyHorizontalTrailingReveal {
  /// **智能粘尾（默认，适合后台推送流）**：
  /// - 若当前视图原本已停在最右端（含此前未溢出、刚因追加变成溢出的情况），
  ///   则自动平滑跟滚到新尾部，让新追加的项完整进入视野；
  /// - 若用户已主动向前滚离尾部（正在浏览前段内容），则不抢视角，保持当前视口不动，
  ///   仅按需轻弹右侧 `>` 箭头提示“右边有新内容”。
  ifAtEnd,

  /// **始终滚入视野（适合用户主动点「+ / 尾部追加」等显式创建操作）**：
  /// 无论当前视图停在最左还是中间，都平滑自动滚到最右端，让刚加出来的尾部项
  /// 立即完整可见，避免用户觉得“点了没反应”。
  always,

  /// **从不自动滚动（适合尾部移除或完全静默更新）**：
  /// 保持当前视口不动，仅按需轻弹 `>` 箭头。
  never,
}

/// [MyHorizontalScroller] 的增强滚动控制器（继承 [ScrollController]，100% 向后兼容）。
///
/// 在普通横向滚动控制基础上，支持与 [MyHorizontalScroller] 协同处理**头部/尾部动态增删**：
/// - [prepareLeadingChange]：在**头部（左侧）**增加或移除子项前调用。
///   - 当前已向右滚动（离开最左端）时：开启视口锚定窗口，在布局同帧按内容宽度增量
///     自动补偿 `pixels`，**眼前正在浏览的标签像素级稳住不跳飞**，并在左侧新增时柔和
///     轻弹 `<` 箭头提示用户左侧多了新内容；
///   - 当前停在最左端（头部）时：不做隐藏补偿，让新项直接在视野左侧平滑展开推入
///     （或收缩退场），右侧超出时 `>` 箭头自动淡入。
/// - [notifyTrailingChange]：在**尾部（右侧）**增加或移除子项时调用，立即结束未过期的
///   头部锚定窗口，并按 [MyHorizontalTrailingReveal] 策略处理视口：
///   - 默认 `ifAtEnd`（智能粘尾）：原本就在尾部（含未溢出）时平滑跟滚露出新项，
///     用户已往前翻看时不打断浏览、仅轻弹 `>` 箭头；
///   - 用户主动点「尾部追加」等创建动作建议传 `always`，直接平滑滚到尾部展示新项。
/// - [pulseIndicator]：手动轻弹左/右侧边缘指示器。
/// - [scrollToStart] / [scrollToEnd]：一键平滑滚回头部或滚到尾部。
class MyHorizontalScrollerController extends ScrollController {
  MyHorizontalScrollerController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  }) {
    _coordinator.onControllerNotify = () {
      if (hasClients) notifyListeners();
    };
  }

  final _LeadingAnchorCoordinator _coordinator = _LeadingAnchorCoordinator();

  /// 是否正处于头部视口锚定补偿窗口内。
  bool get isAnchoringLeading => _coordinator.isAnchoring;

  /// 在**头部（左侧）**即将增加或移除子项时调用。
  ///
  /// - [anchorDuration]：锚定补偿持续窗口，应略大于子项展开/收缩动画时长（无动画时
  ///   默认 `360ms` 同样安全，首次布局变化即完成补偿；用户一旦主动滚滑会自动提前退出）。
  /// - [pulseLeadingIndicator]：当处于锚定态且左侧内容增长时，是否柔和轻弹 `<` 箭头。
  void prepareLeadingChange({
    Duration anchorDuration = const Duration(milliseconds: 360),
    bool pulseLeadingIndicator = true,
  }) {
    _coordinator.stopTrailingReveal();
    if (!hasClients) return;
    final pos = position;
    if (!pos.hasContentDimensions) return;

    if (pos.pixels > _MyHorizontalScrollerState._edgeEpsilon) {
      _coordinator.beginLeadingAnchor(
        duration: anchorDuration,
        pulseLeadingOnGrow: pulseLeadingIndicator,
        initialContentWidth: pos.viewportDimension + pos.maxScrollExtent,
      );
    } else {
      // 用户正停在头部：新项直接推入当前视野，不做隐藏锚定。
      _coordinator.stopLeadingAnchor();
    }
  }

  /// 在**尾部（右侧）**增加或移除子项时调用。
  ///
  /// 立即结束可能未过期的头部锚定窗口，并按 [reveal] 策略处理视口：
  /// - [MyHorizontalTrailingReveal.ifAtEnd]（默认）：当前已停在最右端（含未溢出）时
  ///   在 [revealDuration] 窗口内平滑粘尾露出新项；若已向前滚离尾部则保持当前视野，
  ///   并在 [pulseTrailingIndicator] 为 `true` 时轻弹 `>` 箭头提示；
  /// - [MyHorizontalTrailingReveal.always]：始终平滑滚动到最右端，适合用户主动追加；
  /// - [MyHorizontalTrailingReveal.never]：不自动滚动，适合尾部移除。
  ///
  /// [revealDuration] 应略大于子项展开动画时长，使带 `SizeTransition` 等动画的新项
  /// 也能一气呵成完整滚入视野；用户一旦主动滚动/拖滑会立即中止自动跟滚。
  void notifyTrailingChange({
    MyHorizontalTrailingReveal reveal = MyHorizontalTrailingReveal.ifAtEnd,
    Duration revealDuration = const Duration(milliseconds: 360),
    bool pulseTrailingIndicator = true,
  }) {
    _coordinator.stopLeadingAnchor();
    _coordinator.stopTrailingReveal();

    var shouldFollow = false;
    switch (reveal) {
      case MyHorizontalTrailingReveal.always:
        shouldFollow = true;
      case MyHorizontalTrailingReveal.ifAtEnd:
        if (hasClients && position.hasContentDimensions) {
          shouldFollow = (position.maxScrollExtent - position.pixels) <= 8.0;
        }
      case MyHorizontalTrailingReveal.never:
        shouldFollow = false;
    }

    if (shouldFollow) {
      _coordinator.requestTrailingReveal(revealDuration);
    } else if (pulseTrailingIndicator) {
      _coordinator.requestTrailingPulseOnNextFrame();
    }
  }

  /// 手动触发左侧（[isLeft] = true）或右侧（[isLeft] = false）指示器轻弹提示。
  void pulseIndicator({required bool isLeft}) {
    _coordinator.emitPulse(isLeft: isLeft);
  }

  /// 平滑滚回最左端（头部）。
  Future<void> scrollToStart({
    Duration duration = const Duration(milliseconds: 240),
    Curve curve = Curves.easeOutCubic,
  }) async {
    _coordinator.stopLeadingAnchor();
    _coordinator.stopTrailingReveal();
    if (!hasClients) return;
    final pos = position;
    if (!pos.hasContentDimensions) return;
    if ((pos.pixels - pos.minScrollExtent).abs() < 0.5) return;
    await animateTo(pos.minScrollExtent, duration: duration, curve: curve);
  }

  /// 平滑滚到最右端（尾部）。
  Future<void> scrollToEnd({
    Duration duration = const Duration(milliseconds: 240),
    Curve curve = Curves.easeOutCubic,
  }) async {
    _coordinator.stopLeadingAnchor();
    _coordinator.stopTrailingReveal();
    if (!hasClients) return;
    final pos = position;
    if (!pos.hasContentDimensions) return;
    if ((pos.pixels - pos.maxScrollExtent).abs() < 0.5) return;
    await animateTo(pos.maxScrollExtent, duration: duration, curve: curve);
  }

  /// 当 `childIsScrollable = true` 时，可把此方法返回的 [ScrollPhysics] 传给自定义
  /// `ListView` / `CustomScrollView`，使其同样获得零抖动的头部视口锚定能力。
  ScrollPhysics createAnchorPhysics({ScrollPhysics? parent}) {
    return _LeadingAnchorScrollPhysics(
      coordinator: _coordinator,
      parent: parent,
    );
  }

  @override
  void dispose() {
    _coordinator.dispose();
    super.dispose();
  }
}

class _LeadingAnchorCoordinator {
  bool _anchoring = false;
  bool _pulseLeadingOnGrow = false;
  double? _lastCompensatedContentWidth;
  Timer? _anchorTimer;

  void Function(bool isLeft)? _onPulse;
  VoidCallback? _onTrailingPulsePending;
  void Function(Duration duration)? _onTrailingRevealRequested;
  VoidCallback? _onTrailingRevealStop;
  VoidCallback? _onPixelsCompensated;
  VoidCallback? onControllerNotify;

  bool get isAnchoring => _anchoring;
  double? get lastCompensatedContentWidth => _lastCompensatedContentWidth;

  void attach({
    required void Function(bool isLeft) onPulse,
    required VoidCallback onTrailingPulsePending,
    required void Function(Duration duration) onTrailingRevealRequested,
    required VoidCallback onTrailingRevealStop,
    required VoidCallback onPixelsCompensated,
  }) {
    _onPulse = onPulse;
    _onTrailingPulsePending = onTrailingPulsePending;
    _onTrailingRevealRequested = onTrailingRevealRequested;
    _onTrailingRevealStop = onTrailingRevealStop;
    _onPixelsCompensated = onPixelsCompensated;
  }

  void detach() {
    _onPulse = null;
    _onTrailingPulsePending = null;
    _onTrailingRevealRequested = null;
    _onTrailingRevealStop = null;
    _onPixelsCompensated = null;
  }

  void beginLeadingAnchor({
    required Duration duration,
    required bool pulseLeadingOnGrow,
    required double initialContentWidth,
  }) {
    _anchorTimer?.cancel();
    _anchoring = true;
    _pulseLeadingOnGrow = pulseLeadingOnGrow;
    _lastCompensatedContentWidth = initialContentWidth;
    _anchorTimer = Timer(duration, stopLeadingAnchor);
  }

  void stopLeadingAnchor() {
    _anchorTimer?.cancel();
    _anchorTimer = null;
    _anchoring = false;
    _pulseLeadingOnGrow = false;
    _lastCompensatedContentWidth = null;
  }

  void recordCompensatedContentWidth(double width) {
    _lastCompensatedContentWidth = width;
  }

  void notifyPixelsCompensated({required bool grew}) {
    final shouldPulse = grew && _pulseLeadingOnGrow;
    if (shouldPulse) _pulseLeadingOnGrow = false;
    scheduleMicrotask(() {
      _onPixelsCompensated?.call();
      onControllerNotify?.call();
      if (shouldPulse) emitPulse(isLeft: true);
    });
  }

  void requestTrailingPulseOnNextFrame() {
    _onTrailingPulsePending?.call();
  }

  void requestTrailingReveal(Duration duration) {
    _onTrailingRevealRequested?.call(duration);
  }

  void stopTrailingReveal() {
    _onTrailingRevealStop?.call();
  }

  void emitPulse({required bool isLeft}) {
    _onPulse?.call(isLeft);
  }

  void dispose() {
    stopLeadingAnchor();
    stopTrailingReveal();
    onControllerNotify = null;
    detach();
  }
}

/// 在布局同帧（`applyContentDimensions` → `paint` 之前）按内容宽度变化补偿滚动偏移，
/// 彻底消除头部增删时的 1 帧闪烁与视口跳变。
class _LeadingAnchorScrollPhysics extends ScrollPhysics {
  const _LeadingAnchorScrollPhysics({
    required this.coordinator,
    super.parent,
  });

  final _LeadingAnchorCoordinator coordinator;

  @override
  _LeadingAnchorScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return _LeadingAnchorScrollPhysics(
      coordinator: coordinator,
      parent: buildParent(ancestor),
    );
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    if (coordinator.isAnchoring &&
        !isScrolling &&
        newPosition.pixels > _MyHorizontalScrollerState._edgeEpsilon) {
      final baseContentW = coordinator.lastCompensatedContentWidth ??
          (oldPosition.viewportDimension + oldPosition.maxScrollExtent);
      final newContentW =
          newPosition.viewportDimension + newPosition.maxScrollExtent;
      final deltaContentW = newContentW - baseContentW;

      if (deltaContentW.abs() > 0.01) {
        coordinator.recordCompensatedContentWidth(newContentW);
        final target = (newPosition.pixels + deltaContentW).clamp(
          newPosition.minScrollExtent,
          newPosition.maxScrollExtent,
        );
        coordinator.notifyPixelsCompensated(grew: deltaContentW > 0.5);
        return target;
      }
    }

    return super.adjustPositionForNewDimensions(
      oldPosition: oldPosition,
      newPosition: newPosition,
      isScrolling: isScrolling,
      velocity: velocity,
    );
  }
}

/// 桌面与移动端通用的横向滚动容器（内部拖滑 + 滚轮横滚 + 边缘渐隐 + 悬浮翻页箭头）。
///
/// 解决桌面端窄横排（地区胶囊、筛选标签、活跃通道条等）在整窗拖拽环境下的痛点：
/// - **内部滑动不拖母窗**：当内容横向溢出时，鼠标左键按住或手指在滑条内左右滑动只在
///   内部滚动，通过 [MyWindowDragExcludeZone] 隔绝外层窗口拖拽，且参与标准
///   [GestureArena]：轻点（位移未达 [mouseDragSlop]）正常点击子胶囊，拖滑时自动取消
///   子项点击、自带原生惯性滑行，零误触。内容未溢出时自动放行外层母窗拖拽。
/// - **悬停滚轮直接横滚**：鼠标停在任意子元素上滚动普通垂直滚轮即可平滑横滚；未溢出
///   时自动透传外层竖滚。
/// - **边缘渐隐 + 翻页箭头**：仅在对应方向仍有溢出内容时平滑淡入淡出渐变遮罩与 `<` / `>`
///   按钮，支持单击步进与长按连续滚动，内置 [MyDoubleClickConsumeZone] 防高速连点触发窗口最大化。
/// - **头部/尾部动态增删协同**：配合 [MyHorizontalScrollerController] 可自动区分当前视图位置：
///   停在头部时新项直接推入视野；滚离头部时同帧锚定当前视野不跳飞，并柔和轻弹边缘箭头提示。
///
/// **尺寸参数契约**：[fadeWidth]、[indicatorHitWidth]、[indicatorIconSize]、
/// [padding] 显式传入时按 Flutter 逻辑像素直接使用，组件内部不再二次缩放；
/// 为 `null` 时使用基于 ScreenUtil 换算一次的默认值。
class MyHorizontalScroller extends StatefulWidget {
  /// 左侧翻页指示器的测试/定位 Key。
  static const Key leadingIndicatorKey = Key('my-horizontal-scroller-leading');

  /// 右侧翻页指示器的测试/定位 Key。
  static const Key trailingIndicatorKey =
      Key('my-horizontal-scroller-trailing');

  const MyHorizontalScroller({
    super.key,
    required this.child,
    this.controller,
    this.childIsScrollable = false,
    this.padding,
    this.physics,
    this.fadeColor,
    this.indicatorColor,
    this.fadeWidth,
    this.indicatorHitWidth,
    this.indicatorIconSize,
    this.showEdgeIndicators = true,
    this.showGradient = true,
    this.enableMouseWheelScroll = true,
    this.wheelScrollMultiplier = 1.0,
    this.enableMouseDragScroll = true,
    this.mouseDragSlop = 6.0,
    this.enableArrowTapScroll = true,
    this.arrowTapScrollExtent,
    this.enableArrowLongPressScroll = true,
    this.arrowLongPressInitialDelay = const Duration(milliseconds: 260),
    this.arrowLongPressInterval = const Duration(milliseconds: 48),
    this.arrowLongPressStep = 32.0,
    this.arrowHoverScale = 1.18,
  })  : assert(
          !childIsScrollable || controller != null,
          'childIsScrollable=true 时必须提供 controller',
        ),
        assert(
          fadeWidth == null || fadeWidth > 0,
          'fadeWidth 必须大于 0',
        ),
        assert(
          indicatorHitWidth == null || indicatorHitWidth > 0,
          'indicatorHitWidth 必须大于 0',
        ),
        assert(
          indicatorIconSize == null || indicatorIconSize > 0,
          'indicatorIconSize 必须大于 0',
        ),
        assert(
          wheelScrollMultiplier > 0,
          'wheelScrollMultiplier 必须大于 0',
        ),
        assert(
          mouseDragSlop > 0,
          'mouseDragSlop 必须大于 0',
        ),
        assert(
          arrowTapScrollExtent == null || arrowTapScrollExtent > 0,
          'arrowTapScrollExtent 必须大于 0',
        ),
        assert(
          arrowLongPressStep > 0,
          'arrowLongPressStep 必须大于 0',
        ),
        assert(
          arrowHoverScale >= 1.0,
          'arrowHoverScale 必须大于等于 1.0',
        );

  /// 内部横向内容（通常为 `Row`；当 [childIsScrollable] 为 true 时可传 `ListView` 等）。
  final Widget child;

  /// 外部可选的滚动控制器（支持普通 [ScrollController] 或 [MyHorizontalScrollerController]）；
  /// 未提供时由组件内部管理生命周期。
  final ScrollController? controller;

  /// [child] 自身是否已经是可滚动组件。
  ///
  /// - `false`（默认）：内部用横向 [SingleChildScrollView] 包裹 [child]。
  /// - `true`：直接渲染 [child]，此时必须传入与 [child] 共用的 [controller]。
  final bool childIsScrollable;

  /// 内置 [SingleChildScrollView] 的内边距（逻辑像素，不二次缩放）。
  /// 仅在 [childIsScrollable] 为 `false` 时生效。
  final EdgeInsetsGeometry? padding;

  /// 内置 [SingleChildScrollView] 的滚动物理特性。
  /// 仅在 [childIsScrollable] 为 `false` 时生效。
  final ScrollPhysics? physics;

  /// 边缘渐隐底色（应传入实色背景以完全遮盖溢出的文字边缘）。
  /// 为 `null` 时默认取 `Theme.of(context).scaffoldBackgroundColor`。
  final Color? fadeColor;

  /// 左右箭头图标颜色；为 `null` 时按当前主题明暗自动适配。
  final Color? indicatorColor;

  /// 边缘渐隐视觉宽度（逻辑像素）。为 `null` 时默认 `26.w`。
  final double? fadeWidth;

  /// 左右翻页按钮的命中宽度（逻辑像素）。为 `null` 时默认取 `max(fadeWidth, 24.w)`。
  final double? indicatorHitWidth;

  /// 左右箭头图标尺寸（逻辑像素）。为 `null` 时默认 `16.sp`。
  final double? indicatorIconSize;

  /// 是否在有内容溢出时显示边缘指示器（渐隐与箭头）。
  final bool showEdgeIndicators;

  /// 指示器是否渲染渐变淡出遮罩。
  final bool showGradient;

  /// 是否允许鼠标悬停时用滚轮直接横滚。
  final bool enableMouseWheelScroll;

  /// 鼠标滚轮位移倍率，默认 `1.0`。
  final double wheelScrollMultiplier;

  /// 是否允许桌面端鼠标左键按住滑条内部横向拖动滚动（默认 `true`）。
  ///
  /// 参与 Flutter 标准 [GestureArena]，超过 [mouseDragSlop] 时接管横向滚动并自动
  /// 取消子元素点击，绝不误触胶囊；同时屏蔽外层母窗口拖动。
  final bool enableMouseDragScroll;

  /// 鼠标拖动触发横滚的最小水平位移（逻辑像素），默认 `6.0`。
  /// 低于此阈值视为轻点（交回子胶囊），避免点击手抖吞掉点击。
  final double mouseDragSlop;

  /// 是否允许点击左右箭头平滑步进滚动。
  final bool enableArrowTapScroll;

  /// 单击箭头的滚动距离（逻辑像素）；为 `null` 时按视口宽度的 65%（夹在 `80..260`）。
  final double? arrowTapScrollExtent;

  /// 是否允许长按左右箭头连续滚动。
  final bool enableArrowLongPressScroll;

  /// 长按箭头开始连续滚动前的延迟。
  final Duration arrowLongPressInitialDelay;

  /// 长按箭头连续滚动的步进间隔。
  final Duration arrowLongPressInterval;

  /// 长按箭头每步滚动的逻辑像素。
  final double arrowLongPressStep;

  /// 鼠标悬停在箭头上时的轻微放大比例，默认 `1.18`。
  final double arrowHoverScale;

  @override
  State<MyHorizontalScroller> createState() => _MyHorizontalScrollerState();
}

class _MyHorizontalScrollerState extends State<MyHorizontalScroller>
    with TickerProviderStateMixin {
  static const double _edgeEpsilon = 0.5;
  static const Duration _arrowScrollDuration = Duration(milliseconds: 160);
  static const Duration _indicatorFadeDuration = Duration(milliseconds: 160);
  static const Duration _pulseDuration = Duration(milliseconds: 300);

  late ScrollController _scrollController;
  bool _ownsController = false;
  _LeadingAnchorCoordinator? _attachedCoordinator;

  late final AnimationController _leadingPulseController;
  late final AnimationController _trailingPulseController;
  late final Animation<double> _leadingPulseScale;
  late final Animation<double> _trailingPulseScale;

  bool _canScrollLeft = false;
  bool _canScrollRight = false;
  bool _leftHovered = false;
  bool _rightHovered = false;
  bool _isMouseDragging = false;
  bool _pendingTrailingPulse = false;

  late final Ticker _trailingRevealTicker;
  bool _trailingRevealActive = false;
  bool _trailingRevealGlued = false;
  Duration _trailingRevealWindow = Duration.zero;
  Duration? _trailingRevealLastElapsed;

  Drag? _mouseDrag;
  double? _queuedArrowTarget;
  Timer? _holdInitialTimer;
  Timer? _holdRepeatTimer;

  bool get _hasOverflow => _canScrollLeft || _canScrollRight;

  @override
  void initState() {
    super.initState();
    _trailingRevealTicker = createTicker(_onTrailingRevealTick);
    _leadingPulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );
    _trailingPulseController = AnimationController(
      vsync: this,
      duration: _pulseDuration,
    );
    final pulseTween = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.32)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 42,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.32, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 58,
      ),
    ]);
    _leadingPulseScale = pulseTween.animate(_leadingPulseController);
    _trailingPulseScale = pulseTween.animate(_trailingPulseController);

    _attachController(widget.controller);
    _scheduleScrollStateRefresh();
  }

  @override
  void didUpdateWidget(covariant MyHorizontalScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _cancelMouseDrag();
      _detachController();
      _attachController(widget.controller);
      _queuedArrowTarget = null;
    }
    if (!widget.enableArrowLongPressScroll &&
        oldWidget.enableArrowLongPressScroll) {
      _stopHoldScroll();
    }
    if (!widget.enableMouseDragScroll && oldWidget.enableMouseDragScroll) {
      _cancelMouseDrag();
    }
    _scheduleScrollStateRefresh();
  }

  @override
  void dispose() {
    _stopTrailingReveal();
    _trailingRevealTicker.dispose();
    _cancelMouseDrag();
    _stopHoldScroll();
    _detachController();
    _leadingPulseController.dispose();
    _trailingPulseController.dispose();
    super.dispose();
  }

  void _attachController(ScrollController? external) {
    if (external != null) {
      _scrollController = external;
      _ownsController = false;
    } else {
      _scrollController = ScrollController();
      _ownsController = true;
    }
    _scrollController.addListener(_updateScrollState);
    if (_scrollController is MyHorizontalScrollerController) {
      _attachedCoordinator =
          (_scrollController as MyHorizontalScrollerController)._coordinator;
      _attachedCoordinator!.attach(
        onPulse: _triggerPulse,
        onTrailingPulsePending: _scheduleTrailingPulse,
        onTrailingRevealRequested: _startTrailingReveal,
        onTrailingRevealStop: _stopTrailingReveal,
        onPixelsCompensated: _scheduleScrollStateRefresh,
      );
    }
  }

  void _detachController() {
    _stopTrailingReveal();
    _attachedCoordinator?.detach();
    _attachedCoordinator = null;
    _scrollController.removeListener(_updateScrollState);
    if (_ownsController) {
      _scrollController.dispose();
    }
  }

  void _startTrailingReveal(Duration windowDuration) {
    if (!mounted) return;
    _pendingTrailingPulse = false;
    _queuedArrowTarget = null;
    _trailingRevealActive = true;
    _trailingRevealWindow = windowDuration;
    _trailingRevealLastElapsed = null;
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      final pos = _scrollController.position;
      _trailingRevealGlued = (pos.maxScrollExtent - pos.pixels) <= 18.0;
    } else {
      _trailingRevealGlued = false;
    }
    if (_trailingRevealTicker.isActive) {
      _trailingRevealTicker.stop();
    }
    _trailingRevealTicker.start();
  }

  void _stopTrailingReveal() {
    _trailingRevealActive = false;
    _trailingRevealGlued = false;
    _trailingRevealLastElapsed = null;
    if (_trailingRevealTicker.isActive) {
      _trailingRevealTicker.stop();
    }
  }

  void _onTrailingRevealTick(Duration elapsed) {
    if (!mounted || !_trailingRevealActive || !_scrollController.hasClients) {
      _stopTrailingReveal();
      return;
    }
    final pos = _scrollController.position;
    if (!pos.hasContentDimensions) return;

    final prev = _trailingRevealLastElapsed;
    _trailingRevealLastElapsed = elapsed;
    final dtSec = prev == null
        ? (1.0 / 60.0)
        : ((elapsed - prev).inMicroseconds / 1e6).clamp(0.001, 0.05);

    final target = pos.maxScrollExtent;
    final gap = target - pos.pixels;

    if (gap <= _edgeEpsilon) {
      _trailingRevealGlued = true;
      if (elapsed >= _trailingRevealWindow) {
        _stopTrailingReveal();
      }
      return;
    }

    // 超出安全上限直接收口，确保极端大列表下也能干净收敛。
    if (elapsed > _trailingRevealWindow + const Duration(milliseconds: 900)) {
      _scrollController.jumpTo(target);
      _stopTrailingReveal();
      return;
    }

    if (_trailingRevealGlued && gap <= 24.0) {
      // 已贴紧右缘且子项正在逐帧展开（如 SizeTransition）：1:1 跟随目标右缘，
      // 直接沿用子项自身的 easeOutCubic 曲线，零抖动零滞后。
      _scrollController.jumpTo(target);
      return;
    }

    // 跨越较长距离滚向尾部：指数衰减平滑追随（对动态增长的 maxScrollExtent 同样单曲线丝滑）。
    const tau = 0.065;
    final step = math.max(gap * (1.0 - math.exp(-dtSec / tau)), 1.0);
    final next = (pos.pixels + step).clamp(pos.minScrollExtent, target);
    if ((target - next) < 0.6) {
      _scrollController.jumpTo(target);
      _trailingRevealGlued = true;
    } else {
      _scrollController.jumpTo(next);
    }
  }

  void _triggerPulse(bool isLeft) {
    if (!mounted || !widget.showEdgeIndicators) return;
    if (isLeft) {
      if (!_canScrollLeft) return;
      _leadingPulseController.forward(from: 0.0);
    } else {
      if (!_canScrollRight) return;
      _trailingPulseController.forward(from: 0.0);
    }
  }

  void _scheduleTrailingPulse() {
    _pendingTrailingPulse = true;
    _scheduleScrollStateRefresh();
  }

  void _scheduleScrollStateRefresh() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateScrollState();
      if (_pendingTrailingPulse) {
        _pendingTrailingPulse = false;
        if (_canScrollRight) {
          _triggerPulse(false);
        }
      }
    });
  }

  void _updateScrollState() {
    if (!mounted || !_scrollController.hasClients) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks) {
      _scheduleScrollStateRefresh();
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return;
    }

    final nextLeft = position.pixels > position.minScrollExtent + _edgeEpsilon;
    final nextRight = position.pixels < position.maxScrollExtent - _edgeEpsilon;

    if (nextLeft != _canScrollLeft || nextRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = nextLeft;
        _canScrollRight = nextRight;
        if (!nextLeft) _leftHovered = false;
        if (!nextRight) _rightHovered = false;
      });
    }

    if (!nextLeft && !nextRight) {
      _queuedArrowTarget = null;
      return;
    }

    final queued = _queuedArrowTarget;
    if (queued != null) {
      final clamped =
          queued.clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((clamped - position.pixels).abs() < 1.0) {
        _queuedArrowTarget = null;
      } else {
        _queuedArrowTarget = clamped;
      }
    }
  }

  void _handleMouseDragStart(DragStartDetails details) {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) return;

    _attachedCoordinator?.stopLeadingAnchor();
    _stopTrailingReveal();
    _queuedArrowTarget = null;
    _mouseDrag?.cancel();
    _mouseDrag = position.drag(details, () {
      _mouseDrag = null;
    });
    if (!_isMouseDragging && mounted) {
      setState(() => _isMouseDragging = true);
    }
  }

  void _handleMouseDragUpdate(DragUpdateDetails details) {
    _mouseDrag?.update(details);
  }

  void _handleMouseDragEnd(DragEndDetails details) {
    final drag = _mouseDrag;
    _mouseDrag = null;
    drag?.end(details);
    if (_isMouseDragging && mounted) {
      setState(() => _isMouseDragging = false);
    }
  }

  void _cancelMouseDrag() {
    final drag = _mouseDrag;
    _mouseDrag = null;
    drag?.cancel();
    if (_isMouseDragging && mounted) {
      setState(() => _isMouseDragging = false);
    }
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (!widget.enableMouseWheelScroll) return;
    if (event is! PointerScrollEvent) return;
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }

    // 优先尊重原生横向滚轮/触控板横滑，否则把普通垂直滚轮映射为横滚。
    final primaryDelta =
        event.scrollDelta.dx.abs() >= event.scrollDelta.dy.abs()
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;
    if (primaryDelta == 0) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (_) {
      if (!mounted || !_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (!pos.hasContentDimensions || pos.maxScrollExtent <= 0) return;

      _attachedCoordinator?.stopLeadingAnchor();
      _stopTrailingReveal();
      _queuedArrowTarget = null;
      final target = (pos.pixels + primaryDelta * widget.wheelScrollMultiplier)
          .clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if ((target - pos.pixels).abs() < 0.5) return;
      _scrollController.jumpTo(target);
    });
  }

  void _scrollByArrow({required bool isLeft}) {
    if (!widget.enableArrowTapScroll) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions || !position.hasViewportDimension) {
      return;
    }

    _attachedCoordinator?.stopLeadingAnchor();
    _stopTrailingReveal();

    final step = widget.arrowTapScrollExtent ??
        (position.viewportDimension * 0.65).clamp(80.0, 260.0);

    final queued = _queuedArrowTarget;
    final basePixels = queued == null
        ? position.pixels
        : (isLeft
            ? math.min(position.pixels, queued)
            : math.max(position.pixels, queued));

    final target = (isLeft ? basePixels - step : basePixels + step)
        .clamp(position.minScrollExtent, position.maxScrollExtent);

    if ((target - position.pixels).abs() < _edgeEpsilon) {
      _queuedArrowTarget = null;
      return;
    }

    _queuedArrowTarget = target;
    _scrollController
        .animateTo(
      target,
      duration: _arrowScrollDuration,
      curve: Curves.easeOutCubic,
    )
        .whenComplete(() {
      if (!mounted || !_scrollController.hasClients) return;
      final current = _scrollController.position.pixels;
      if ((current - target).abs() < 1.0) {
        _queuedArrowTarget = null;
      }
    });
  }

  void _startHoldScroll({required bool isLeft}) {
    if (!widget.enableArrowLongPressScroll) return;
    if (!_scrollController.hasClients) return;

    _attachedCoordinator?.stopLeadingAnchor();
    _stopTrailingReveal();
    _stopHoldScroll();
    _jumpByHoldStep(isLeft: isLeft);

    _holdInitialTimer = Timer(widget.arrowLongPressInitialDelay, () {
      if (!mounted) return;
      _holdRepeatTimer = Timer.periodic(widget.arrowLongPressInterval, (_) {
        if (!mounted || !_jumpByHoldStep(isLeft: isLeft)) {
          _stopHoldScroll();
        }
      });
    });
  }

  bool _jumpByHoldStep({required bool isLeft}) {
    if (!_scrollController.hasClients) return false;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return false;

    final delta =
        isLeft ? -widget.arrowLongPressStep : widget.arrowLongPressStep;
    final target = (position.pixels + delta)
        .clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((target - position.pixels).abs() < _edgeEpsilon) {
      return false;
    }

    _scrollController.jumpTo(target);
    _queuedArrowTarget = target;
    return true;
  }

  void _stopHoldScroll() {
    _holdInitialTimer?.cancel();
    _holdInitialTimer = null;
    _holdRepeatTimer?.cancel();
    _holdRepeatTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fadeColor = widget.fadeColor ?? theme.scaffoldBackgroundColor;
    final indicatorColor =
        widget.indicatorColor ?? (isDark ? Colors.white : Colors.black87);
    final fadeWidth = widget.fadeWidth ?? 26.w;
    final hitWidth = widget.indicatorHitWidth ?? math.max(fadeWidth, 24.w);
    final iconSize = widget.indicatorIconSize ?? 16.sp;

    final effectivePhysics = _attachedCoordinator != null
        ? _LeadingAnchorScrollPhysics(
            coordinator: _attachedCoordinator!,
            parent: widget.physics,
          )
        : widget.physics;

    final Widget scrollable = widget.childIsScrollable
        ? widget.child
        : SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: widget.padding,
            physics: effectivePhysics,
            child: widget.child,
          );

    // 桌面鼠标左键横向拖滑：走正规 GestureArena + 可调 slop，
    // 轻点（< slop）交回子项 onTap，明确横拖自动取消子项点击并原生惯性滚。
    final Widget dragAwareScrollable = RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        _MouseHorizontalDragRecognizer: GestureRecognizerFactoryWithHandlers<
            _MouseHorizontalDragRecognizer>(
          () => _MouseHorizontalDragRecognizer(
            debugOwner: this,
            isEnabled: () => widget.enableMouseDragScroll && _hasOverflow,
            slop: widget.mouseDragSlop,
          ),
          (_MouseHorizontalDragRecognizer instance) {
            instance.isEnabled =
                () => widget.enableMouseDragScroll && _hasOverflow;
            instance.slop = widget.mouseDragSlop;
            instance.onStart = _handleMouseDragStart;
            instance.onUpdate = _handleMouseDragUpdate;
            instance.onEnd = _handleMouseDragEnd;
            instance.onCancel = _cancelMouseDrag;
          },
        ),
      },
      child: MouseRegion(
        cursor:
            _isMouseDragging ? SystemMouseCursors.grabbing : MouseCursor.defer,
        child: scrollable,
      ),
    );

    final showLeft = widget.showEdgeIndicators && _canScrollLeft;
    final showRight = widget.showEdgeIndicators && _canScrollRight;

    return MyWindowDragExcludeZone(
      enabled: _hasOverflow,
      behavior: HitTestBehavior.translucent,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification &&
              notification.dragDetails != null) {
            // 用户手指触屏开始滑动时立即退出头部锚定与尾部跟滚，绝不与手动滑动打架。
            _attachedCoordinator?.stopLeadingAnchor();
            _stopTrailingReveal();
          }
          return false;
        },
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (_) {
            _updateScrollState();
            return false;
          },
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: _handlePointerSignal,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                dragAwareScrollable,
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: _indicatorFadeDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: showLeft
                        ? _buildEdgeIndicator(
                            isLeft: true,
                            fadeColor: fadeColor,
                            indicatorColor: indicatorColor,
                            fadeWidth: fadeWidth,
                            hitWidth: hitWidth,
                            iconSize: iconSize,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: AnimatedSwitcher(
                    duration: _indicatorFadeDuration,
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: showRight
                        ? _buildEdgeIndicator(
                            isLeft: false,
                            fadeColor: fadeColor,
                            indicatorColor: indicatorColor,
                            fadeWidth: fadeWidth,
                            hitWidth: hitWidth,
                            iconSize: iconSize,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeIndicator({
    required bool isLeft,
    required Color fadeColor,
    required Color indicatorColor,
    required double fadeWidth,
    required double hitWidth,
    required double iconSize,
  }) {
    final hovered = isLeft ? _leftHovered : _rightHovered;
    final canInteract = widget.enableArrowTapScroll;
    final scale = hovered ? widget.arrowHoverScale : 1.0;
    final iconOpacity = hovered ? 0.96 : 0.72;
    final pulseScale = isLeft ? _leadingPulseScale : _trailingPulseScale;

    final decoration = widget.showGradient
        ? BoxDecoration(
            gradient: LinearGradient(
              begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
              end: isLeft ? Alignment.centerRight : Alignment.centerLeft,
              stops: const [0.0, 0.52, 1.0],
              colors: [
                fadeColor,
                fadeColor.withValues(alpha: 0.9),
                fadeColor.withValues(alpha: 0.0),
              ],
            ),
          )
        : null;

    void setHover(bool value) {
      final current = isLeft ? _leftHovered : _rightHovered;
      if (current == value || !mounted) return;
      setState(() {
        if (isLeft) {
          _leftHovered = value;
        } else {
          _rightHovered = value;
        }
      });
    }

    return MyWindowDragExcludeZone(
      key: ValueKey<String>(isLeft ? 'edge-left' : 'edge-right'),
      behavior: HitTestBehavior.opaque,
      child: MyDoubleClickConsumeZone(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            if (!canInteract) return;
            // 鼠标主键按下即触发，避免高速连点被双击手势窗口吞掉。
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons == kPrimaryMouseButton) {
              _scrollByArrow(isLeft: isLeft);
            }
          },
          onPointerUp: (_) => _stopHoldScroll(),
          onPointerCancel: (_) => _stopHoldScroll(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            // 显式消费点击与拖拽，阻止穿透到底层被遮挡的子项。
            onTap: () {},
            onTapDown: (details) {
              if (!canInteract) return;
              if (details.kind == PointerDeviceKind.mouse) return;
              _scrollByArrow(isLeft: isLeft);
            },
            onLongPressStart: canInteract && widget.enableArrowLongPressScroll
                ? (_) => _startHoldScroll(isLeft: isLeft)
                : null,
            onLongPressEnd: canInteract && widget.enableArrowLongPressScroll
                ? (_) => _stopHoldScroll()
                : null,
            onLongPressCancel: canInteract && widget.enableArrowLongPressScroll
                ? _stopHoldScroll
                : null,
            child: MouseRegion(
              cursor:
                  canInteract ? SystemMouseCursors.click : MouseCursor.defer,
              onEnter: (_) => setHover(true),
              onExit: (_) => setHover(false),
              child: SizedBox(
                key: isLeft
                    ? MyHorizontalScroller.leadingIndicatorKey
                    : MyHorizontalScroller.trailingIndicatorKey,
                width: hitWidth,
                child: Align(
                  alignment:
                      isLeft ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    width: fadeWidth,
                    height: double.infinity,
                    decoration: decoration,
                    alignment:
                        isLeft ? Alignment.centerLeft : Alignment.centerRight,
                    child: ScaleTransition(
                      scale: pulseScale,
                      child: AnimatedScale(
                        scale: scale,
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: iconOpacity,
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOutCubic,
                          child: Icon(
                            isLeft
                                ? Icons.chevron_left_rounded
                                : Icons.chevron_right_rounded,
                            size: iconSize,
                            color: indicatorColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 仅响应桌面鼠标主键的横向拖拽识别器：
/// - 轻点（水平位移 ≤ [slop]）不赢得竞技场，点击无阻透传到胶囊 `onTap`；
/// - 明确横拖（> [slop]）赢得竞技场，自动取消子项点击并驱动滚动容器。
class _MouseHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  _MouseHorizontalDragRecognizer({
    super.debugOwner,
    required this.isEnabled,
    required this.slop,
  }) {
    onlyAcceptDragOnThreshold = true;
  }

  bool Function() isEnabled;
  double slop;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!isEnabled()) return false;
    if (event.kind != PointerDeviceKind.mouse) return false;
    if (event is PointerDownEvent && event.buttons != kPrimaryMouseButton) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return globalDistanceMoved.abs() > slop;
  }
}
