part of '../../xly.dart';

class _FloatBoxPanel extends StatefulWidget {
  final Key? panelKey;
  // 缩放基础值（用于 ScreenUtil 计算）
  final double panelWidthInput;
  final double borderWidthInput;
  final double iconSizeInput;
  final BorderRadius? borderRadiusInput;
  final double panelOpenOffsetInput;

  // defaults (avoid dependency on user_code/global.dart)
  static const double _kDefaultPanelWidth = 50.0;
  static const double _kDefaultBorderRadius = 10.0;

  // Calculated properties
  final double finalPanelWidth;
  final double finalBorderWidth;
  final double finalIconSize;
  final BorderRadius finalBorderRadius;
  final double finalPanelOpenOffset;
  final double finalDockOffset;

  _FloatBoxPanel({
    this.panelKey,
    this.panelWidthInput = _kDefaultPanelWidth,
    this.borderWidthInput = 0,
    this.iconSizeInput = 24,
    this.borderRadiusInput,
    this.panelOpenOffsetInput = 5.0,
  })  : finalPanelWidth = panelWidthInput,
        finalBorderWidth =
            borderWidthInput * (panelWidthInput / _kDefaultPanelWidth),
        finalIconSize = iconSizeInput * (panelWidthInput / _kDefaultPanelWidth),
        finalBorderRadius = borderRadiusInput ??
            BorderRadius.circular(_kDefaultBorderRadius *
                (panelWidthInput / _kDefaultPanelWidth)),
        finalPanelOpenOffset =
            panelOpenOffsetInput * (panelWidthInput / _kDefaultPanelWidth),
        finalDockOffset = panelWidthInput / 2,
        super(key: panelKey) {
    Get.put(
      FloatBoxController(),
      tag: panelKey?.toString(),
    );
  }

  @override
  State<_FloatBoxPanel> createState() => _FloatBoxPanelState();
}

class _FloatBoxPanelState extends State<_FloatBoxPanel> {
  final GlobalKey _panelRenderKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<FloatBoxController>(tag: widget.panelKey?.toString());

