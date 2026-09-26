import 'dart:math';
import 'dart:ui';

import 'package:flutter/gestures.dart'
    show
        DragStartBehavior,
        VelocityTracker,
        kLongPressTimeout,
        kMinFlingVelocity,
        kTouchSlop;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

class MyList<T> extends StatelessWidget {
  // 1. 核心数据和构建器
  final List<T> items;
  final Widget Function(BuildContext, int) itemBuilder;

  // 2. 滚动控制
  final ScrollController scrollController;
  final bool showScrollbar;

  // 3. 拖拽相关
  final bool isDraggable;
  final Function(int, int)? onCardReordered;

  // 4. 附加组件
  final Widget? footer;

  const MyList({
    super.key,
    // 1. 核心数据和构建器
    required this.items,
    required this.itemBuilder,

    // 2. 滚动控制
    required this.scrollController,
    this.showScrollbar = true,

    // 3. 拖拽相关
    this.isDraggable = false,
    this.onCardReordered,

    // 4. 附加组件
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
      thumbVisibility: showScrollbar,
      child: isDraggable
          ? Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: _ScrollFlingRestorer(
                controller: scrollController,
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  // 长按识别会占着竞技场，快滑的位移发生在滚动获胜之前。
                  // start 会丢掉这段；down 把它算进滚动。
                  dragStartBehavior: DragStartBehavior.down,
                  itemCount: items.length,
                  itemBuilder: itemBuilder,
                  onReorderItem: (oldIndex, newIndex) {
                    // 保持 MyList 既有回调契约：向后移动时仍传移除前的插入下标。
                    onCardReordered!(
                      oldIndex,
                      oldIndex < newIndex ? newIndex + 1 : newIndex,
                    );
                  },
                  footer: footer,
                  buildDefaultDragHandles: false,
                  onReorderStart: (_) {
                    // 进入拖动时震一下。没有马达的桌面这次调用没有效果。
                    HapticFeedback.mediumImpact();
                  },
                  proxyDecorator: _proxyDecorator,
                ),
              ),
            )
          : ListView.builder(
              controller: scrollController,
              itemCount: items.length + (footer != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == items.length) {
                  return footer!;
                }
                return itemBuilder(context, index);
              },
            ),
    );
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        // 只放大卡片自己。再套一层 Material 阴影会按整行矩形来画，
        // 和卡片圆角阴影、左右边距叠成硬边。
        final double scale = lerpDouble(1, 1.03, animValue)!;
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// 快滑松手后，把手指速度交回列表，让它按力度滑一段再慢慢停下。
///
/// 长按拖动和滚动抢同一个手势时，框架有时只留下手指划过的距离，
/// 松手速度被记成 0。这里用全部触点（含系统补出来的点）自己算速度，
/// 下一帧按这个速度重新甩出去。按住超过长按时间才移动的，仍交给拖卡片。
class _ScrollFlingRestorer extends StatefulWidget {
  const _ScrollFlingRestorer({
    required this.controller,
    required this.child,
  });

  final ScrollController controller;
  final Widget child;

  @override
  State<_ScrollFlingRestorer> createState() => _ScrollFlingRestorerState();
}

class _ScrollFlingRestorerState extends State<_ScrollFlingRestorer> {
  VelocityTracker? _tracker;
  Offset? _downPosition;
  Duration? _downTime;
  int? _pointer;
  bool _flick = false;

  void _down(PointerDownEvent event) {
    if (_pointer != null) return;
    _pointer = event.pointer;
    _flick = false;
    _downPosition = event.position;
    _downTime = event.timeStamp;
    _tracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
  }

  void _move(PointerMoveEvent event) {
    if (event.pointer != _pointer) return;
    _tracker?.addPosition(event.timeStamp, event.position);
    final origin = _downPosition;
    final start = _downTime;
    if (origin == null || start == null || _flick) return;
    final slop =
        MediaQuery.maybeGestureSettingsOf(context)?.touchSlop ?? kTouchSlop;
    if ((event.position - origin).distance <= slop) return;
    if (event.timeStamp - start < kLongPressTimeout) {
      _flick = true;
    }
  }

