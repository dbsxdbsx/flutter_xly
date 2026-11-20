import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app/desktop_window_gestures.dart';
import 'tab.dart';
import 'tab_controller.dart';

/// macOS 风格的分段控制栏
///
/// 将多个 [MyTab] 水平排列，提供 macOS segmented control 的视觉效果。
/// 通常由 [MyTabView] 内部使用，也可以单独使用。
///
/// **布局模式**：通过 [fit] 参数控制水平布局行为：
/// - [MyTabBarFit.stretched]：各 Tab 等宽拉伸填满容器
/// - [MyTabBarFit.compact]：各 Tab 按内容收缩，整体宽度由内容决定（默认）
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

  /// 水平布局模式（默认 [MyTabBarFit.compact]）
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

class _MySegmentedControlState extends State<MySegmentedControl>
    with SingleTickerProviderStateMixin {
  late final AnimationController _posController;

  Duration get _slideDuration =>
      widget.slideDuration ?? const Duration(milliseconds: 200);
  Curve get _slideCurve => widget.slideCurve ?? Curves.easeInOut;
  double get _maxPos =>
      widget.tabs.isEmpty ? 0.0 : (widget.tabs.length - 1).toDouble();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
    _posController = AnimationController.unbounded(
      vsync: this,
      value: widget.controller.index.toDouble().clamp(0.0, _maxPos),
    );
  }

  @override
  void didUpdateWidget(MySegmentedControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTabChanged);
      widget.controller.addListener(_onTabChanged);
      _posController.stop();
      _posController.value =
          widget.controller.index.toDouble().clamp(0.0, _maxPos);
    } else if (oldWidget.tabs.length != widget.tabs.length) {
      _posController.stop();
      _posController.value =
          widget.controller.index.toDouble().clamp(0.0, _maxPos);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    _posController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    final target = widget.controller.index.toDouble().clamp(0.0, _maxPos);
    if ((_posController.value - target).abs() > 0.001) {
      _posController.animateTo(
        target,
        duration: _slideDuration,
        curve: _slideCurve,
      );
    } else {
      _posController.value = target;
    }
    setState(() {});
  }

  bool get _isCompact => widget.fit == MyTabBarFit.compact;

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

    return MyDoubleClickConsumeZone(
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: _isCompact
            ? _buildCompactBody(
                isLight,
                dividerColor,
                dividerWidth,
                dividerIndent,
                _slideDuration,
              )
            : _buildStretchedBody(
                isLight,
                dividerColor,
                dividerWidth,
                dividerIndent,
                _slideDuration,
                _slideCurve,
              ),
      ),
    );
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
  // compact 模式：自定义 RenderBox 同帧布局（无缓存、窗口缩放零错位）
  // ─────────────────────────────────────────────────────────

  Widget _buildCompactBody(
    bool isLight,
    Color dividerColor,
    double dividerWidth,
    double dividerIndent,
    Duration slideDuration,
  ) {
    final activeIndex = widget.controller.index;

    return _CompactSegmentedControlLayout(
      position: _posController,
      tabCount: widget.tabs.length,
      children: [
        IgnorePointer(child: _buildSlideDecoration(isLight, activeIndex)),
        ..._buildChildren(
          dividerColor,
          dividerWidth,
          dividerIndent,
          slideDuration,
          useExpanded: false,
        ),
      ],
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
// 内部布局引擎：compact 模式零缓存同帧定位滑块
// ─────────────────────────────────────────────────────────

class _CompactSegmentedControlLayout extends MultiChildRenderObjectWidget {
  const _CompactSegmentedControlLayout({
    required this.position,
    required this.tabCount,
    required super.children,
  });

  final ValueListenable<double> position;
  final int tabCount;

  @override
  _RenderCompactSegmentedControlLayout createRenderObject(
    BuildContext context,
  ) {
    return _RenderCompactSegmentedControlLayout(
      position: position,
      tabCount: tabCount,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderCompactSegmentedControlLayout renderObject,
  ) {
    renderObject
      ..position = position
      ..tabCount = tabCount;
  }
}

class _CompactSegmentedParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderCompactSegmentedControlLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _CompactSegmentedParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox,
            _CompactSegmentedParentData> {
  _RenderCompactSegmentedControlLayout({
    required ValueListenable<double> position,
    required int tabCount,
  })  : _position = position,
        _tabCount = tabCount;

  ValueListenable<double> _position;
  set position(ValueListenable<double> value) {
    if (_position == value) return;
    if (attached) _position.removeListener(_onPositionChanged);
    _position = value;
    if (attached) _position.addListener(_onPositionChanged);
    markNeedsLayout();
  }

  int _tabCount;
  set tabCount(int value) {
    if (_tabCount == value) return;
    _tabCount = value;
    markNeedsLayout();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _position.addListener(_onPositionChanged);
  }

  @override
  void detach() {
    _position.removeListener(_onPositionChanged);
    super.detach();
  }

  void _onPositionChanged() {
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _CompactSegmentedParentData) {
      child.parentData = _CompactSegmentedParentData();
    }
  }

  List<RenderBox> _rowChildren() {
    final result = <RenderBox>[];
    final thumb = firstChild;
    if (thumb == null) return result;
    var child = childAfter(thumb);
    while (child != null) {
      result.add(child);
      child = childAfter(child);
    }
    return result;
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var sum = 0.0;
    for (final child in _rowChildren()) {
      sum += child.getMinIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var sum = 0.0;
    for (final child in _rowChildren()) {
      sum += child.getMaxIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    var maxH = 0.0;
    for (final child in _rowChildren()) {
      maxH = math.max(maxH, child.getMinIntrinsicHeight(double.infinity));
    }
    return maxH;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    var maxH = 0.0;
    for (final child in _rowChildren()) {
      maxH = math.max(maxH, child.getMaxIntrinsicHeight(double.infinity));
    }
    return maxH;
  }

  @override
  void performLayout() {
    final thumb = firstChild;
    final rowChildren = _rowChildren();
    if (thumb == null || rowChildren.isEmpty || _tabCount <= 0) {
      size = constraints.smallest;
      return;
    }

    final double trackHeight;
    if (constraints.hasTightHeight) {
      trackHeight = constraints.maxHeight;
    } else {
      var h = constraints.minHeight;
      for (final child in rowChildren) {
        h = math.max(h, child.getMaxIntrinsicHeight(double.infinity));
      }
      trackHeight = h.clamp(constraints.minHeight, constraints.maxHeight);
    }

    final natWidths = List<double>.filled(rowChildren.length, 0.0);
    var naturalTotal = 0.0;
    for (var i = 0; i < rowChildren.length; i++) {
      final w = rowChildren[i].getMaxIntrinsicWidth(trackHeight);
      natWidths[i] = w;
      naturalTotal += w;
    }

    final scale = (constraints.hasBoundedWidth &&
            naturalTotal > constraints.maxWidth &&
            naturalTotal > 0)
        ? constraints.maxWidth / naturalTotal
        : 1.0;

    final tabLefts = <double>[];
    final tabWidths = <double>[];
    var cursorX = 0.0;
    for (var i = 0; i < rowChildren.length; i++) {
      final child = rowChildren[i];
      final w = math.max(0.0, natWidths[i] * scale);
      child.layout(
        BoxConstraints.tightFor(width: w, height: trackHeight),
        parentUsesSize: true,
      );
      (child.parentData! as _CompactSegmentedParentData).offset =
          Offset(cursorX, 0.0);
      // 偶数索引（0, 2, 4...）是 Tab 按钮，奇数索引是分隔线。
      if (i.isEven) {
        tabLefts.add(cursorX);
        tabWidths.add(child.size.width);
      }
      cursorX += child.size.width;
    }

    size = constraints.constrain(Size(cursorX, trackHeight));

    if (tabLefts.isEmpty) {
      thumb.layout(const BoxConstraints.tightFor(width: 0, height: 0));
      return;
    }

    final maxPos = (tabLefts.length - 1).toDouble();
    final pos = _position.value.clamp(0.0, maxPos);
    final lo = pos.floor().clamp(0, tabLefts.length - 1);
    final hi = pos.ceil().clamp(0, tabLefts.length - 1);
    final t = pos - lo;
    final left = lerpDouble(tabLefts[lo], tabLefts[hi], t)!;
    final width = math.max(0.0, lerpDouble(tabWidths[lo], tabWidths[hi], t)!);

    thumb.layout(
      BoxConstraints.tightFor(width: width, height: size.height),
      parentUsesSize: false,
    );
    (thumb.parentData! as _CompactSegmentedParentData).offset =
        Offset(left, 0.0);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}

// ─────────────────────────────────────────────────────────
// 内部组件：单个 Tab 按钮（不再渲染选中态背景，由滑块层负责）
// ─────────────────────────────────────────────────────────

class _TabButton extends StatefulWidget {
  const _TabButton({
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
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
          ),
          child: Padding(
            padding: padding,
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
      ),
    );
  }
}