    // 先计算并更新缩放值，确保后续 updateScreenSize 中的位置限位
    // 使用正确的 effectivePanelHeight（依赖 currentPanelWidth）
    final scaledPanelWidth = widget.finalPanelWidth.w;
    final scaledBorderWidth = widget.finalBorderWidth.w;
    final scaledIconSize = widget.finalIconSize.sp;
    final scaledBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(widget.finalBorderRadius.topLeft.x.r),
      topRight: Radius.circular(widget.finalBorderRadius.topRight.x.r),
      bottomLeft: Radius.circular(widget.finalBorderRadius.bottomLeft.x.r),
      bottomRight: Radius.circular(widget.finalBorderRadius.bottomRight.x.r),
    );
    final scaledPanelOpenOffset = widget.finalPanelOpenOffset.w;
    final scaledDockOffset = widget.finalDockOffset.w;

    ctrl.updateScaledDimensions(
      scaledPanelWidth: scaledPanelWidth,
      scaledBorderWidth: scaledBorderWidth,
      scaledIconSize: scaledIconSize,
      scaledBorderRadius: scaledBorderRadius,
      scaledPanelOpenOffset: scaledPanelOpenOffset,
      scaledDockOffset: scaledDockOffset,
    );

    // 在缩放值更新后再更新屏幕尺寸，此时位置限位能正确使用新的面板高度
    ctrl.updateScreenSize(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Obx(() => AnimatedPositioned(
          duration: Duration(milliseconds: ctrl.movementSpeed.value),
          top: ctrl.yOffset.value,
          left: ctrl.xOffset.value,
          curve: ctrl.dockAnimCurve,
          child: AnimatedContainer(
            key: _panelRenderKey,
            duration: Duration(milliseconds: ctrl.panelAnimDuration),
            width: ctrl.effectivePanelWidth,
            height: ctrl.effectivePanelHeight,
            decoration: BoxDecoration(
              color: ctrl.backgroundColor,
              borderRadius: ctrl.effectiveBorderRadius,
              border: ctrl.effectivePanelBorder,
            ),
            curve: ctrl.panelAnimCurve,
            child: _buildPanelLayout(ctrl),
          ),
        ));
  }

  /// 构建面板内部布局（handle + items），根据展开方向和 RTL 排列
  Widget _buildPanelLayout(FloatBoxController ctrl) {
    final handleButton = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (_) => ctrl.onPanEndGesture(),
      onPanStart: (d) => ctrl.onPanStartGesture(d.globalPosition),
      onPanUpdate: (d) => ctrl.onPanUpdateGesture(d.globalPosition),
      onTap: () => ctrl.onInnerButtonTap(),
      child: MouseRegion(
        onEnter: (_) => ctrl.setButtonFocus(0, true),
        onExit: (_) => ctrl.setButtonFocus(0, false),
        cursor: SystemMouseCursors.click,
        child: Obx(() => _FloatButton(
              focusColor: ctrl.innerButtonFocusColor,
              size: ctrl.currentPanelWidth.value,
              icon: ctrl.panelIcon.value,
              color: ctrl.panelButtonColor,
              hightLight:
                  ctrl.isFocusColors.isNotEmpty ? ctrl.isFocusColors[0] : false,
              iconSize: ctrl.currentIconSize.value,
            )),
      ),
    );

    final itemsWidget = Obx(() {
      final currentItems = FloatPanel.to.items;
      final buttonList = List.generate(currentItems.length, (index) {
        final item = currentItems[index];
        final disabledSet = FloatPanel.to.disabledIds;
        final highlightedSet = FloatPanel.to.highlightedIds;
        final bool iconBtnDisabledMatch =
            item.id != null && disabledSet.contains(item.id);
        final bool explicitDisabled = item.disabled == true;
        final bool isEnabled = !(iconBtnDisabledMatch || explicitDisabled);
        final bool isDisabledLinked = iconBtnDisabledMatch;
        final bool forcedHighlighted =
            item.id != null && highlightedSet.contains(item.id);
        final Widget gestureWidget = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanEnd: (_) => ctrl.onPanEndGesture(),
          onPanStart: (d) => ctrl.onPanStartGesture(d.globalPosition),
          onPanUpdate: (d) => ctrl.onPanUpdateGesture(d.globalPosition),
          onTap: () async {
            if (!isEnabled) return;
            if (item.onTap != null) {
              try {
                await item.onTap!();
              } catch (e, s) {
                XlyLogger.error('FloatPanelIconBtn.onTap error', e, s);
              }
            }
          },
          child: MouseRegion(
            onEnter: (_) => ctrl.setButtonFocus(index + 1, true),
            onExit: (_) => ctrl.setButtonFocus(index + 1, false),
            cursor: SystemMouseCursors.click,
            child: _FloatButton(
              key: ValueKey('float_button_${index}_$isEnabled'),
              focusColor: ctrl.customButtonFocusColor,
              size: ctrl.currentPanelWidth.value,
              icon: item.icon,
              color: ctrl.customButtonColor,
              hightLight: ctrl.isFocusColors.length > index + 1
                  ? ctrl.isFocusColors[index + 1]
                  : false,
              iconSize: ctrl.currentIconSize.value,
              enabled: isEnabled,
              isHighlighted: forcedHighlighted || isDisabledLinked,
            ),
          ),
        );
        // 仅在 tooltip 非空时套 Tooltip，避免无意义的 widget 开销。
        // 0.38.0 起 FloatPanelIconBtn.tooltip 完整渲染与智能避让（此前字段未使用）。
        final tip = item.tooltip;
        return (tip != null && tip.isNotEmpty)
            ? _FloatPanelTooltip(
                message: tip,
                controller: ctrl,
                panelKey: _panelRenderKey,
                child: gestureWidget,
              )
            : gestureWidget;
      });

      // RTL 模式下反转按钮视觉顺序，使 btn1 紧挨 handle
      final orderedList =
          ctrl._isRtlExpand ? buttonList.reversed.toList() : buttonList;

      return Visibility(
        visible: ctrl.panelState.value == PanelState.expanded,
        child: Flex(
          direction: ctrl._isHorizontalExpand ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          children: orderedList,
        ),
      );
    });

    // RTL 模式下 handle 在右端：调换 handle 和 items 的顺序
    final children = ctrl._isRtlExpand
        ? [itemsWidget, handleButton]
        : [handleButton, itemsWidget];

    return Wrap(
      direction: ctrl._isHorizontalExpand ? Axis.vertical : Axis.horizontal,
      children: children,
    );
  }
}

