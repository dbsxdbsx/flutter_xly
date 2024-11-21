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
  final Function(int, int)? onReorder;

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
    this.onReorder,

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
                onReorder: onReorder!,
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
  final bool isCardDraggable;
  final Function(int, int)? onReorder;
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

  const MyCardList({
    super.key,
    // 1. 核心内容
    required this.itemCount,
    this.cardLeading,
    required this.cardBody,
    this.cardTrailing,

    // 2. 交互行为
    this.isCardDraggable = false,
    this.onReorder,
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
  });

  @override
  State<MyCardList> createState() => _MyCardListState();
}

class _MyCardListState extends State<MyCardList> {
  final ScrollController _scrollController = ScrollController();

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
  Widget build(BuildContext context) {
    return MyList<int>(
      items: List.generate(widget.itemCount, (i) => i),
      isDraggable: widget.isCardDraggable,
      scrollController: _scrollController,
      onReorder: widget.onReorder,
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
          isDraggable: widget.isCardDraggable,
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
