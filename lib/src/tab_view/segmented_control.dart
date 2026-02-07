import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'tab.dart';
import 'tab_controller.dart';

/// macOS 风格的分段控制栏
///
/// 将多个 [MyTab] 水平排列，提供 macOS segmented control 的视觉效果。
/// 通常由 [MyTabView] 内部使用，也可以单独使用。
///
/// **布局模式**：通过 [fit] 参数控制水平布局行为：
/// - [MyTabBarFit.stretched]：各 Tab 等宽拉伸填满容器（默认）
/// - [MyTabBarFit.compact]：各 Tab 按内容收缩，整体宽度由内容决定
///
/// **选中态滑块动画**：切换 Tab 时，选中态背景会平滑滑动到目标 Tab 位置，
/// 可通过 [slideDuration] 和 [slideCurve] 自定义动画行为。
///
/// 示例：
/// ```dart
/// MySegmentedControl(
///   tabs: [MyTab(label: '选项一'), MyTab(label: '选项二')],
///   controller: myTabController,
///   fit: MyTabBarFit.compact, // macOS 原版风格
/// )
/// ```
class MySegmentedControl extends StatefulWidget {
  const MySegmentedControl({
    super.key,
    required this.tabs,
    required this.controller,
    this.fit = MyTabBarFit.compact,
    this.backgroundColor,
    this.borderRadius,
    this.dividerColor,
    this.dividerWidth,
    this.dividerIndent,
    this.padding,
    this.boxShadow,
    this.slideDuration,
    this.slideCurve,
  });

  /// Tab 数据列表
  final List<MyTab> tabs;

  /// Tab 控制器
  final MyTabController controller;

  /// 水平布局模式（默认 [MyTabBarFit.stretched]）
  final MyTabBarFit fit;

  /// 背景色（默认：亮色 #E2E3E6，暗色 #2B2E33）
  final Color? backgroundColor;

  /// 外层圆角
  final BorderRadius? borderRadius;

  /// 分隔线颜色（默认：亮色 #C9C9C9，暗色 #26222C）
  final Color? dividerColor;

  /// 分隔线宽度
  final double? dividerWidth;

  /// 分隔线上下缩进
  final double? dividerIndent;

  /// 内部 padding
  final EdgeInsetsGeometry? padding;

  /// 自定义阴影
  final List<BoxShadow>? boxShadow;

  /// 选中态滑块动画时长（默认 200ms）
  final Duration? slideDuration;

  /// 选中态滑块动画曲线（默认 [Curves.easeInOut]）
  final Curve? slideCurve;

  @override
  State<MySegmentedControl> createState() => _MySegmentedControlState();
}