class _FloatPanelTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final FloatBoxController controller;
  final GlobalKey panelKey;

  const _FloatPanelTooltip({
    required this.message,
    required this.child,
    required this.controller,
    required this.panelKey,
  });

  @override
  State<_FloatPanelTooltip> createState() => _FloatPanelTooltipState();
}

class _FloatPanelTooltipState extends State<_FloatPanelTooltip> {
  static const Duration _waitDuration = Duration(milliseconds: 400);
  static const Duration _fadeInDuration = Duration(milliseconds: 120);
  static const Duration _fadeOutDuration = Duration(milliseconds: 120);

  // 用 ValueNotifier 通知 overlay 触发 AnimatedOpacity 淡入/淡出。
  final ValueNotifier<bool> _visibility = ValueNotifier<bool>(false);

  Timer? _showTimer;
  Timer? _removeTimer;
  OverlayEntry? _overlayEntry;
  Worker? _xWorker;
  Worker? _yWorker;

  @override
  void didUpdateWidget(covariant _FloatPanelTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) {
      _hideImmediately();
    }
  }

  @override
  void dispose() {
    _hideImmediately();
    _visibility.dispose();
    super.dispose();
  }

  void _scheduleTooltip() {
    _showTimer?.cancel();
    _showTimer = Timer(_waitDuration, _showTooltip);
  }

  void _showTooltip() {
    if (!mounted || _overlayEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    final overlayObject = overlay.context.findRenderObject();
    final targetObject = context.findRenderObject();
    final panelObject = widget.panelKey.currentContext?.findRenderObject();
    if (overlayObject is! RenderBox ||
        targetObject is! RenderBox ||
        panelObject is! RenderBox ||
        !overlayObject.hasSize ||
        !targetObject.hasSize ||
        !panelObject.hasSize) {
      return;
    }

    final targetRect = _rectInOverlay(targetObject, overlayObject);
    final panelRect = _rectInOverlay(panelObject, overlayObject);
    final preferVerticalPlacement = widget.controller._isHorizontalExpand;

    _removeTimer?.cancel();
    _removeTimer = null;
    _visibility.value = false;
    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatPanelTooltipOverlay(
        message: widget.message,
        targetRect: targetRect,
        panelRect: panelRect,
        preferVerticalPlacement: preferVerticalPlacement,
        visibility: _visibility,
        fadeInDuration: _fadeInDuration,
        fadeOutDuration: _fadeOutDuration,
      ),
    );
    overlay.insert(_overlayEntry!);
    // 第一帧 opacity=0，post-frame 再切到 true 触发淡入动画。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _overlayEntry != null) _visibility.value = true;
    });

    // 浮动条任意位置变化都视为"用户开始操作"，立刻淡出 tooltip，
    // 避免气泡和按钮位置错位。停靠/展开收起也会改 xOffset/yOffset。
    _xWorker = ever<double>(
      widget.controller.xOffset,
      (_) => _startHide(),
    );
    _yWorker = ever<double>(
      widget.controller.yOffset,
      (_) => _startHide(),
    );
  }

  Rect _rectInOverlay(RenderBox box, RenderBox overlayBox) {
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  /// 触发淡出动画，等动画结束再真正 remove overlay。
  void _startHide() {
    _showTimer?.cancel();
    _showTimer = null;
    _disposeMovementWatchers();
    if (_overlayEntry == null) return;
    _setVisibility(false);
    _removeTimer?.cancel();
    _removeTimer = Timer(_fadeOutDuration, _removeOverlay);
  }

  /// 不走动画直接销毁（用于 dispose / message 变化场景）。
  void _hideImmediately() {
    _showTimer?.cancel();
    _showTimer = null;
    _removeTimer?.cancel();
    _removeTimer = null;
    _disposeMovementWatchers();
    _setVisibility(false);
    _removeOverlay();
  }

  void _setVisibility(bool visible) {
    if (_visibility.value == visible) return;

    void apply() {
      if (!mounted || _visibility.value == visible) return;
      _visibility.value = visible;
    }

    // 窗口缩放会在 FloatBoxPanel.build 期间同步更新位置；位置监听此时隐藏
    // tooltip 会要求 overlay 重建，必须延后到本帧结束后再通知。
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => apply());
      return;
    }
    apply();
  }

  void _disposeMovementWatchers() {
    _xWorker?.dispose();
    _yWorker?.dispose();
    _xWorker = null;
    _yWorker = null;
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      tooltip: widget.message,
      child: MouseRegion(
        onEnter: (_) => _scheduleTooltip(),
        onExit: (_) => _startHide(),
        child: widget.child,
      ),
    );
  }
}

