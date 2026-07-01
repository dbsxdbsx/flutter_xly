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
  final MyPanelPlacement placement;

  /// 自定义 [itemBuilder] 离屏测量得到的内容宽度。
  ///
  /// 为 `null` 时使用默认条目的文本测宽逻辑；非 `null` 时优先参与自适应宽度计算。
  final double? measuredContentWidth;

  /// 触发处的环境文字样式（含 fontFamily），用于面板测宽对齐实际渲染。
  final TextStyle ambientTextStyle;

  /// 触发处的文字缩放，用于面板测宽对齐实际渲染。
  final TextScaler textScaler;

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
    required this.placement,
    required this.measuredContentWidth,
    required this.ambientTextStyle,
    required this.textScaler,
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
  /// - 传了 [MySelectorStyle.panelWidth]：**固定宽度**，无视内容（仍夹到屏内安全宽）。
  /// - 否则**完全自适应**：面板宽度贴合内容（不窄于 trigger），内容更长时自动增长，
  ///   最宽不超过屏内安全宽（`screenW - 16.w`，同时避免整页 RenderBox 触发撑满异常）。
  ///
  /// 自定义 `itemBuilder` 面板会在弹出前离屏测量一次，测量失败时退回 trigger 宽度。
  double _resolvePanelW(double triggerW, double screenW) {
    final double screenSafe = math.max(0.0, screenW - _kPanelHorizontalSafe.w);
    final style = widget.style;
    if (style.panelWidth != null) {
      return math.min(style.panelWidth!, screenSafe);
    }
    final double content =
        widget.measuredContentWidth ?? _measureContentW() ?? 0.0;
    final double desired = math.max(triggerW, content);
    return math.min(desired, screenSafe);
  }

  /// 测量默认样式条目所需的最大内容宽度（用于「完全自适应」）；
  /// 自定义 `itemBuilder` 由 [widget.measuredContentWidth] 承载。
  ///
  /// 用触发处的环境样式（字体）+ 文字缩放测量，对齐实际渲染，避免偏小截断。
  /// 结构对齐 [_DefaultSelectorItem]：左竖线 + 前缀 + 标题/副标题 + 右侧勾选，
  /// 外加水平内边距。标题按选中态字重（w600，较宽）测量以预留足够空间，并再
  /// 补一点安全余量抵消亚像素舍入。
  double? _measureContentW() {
    double textW(String text, double fontSize, FontWeight weight) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: widget.ambientTextStyle
              .copyWith(fontSize: fontSize, fontWeight: weight),
        ),
        textDirection: TextDirection.ltr,
        textScaler: widget.textScaler,
        maxLines: 1,
      )..layout();
      return tp.width;
    }

    double maxInner = 0;
    for (final item in widget.items) {
      double w = textW(item.title, 13.sp, FontWeight.w600);
      final sub = item.subtitle;
      if (sub != null && sub.isNotEmpty) {
        w = math.max(w, textW(sub, 10.sp, FontWeight.w400));
      }
      if (item.leading != null) w += 24.w; // 前缀图标 + 间距（估算）
      final badges = item.badges;
      if (badges != null && badges.isNotEmpty) {
        w += badges.length * 22.w + 5.w; // 徽章（估算）
      }
      maxInner = math.max(maxInner, w);
    }

    // 清除项标题也参与测量（其行结构与普通项对齐）
    final clear = widget.clearOption;
    if (clear != null) {
      maxInner = math.max(maxInner, textW(clear.label, 13.sp, FontWeight.w400));
    }

    if (maxInner <= 0) return null;
    // 加上：水平内边距 14*2 + 左竖线区(3+10) + 右侧勾选预留(8+16) + 安全余量 8
    return maxInner + 28.w + 13.w + 24.w + 8.w;
  }

  /// 估算面板内容高度（用于翻转方向判断），非精确值：
  /// 列表项按 ~50.h/项 + 列表上下 padding，另计可选的搜索框 / 清除项 / 底部区。
  /// 只需大致反映"内容多少"，用来决定默认向下、下方不足才向上。
  double _estimateContentH() {
    double h = 8.h; // ListView 上下各 4.h padding
    h += widget.items.length * 50.h; // 每项 ≈ 8*2 padding + 34 内容
    if (widget.showSearch) h += 60.h; // 搜索框 + 分隔线
    if (widget.clearOption != null) h += 50.h; // 清除项 + 分隔线
    if (widget.footerBuilder != null) h += 48.h; // 底部区（粗估）
    return h;
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
      // 面板期望高度：按实际内容估算，再夹到 style.maxHeight 上限。
      // 内容少时期望高度也小，避免"另一侧有大片留白就翻转"的误判。
      final double desiredH = math.min(effectiveMaxH, _estimateContentH());
      // 按 placement 决定方向：
      // - forceBelow / forceAbove：硬强制，不翻转；
      // - below：首选向下，仅当"下方放不下且上方更宽裕"才上翻；
      // - above：首选向上，仅当"上方放不下且下方更宽裕"才下翻。
      switch (widget.placement) {
        case MyPanelPlacement.forceBelow:
          showAbove = false;
        case MyPanelPlacement.forceAbove:
          showAbove = true;
        case MyPanelPlacement.below:
          showAbove = spaceBelow < desiredH && spaceAbove > spaceBelow;
        case MyPanelPlacement.above:
          showAbove = !(spaceAbove < desiredH && spaceBelow > spaceAbove);
      }

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
