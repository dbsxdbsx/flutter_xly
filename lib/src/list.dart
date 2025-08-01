import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
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
              child: ReorderableListView.builder(
                scrollController: scrollController,
                itemCount: items.length,
                itemBuilder: itemBuilder,
                onReorder: onCardReordered!,
                footer: footer,
                buildDefaultDragHandles: false,
                proxyDecorator: _proxyDecorator,
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
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          child: child,
        );
      },
      child: child,
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
  void scrollToIndex(
    int index, {
    Duration duration = const Duration(milliseconds: 500),
    Curve curve = Curves.easeInOut,
    double alignment = 0.5, // 0.0 顶部, 0.5 居中, 1.0 底部
  }) {
    if (!mounted) return;

    final RenderBox? listViewBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewBox == null) return;

    // 计算滚动位置
    final listViewHeight = listViewBox.size.height;
    final cardTotalHeight = (widget.cardHeight ?? 80.h) +
        (widget.cardMargin?.call(index)?.vertical ?? 3.h);

    final targetCard = index * cardTotalHeight;
    final viewportMiddle = listViewHeight * alignment;
    final cardOffset = cardTotalHeight * alignment;

    double targetPosition = targetCard - (viewportMiddle - cardOffset);
    targetPosition = targetPosition.clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

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