/// 气泡相对浮动条的位置（"哪一侧的尾巴指向按钮"）。
enum _FloatPanelTooltipSide { left, right, top, bottom }

/// Tooltip overlay：先离屏测量气泡尺寸，再按计算好的位置和尾巴绘制。
class _FloatPanelTooltipOverlay extends StatefulWidget {
  final String message;
  final Rect targetRect;
  final Rect panelRect;
  final bool preferVerticalPlacement;
  final ValueListenable<bool> visibility;
  final Duration fadeInDuration;
  final Duration fadeOutDuration;

  const _FloatPanelTooltipOverlay({
    required this.message,
    required this.targetRect,
    required this.panelRect,
    required this.preferVerticalPlacement,
    required this.visibility,
    required this.fadeInDuration,
    required this.fadeOutDuration,
  });

  @override
  State<_FloatPanelTooltipOverlay> createState() =>
      _FloatPanelTooltipOverlayState();
}

class _FloatPanelTooltipOverlayState extends State<_FloatPanelTooltipOverlay> {
  // --- 设计稿基础值（与 Material 默认 Tooltip 风格一致）---
  // 通过 ScreenUtil 在运行时缩放，避免在窗口缩放后 tooltip 游离于 FloatPanel
  // 主体的尺寸体系外。横向 layout 用 .w，对称几何与圆角用 .r，字号用 .sp。
  static const double _kBaseGap = 6.0;
  static const double _kBaseScreenMargin = 8.0;
  // 默认"理智上限"：足够装下大多数 tooltip 一行，太长才换行。
  // 调用方可通过 TooltipTheme.constraints.maxWidth 覆盖此默认值。
  static const double _kBaseMaxBubbleWidth = 320.0;
  // _kBaseMinBubbleWidth 仅用于"哪一侧空间够"的判断阈值，不再作用到气泡的
  // BoxConstraints.minWidth，避免短文本被强行撑宽。
  static const double _kBaseMinBubbleWidth = 60.0;
  static const double _kBaseTailLength = 6.0;
  static const double _kBaseTailHalfWidth = 5.0;
  static const double _kBaseBubbleCornerRadius = 4.0;
  static const double _kBaseTailSafeMargin = 2.0;
  static const double _kBaseDefaultFontSize = 14.0;
  static const double _kBaseDefaultPaddingH = 16.0;
  static const double _kBaseDefaultPaddingV = 4.0;
  // 与 Material 默认 Tooltip 一致的颜色（亮色主题 / 暗色主题）
  static const Color _bubbleColorLight = Color(0xE6616161);
  static const Color _bubbleColorDark = Color(0xE6FFFFFF);

  // --- 运行时缩放后的尺寸（每次 build 重取，跟随 ScreenUtil 当前比例）---
  double get _gap => _kBaseGap.w;
  double get _screenMargin => _kBaseScreenMargin.w;
  double get _maxBubbleWidth => _kBaseMaxBubbleWidth.w;
  double get _minBubbleWidth => _kBaseMinBubbleWidth.w;
  double get _tailLength => _kBaseTailLength.r;
  double get _tailHalfWidth => _kBaseTailHalfWidth.r;
  double get _bubbleCornerRadius => _kBaseBubbleCornerRadius.r;
  double get _tailSafeMargin => _kBaseTailSafeMargin.r;

