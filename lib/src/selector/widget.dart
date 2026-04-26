import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'models.dart';

// 默认面板宽度的设计稿基准（在 ScreenUtil 下经 `.w` 缩放为当前 px）。
// - 280.w 是常见下拉宽度，能容纳"图标 + 标题 + 副标题"三段；
// - 220.w 作为下界，避免 trigger 太窄时面板挤成一条；
// - 16.w 是面板距屏幕左右的安全边距（左右各 8.w）。
const double _kPanelDefaultMaxW = 280.0;
const double _kPanelMinW = 220.0;
const double _kPanelHorizontalSafe = 16.0;

// ============================================================================
// 公开 API
// ============================================================================

/// 通用选择器浮层
///
/// 在 [triggerContext] 所指 Widget 附近弹出一个面板，面板内含可选搜索框、
/// 富格式列表和可选底部区域。
///
/// 返回 [MySelectorResult]：
/// - [MySelectorDismissed]：用户点击外部或按 Escape，不做任何操作
/// - [MySelectorValueChanged]：用户做出了明确操作；
///   `value == null` 表示主动清除，`value != null` 表示选中了某项
///
/// ```dart
/// final result = await MySelector.show<String>(
///   triggerContext: context,
///   items: [...],
///   currentValue: selected,
///   showSearch: true,
///   clearOption: MySelectorClearOption(label: '不选择'),
///   allowReselect: true,
/// );
/// switch (result) {
///   case MySelectorDismissed(): break;
///   case MySelectorValueChanged(:final value):
///     state = value; // null = cleared, non-null = selected
/// }
/// ```
class MySelector {
  MySelector._();

  /// 弹出选择器面板，返回 [MySelectorResult] 告知调用方用户的操作意图。
  static Future<MySelectorResult<T>> show<T>({
    required BuildContext triggerContext,
    required List<MySelectorItem<T>> items,
    T? currentValue,
    // 清除 & 复选取消
    MySelectorClearOption? clearOption,
    bool allowReselect = false,
    // 弹出方向：null = 自动（根据可用空间判断），true = 强制上方，false = 强制下方
    bool? showPanelAbove,
    // 搜索
    bool showSearch = false,
    String searchHint = '搜索…',
    bool Function(MySelectorItem<T> item, String query)? searchFilter,
    // 自定义渲染
    Widget Function(
      BuildContext context,
      MySelectorItem<T> item,
      bool isSelected,
    )? itemBuilder,
    Widget Function(BuildContext context, VoidCallback dismiss)? footerBuilder,
    // 样式
    MySelectorStyle? style,
  }) async {
    assert(items.isNotEmpty, 'items 不能为空');

    final effectiveStyle = style ?? MySelectorStyle();
    final completer = Completer<MySelectorResult<T>>();

    final renderBox = triggerContext.findRenderObject() as RenderBox;
    final overlayState = Overlay.of(triggerContext, rootOverlay: true);

    late OverlayEntry entry;

    void dismiss(MySelectorResult<T> result) {
      entry.remove();
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    entry = OverlayEntry(
      builder: (_) => _SelectorOverlay<T>(
        renderBox: renderBox,
        overlayState: overlayState,
        items: items,
        currentValue: currentValue,
        clearOption: clearOption,
        allowReselect: allowReselect,
        showPanelAbove: showPanelAbove,
        showSearch: showSearch,
        searchHint: searchHint,
        searchFilter: searchFilter,
        itemBuilder: itemBuilder,
        footerBuilder: footerBuilder,
        style: effectiveStyle,
        onSelected: (item) => dismiss(MySelectorValueChanged(item.value, item: item)),
        onCleared: () => dismiss(MySelectorValueChanged(null)),
        onDismiss: () => dismiss(MySelectorDismissed()),
      ),
    );

    overlayState.insert(entry);
    return completer.future;
  }
}

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

// ============================================================================
// 选择面板主体
// ============================================================================

class _SelectorPanel<T> extends StatefulWidget {
  final List<MySelectorItem<T>> items;
  final T? currentValue;
  final MySelectorClearOption? clearOption;
  final bool allowReselect;
  final bool showAbove;
  final bool showSearch;
  final String searchHint;
  final bool Function(MySelectorItem<T>, String)? searchFilter;
  final Widget Function(BuildContext, MySelectorItem<T>, bool)? itemBuilder;
  final Widget Function(BuildContext, VoidCallback)? footerBuilder;
  final MySelectorStyle style;
  final void Function(MySelectorItem<T>) onSelected;
  final VoidCallback onCleared;
  final VoidCallback onDismiss;

