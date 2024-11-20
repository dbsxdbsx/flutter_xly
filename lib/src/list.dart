import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class MyList<T> extends StatelessWidget {
  final List<T> items;
  final bool isDraggable;
  final ScrollController scrollController;
  final Function(int, int)? onReorder;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget? footer;
  final bool showScrollbar;

  const MyList({
    super.key,
    required this.items,
    this.isDraggable = false,
    required this.scrollController,
    this.onReorder,
    required this.itemBuilder,
    this.footer,
    this.showScrollbar = true,
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
  // 1. 核心内容构建器（从左到右的视觉顺序）
  final Widget Function(int)? cardLeading;
  final Widget Function(int) cardBody;
  final Widget Function(int)? cardTrailing;

  // 2. 列表数据和状态
  final int itemCount;
  final bool isCardDraggable;
  final bool showScrollbar;

  // 3. 卡片样式和布局
  final Color? cardColor;
  final double? cardHeight;
  final double fontSize;
  final EdgeInsetsGeometry? cardPadding;
  final EdgeInsetsGeometry? cardMargin;

  // 4. 列表附加组件
  final Widget? footer;

  // 5. 回调函数
  final Function(int)? onSwipeDelete;
  final Function(int, int)? onReorder;
  final Function(int)? onCardPressed;
  final Future<void> Function()? onLoadMore;

  const MyCardList({
    super.key,
    // 1. 核心内容构建器
    this.cardLeading,
    required this.cardBody,
    this.cardTrailing,

    // 2. 列表数据和状态
    required this.itemCount,
    this.isCardDraggable = false,
    this.showScrollbar = true,

    // 3. 卡片样式和布局
    this.cardColor,
    this.cardHeight,
    this.fontSize = 14,
    this.cardPadding,
    this.cardMargin,

    // 4. 列表附加组件
    this.footer,

    // 5. 回调函数
    this.onSwipeDelete,
    this.onReorder,
    this.onCardPressed,
    this.onLoadMore,
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
          key: _generateStableKey(index), // 使用统一的 key 生成方法
          isDraggable: widget.isCardDraggable,
          index: index,
          backgroundColor: widget.cardColor,
          height: widget.cardHeight,
          padding: widget.cardPadding ?? EdgeInsets.all(16.w),
          margin: widget.cardMargin ?? EdgeInsets.symmetric(vertical: 4.h),
          onPressed: widget.onCardPressed != null
              ? () => widget.onCardPressed!(index)
              : null,
          enableSwipeToDelete: widget.onSwipeDelete != null,
          onSwipeDeleted: widget.onSwipeDelete != null
              ? () => widget.onSwipeDelete!(index)
              : null,
          leading: widget.cardLeading?.call(index),
          trailing: widget.cardTrailing?.call(index),
          child: widget.cardBody(index),
        );
      },
    );
  }
}
