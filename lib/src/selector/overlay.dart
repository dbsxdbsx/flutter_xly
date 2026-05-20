part of '../../selector.dart';

// ============================================================================
// Overlay 层（全屏捕获 + 面板定位，窗口 resize 时自动重算坐标）
// ============================================================================

class _SelectorOverlay<T> extends StatefulWidget {
  /// 触发按钮的 RenderBox（resize 后仍然有效，可重新读取坐标）
  final RenderBox renderBox;

  /// 当前 Overlay 的 State（用于获取 Overlay 坐标系）
  final OverlayState overlayState;

  final List<MySelectorItem<T>> items;
  final T? currentValue;
  final MySelectorClearOption? clearOption;
  final bool allowReselect;
  final bool? showPanelAbove;
  final bool showSearch;
  final String searchHint;
  final bool Function(MySelectorItem<T>, String)? searchFilter;
  final Widget Function(BuildContext, MySelectorItem<T>, bool)? itemBuilder;
  final Widget Function(BuildContext, VoidCallback)? footerBuilder;
  final MySelectorStyle style;
  final void Function(MySelectorItem<T>) onSelected;
  final VoidCallback onCleared;
  final VoidCallback onDismiss;

  const _SelectorOverlay({
    required this.renderBox,
    required this.overlayState,
    required this.items,
    required this.currentValue,
    required this.clearOption,
    required this.allowReselect,
    required this.showPanelAbove,
    required this.showSearch,
    required this.searchHint,
    required this.searchFilter,
    required this.itemBuilder,
    required this.footerBuilder,
    required this.style,
    required this.onSelected,
    required this.onCleared,
    required this.onDismiss,
  });

  @override
  State<_SelectorOverlay<T>> createState() => _SelectorOverlayState<T>();
}