  const _SelectorPanel({
    required this.items,
    required this.currentValue,
    required this.clearOption,
    required this.allowReselect,
    required this.showAbove,
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
  State<_SelectorPanel<T>> createState() => _SelectorPanelState<T>();
}

class _SelectorPanelState<T> extends State<_SelectorPanel<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late List<MySelectorItem<T>> _filtered;

  /// 普通列表项的键盘高亮索引，-1 表示无高亮
  int _highlightedIndex = -1;

  /// 清除项的键盘高亮状态
  bool _highlightClear = false;

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;

    _animCtrl = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scaleAnim = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();

    if (widget.showSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ---- 搜索 ----

  bool _defaultFilter(MySelectorItem<T> item, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return item.title.toLowerCase().contains(q) ||
        (item.subtitle?.toLowerCase().contains(q) ?? false);
  }

  void _handleSearch(String query) {
    final filter = widget.searchFilter ?? _defaultFilter;
    setState(() {
      _filtered = query.trim().isEmpty
          ? widget.items
          : widget.items.where((item) => filter(item, query)).toList();
      _highlightedIndex = -1;
      _highlightClear = false;
    });
  }

  // ---- 键盘导航 ----

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowDown:
        _moveHighlightDown();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        _moveHighlightUp();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.enter:
        if (event is KeyDownEvent) return _confirmHighlighted();
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.escape:
        if (event is KeyDownEvent) {
          widget.onDismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _moveHighlightDown() {
    if (!_highlightClear && _highlightedIndex == -1) {
      // 尚未高亮任何项：优先高亮清除项（如果存在），否则高亮第一个普通项
      setState(() {
        if (widget.clearOption != null) {
          _highlightClear = true;
        } else if (_filtered.isNotEmpty) {
          _highlightedIndex = 0;
        }
      });
    } else if (_highlightClear) {
      // 清除项 → 第一个普通项
      if (_filtered.isNotEmpty) {
        setState(() {
          _highlightClear = false;
          _highlightedIndex = 0;
        });
      }
    } else if (_highlightedIndex < _filtered.length - 1) {
      setState(() => _highlightedIndex++);
    }
    // 已在最后一项，不做操作
  }

  void _moveHighlightUp() {
    if (_highlightClear) {
      // 已在清除项（顶部），不做操作
    } else if (_highlightedIndex == 0 && widget.clearOption != null) {
      // 第一个普通项 → 清除项
      setState(() {
        _highlightClear = true;
        _highlightedIndex = -1;
      });
    } else if (_highlightedIndex > 0) {
      setState(() => _highlightedIndex--);
    } else if (_highlightedIndex == -1 && !_highlightClear) {
      // 尚未高亮，向上按 → 跳到最后一项
      if (_filtered.isNotEmpty) {
        setState(() => _highlightedIndex = _filtered.length - 1);
      }
    }
  }

  KeyEventResult _confirmHighlighted() {
    if (_highlightClear) {
      widget.onCleared();
      return KeyEventResult.handled;
    }
    if (_highlightedIndex >= 0 && _highlightedIndex < _filtered.length) {
      final item = _filtered[_highlightedIndex];
      if (item.enabled) {
        if (widget.allowReselect && item.value == widget.currentValue) {
          widget.onCleared();
        } else {
          widget.onSelected(item);
        }
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  // ---- 渲染 ----

  @override
  Widget build(BuildContext context) {
    final scaleAlignment =
        widget.showAbove ? Alignment.bottomLeft : Alignment.topLeft;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (_, child) => Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            alignment: scaleAlignment,
            child: child,
          ),
        ),
        child: _buildCard(),
      ),
    );
  }

  Widget _buildCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(widget.style.borderRadius),
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.style.borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.style.blurSigma,
            sigmaY: widget.style.blurSigma,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(widget.style.borderRadius),
              border: Border.all(color: Colors.grey.shade200, width: 0.8.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: widget.style.shadowOpacity),
                  blurRadius: 24.r,
                  offset: Offset(0, 6.h),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6.r,
                  offset: Offset(0, 1.h),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.showSearch) ...[
                  _buildSearch(),
                  _divider(),
                ],
                if (widget.clearOption != null) ...[
                  _buildClearItem(),
                  _divider(),
                ],
                Flexible(child: _buildList()),
                if (widget.footerBuilder != null) ...[
                  _divider(),
                  widget.footerBuilder!(context, widget.onDismiss),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _divider() =>
      Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200);

  // ---- 搜索框 ----

  Widget _buildSearch() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 8.h),
      child: TextField(
        controller: _searchCtrl,
        focusNode: _searchFocusNode,
        onChanged: _handleSearch,
        style: TextStyle(fontSize: 13.sp, color: Colors.black87),
        decoration: InputDecoration(
          hintText: widget.searchHint,
          hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 8.w, right: 4.w),
            child: Icon(Icons.search_rounded,
                size: 16.w, color: Colors.grey.shade400),
          ),
          prefixIconConstraints: BoxConstraints(minWidth: 32.w, minHeight: 0),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(
              color: const Color(0xFF4F6BFE).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ---- 清除项 ----

  Widget _buildClearItem() {
    final option = widget.clearOption!;
    return _HoverWrapper(
      enabled: true,
      hoverColor: widget.style.hoverColor,
      onTap: widget.onCleared,
      onHover: () => setState(() {
        _highlightClear = true;
        _highlightedIndex = -1;
      }),
      child: Container(
        // 键盘高亮时叠加背景色（与 _DefaultSelectorItem 的 isHighlighted 逻辑一致）
        color: _highlightClear ? widget.style.hoverColor : Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: Row(
          children: [
            // 与普通项左侧指示条+间距对齐（3w bar + 10w margin）
            SizedBox(width: 13.w),
            // 前缀图标
            if (option.leading != null) ...[
              option.leading!,
              SizedBox(width: 8.w),
            ] else ...[
              Icon(Icons.cancel_outlined,
                  size: 14.w, color: Colors.grey.shade400),
              SizedBox(width: 8.w),
            ],
            // 文字
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (option.subtitle != null &&
                      option.subtitle!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      option.subtitle!,
                      style: TextStyle(
                          fontSize: 10.sp, color: Colors.grey.shade400),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- 列表 ----

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text('无匹配项',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400)),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: _filtered.length,
      itemBuilder: (ctx, i) {
        final item = _filtered[i];
        final isSelected = item.value == widget.currentValue;

        // 点击逻辑：allowReselect 时复选已选项触发 onCleared
        final onTap = item.enabled
            ? () {
                if (widget.allowReselect && isSelected) {
                  widget.onCleared();
                } else {
                  widget.onSelected(item);
                }
              }
            : null;

        void onHover() => setState(() {
              _highlightedIndex = i;
              _highlightClear = false;
            });

        if (widget.itemBuilder != null) {
          return _HoverWrapper(
            enabled: item.enabled,
            hoverColor: widget.style.hoverColor,
            onTap: onTap,
            onHover: onHover,
            child: widget.itemBuilder!(ctx, item, isSelected),
          );
        }
        return _DefaultSelectorItem<T>(
          item: item,
          isSelected: isSelected,
          isHighlighted: i == _highlightedIndex,
          selectedColor: widget.style.selectedColor,
          hoverColor: widget.style.hoverColor,
          onTap: onTap,
          onHover: onHover,
        );
      },
    );
  }
}

// ============================================================================
// 通用 Hover 包裹器（供默认 item 和 itemBuilder 共享）
// ============================================================================

/// 为任意子组件附加 hover 背景色、鼠标光标和点击响应。
///
/// 内部用 [MouseRegion] + 自管理 [_isHovered] 状态直接修改 [Container.color]，
/// 绕开 InkWell ink 系统在有不透明背景时无法显示叠加色的问题。
class _HoverWrapper extends StatefulWidget {
  final Widget child;
  final Color hoverColor;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback onHover;

  const _HoverWrapper({
    required this.child,
    required this.hoverColor,
    required this.enabled,
    required this.onTap,
    required this.onHover,
  });

  @override
  State<_HoverWrapper> createState() => _HoverWrapperState();
}

class _HoverWrapperState extends State<_HoverWrapper> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.enabled && widget.onTap != null
          ? SystemMouseCursors.click
          : MouseCursor.defer,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover();
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          color: _isHovered ? widget.hoverColor : Colors.transparent,
          child: widget.child,
        ),
      ),
    );
  }
}