  final GlobalKey _bubbleKey = GlobalKey();
  Size? _bubbleSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureBubble());
  }

  void _measureBubble() {
    if (!mounted) return;
    final renderObject = _bubbleKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;
    final size = renderObject.size;
    if (_bubbleSize == size) return;
    setState(() => _bubbleSize = size);
  }

  /// 根据浮动条所在一侧 + 当前 hover 按钮的位置，决定气泡可用最大宽度。
  /// 不能跨过浮动条本身，否则气泡会盖在浮动条上。
  ///
  /// [effectiveMax] 是"理智上限"，由 [TooltipTheme.constraints.maxWidth]
  /// 覆盖（若设置）或回落到 [_maxBubbleWidth]。最终 maxWidth = min(可用空间, effectiveMax)，
  /// 兜底不小于 [_minBubbleWidth]，避免极窄屏幕下算出 0/负值。
  double _resolveMaxWidth(Size overlaySize, double effectiveMax) {
    if (widget.preferVerticalPlacement) {
      final available = overlaySize.width - (_screenMargin * 2);
      return _clampMaxWidth(available, effectiveMax);
    }

    final leftSpace =
        widget.panelRect.left - _screenMargin - _gap - _tailLength;
    final rightSpace = overlaySize.width -
        widget.panelRect.right -
        _screenMargin -
        _gap -
        _tailLength;
    final preferRight = widget.panelRect.center.dx < overlaySize.width / 2;
    final preferred = preferRight ? rightSpace : leftSpace;
    final fallback = rightSpace > leftSpace ? rightSpace : leftSpace;
    final available = preferred >= _minBubbleWidth ? preferred : fallback;
    return _clampMaxWidth(available, effectiveMax);
  }

  /// 取 min(available, effectiveMax)，并兜底不小于 [_minBubbleWidth]。
  /// 不再像旧实现那样把过短的可用空间硬撑回 [_minBubbleWidth] 之上当 max 用——
  /// 那会让气泡比可用空间更宽并撞到浮动条。这里只在算出 0/负值时兜底。
  double _clampMaxWidth(double available, double effectiveMax) {
    final upper = available < effectiveMax ? available : effectiveMax;
    return upper < _minBubbleWidth ? _minBubbleWidth : upper;
  }

  /// 选定气泡放在哪一侧。preferVerticalPlacement = true 时只考虑上下，否则只考虑左右。
  /// 优先放在浮动条远离屏幕中心的反方向，避免和浮动条重叠。
  _FloatPanelTooltipSide _resolveSide(Size overlaySize, Size bubbleSize) {
    if (widget.preferVerticalPlacement) {
      final spaceBelow = overlaySize.height -
          widget.panelRect.bottom -
          _gap -
          _tailLength -
          _screenMargin;
      final spaceAbove =
          widget.panelRect.top - _gap - _tailLength - _screenMargin;
      final preferBelow = widget.panelRect.center.dy < overlaySize.height / 2;

      if (preferBelow && spaceBelow >= bubbleSize.height) {
        return _FloatPanelTooltipSide.bottom;
      }
      if (!preferBelow && spaceAbove >= bubbleSize.height) {
        return _FloatPanelTooltipSide.top;
      }
      if (spaceBelow >= bubbleSize.height) return _FloatPanelTooltipSide.bottom;
      if (spaceAbove >= bubbleSize.height) return _FloatPanelTooltipSide.top;
      return spaceBelow >= spaceAbove
          ? _FloatPanelTooltipSide.bottom
          : _FloatPanelTooltipSide.top;
    }

    final spaceRight = overlaySize.width -
        widget.panelRect.right -
        _gap -
        _tailLength -
        _screenMargin;
    final spaceLeft =
        widget.panelRect.left - _gap - _tailLength - _screenMargin;
    final preferRight = widget.panelRect.center.dx < overlaySize.width / 2;

    if (preferRight && spaceRight >= bubbleSize.width) {
      return _FloatPanelTooltipSide.right;
    }
    if (!preferRight && spaceLeft >= bubbleSize.width) {
      return _FloatPanelTooltipSide.left;
    }
    if (spaceRight >= bubbleSize.width) return _FloatPanelTooltipSide.right;
    if (spaceLeft >= bubbleSize.width) return _FloatPanelTooltipSide.left;
    return spaceRight >= spaceLeft
        ? _FloatPanelTooltipSide.right
        : _FloatPanelTooltipSide.left;
  }

  /// 计算气泡左上角在 overlay 内的位置。垂直方向上按按钮中心对齐，
  /// 水平方向上按按钮中心对齐；越界时夹回到屏幕安全区。
  Offset _calculateBubbleOrigin(
      Size overlaySize, Size bubbleSize, _FloatPanelTooltipSide side) {
    double left;
    double top;
    switch (side) {
      case _FloatPanelTooltipSide.right:
        left = widget.panelRect.right + _gap + _tailLength;
        top = widget.targetRect.center.dy - bubbleSize.height / 2;
        break;
      case _FloatPanelTooltipSide.left:
        left = widget.panelRect.left - _gap - _tailLength - bubbleSize.width;
        top = widget.targetRect.center.dy - bubbleSize.height / 2;
        break;
      case _FloatPanelTooltipSide.bottom:
        left = widget.targetRect.center.dx - bubbleSize.width / 2;
        top = widget.panelRect.bottom + _gap + _tailLength;
        break;
      case _FloatPanelTooltipSide.top:
        left = widget.targetRect.center.dx - bubbleSize.width / 2;
        top = widget.panelRect.top - _gap - _tailLength - bubbleSize.height;
        break;
    }

    final maxLeft = overlaySize.width - _screenMargin - bubbleSize.width;
    final maxTop = overlaySize.height - _screenMargin - bubbleSize.height;
    final clampedLeft =
        maxLeft >= _screenMargin ? left.clamp(_screenMargin, maxLeft) : left;
    final clampedTop =
        maxTop >= _screenMargin ? top.clamp(_screenMargin, maxTop) : top;
    return Offset(clampedLeft.toDouble(), clampedTop.toDouble());
  }

  /// 尾巴尖端在 overlay 内的全局坐标，应正对按钮中心一侧的浮动条边缘。
  Offset _tailTipGlobal(_FloatPanelTooltipSide side) {
    switch (side) {
      case _FloatPanelTooltipSide.right:
        return Offset(widget.panelRect.right, widget.targetRect.center.dy);
      case _FloatPanelTooltipSide.left:
        return Offset(widget.panelRect.left, widget.targetRect.center.dy);
      case _FloatPanelTooltipSide.bottom:
        return Offset(widget.targetRect.center.dx, widget.panelRect.bottom);
      case _FloatPanelTooltipSide.top:
        return Offset(widget.targetRect.center.dx, widget.panelRect.top);
    }
  }

  Widget _buildBubbleContent(BuildContext context, double maxWidth) {
    final tooltipTheme = TooltipTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultTextColor = isDark ? Colors.black : Colors.white;
    // 调用方未通过 TooltipTheme 接管时，用 ScreenUtil 缩放过的默认字号 / padding；
    // 一旦 TooltipTheme.textStyle / padding 显式给值，认为外部要自己控制，不二次缩放。
    final defaultFontSize = _kBaseDefaultFontSize.sp;
    final defaultTextStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: defaultTextColor,
              fontSize: defaultFontSize,
            ) ??
        TextStyle(color: defaultTextColor, fontSize: defaultFontSize);
    final textStyle = tooltipTheme.textStyle ?? defaultTextStyle;
    final padding = tooltipTheme.padding ??
        EdgeInsets.symmetric(
          horizontal: _kBaseDefaultPaddingH.w,
          vertical: _kBaseDefaultPaddingV.h,
        );

    // 对齐 Material Tooltip：仅约束 maxWidth，让气泡按文本 intrinsic 宽度展示。
    // 短文本紧贴文字，长文本自动换行。
    return Container(
      key: _bubbleKey,
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: padding,
      child: Text(
        widget.message,
        style: textStyle,
        softWrap: true,
      ),
    );
  }

  /// 解析气泡背景色：优先取 TooltipTheme.decoration 上的颜色，否则按主题给默认值。
  Color _resolveBubbleColor(BuildContext context) {
    final tooltipTheme = TooltipTheme.of(context);
    final decoration = tooltipTheme.decoration;
    if (decoration is BoxDecoration && decoration.color != null) {
      return decoration.color!;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? _bubbleColorDark : _bubbleColorLight;
  }

  /// 解析"理智上限"：优先取 [TooltipTheme.constraints.maxWidth]（若设置且有限），
  /// 否则用 [_kBaseMaxBubbleWidth] 经 ScreenUtil 缩放后的值。
  /// 这样下游 App 调 `TooltipTheme(data: TooltipThemeData(constraints: ...))`
  /// 控制官方 Tooltip 时，FloatPanel 上的气泡也跟着变。
  double _resolveEffectiveMaxWidth(BuildContext context) {
    final themeMax = TooltipTheme.of(context).constraints?.maxWidth;
    if (themeMax != null && themeMax.isFinite) return themeMax;
    return _maxBubbleWidth;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final overlaySize = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            final effectiveMax = _resolveEffectiveMaxWidth(context);
            final maxWidth = _resolveMaxWidth(overlaySize, effectiveMax);
            final bubbleContent = _buildBubbleContent(context, maxWidth);
            final bubbleColor = _resolveBubbleColor(context);

            // 第一帧：用 Offstage 让气泡走 layout 但不绘制，从而拿到真实尺寸。
            if (_bubbleSize == null) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    child: Offstage(
                      offstage: true,
                      child: bubbleContent,
                    ),
                  ),
                ],
              );
            }

            // 第二帧：按测量结果定位 + 画带尾巴的气泡。
            final bubbleSize = _bubbleSize!;
            final side = _resolveSide(overlaySize, bubbleSize);
            final origin =
                _calculateBubbleOrigin(overlaySize, bubbleSize, side);
            final tailTipGlobal = _tailTipGlobal(side);
            final tailTipLocal = tailTipGlobal - origin;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: origin.dx,
                  top: origin.dy,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: widget.visibility,
                    builder: (context, visible, child) => AnimatedOpacity(
                      opacity: visible ? 1.0 : 0.0,
                      duration: visible
                          ? widget.fadeInDuration
                          : widget.fadeOutDuration,
                      curve: Curves.easeOut,
                      child: child,
                    ),
                    child: CustomPaint(
                      painter: _FloatPanelTooltipBubblePainter(
                        side: side,
                        tailTipLocal: tailTipLocal,
                        tailHalfWidth: _tailHalfWidth,
                        cornerRadius: _bubbleCornerRadius,
                        tailSafeMargin: _tailSafeMargin,
                        color: bubbleColor,
                      ),
                      child: bubbleContent,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 把圆角矩形和小尾巴合并成一个 Path 一次性绘制，避免接缝。
class _FloatPanelTooltipBubblePainter extends CustomPainter {
  final _FloatPanelTooltipSide side;
  final Offset tailTipLocal;
  final double tailHalfWidth;
  final double cornerRadius;
  // 尾巴基线避开圆角的安全裕度；和圆角一起缩放，避免小窗下尾巴撞圆角。
  final double tailSafeMargin;
  final Color color;

  const _FloatPanelTooltipBubblePainter({
    required this.side,
    required this.tailTipLocal,
    required this.tailHalfWidth,
    required this.cornerRadius,
    required this.tailSafeMargin,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bubblePath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(cornerRadius),
        ),
      );

    final tailPath = _buildTailPath(size);
    final combined = Path.combine(PathOperation.union, bubblePath, tailPath);
    canvas.drawPath(combined, paint);
  }

  Path _buildTailPath(Size size) {
    final path = Path();
    final minBaseAxis = cornerRadius + tailSafeMargin;

    switch (side) {
      case _FloatPanelTooltipSide.right:
        // 气泡在浮动条右侧；尾巴从气泡左边缘指向浮动条边缘。
        final maxBase = size.height - cornerRadius - tailSafeMargin;
        final baseY = maxBase >= minBaseAxis
            ? tailTipLocal.dy.clamp(minBaseAxis, maxBase)
            : size.height / 2;
        path.moveTo(0, baseY - tailHalfWidth);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(0, baseY + tailHalfWidth);
        path.close();
        break;
      case _FloatPanelTooltipSide.left:
        final maxBase = size.height - cornerRadius - tailSafeMargin;
        final baseY = maxBase >= minBaseAxis
            ? tailTipLocal.dy.clamp(minBaseAxis, maxBase)
            : size.height / 2;
        path.moveTo(size.width, baseY - tailHalfWidth);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(size.width, baseY + tailHalfWidth);
        path.close();
        break;
      case _FloatPanelTooltipSide.bottom:
        final maxBase = size.width - cornerRadius - tailSafeMargin;
        final baseX = maxBase >= minBaseAxis
            ? tailTipLocal.dx.clamp(minBaseAxis, maxBase)
            : size.width / 2;
        path.moveTo(baseX - tailHalfWidth, 0);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(baseX + tailHalfWidth, 0);
        path.close();
        break;
      case _FloatPanelTooltipSide.top:
        final maxBase = size.width - cornerRadius - tailSafeMargin;
        final baseX = maxBase >= minBaseAxis
            ? tailTipLocal.dx.clamp(minBaseAxis, maxBase)
            : size.width / 2;
        path.moveTo(baseX - tailHalfWidth, size.height);
        path.lineTo(tailTipLocal.dx, tailTipLocal.dy);
        path.lineTo(baseX + tailHalfWidth, size.height);
        path.close();
        break;
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _FloatPanelTooltipBubblePainter oldDelegate) {
    return side != oldDelegate.side ||
        tailTipLocal != oldDelegate.tailTipLocal ||
        tailHalfWidth != oldDelegate.tailHalfWidth ||
        cornerRadius != oldDelegate.cornerRadius ||
        tailSafeMargin != oldDelegate.tailSafeMargin ||
        color != oldDelegate.color;
  }
}

class _FloatButton extends StatelessWidget {
  final double size;
  final Color color;
  final IconData icon;
  final double iconSize;
  final bool hightLight;
  final Color focusColor;
  final bool enabled;
  final bool isHighlighted;

  const _FloatButton({
    super.key,
    required this.icon,
    required this.color,
    required this.focusColor,
    this.size = 70,
    this.iconSize = 24,
    this.hightLight = false,
    this.enabled = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    Color iconColorToShow = (hightLight || isHighlighted) ? focusColor : color;
    if (!enabled) {
      iconColorToShow =
          iconColorToShow.withValues(alpha: (iconColorToShow.a * 0.4));
    }
    final iconDisplay = Icon(icon, color: iconColorToShow, size: iconSize);

    if (!enabled) {
      // 仅在禁用态时订阅样式变化，避免GetX空订阅错误
      return Obx(() {
        final style = FloatPanel.to.disabledStyle.value;
        if (style.type == DisabledStyleType.dimOnly) {
          return SizedBox(
            width: size,
            height: size,
            child: Center(child: iconDisplay),
          );
        }
        if (style.type == DisabledStyleType.custom &&
            style.overlayBuilder != null) {
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                iconDisplay,
                style.overlayBuilder!(iconSize),
              ],
            ),
          );
        }
        // defaultX
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              iconDisplay,
              Icon(
                CupertinoIcons.xmark,
                color: Colors.yellowAccent
                    .withValues(alpha: Colors.yellowAccent.a * 0.85),
                size: iconSize * 0.9,
              ),
            ],
          ),
        );
      });
    }

    return SizedBox(
        width: size, height: size, child: Center(child: iconDisplay));
  }
}
