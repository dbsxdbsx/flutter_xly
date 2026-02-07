import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'segmented_control.dart';
import 'tab.dart';
import 'tab_controller.dart';

/// macOS 风格的 Tab 视图组件
///
/// 将 [MySegmentedControl]（Tab 栏）和内容区域组合在一起，
/// 提供完整的 Tab 切换体验。支持顶部/底部两种 Tab 位置。
///
/// **布局原理**：采用 Stack 布局，Tab 栏通过 [Positioned] 骑在内容区边框的
/// 中线上（与 macOS 原生风格一致）。[padding] 参数控制内容区向内缩进的距离，
/// 约为 Tab 栏高度的一半时，Tab 栏恰好居中在边框线上。
///
/// **注意**：此组件需要有界高度约束（bounded height），
/// 请将其放在 [SizedBox]、[Expanded] 或其他提供高度约束的容器中。
///
/// 示例：
/// ```dart
/// SizedBox(
///   height: 300.h,
///   child: MyTabView(
///     tabs: [MyTab(label: '棋谱'), MyTab(label: '日志')],
///     children: [ChessRecordView(), LogView()],
///     position: MyTabPosition.bottom,
///   ),
/// )
/// ```
class MyTabView extends StatefulWidget {
  const MyTabView({
    super.key,
    required this.tabs,
    required this.children,
    this.controller,
    this.position = MyTabPosition.top,
    this.tabBarFit = MyTabBarFit.compact,
    this.padding,
    // 内容区样式
    this.contentBackgroundColor,
    this.contentBorderColor,
    this.contentBorderWidth,
    this.contentBorderRadius,
    // Tab 栏样式（透传给 MySegmentedControl）
    this.tabBarBackgroundColor,
    this.tabBarBorderRadius,
    this.tabBarPadding,
    this.tabBarBoxShadow,
    this.dividerColor,
    this.dividerWidth,
    this.dividerIndent,
    // Tab 栏滑块动画
    this.slideDuration,
    this.slideCurve,
    // 内容区切换动画
    this.transitionBuilder,
    this.transitionDuration,
  });

  /// Tab 数据列表
  final List<MyTab> tabs;

  /// 每个 Tab 对应的内容 Widget，数量必须与 [tabs] 一致
  final List<Widget> children;

  /// Tab 控制器（可选，不传则内部自动创建并管理）
  final MyTabController? controller;

  /// Tab 栏位置，默认顶部
  final MyTabPosition position;

  /// Tab 栏水平布局模式
  ///
  /// - [MyTabBarFit.stretched]（默认）：Tab 栏拉伸填满内容区宽度
  /// - [MyTabBarFit.compact]：Tab 栏按内容收缩并居中（macOS 原版风格）
  final MyTabBarFit tabBarFit;

  /// 内容区外层 padding
  ///
  /// 此值同时决定 Tab 栏与内容边框的重叠量——当约等于 Tab 栏高度的一半时，
  /// Tab 栏恰好骑在边框中线上（macOS 原生风格）。默认 `EdgeInsets.all(12.w)`。
  final EdgeInsetsGeometry? padding;

  // ── 内容区样式 ──

  /// 内容区背景色（默认：亮色 #E6E9EA，暗色 #2B2E33）
  final Color? contentBackgroundColor;

  /// 内容区边框色（默认：亮色 #E1E2E4，暗色 #3E4045）
  final Color? contentBorderColor;

  /// 内容区边框宽度
  final double? contentBorderWidth;

  /// 内容区圆角
  final BorderRadius? contentBorderRadius;

  // ── Tab 栏样式（透传给 MySegmentedControl） ──

  /// Tab 栏背景色
  final Color? tabBarBackgroundColor;

  /// Tab 栏圆角
  final BorderRadius? tabBarBorderRadius;

  /// Tab 栏内部 padding
  final EdgeInsetsGeometry? tabBarPadding;

  /// Tab 栏阴影
  final List<BoxShadow>? tabBarBoxShadow;

  /// Tab 栏分隔线颜色
  final Color? dividerColor;

  /// Tab 栏分隔线宽度
  final double? dividerWidth;

  /// Tab 栏分隔线缩进
  final double? dividerIndent;

  // ── Tab 栏滑块动画 ──

  /// 选中态滑块动画时长（默认 200ms）
  final Duration? slideDuration;

  /// 选中态滑块动画曲线（默认 [Curves.easeInOut]）
  final Curve? slideCurve;

