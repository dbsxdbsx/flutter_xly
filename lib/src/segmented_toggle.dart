import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app/desktop_window_gestures.dart';

/// [MySegmentedToggle] 的单个分段选项数据。
class MyToggleOption<T> {
  const MyToggleOption({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
    this.activeColor,
    this.activeForegroundColor,
    this.key,
  });

  /// 该段对应的业务值。
  final T value;

  /// 显示文本。
  final String label;

  /// 可选前置图标。
  final IconData? icon;

  /// 可选悬停提示。
  final String? tooltip;

  /// 该段被选中时滑块的背景色；为 `null` 时使用组件级 [MySegmentedToggle.thumbColor]。
  final Color? activeColor;

  /// 该段被选中时的文字与图标颜色；为 `null` 时使用组件级 [MySegmentedToggle.activeForegroundColor]。
  final Color? activeForegroundColor;

  /// 可选定位/测试 Key（挂在该段可点击区域上）。
  final Key? key;
}

/// 带真实物理滑块动画与跟手拖滑切换的胶囊分段开关。
///
/// 与绑定 `MyTabController` 的 `MySegmentedControl` 互补，适合无控制器负担的值驱动场景
/// （如「手动 / 智能」「浅色 / 深色」「列表 / 网格」等 2~N 段状态切换）：
/// - **连续物理驱动**：底层由单个 `AnimationController` 驱动连续逻辑槽位 `pos ∈ [0, N - 1]`，
///   支持点击任意段平滑滑行，也支持按住滑块跨任意多段 1:1 满程拖滑（绝不卡在半路）；
///   拖动中滑块位置、背景色、投影、文字/图标反色以及紧凑模式宽度均随位置实时插值。
/// - **零缓存同帧布局**：等宽与紧凑模式统一由自定义 `RenderBox` 在单次 `performLayout()`
///   中实时计算各分段与滑块几何，无 `GlobalKey` 测量缓存、无 `postFrameCallback` 滞后；
///   窗口任意放大/缩小 X、Y 轴或字体缩放时，滑块 0 帧延迟严丝合缝。
/// - **松手零倒车交接**：松手后保留当前滑块停留位置先回调 [onChanged]；若外部同步更新
///   [value]（推荐异步业务在状态层维护乐观目标态），滑块直接从松手处无缝滑完余程；若外部
///   拒绝变更或未更新 [value]，则平滑回弹回原槽位。
/// - **桌面手势友好**：内置 [MyWindowDragExcludeZone] 与 [MyDoubleClickConsumeZone]，在桌面端
///   拨动开关不会带走母窗口，连点也不会触发窗口双击最大化。
/// - **支持未选中态（`value == null`）**：`value` 为空或不在 [options] 中时滑块优雅缩隐，
///   获得有效值后原地平滑浮现。
///
/// **尺寸参数契约**：[padding]、[itemPadding]、[borderRadius]、[fontSize]、[iconSize]、
/// [iconGap]、[height] 显式传入时按 Flutter 逻辑像素直接使用，组件内部不再二次缩放；
/// 为 `null` 时使用基于 ScreenUtil 换算一次的默认值。
class MySegmentedToggle<T> extends StatefulWidget {
  /// 内部滑块层的测试/定位 Key（用于断言滑块位置与过渡动画）。
  static const Key thumbKey = Key('my-segmented-toggle-thumb');

  const MySegmentedToggle({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.notifyOnReselect = false,
    this.equalWidth = true,
    this.enableSwipe = true,
    this.height,
    this.trackColor,
    this.thumbColor,
    this.activeForegroundColor,
    this.inactiveForegroundColor,
    this.padding,
    this.itemPadding,
    this.borderRadius,
    this.fontSize,
    this.iconSize,
    this.iconGap,
    this.duration = const Duration(milliseconds: 240),
    this.curve = const Cubic(0.22, 1.0, 0.36, 1.0),
    this.tooltipWaitDuration = const Duration(milliseconds: 350),
  }) : assert(options.length >= 2, 'MySegmentedToggle 至少需要 2 个选项');

  /// 分段选项列表（至少 2 项）。
  final List<MyToggleOption<T>> options;

  /// 当前选中的值；为 `null` 或不在 [options] 中时进入未选中态（滑块隐藏）。
  final T? value;