// ============================================================================
// 默认列表项渲染
// ============================================================================

/// 默认 item 的内容渲染（无状态），hover/cursor 由外层 [_HoverWrapper] 负责。
class _DefaultSelectorItem<T> extends StatelessWidget {
  final MySelectorItem<T> item;
  final bool isSelected;

  /// 键盘导航高亮（方向键）时为 true
  final bool isHighlighted;
  final Color selectedColor;
  final Color hoverColor;
  final VoidCallback? onTap;
  final VoidCallback onHover;

  const _DefaultSelectorItem({
    required this.item,
    required this.isSelected,
    required this.isHighlighted,
    required this.selectedColor,
    required this.hoverColor,
    required this.onTap,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    // _HoverWrapper 处理鼠标 hover；这里只处理选中态和键盘高亮的背景色。
    final Color extraBg = isSelected
        ? selectedColor.withValues(alpha: 0.06)
        : (isHighlighted ? hoverColor : Colors.transparent);

    return _HoverWrapper(
      enabled: item.enabled,
      hoverColor: hoverColor,
      onTap: onTap,
      onHover: onHover,
      child: Container(
        color: extraBg,
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        child: Row(
          children: [
            // 左侧选中指示条
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 3.w,
              height: 34.h,
              margin: EdgeInsets.only(right: 10.w),
              decoration: BoxDecoration(
                color: isSelected ? selectedColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Leading
            if (item.leading != null) ...[
              item.leading!,
              SizedBox(width: 8.w),
            ],
            // 标题 + 徽章 + 副标题
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? selectedColor
                                : (item.enabled ? Colors.black87 : Colors.grey),
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (item.badges != null && item.badges!.isNotEmpty) ...[
                        SizedBox(width: 5.w),
                        ...item.badges!,
                      ],
                    ],
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                    SizedBox(height: 2.h),
                    Text(
                      item.subtitle!,
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // 右侧勾选标记
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child:
                  Icon(Icons.check_rounded, size: 16.w, color: selectedColor),
            ),
          ],
        ),
      ),
    );
  }
}