  // ── 内容区切换动画 ──

  /// 页面切换动画构建器（默认 null 表示无动画，使用 IndexedStack）
  ///
  /// 注意：使用动画时，非可见页面的状态不会被保留（与 IndexedStack 不同）。
  final AnimatedSwitcherTransitionBuilder? transitionBuilder;

  /// 切换动画时长（默认 300ms，仅在 [transitionBuilder] 不为 null 时生效）
  final Duration? transitionDuration;

  @override
  State<MyTabView> createState() => _MyTabViewState();
}

class _MyTabViewState extends State<MyTabView> {
  late MyTabController _controller;
  bool _ownController = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  @override
  void didUpdateWidget(MyTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部 controller 变更
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_rebuild);
      if (_ownController) {
        _controller.dispose();
        _ownController = false;
      }
      _initController();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    if (_ownController) _controller.dispose();
    super.dispose();
  }

  void _initController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = MyTabController(length: widget.tabs.length);
      _ownController = true;
    }
    _controller.addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tabs.length == widget.children.length,
      'tabs (${widget.tabs.length}) 与 children (${widget.children.length}) 数量必须一致',
    );
    assert(
      widget.tabs.isNotEmpty,
      'tabs 不能为空',
    );

    final isLight = Theme.of(context).brightness == Brightness.light;
    final padding = widget.padding ?? EdgeInsets.all(12.w);

    // ── 内容区样式 ──
    final contentBg = widget.contentBackgroundColor ??
        (isLight ? const Color(0xFFE6E9EA) : const Color(0xFF2B2E33));
    final contentBorderColor = widget.contentBorderColor ??
        (isLight ? const Color(0xFFE1E2E4) : const Color(0xFF3E4045));
    final contentBorderWidth = widget.contentBorderWidth ?? 1.w;
    final contentBorderRadius =
        widget.contentBorderRadius ?? BorderRadius.circular(5.r);

    // ── Tab 栏 ──
    final tabBar = MySegmentedControl(
      tabs: widget.tabs,
      controller: _controller,
      fit: widget.tabBarFit,
      backgroundColor: widget.tabBarBackgroundColor,
      borderRadius: widget.tabBarBorderRadius,
      padding: widget.tabBarPadding,
      boxShadow: widget.tabBarBoxShadow,
      dividerColor: widget.dividerColor,
      dividerWidth: widget.dividerWidth,
      dividerIndent: widget.dividerIndent,
      slideDuration: widget.slideDuration,
      slideCurve: widget.slideCurve,
    );

    // 解析 padding 以获取水平方向的值
    final resolvedPadding = padding.resolve(Directionality.of(context));
    final isCompact = widget.tabBarFit == MyTabBarFit.compact;

    // ── Stack 布局：Tab 栏骑在内容区边框中线上 ──
    return Stack(
      alignment: Alignment.center,
      children: [
        // 内容区：带 padding 使边框向内缩进，为 Tab 栏腾出重叠空间
        Padding(
          padding: padding,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: contentBg,
              border: Border.all(
                  color: contentBorderColor, width: contentBorderWidth),
              borderRadius: contentBorderRadius,
            ),
            child: ClipRRect(
              borderRadius: contentBorderRadius,
              child: _buildContent(),
            ),
          ),
        ),
        // Tab 栏：Positioned 到对应边缘
        // stretched 模式：设 left/right 拉满宽度
        // compact 模式：不设 left/right，靠 Stack alignment 居中
        Positioned(
          top: widget.position == MyTabPosition.top ? 0 : null,
          bottom: widget.position == MyTabPosition.bottom ? 0 : null,
          left: isCompact ? null : resolvedPadding.left,
          right: isCompact ? null : resolvedPadding.right,
          child: tabBar,
        ),
      ],
    );
  }

  /// 构建内容区域：无动画时用 IndexedStack，有动画时用 AnimatedSwitcher
  Widget _buildContent() {
    if (widget.transitionBuilder != null) {
      return AnimatedSwitcher(
        duration:
            widget.transitionDuration ?? const Duration(milliseconds: 300),
        transitionBuilder: widget.transitionBuilder!,
        child: KeyedSubtree(
          key: ValueKey(_controller.index),
          child: widget.children[_controller.index],
        ),
      );
    }
    return IndexedStack(
      index: _controller.index,
      children: widget.children,
    );
  }
}