  /// 选中或拖滑切换时的回调。
  ///
  /// 注意：本组件为受控组件，真理源始终是外部传入的 [value]。若切换涉及耗时异步操作
  /// （如网络请求、写配置、状态同步），建议调用方在状态层先置入乐观目标值、失败再回滚，
  /// 即可获得“松手即滑到位，失败自动弹回”的原生手感。
  final ValueChanged<T>? onChanged;

  /// 点击当前已激活分段时是否也触发 [onChanged]（默认 `false`）。
  final bool notifyOnReselect;

  /// 各分段是否等宽（默认 `true`，2~3 段文字相近时更对称）。
  final bool equalWidth;

  /// 是否支持鼠标或手指在开关上左右拖滑切换（默认 `true`）。
  final bool enableSwipe;

  /// 可选显式高度（逻辑像素）；为 `null` 时按内容 + [itemPadding] + [padding] 自适应。
  final double? height;

  /// 外层轨道背景色；为 `null` 时按主题明暗自动适配。
  final Color? trackColor;

  /// 默认滑块背景色（选项自身未指定 [MyToggleOption.activeColor] 时使用）。
  final Color? thumbColor;

  /// 默认激活态文字/图标色（选项自身未指定 [MyToggleOption.activeForegroundColor] 时使用）。
  final Color? activeForegroundColor;

  /// 未激活态文字/图标色。
  final Color? inactiveForegroundColor;

  /// 轨道内边距（逻辑像素，不二次缩放）；为 `null` 时默认 `EdgeInsets.all(2.w)`。
  final EdgeInsetsGeometry? padding;

  /// 单个分段的内部边距（逻辑像素，不二次缩放）；为 `null` 时默认
  /// `EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h)`。
  final EdgeInsetsGeometry? itemPadding;

  /// 外层轨道圆角半径（逻辑像素，不二次缩放）；滑块圆角自动内缩。为 `null` 时默认 `13.r`。
  final double? borderRadius;

  /// 文本字号（逻辑像素，不二次缩放）；为 `null` 时默认 `11.sp`。
  final double? fontSize;

  /// 图标尺寸（逻辑像素，不二次缩放）；为 `null` 时默认 `12.sp`。
  final double? iconSize;

  /// 图标与文本间距（逻辑像素，不二次缩放）；为 `null` 时默认 `3.w`。
  final double? iconGap;

  /// 滑块滑动与颜色过渡时长，默认 `240ms`。
  final Duration duration;

  /// 滑块滑动曲线，默认 Apple 风格平滑减速曲线 `Cubic(0.22, 1.0, 0.36, 1.0)`。
  final Curve curve;

  /// Tooltip 悬停延迟。
  final Duration tooltipWaitDuration;

  @override
  State<MySegmentedToggle<T>> createState() => _MySegmentedToggleState<T>();
}