class _MySegmentedControlState extends State<MySegmentedControl> {
  // compact 模式下用于测量每个 Tab 按钮实际位置和宽度的 key
  List<GlobalKey> _tabKeys = [];
  // compact 模式下 Row 的 key，用于计算相对坐标
  final GlobalKey _rowKey = GlobalKey();
  // compact 模式下存储测量到的滑块位置和宽度
  double? _slideLeft;
  double? _slideWidth;
  // 是否已完成首次测量（compact 模式下首帧不显示滑块动画）
  bool _hasMeasured = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
    _initKeys();
  }

  @override
  void didUpdateWidget(MySegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
    }
    // Tab 数量变化时重新初始化 keys
    if (oldWidget.tabs.length != widget.tabs.length) {
      _initKeys();
      _hasMeasured = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  void _initKeys() {
    _tabKeys = List.generate(widget.tabs.length, (_) => GlobalKey());
  }

  void _onTabChanged() {
    if (!mounted) return;
    if (_isCompact) {
      _measureAndUpdate();
    }
    setState(() {});
  }

  bool get _isCompact => widget.fit == MyTabBarFit.compact;

  /// compact 模式下测量指定 Tab 的位置
  void _measureAndUpdate() {
    final index = widget.controller.index;
    if (index >= _tabKeys.length) return;

    final tabKey = _tabKeys[index];
    final tabBox = tabKey.currentContext?.findRenderObject() as RenderBox?;
    final rowBox = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    if (tabBox == null || rowBox == null) return;

    final offset = tabBox.localToGlobal(Offset.zero, ancestor: rowBox);
    _slideLeft = offset.dx;
    _slideWidth = tabBox.size.width;
    _hasMeasured = true;
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    final backgroundColor = widget.backgroundColor ??
        (isLight ? const Color(0xFFE2E3E6) : const Color(0xFF2B2E33));
    final borderRadius = widget.borderRadius ?? BorderRadius.circular(5.r);
    final dividerColor = widget.dividerColor ??
        (isLight ? const Color(0xFFC9C9C9) : const Color(0xFF26222C));
    final dividerWidth = widget.dividerWidth ?? 1.w;
    final dividerIndent = widget.dividerIndent ?? 5.h;
    final padding =
        widget.padding ?? EdgeInsets.symmetric(horizontal: 2.w, vertical: 2.h);
    final boxShadow = widget.boxShadow ??
        [
          BoxShadow(
            color: isLight ? const Color(0xFFDBDCDE) : const Color(0xFF4F5155),
            offset: Offset(0, 0.5.h),
            spreadRadius: 0.5.r,
          ),
        ];
    final slideDuration =
        widget.slideDuration ?? const Duration(milliseconds: 200);
    final slideCurve = widget.slideCurve ?? Curves.easeInOut;

    final container = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: _isCompact
          ? _buildCompactBody(isLight, dividerColor, dividerWidth,
              dividerIndent, slideDuration, slideCurve)
          : _buildStretchedBody(isLight, dividerColor, dividerWidth,
              dividerIndent, slideDuration, slideCurve),
    );

    // compact 模式下首帧后进行测量
    if (_isCompact && !_hasMeasured) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureAndUpdate();
        if (mounted) setState(() {});
      });
    }

    return container;
  }

  // ─────────────────────────────────────────────────────────
  // stretched 模式：LayoutBuilder + 等宽计算
  // ─────────────────────────────────────────────────────────

  Widget _buildStretchedBody(
    bool isLight,
    Color dividerColor,
    double dividerWidth,
    double dividerIndent,
    Duration slideDuration,
    Curve slideCurve,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabCount = widget.tabs.length;
        final activeIndex = widget.controller.index;

        // 计算每个 Tab 和分隔线的尺寸
        final dividerCount = tabCount - 1;
        final totalDividerWidth = dividerCount * dividerWidth;
        final tabWidth = (totalWidth - totalDividerWidth) / tabCount;

        // 滑块的 left 偏移
        final slideLeft = activeIndex * (tabWidth + dividerWidth);

        return IntrinsicHeight(
          child: Stack(
            children: [
              // ── 底层：选中态滑块 ──
              AnimatedPositioned(
                duration: slideDuration,
                curve: slideCurve,
                left: slideLeft,
                top: 0,
                bottom: 0,
                width: tabWidth,
                child: _buildSlideDecoration(isLight, activeIndex),
              ),
              // ── 上层：Tab 按钮 + 分隔线 ──
              Row(
                children: _buildChildren(
                  dividerColor,
                  dividerWidth,
                  dividerIndent,
                  slideDuration,
                  useExpanded: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // compact 模式：IntrinsicWidth + GlobalKey 测量
  // ─────────────────────────────────────────────────────────

  Widget _buildCompactBody(
    bool isLight,
    Color dividerColor,
    double dividerWidth,
    double dividerIndent,
    Duration slideDuration,
    Curve slideCurve,
  ) {
    final activeIndex = widget.controller.index;

    return IntrinsicHeight(
      child: IntrinsicWidth(
        child: Stack(
          children: [
            // ── 底层：选中态滑块（首帧前隐藏，避免位置跳动） ──
            if (_hasMeasured && _slideLeft != null && _slideWidth != null)
              AnimatedPositioned(
                duration: slideDuration,
                curve: slideCurve,
                left: _slideLeft!,
                top: 0,
                bottom: 0,
                width: _slideWidth!,
                child: _buildSlideDecoration(isLight, activeIndex),
              ),
            // ── 上层：Tab 按钮 + 分隔线 ──
            Row(
              key: _rowKey,
              mainAxisSize: MainAxisSize.min,
              children: _buildChildren(
                dividerColor,
                dividerWidth,
                dividerIndent,
                slideDuration,
                useExpanded: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 公共：滑块装饰、Tab 按钮列表
  // ─────────────────────────────────────────────────────────

  /// 构建选中态滑块的 DecoratedBox
  Widget _buildSlideDecoration(bool isLight, int activeIndex) {
    final activeTab = widget.tabs[activeIndex];
    final activeColor = activeTab.activeColor ??
        (isLight ? Colors.white : const Color(0xFF646669));
    final tabBorderRadius =
        activeTab.borderRadius ?? BorderRadius.circular(4.r);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: activeColor,
        borderRadius: tabBorderRadius,
        boxShadow: [
          BoxShadow(
            color: isLight
                ? Colors.black.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 1.5.r,
            offset: Offset(0, 0.5.h),
          ),
        ],
      ),
    );
  }

  /// 构建 Tab 按钮和分隔线列表
  ///
  /// [useExpanded] 为 true 时用 Expanded 等宽（stretched），
  /// 为 false 时由内容决定宽度（compact）。
  List<Widget> _buildChildren(
    Color dividerColor,
    double dividerWidth,
    double dividerIndent,
    Duration slideDuration, {
    required bool useExpanded,
  }) {
    final List<Widget> children = [];
    final activeIndex = widget.controller.index;

    for (int i = 0; i < widget.tabs.length; i++) {
      // 分隔线：选中 Tab 两侧不显示（用 AnimatedOpacity 平滑过渡）
      if (i > 0) {
        final showDivider = (activeIndex != i - 1) && (activeIndex != i);
        children.add(
          SizedBox(
            width: dividerWidth,
            child: AnimatedOpacity(
              opacity: showDivider ? 1.0 : 0.0,
              duration: slideDuration,
              child: VerticalDivider(
                width: dividerWidth,
                indent: dividerIndent,
                endIndent: dividerIndent,
                color: dividerColor,
              ),
            ),
          ),
        );
      }

      final button = _TabButton(
        key: _isCompact ? _tabKeys[i] : null,
        tab: widget.tabs[i],
        active: i == activeIndex,
        onTap: () => widget.controller.index = i,
      );

      children.add(useExpanded ? Expanded(child: button) : button);
    }

    return children;
  }
}

// ─────────────────────────────────────────────────────────
// 内部组件：单个 Tab 按钮（不再渲染选中态背景，由滑块层负责）
// ─────────────────────────────────────────────────────────

class _TabButton extends StatefulWidget {
  const _TabButton({
    super.key,
    required this.tab,
    required this.active,
    required this.onTap,
  });

  final MyTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    // ── hover 背景色（仅非激活态显示） ──
    final hoverColor = widget.tab.hoverColor ??
        (isLight
            ? Colors.black.withValues(alpha: 0.04)
            : Colors.white.withValues(alpha: 0.05));

    // 选中态背景由滑块层负责，这里只处理 hover
    Color backgroundColor;
    if (widget.active) {
      backgroundColor = Colors.transparent;
    } else if (_isHovered) {
      backgroundColor = hoverColor;
    } else {
      backgroundColor = Colors.transparent;
    }

    // ── 文字样式 ──
    final defaultTextStyle = TextStyle(
      fontSize: 13.sp,
      color: isLight ? Colors.black87 : Colors.white70,
    );
    final defaultActiveTextStyle = TextStyle(
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      color: isLight ? Colors.black : Colors.white,
    );
    final textStyle = widget.active
        ? (widget.tab.activeTextStyle ?? defaultActiveTextStyle)
        : (widget.tab.textStyle ?? defaultTextStyle);

    // ── 布局参数 ──
    final padding = widget.tab.padding ??
        EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h);
    final borderRadius = widget.tab.borderRadius ?? BorderRadius.circular(4.r);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          alignment: Alignment.center,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.tab.icon != null) ...[
                widget.tab.icon!,
                SizedBox(width: 4.w),
              ],
              Flexible(
                child: Text(
                  widget.tab.label,
                  style: textStyle,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