  void _up(PointerUpEvent event) {
    if (event.pointer != _pointer) return;
    final tracker = _tracker;
    final flick = _flick;
    _pointer = null;
    _tracker = null;
    _downPosition = null;
    _downTime = null;
    _flick = false;
    if (!flick || tracker == null) return;
    final estimate = tracker.getVelocityEstimate();
    if (estimate == null) return;
    final speed = estimate.pixelsPerSecond;
    if (speed.dx.abs() > speed.dy.abs()) return;
    final desired = -speed.dy;
    if (desired.abs() < kMinFlingVelocity) return;
    final controller = widget.controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      final position = controller.position;
      if (position is! ScrollPositionWithSingleContext) return;
      if (!position.hasContentDimensions) return;
      position.goBallistic(desired);
    });
  }

  void _cancel(PointerCancelEvent event) {
    if (event.pointer != _pointer) return;
    _pointer = null;
    _tracker = null;
    _downPosition = null;
    _downTime = null;
    _flick = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _down,
      onPointerMove: _move,
      onPointerUp: _up,
      onPointerCancel: _cancel,
      child: widget.child,
    );
  }
}

class MyCardList extends StatefulWidget {
  // 1. 核心内容构建器
  final int itemCount;
  final Widget Function(int)? cardLeading;
  final Widget Function(int) cardBody;
  final Widget Function(int)? cardTrailing;

  // 2. 交互行为
  final Function(int, int)? onCardReordered;
  final Function(int)? onCardPressed;
  final Function(int)? onSwipeDelete;
  final Future<void> Function()? onLoadMore;

  // 3. 列表行为
  final bool showScrollbar;

  // 4. 卡片布局
  final double? cardHeight;
  final Widget Function(int)? cardSubtitle;
  final Widget Function(int)? cardBelow;
  final double? leadingAndBodySpacing;
  final EdgeInsets? Function(int)? cardPadding;
  final EdgeInsets? Function(int)? cardMargin;

  // 5. 卡片样式 - 修改为函数类型
  final Color? Function(int)? cardColor;
  final Color? Function(int)? cardHoverColor;
  final Color? Function(int)? cardSplashColor;
  final Color? Function(int)? cardShadowColor;
  final double? Function(int)? cardElevation;
  final BorderRadius? Function(int)? cardBorderRadius;

  // 6. 附加组件
  final Widget? footer;

  // Add new parameter for scroll control
  final int? indexToScroll;

  // 7. 状态回调
  final void Function(MyCardListState)? onStateCreated;

  const MyCardList({
    super.key,
    // 1. 核心内容
    required this.itemCount,
    this.cardLeading,
    required this.cardBody,
    this.cardTrailing,

    // 2. 交互行为
    this.onCardReordered,
    this.onCardPressed,
    this.onSwipeDelete,
    this.onLoadMore,

    // 3. 列表行为
    this.showScrollbar = true,

    // 4. 卡片布局
    this.cardHeight,
    this.cardSubtitle,
    this.cardBelow,
    this.leadingAndBodySpacing,
    this.cardPadding,
    this.cardMargin,

    // 5. 卡片样式
    this.cardColor,
    this.cardHoverColor,
    this.cardSplashColor,
    this.cardShadowColor,
    this.cardElevation,
    this.cardBorderRadius,

    // 6. 附加组件
    this.footer,
    this.indexToScroll,

    // 7. 状态回调
    this.onStateCreated,
  });

  @override
  MyCardListState createState() => MyCardListState();
}

class MyCardListState extends State<MyCardList> {
  final ScrollController _scrollController = ScrollController();
  // 使用全局唯一的计数器确保每个实例的 GlobalKey 都是唯一的
  static int _globalInstanceCounter = 0;
  late final GlobalKey _listViewKey;