class _MySegmentedToggleState<T> extends State<MySegmentedToggle<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _layoutKey = GlobalKey();

  late final AnimationController _posController;
  final ValueNotifier<bool> _draggingNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<int?> _hoveredIndexNotifier = ValueNotifier<int?>(null);

  bool _isDragging = false;
  double? _swipeDownX;
  int? _swipeDownIndex;
  double _dragStartPos = 0.0;
  double _dragStartCenterX = 0.0;
  double _lastGlobalX = 0.0;
  int _settleGeneration = 0;

  int get _activeIndex {
    if (widget.value == null) return -1;
    return widget.options.indexWhere((o) => o.value == widget.value);
  }

  double get _maxPos => (widget.options.length - 1).toDouble();

  _RenderSegmentedToggleLayout? get _layoutRenderObject {
    final ro = _layoutKey.currentContext?.findRenderObject();
    return ro is _RenderSegmentedToggleLayout && ro.hasSize ? ro : null;
  }

  @override
  void initState() {
    super.initState();
    final initialIdx = _activeIndex;
    _posController = AnimationController.unbounded(
      vsync: this,
      value: initialIdx >= 0 ? initialIdx.toDouble() : 0.0,
    );
  }

  @override
  void dispose() {
    _posController.dispose();
    _draggingNotifier.dispose();
    _hoveredIndexNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MySegmentedToggle<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldIdx = oldWidget.value == null
        ? -1
        : oldWidget.options.indexWhere((o) => o.value == oldWidget.value);
    final newIdx = _activeIndex;

    if (oldWidget.options.length != widget.options.length ||
        oldWidget.equalWidth != widget.equalWidth) {
      _posController.stop();
      _posController.value =
          (newIdx >= 0 ? newIdx.toDouble() : 0.0).clamp(0.0, _maxPos);
      return;
    }

    if (oldIdx != newIdx && !_isDragging) {
      _settleGeneration++;
      if (newIdx < 0) {
        // 变为未选中态：保持原地淡出，不额外飞行。
      } else if (oldIdx < 0) {
        // 从未选中态获得值：直接原地就位，由 AnimatedOpacity + AnimatedScale 浮现。
        _posController.stop();
        _posController.value = newIdx.toDouble();
      } else {
        // 从当前真实位置（含刚松手的拖拽停留点或中途打断位置）无缝滑向新槽位。
        _animateToIndex(newIdx);
      }
    }
  }

  void _animateToIndex(int index) {
    final target = index.toDouble().clamp(0.0, _maxPos);
    final distance = (target - _posController.value).abs();
    if (distance < 0.001) {
      _posController.value = target;
      return;
    }
    // 拖到接近目标处松手时按剩余路程自适应收尾时长，吸附更干脆利落。
    final factor = distance >= 1.0 ? 1.0 : (0.45 + 0.55 * distance);
    final adaptiveMs = (widget.duration.inMilliseconds * factor)
        .round()
        .clamp(80, widget.duration.inMilliseconds);
    _posController.animateTo(
      target,
      duration: Duration(milliseconds: adaptiveMs),
      curve: widget.curve,
    );
  }

  void _selectIndex(int index) {
    if (widget.onChanged == null) return;
    if (index < 0 || index >= widget.options.length) return;
    final target = widget.options[index].value;
    if (!widget.notifyOnReselect && target == widget.value) return;
    widget.onChanged!(target);
  }

  int? _hitIndexAtGlobalX(double globalX) {
    final ro = _layoutRenderObject;
    if (ro == null || ro.size.width <= 0) return null;
    final localX = ro.globalToLocal(Offset(globalX, 0)).dx;
    final count = widget.options.length;
    final lefts = ro.segmentLefts;
    final widths = ro.segmentWidths;
    if (lefts.length != count || widths.length != count) {
      final segW = ro.size.width / count;
      if (segW <= 0) return null;
      return (localX / segW).floor().clamp(0, count - 1);
    }
    for (var i = 0; i < count; i++) {
      final right = lefts[i] + widths[i];
      if (localX <= right || i == count - 1) {
        return i;
      }
    }
    return count - 1;
  }

  double _centerAtPos(
    double pos,
    List<double> lefts,
    List<double> widths,
  ) {
    final count = lefts.length;
    final clamped = pos.clamp(0.0, (count - 1).toDouble());
    final lo = clamped.floor().clamp(0, count - 1);
    final hi = clamped.ceil().clamp(0, count - 1);
    final t = clamped - lo;
    final cLo = lefts[lo] + widths[lo] * 0.5;
    final cHi = lefts[hi] + widths[hi] * 0.5;
    return lerpDouble(cLo, cHi, t)!;
  }

  double _posForCenterX(
    double centerX,
    List<double> lefts,
    List<double> widths,
  ) {
    final count = lefts.length;
    final centers = [
      for (var i = 0; i < count; i++) lefts[i] + widths[i] * 0.5,
    ];
    if (centerX <= centers.first) return 0.0;
    if (centerX >= centers.last) return (count - 1).toDouble();
    for (var i = 0; i < count - 1; i++) {
      final c0 = centers[i];
      final c1 = centers[i + 1];
      if (centerX <= c1) {
        final span = c1 - c0;
        if (span <= 0) return i.toDouble();
        return i + ((centerX - c0) / span).clamp(0.0, 1.0);
      }
    }
    return (count - 1).toDouble();
  }

  void _applyDragAtGlobalX(double globalX) {
    _lastGlobalX = globalX;
    final downX = _swipeDownX;
    if (downX == null) return;
    final ro = _layoutRenderObject;
    final count = widget.options.length;
    if (ro == null || count < 2) return;

    final lefts = ro.segmentLefts;
    final widths = ro.segmentWidths;
    if (lefts.length != count || widths.length != count) return;

    // 换算成组件局部坐标差，兼容 FittedBox 等祖先缩放变换。
    final localDownX = ro.globalToLocal(Offset(downX, 0)).dx;
    final localCurX = ro.globalToLocal(Offset(globalX, 0)).dx;
    final localDx = localCurX - localDownX;

    final targetCenter = _dragStartCenterX + localDx;
    _posController.value = _posForCenterX(targetCenter, lefts, widths);
  }

  void _handleSwipeDown(DragDownDetails details) {
    _swipeDownX = details.globalPosition.dx;
    _lastGlobalX = details.globalPosition.dx;
    _swipeDownIndex = _hitIndexAtGlobalX(details.globalPosition.dx);
  }

  void _handleSwipeStart(DragStartDetails details) {
    if (!widget.enableSwipe || widget.onChanged == null) return;
    _settleGeneration++;
    _posController.stop();

    _isDragging = true;
    _draggingNotifier.value = true;
    _hoveredIndexNotifier.value = null;

    final currentActive = _activeIndex;
    _dragStartPos = currentActive >= 0
        ? _posController.value.clamp(0.0, _maxPos)
        : (_swipeDownIndex?.toDouble() ?? 0.0);

    final ro = _layoutRenderObject;
    final count = widget.options.length;
    if (ro != null &&
        ro.segmentLefts.length == count &&
        ro.segmentWidths.length == count) {
      _dragStartCenterX =
          _centerAtPos(_dragStartPos, ro.segmentLefts, ro.segmentWidths);
    }

    _swipeDownX ??= details.globalPosition.dx;
    _applyDragAtGlobalX(details.globalPosition.dx);
  }

  void _handleSwipeUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    _applyDragAtGlobalX(details.globalPosition.dx);
  }

  void _handleSwipeEnd(DragEndDetails details) {
    if (!_isDragging) {
      _swipeDownX = null;
      _swipeDownIndex = null;
      return;
    }

    final downX = _swipeDownX ?? _lastGlobalX;
    final totalDx = _lastGlobalX - downX;
    final vx = details.velocity.pixelsPerSecond.dx;
    final count = widget.options.length;
    final currentActive = _activeIndex;
    final currentPos = _posController.value.clamp(0.0, _maxPos);
    final downIdx = _swipeDownIndex;

    // 关键：先结束拖拽态，但保留 _posController.value 停在松手瞬间的位置，绝不提前清零回弹！
    _isDragging = false;
    _draggingNotifier.value = false;
    _swipeDownX = null;
    _swipeDownIndex = null;

    if (count < 2) return;

    int targetIdx;
    final deltaPos = currentPos - _dragStartPos;

    // 1. 轻按目标段时的轻微手抖（位移很小且松手仍在按下的那段内）：按点击该段处理，避免误吞点击。
    final upIdx = _hitIndexAtGlobalX(_lastGlobalX);
    if (currentActive >= 0 &&
        downIdx != null &&
        downIdx != currentActive &&
        upIdx == downIdx &&
        totalDx.abs() < 14.0 &&
        vx.abs() < 180.0) {
      targetIdx = downIdx;
    } else if (deltaPos.abs() >= 1.0) {
      // 2. 跨段满程拖滑：以最终落点四舍五入，支持从第 0 段一口气丝滑拖到第 N 段。
      targetIdx = currentPos.round().clamp(0, count - 1);
    } else if (deltaPos.abs() >= 0.30) {
      // 3. 单段内拖动超过 30%：直接顺势切入拖动方向相邻段。
      final step = deltaPos > 0 ? 1 : -1;
      targetIdx = (_dragStartPos.round() + step).clamp(0, count - 1);
    } else if (vx.abs() >= 180.0) {
      // 4. 快速轻甩：按甩动方向切 1 步。
      final step = vx > 0 ? 1 : -1;
      final base = currentActive >= 0
          ? _dragStartPos.round()
          : (step > 0 ? 0 : count - 1);
      targetIdx = (base + step).clamp(0, count - 1);
    } else {
      // 5. 未过阈值且无甩动：平滑弹回起点。
      targetIdx = currentActive >= 0 ? currentActive : 0;
    }

    final gen = ++_settleGeneration;

    if (targetIdx != currentActive) {
      // 先通知外部：若外部同步更新 widget.value（或使用乐观态），didUpdateWidget
      // 会在本帧立刻递增 _settleGeneration，并从当前停留点无缝滑完最后一段路程。
      _selectIndex(targetIdx);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || gen != _settleGeneration || _isDragging) return;
        // 若本帧结束时外部未改变 widget.value（如未连接、繁忙拦截或异步未做乐观态），
        // 从当前松手位置柔和弹回原槽位。
        final fallback = _activeIndex >= 0 ? _activeIndex : 0;
        _animateToIndex(fallback);
      });
    } else {
      if (currentActive >= 0) {
        _animateToIndex(currentActive);
      }
    }
  }

  void _handleSwipeCancel() {
    _swipeDownX = null;
    _swipeDownIndex = null;
    if (!_isDragging) return;
    _isDragging = false;
    _draggingNotifier.value = false;
    final current = _activeIndex;
    if (current >= 0) {
      _animateToIndex(current);
    }
  }

  Color _thumbColorAtPos(double pos, Color defaultThumbColor) {
    final count = widget.options.length;
    final clamped = pos.clamp(0.0, _maxPos);
    final lo = clamped.floor().clamp(0, count - 1);
    final hi = clamped.ceil().clamp(0, count - 1);
    final t = clamped - lo;
    final cLo = widget.options[lo].activeColor ?? defaultThumbColor;
    final cHi = widget.options[hi].activeColor ?? defaultThumbColor;
    return Color.lerp(cLo, cHi, t) ?? cLo;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trackColor = widget.trackColor ??
        (isDark ? const Color(0xFF2C313A) : const Color(0xFFE4E7EC));
    final defaultThumbColor = widget.thumbColor ??
        (isDark ? Colors.blue.shade500 : Colors.blue.shade600);
    final defaultActiveFg = widget.activeForegroundColor ?? Colors.white;
    final inactiveFg = widget.inactiveForegroundColor ??
        (isDark ? Colors.white70 : Colors.blueGrey.shade700);

    final padding = widget.padding ?? EdgeInsets.all(2.w);
    final itemPadding = widget.itemPadding ??
        EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h);
    final outerRadius = widget.borderRadius ?? 13.r;
    final innerRadius = (outerRadius - 2.0).clamp(2.0, outerRadius);
    final fontSize = widget.fontSize ?? 11.sp;
    final iconSize = widget.iconSize ?? 12.sp;
    final iconGap = widget.iconGap ?? 3.w;

    final activeIdx = _activeIndex;
    final hasActive = activeIdx >= 0;

    Widget track = DecoratedBox(
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(outerRadius),
      ),
      child: Padding(
        padding: padding,
        child: _wrapSwipeDetector(
          child: _SegmentedToggleLayout(
            key: _layoutKey,
            equalWidth: widget.equalWidth,
            position: _posController,
            children: [
              _buildThumb(
                visible: hasActive,
                defaultThumbColor: defaultThumbColor,
                innerRadius: innerRadius,
              ),
              for (var i = 0; i < widget.options.length; i++)
                _buildSegmentItem(
                  index: i,
                  option: widget.options[i],
                  hasActive: hasActive,
                  activeFg: widget.options[i].activeForegroundColor ??
                      defaultActiveFg,
                  inactiveFg: inactiveFg,
                  itemPadding: itemPadding,
                  innerRadius: innerRadius,
                  fontSize: fontSize,
                  iconSize: iconSize,
                  iconGap: iconGap,
                ),
            ],
          ),
        ),
      ),
    );
    if (widget.height != null) {
      track = SizedBox(height: widget.height, child: track);
    }

    return MyWindowDragExcludeZone(
      behavior: HitTestBehavior.opaque,
      child: MyDoubleClickConsumeZone(child: track),
    );
  }

  Widget _wrapSwipeDetector({required Widget child}) {
    if (!widget.enableSwipe || widget.onChanged == null) return child;
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        _ToggleSwipeRecognizer:
            GestureRecognizerFactoryWithHandlers<_ToggleSwipeRecognizer>(
          () => _ToggleSwipeRecognizer(debugOwner: this),
          (_ToggleSwipeRecognizer instance) {
            instance.onDown = _handleSwipeDown;
            instance.onStart = _handleSwipeStart;
            instance.onUpdate = _handleSwipeUpdate;
            instance.onEnd = _handleSwipeEnd;
            instance.onCancel = _handleSwipeCancel;
          },
        ),
      },
      child: child,
    );
  }

  Widget _buildThumb({
    required bool visible,
    required Color defaultThumbColor,
    required double innerRadius,
  }) {
    return IgnorePointer(
      key: MySegmentedToggle.thumbKey,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: widget.curve,
        opacity: visible ? 1.0 : 0.0,
        child: AnimatedScale(
          duration: widget.duration,
          curve: widget.curve,
          scale: visible ? 1.0 : 0.88,
          child: AnimatedBuilder(
            animation: _posController,
            builder: (context, _) {
              final thumbColor =
                  _thumbColorAtPos(_posController.value, defaultThumbColor);
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: thumbColor,
                  borderRadius: BorderRadius.circular(innerRadius),
                  boxShadow: [
                    BoxShadow(
                      color: thumbColor.withValues(alpha: 0.28),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required MyToggleOption<T> option,
    required bool hasActive,
    required Color activeFg,
    required Color inactiveFg,
    required EdgeInsetsGeometry itemPadding,
    required double innerRadius,
    required double fontSize,
    required double iconSize,
    required double iconGap,
  }) {
    // 关键：把 padding 与 hover 的 AnimatedContainer 分离！
    // 窗口缩放改变 ScreenUtil 的 itemPadding 时即时生效，绝不产生 140ms 滞后橡皮筋。
    final segmentBody = GestureDetector(
      key: option.key,
      behavior: HitTestBehavior.opaque,
      onTap: widget.onChanged == null ? null : () => _selectIndex(index),
      child: ValueListenableBuilder<int?>(
        valueListenable: _hoveredIndexNotifier,
        builder: (context, hoveredIndex, child) {
          final showHover =
              hoveredIndex == index && !_isDragging && index != _activeIndex;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: showHover
                  ? Colors.black.withValues(alpha: 0.04)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(innerRadius),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: itemPadding,
          child: AnimatedBuilder(
            animation: _posController,
            builder: (context, _) {
              final weight = hasActive
                  ? (1.0 - (_posController.value - index).abs()).clamp(0.0, 1.0)
                  : 0.0;
              final fg = Color.lerp(inactiveFg, activeFg, weight) ?? inactiveFg;
              // 紧凑模式保持固定字重，防止拖动滑过中线时字宽突增引发微抖。
              final fontWeight = !widget.equalWidth
                  ? FontWeight.w600
                  : (weight >= 0.5 ? FontWeight.w600 : FontWeight.w500);
              return Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: iconSize, color: fg),
                    SizedBox(width: iconGap),
                  ],
                  Text(
                    option.label,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: fontWeight,
                      color: fg,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    Widget content = ValueListenableBuilder<bool>(
      valueListenable: _draggingNotifier,
      builder: (context, dragging, child) {
        final cursor = dragging
            ? SystemMouseCursors.grabbing
            : (widget.onChanged != null
                ? SystemMouseCursors.click
                : SystemMouseCursors.basic);
        return MouseRegion(
          cursor: cursor,
          onEnter: (_) {
            if (!_isDragging) _hoveredIndexNotifier.value = index;
          },
          onExit: (_) {
            if (_hoveredIndexNotifier.value == index) {
              _hoveredIndexNotifier.value = null;
            }
          },
          child: child,
        );
      },
      child: segmentBody,
    );

    if (option.tooltip != null && option.tooltip!.isNotEmpty) {
      content = Tooltip(
        message: option.tooltip!,
        waitDuration: widget.tooltipWaitDuration,
        child: content,
      );
    }

    return content;
  }
}

/// 同帧布局引擎：`children[0]` 为底层滑块，`children[1..N]` 为各分段。
///
/// 在单次 `performLayout()` 内先按实时约束布局所有分段，随即用最新几何与
/// [position] 精确约束并定位滑块，彻底消除任何测量缓存与窗口缩放错位。
class _SegmentedToggleLayout extends MultiChildRenderObjectWidget {
  const _SegmentedToggleLayout({
    super.key,
    required this.equalWidth,
    required this.position,
    required super.children,
  });

  final bool equalWidth;
  final ValueListenable<double> position;

  @override
  _RenderSegmentedToggleLayout createRenderObject(BuildContext context) {
    return _RenderSegmentedToggleLayout(
      equalWidth: equalWidth,
      position: position,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderSegmentedToggleLayout renderObject,
  ) {
    renderObject
      ..equalWidth = equalWidth
      ..position = position;
  }
}

class _SegmentedToggleParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderSegmentedToggleLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _SegmentedToggleParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _SegmentedToggleParentData> {
  _RenderSegmentedToggleLayout({
    required bool equalWidth,
    required ValueListenable<double> position,
  })  : _equalWidth = equalWidth,
        _position = position;

  bool _equalWidth;
  bool get equalWidth => _equalWidth;
  set equalWidth(bool value) {
    if (_equalWidth == value) return;
    _equalWidth = value;
    markNeedsLayout();
  }

  ValueListenable<double> _position;
  ValueListenable<double> get position => _position;
  set position(ValueListenable<double> value) {
    if (_position == value) return;
    if (attached) _position.removeListener(_onPositionChanged);
    _position = value;
    if (attached) _position.addListener(_onPositionChanged);
    markNeedsLayout();
  }

  List<double> _segmentLefts = const [];
  List<double> _segmentWidths = const [];

  List<double> get segmentLefts => _segmentLefts;
  List<double> get segmentWidths => _segmentWidths;

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
    final count = childCount - 1;
    if (_equalWidth &&
        hasSize &&
        firstChild != null &&
        count >= 2 &&
        _segmentLefts.length == count &&
        _segmentWidths.length == count) {
      // 等宽模式滑块宽度不变，仅需原地更新滑块偏移并重绘，零布局开销。
      final (left, _) = _thumbGeometry(count);
      final thumbData = firstChild!.parentData! as _SegmentedToggleParentData;
      if ((thumbData.offset.dx - left).abs() > 0.001) {
        thumbData.offset = Offset(left, 0.0);
        markNeedsPaint();
      }
      return;
    }
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _SegmentedToggleParentData) {
      child.parentData = _SegmentedToggleParentData();
    }
  }

  List<RenderBox> _segmentChildren() {
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

  (double left, double width) _thumbGeometry(int count) {
    final maxPos = (count - 1).toDouble();
    final pos = _position.value.clamp(0.0, maxPos);
    final lo = pos.floor().clamp(0, count - 1);
    final hi = pos.ceil().clamp(0, count - 1);
    final t = pos - lo;
    final left = lerpDouble(_segmentLefts[lo], _segmentLefts[hi], t)!;
    final width = math.max(
      0.0,
      lerpDouble(_segmentWidths[lo], _segmentWidths[hi], t)!,
    );
    return (left, width);
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final segments = _segmentChildren();
    if (segments.isEmpty) return 0.0;
    if (_equalWidth) {
      var maxW = 0.0;
      for (final seg in segments) {
        maxW = math.max(maxW, seg.getMinIntrinsicWidth(height));
      }
      return maxW * segments.length;
    }
    var sum = 0.0;
    for (final seg in segments) {
      sum += seg.getMinIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final segments = _segmentChildren();
    if (segments.isEmpty) return 0.0;
    if (_equalWidth) {
      var maxW = 0.0;
      for (final seg in segments) {
        maxW = math.max(maxW, seg.getMaxIntrinsicWidth(height));
      }
      return maxW * segments.length;
    }
    var sum = 0.0;
    for (final seg in segments) {
      sum += seg.getMaxIntrinsicWidth(height);
    }
    return sum;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final segments = _segmentChildren();
    if (segments.isEmpty) return 0.0;
    final childW = _equalWidth && width.isFinite
        ? width / segments.length
        : double.infinity;
    var maxH = 0.0;
    for (final seg in segments) {
      maxH = math.max(maxH, seg.getMinIntrinsicHeight(childW));
    }
    return maxH;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final segments = _segmentChildren();
    if (segments.isEmpty) return 0.0;
    final childW = _equalWidth && width.isFinite
        ? width / segments.length
        : double.infinity;
    var maxH = 0.0;
    for (final seg in segments) {
      maxH = math.max(maxH, seg.getMaxIntrinsicHeight(childW));
    }
    return maxH;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    return defaultComputeDistanceToFirstActualBaseline(baseline);
  }

  @override
  void performLayout() {
    final thumb = firstChild;
    final segments = _segmentChildren();
    final count = segments.length;
    if (thumb == null || count == 0) {
      _segmentLefts = const [];
      _segmentWidths = const [];
      size = constraints.smallest;
      return;
    }

    final double trackHeight;
    if (constraints.hasTightHeight) {
      trackHeight = constraints.maxHeight;
    } else {
      var h = constraints.minHeight;
      for (final seg in segments) {
        h = math.max(h, seg.getMaxIntrinsicHeight(double.infinity));
      }
      trackHeight = h.clamp(constraints.minHeight, constraints.maxHeight);
    }

    final lefts = List<double>.filled(count, 0.0);
    final widths = List<double>.filled(count, 0.0);
    double totalWidth;

    if (_equalWidth) {
      final double segWidth;
      if (constraints.hasTightWidth) {
        segWidth = constraints.maxWidth / count;
      } else {
        var maxSegW = 0.0;
        for (final seg in segments) {
          maxSegW = math.max(maxSegW, seg.getMaxIntrinsicWidth(trackHeight));
        }
        final desiredTotal = (maxSegW * count).clamp(
          constraints.minWidth,
          constraints.maxWidth,
        );
        segWidth = desiredTotal / count;
      }

      final segConstraints = BoxConstraints.tightFor(
        width: segWidth,
        height: trackHeight,
      );
      for (var i = 0; i < count; i++) {
        final seg = segments[i];
        seg.layout(segConstraints, parentUsesSize: true);
        final left = i * segWidth;
        (seg.parentData! as _SegmentedToggleParentData).offset =
            Offset(left, 0.0);
        lefts[i] = left;
        widths[i] = segWidth;
      }
      totalWidth = segWidth * count;
    } else {
      // 紧凑模式：直接用各分段实时固有宽度算出本帧精确槽宽，只布局一次，
      // 拖动动画中分段约束不变自动短路，窗口缩放时当帧同步重算。
      final natWidths = List<double>.filled(count, 0.0);
      var naturalTotal = 0.0;
      for (var i = 0; i < count; i++) {
        final w = segments[i].getMaxIntrinsicWidth(trackHeight);
        natWidths[i] = w;
        naturalTotal += w;
      }

      final finalWidths = List<double>.filled(count, 0.0);
      if (constraints.hasBoundedWidth &&
          naturalTotal > constraints.maxWidth &&
          naturalTotal > 0) {
        final scale = constraints.maxWidth / naturalTotal;
        for (var i = 0; i < count; i++) {
          finalWidths[i] = natWidths[i] * scale;
        }
      } else if (naturalTotal < constraints.minWidth) {
        final extra = (constraints.minWidth - naturalTotal) / count;
        for (var i = 0; i < count; i++) {
          finalWidths[i] = natWidths[i] + extra;
        }
      } else {
        for (var i = 0; i < count; i++) {
          finalWidths[i] = natWidths[i];
        }
      }

      var cursorX = 0.0;
      for (var i = 0; i < count; i++) {
        final seg = segments[i];
        final w = math.max(0.0, finalWidths[i]);
        seg.layout(
          BoxConstraints.tightFor(width: w, height: trackHeight),
          parentUsesSize: true,
        );
        (seg.parentData! as _SegmentedToggleParentData).offset =
            Offset(cursorX, 0.0);
        lefts[i] = cursorX;
        widths[i] = seg.size.width;
        cursorX += seg.size.width;
      }
      totalWidth = cursorX;
    }

    _segmentLefts = lefts;
    _segmentWidths = widths;
    size = constraints.constrain(Size(totalWidth, trackHeight));

    final (thumbLeft, thumbWidth) = _thumbGeometry(count);
    thumb.layout(
      BoxConstraints.tightFor(width: thumbWidth, height: size.height),
      parentUsesSize: false,
    );
    (thumb.parentData! as _SegmentedToggleParentData).offset =
        Offset(thumbLeft, 0.0);
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

/// 轻拨/拖滑开关专用横向拖拽识别器：
/// 鼠标与触屏均需超过 5px 才接管，保证轻点无阻碍、跟手拖滑零延迟起步。
class _ToggleSwipeRecognizer extends HorizontalDragGestureRecognizer {
  _ToggleSwipeRecognizer({super.debugOwner}) {
    onlyAcceptDragOnThreshold = true;
  }

  static const double _swipeSlop = 5.0;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event.kind == PointerDeviceKind.mouse &&
        event is PointerDownEvent &&
        event.buttons != kPrimaryMouseButton) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  bool hasSufficientGlobalDistanceToAccept(
    PointerDeviceKind pointerDeviceKind,
    double? deviceTouchSlop,
  ) {
    return globalDistanceMoved.abs() > _swipeSlop;
  }
}