class _SelectorOverlayState<T> extends State<_SelectorOverlay<T>>
    with WidgetsBindingObserver {
  double _btnXRatio = 0;
  double _btnYRatio = 0;
  double _btnWRatio = 0;
  double _btnHRatio = 0;
  double _panelWRatio = 0;
  double _maxHRatio = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _snapshotRatios();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _snapshotRatios() {
    if (!widget.renderBox.attached) return;
    final overlayBox =
        widget.overlayState.context.findRenderObject() as RenderBox;
    final gPos = widget.renderBox.localToGlobal(Offset.zero);
    final pos = overlayBox.globalToLocal(gPos);
    final sz = widget.renderBox.size;
    final screen = overlayBox.size;
    if (screen.width > 0 && screen.height > 0) {
      _btnXRatio = pos.dx / screen.width;
      _btnYRatio = pos.dy / screen.height;
      _btnWRatio = sz.width / screen.width;
      _btnHRatio = sz.height / screen.height;

      _panelWRatio = _resolvePanelW(sz.width, screen.width) / screen.width;
      _maxHRatio = widget.style.maxHeight / screen.height;
    }
  }

  /// 计算面板宽度。
  ///
  /// 没传 [MySelectorStyle.panelWidth] 时，默认贴合 trigger 但封顶
  /// `_kPanelDefaultMaxW.w`（≈ 280.w），下界 `_kPanelMinW.w`（≈ 220.w）。
  /// 这样可以避免 trigger 是整页 RenderBox（如 `Get.context`）时面板
  /// 被"撑满整屏"——撑满后 build 阶段的 left clamp 区间会退化为
  /// `[8.w, 8.w]`，再被浮点误差顶成 `max < min` 触发 `ArgumentError`。
  ///
  /// 极端窄屏（`screen.width - 16.w < 220.w`）下，优先让出 `16.w` 安全边距，
  /// 哪怕面板挤到不足 220.w，也不直接抛异常。
  double _resolvePanelW(double triggerW, double screenW) {
    final double maxByScreen = math.max(0.0, screenW - _kPanelHorizontalSafe.w);
    if (widget.style.panelWidth != null) {
      return math.min(widget.style.panelWidth!, maxByScreen);
    }
    final double target = math.min(triggerW, _kPanelDefaultMaxW.w);
    final double minSafe = math.min(_kPanelMinW.w, maxByScreen);
    return math.min(maxByScreen, math.max(minSafe, target));
  }

  Size _currentScreenSize() {
    final view = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (view != null && view.physicalSize != Size.zero) {
      return view.physicalSize / view.devicePixelRatio;
    }
    final overlayBox =
        widget.overlayState.context.findRenderObject() as RenderBox;
    return overlayBox.size;
  }

  @override
  void didChangeMetrics() {
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _snapshotRatios();
        setState(() {});
      }
    });
  }

  ({
    Offset buttonPos,
    Size buttonSize,
    Size screenSize,
    bool showAbove,
    bool centered,
    double maxH,
    double panelW,
    double panelLeft,
    double gap,
  }) _computeLayout() {
    final double gap = 6.w;
    final double safeMargin = 8.w;

    final screenSize = _currentScreenSize();

    final buttonPos = Offset(
      screenSize.width * _btnXRatio,
      screenSize.height * _btnYRatio,
    );
    final buttonSize = Size(
      screenSize.width * _btnWRatio,
      screenSize.height * _btnHRatio,
    );

    final double effectiveMaxH = screenSize.height * _maxHRatio;
    final double panelW = screenSize.width * _panelWRatio;

    // trigger 几乎占满整屏（如调用方误把 `Get.context` / Navigator 顶层 context
    // 当 triggerContext 传进来）时，没有"按钮上下方"可贴——上下空间都是 0，
    // 走 showAbove=false 分支会让 `top = buttonPos.dy + buttonSize.height + gap`
    // 直接顶到 screen.height 之外，面板被定位到屏幕底部以下，看起来像"点了
    // 没反应"。这种 trigger 本来就不携带"位置"语义，自动降级为屏幕居中。
    final bool isFullscreenTrigger =
        buttonSize.width >= screenSize.width * 0.9 &&
            buttonSize.height >= screenSize.height * 0.9;

    final bool showAbove;
    final double maxH;
    final double panelLeft;
    if (isFullscreenTrigger) {
      // 居中模式：showAbove 不再有"上方/下方"语义，build 端会走 centered 分支；
      // 这里仍给一个稳定值以保持 record 字段语义完整。
      showAbove = false;
      // maxH 不再受 spaceAbove/spaceBelow 约束，按 style.maxHeight 给上限，
      // 同时不超过屏幕高度减安全边距。
      maxH = math.max(
        80.h,
        math.min(effectiveMaxH, screenSize.height - safeMargin * 2),
      );
      panelLeft = (screenSize.width - panelW) / 2;
    } else {
      final double spaceAbove = buttonPos.dy;
      final double spaceBelow =
          screenSize.height - buttonPos.dy - buttonSize.height;
      // null = 自动判断：上方空间 ≥ 面板高度 60% 或上方比下方大，则弹到上面
      showAbove = widget.showPanelAbove ??
          (spaceAbove >= effectiveMaxH * 0.6 || spaceAbove > spaceBelow);

      final double availableH = showAbove
          ? (spaceAbove - gap - safeMargin)
          : (spaceBelow - gap - safeMargin);
      maxH = availableH.clamp(80.h, effectiveMaxH).toDouble();

      // 面板水平定位：贴合 trigger 的左侧，但夹在 [8.w, screenW - panelW - 8.w]。
      // 极窄屏 / panel 占满屏（含浮点误差）时 maxLeft < minLeft 会让 num.clamp
      // 直接抛 ArgumentError，所以用 math.max 兜一道——退化为左对齐到 8.w。
      final double minLeft = safeMargin;
      final double maxLeft =
          math.max(minLeft, screenSize.width - panelW - safeMargin);
      panelLeft = buttonPos.dx.clamp(minLeft, maxLeft).toDouble();
    }

    return (
      buttonPos: buttonPos,
      buttonSize: buttonSize,
      screenSize: screenSize,
      showAbove: showAbove,
      centered: isFullscreenTrigger,
      maxH: maxH,
      panelW: panelW,
      panelLeft: panelLeft,
      gap: gap,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.renderBox.attached) return const SizedBox.shrink();

    final layout = _computeLayout();

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        if (layout.centered)
          // 整屏 trigger 降级：居中显示，让面板范围之外的点击仍能穿透到下方
          // dismiss handler（Align 默认 deferToChild，非 child 区域不参与 hit-test）
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: _panel(layout.panelW, layout.maxH, false),
            ),
          )
        else if (layout.showAbove)
          Positioned(
            left: layout.panelLeft,
            bottom: layout.screenSize.height - layout.buttonPos.dy + layout.gap,
            child: _panel(layout.panelW, layout.maxH, layout.showAbove),
          )
        else
          Positioned(
            left: layout.panelLeft,
            top: layout.buttonPos.dy + layout.buttonSize.height + layout.gap,
            child: _panel(layout.panelW, layout.maxH, layout.showAbove),
          ),
      ],
    );
  }

  Widget _panel(double panelW, double maxH, bool showAbove) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxH,
        maxWidth: panelW,
        minWidth: panelW,
      ),
      child: _SelectorPanel<T>(
        items: widget.items,
        currentValue: widget.currentValue,
        clearOption: widget.clearOption,
        allowReselect: widget.allowReselect,
        showAbove: showAbove,
        showSearch: widget.showSearch,
        searchHint: widget.searchHint,
        searchFilter: widget.searchFilter,
        itemBuilder: widget.itemBuilder,
        footerBuilder: widget.footerBuilder,
        style: widget.style,
        onSelected: widget.onSelected,
        onCleared: widget.onCleared,
        onDismiss: widget.onDismiss,
      ),
    );
  }
}