  // 暴露命令式滚动方法
  /// 滚动到指定索引位置
  ///
  /// [index] 目标卡片索引（会自动 clamp 到有效范围）
  /// [duration] 滚动动画时长
  /// [curve] 滚动动画曲线
  /// [alignment] 对齐方式：0.0 顶部对齐, 0.5 居中, 1.0 底部对齐
  void scrollToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    double alignment = 0.5,
  }) {
    if (!mounted) return;
    if (widget.itemCount <= 0) return;

    // 1. index 越界保护：clamp 到有效范围 [0, itemCount-1]
    final safeIndex = index.clamp(0, widget.itemCount - 1);

    // 2. 检查 ScrollController 是否已附加到 ScrollView
    if (!_scrollController.hasClients) {
      // 还没准备好，延迟到下一帧再执行
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scrollToIndex(safeIndex,
              duration: duration, curve: curve, alignment: alignment);
        }
      });
      return;
    }

    // 3. 检查 RenderBox 是否已渲染
    final RenderBox? listViewBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewBox == null) {
      // RenderBox 还没准备好，延迟到下一帧
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          scrollToIndex(safeIndex,
              duration: duration, curve: curve, alignment: alignment);
        }
      });
      return;
    }

    final listViewHeight = listViewBox.size.height;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;

    // 4. 如果内容不足以滚动（所有项都在视口内），直接返回
    if (maxScrollExtent <= 0) return;

    // 5. 动态计算卡片高度：基于实际滚动范围和列表项数推算
    //    totalContentHeight = maxScrollExtent + viewportHeight
    //    cardAverageHeight = totalContentHeight / itemCount
    //    此方法自动适应缩放、屏幕变化等情况
    final totalContentHeight = maxScrollExtent + listViewHeight;
    final cardTotalHeight = totalContentHeight / widget.itemCount;

    // 6. 计算目标滚动位置，使目标卡片按 alignment 对齐
    final targetCardTop = safeIndex * cardTotalHeight;
    final viewportAlignPoint = listViewHeight * alignment;
    final cardAlignPoint = cardTotalHeight * alignment;

    double targetPosition =
        targetCardTop - (viewportAlignPoint - cardAlignPoint);
    targetPosition = targetPosition.clamp(0.0, maxScrollExtent);

    // 7. 执行滚动动画
    _scrollController.animateTo(
      targetPosition,
      duration: duration,
      curve: curve,
    );
  }

  // 添加私有方法生成稳定的 key
  ValueKey _generateStableKey(int index) {
    // 使用实例哈希码和索引确保 key 的唯一性，避免不同列表实例间的冲突
    final keyString = '${hashCode}_${widget.itemCount}_$index';
    return ValueKey('card_$keyString');
  }

  @override
  void initState() {
    super.initState();
    // 使用随机数和时间戳确保 GlobalKey 的绝对唯一性
    final random = Random();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final randomId = random.nextInt(999999);
    final instanceId = ++_globalInstanceCounter;

    _listViewKey = GlobalKey(
      debugLabel: 'card_list_${instanceId}_${timestamp}_${randomId}_$hashCode',
    );
    _scrollController.addListener(_onScroll);

    // 通知外部 state 已创建
    widget.onStateCreated?.call(this);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      widget.onLoadMore?.call();
    }
  }

  @override
  void didUpdateWidget(MyCardList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll when indexToScroll changes
    if (widget.indexToScroll != null &&
        widget.indexToScroll != oldWidget.indexToScroll) {
      scrollToIndex(widget.indexToScroll!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyList<int>(
      key: _listViewKey, // Add key to list view
      items: List.generate(widget.itemCount, (i) => i),
      isDraggable: widget.onCardReordered != null,
      scrollController: _scrollController,
      onCardReordered: widget.onCardReordered,
      footer: widget.footer,
      showScrollbar: widget.showScrollbar,
      itemBuilder: (context, index) {
        return MyCard(
          key: _generateStableKey(index),
          // 0. 列表相关
          index: index,

          // 1. 核心内容组件
          leading: widget.cardLeading?.call(index),
          trailing: widget.cardTrailing?.call(index),

          // 2. 布局和尺寸
          height: widget.cardHeight,
          subtitle: widget.cardSubtitle?.call(index),
          below: widget.cardBelow?.call(index),
          leadingAndBodySpacing: widget.leadingAndBodySpacing,
          padding: widget.cardPadding?.call(index),
          margin: widget.cardMargin?.call(index),

          // 3. 样式和装饰 - 调用函数获取样式
          cardColor: widget.cardColor?.call(index),
          cardElevation: widget.cardElevation?.call(index),
          cardShadowColor: widget.cardShadowColor?.call(index),
          cardBorderRadius: widget.cardBorderRadius?.call(index),
          cardHoverColor: widget.cardHoverColor?.call(index),
          cardSplashColor: widget.cardSplashColor?.call(index),

          // 4. 交互行为
          isDraggable: widget.onCardReordered != null,
          enableSwipeToDelete: widget.onSwipeDelete != null,
          onPressed: widget.onCardPressed != null
              ? () => widget.onCardPressed!(index)
              : null,
          onSwipeDeleted: widget.onSwipeDelete != null
              ? () => widget.onSwipeDelete!(index)
              : null,
          child: widget.cardBody(index),
        );
      },
    );
  }
}
