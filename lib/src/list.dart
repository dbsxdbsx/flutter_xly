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
  final EdgeInsets? cardPadding;
  final EdgeInsets? cardMargin;

  // 5. 卡片样式
  final Color? cardColor;
  final Color? cardHoverColor;
  final Color? cardSplashColor;
  final Color? cardShadowColor;
  final double? cardElevation;
  final BorderRadius? cardBorderRadius;

  // 6. 附加组件
  final Widget? footer;

  // Add new parameter for scroll control
  final int? indexToScroll;

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
  });

  @override
  MyCardListState createState() => MyCardListState();
}

class MyCardListState extends State<MyCardList> {
  final ScrollController _scrollController = ScrollController();
  // Add key to measure list view size
  final GlobalKey _listViewKey = GlobalKey();

  // 添加私有方法生成稳定的 key
  ValueKey _generateStableKey(int index) {
    // 使用 hashCode 来确保 key 的唯一性
    final keyString = '${widget.itemCount}_$index'.hashCode.toString();
    return ValueKey('card_$keyString');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
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
      _scrollToIndex(widget.indexToScroll!);
    }
  }

  void _scrollToIndex(int index) {
    if (!mounted) return;
    //↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓计算滚动条的目标位置↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
    // Get the list view's render box
    final RenderBox? listViewBox =
        _listViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (listViewBox == null) return;

    // Calculate total height of list view
    final listViewHeight = listViewBox.size.height;

    // Calculate card total height including margins
    final cardTotalHeight =
        (widget.cardHeight ?? 80.h) + (widget.cardMargin?.vertical ?? 3.h);

    // Calculate ideal position to center the card
    final targetCard = index * cardTotalHeight;
    final middleOffset = listViewHeight / 2;
    final cardOffset = cardTotalHeight / 2;

    // Calculate target scroll position
    double targetPosition = targetCard - (middleOffset - cardOffset);

    // Constrain target position to valid scroll bounds
    targetPosition =
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent);
    //↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑计算滚动条的目标位置↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑

    // 使用动画滚动到目标位置
    _scrollController.animateTo(
      targetPosition,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
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
          padding: widget.cardPadding,
          margin: widget.cardMargin,

          // 3. 样式和装饰
          backgroundColor: widget.cardColor,
          elevation: widget.cardElevation,
          shadowColor: widget.cardShadowColor,
          borderRadius: widget.cardBorderRadius,
          hoverColor: widget.cardHoverColor,
          splashColor: widget.cardSplashColor,

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
