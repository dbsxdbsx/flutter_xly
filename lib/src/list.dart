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
  final int itemCount;
  final bool isCardDraggable;
  final Function(int)? onSwipeDelete;
  final Function(int, int)? onReorder;
  final Widget? footer;
  final Future<void> Function()? onLoadMore;
  final Color? cardColor;
  final Widget Function(int)? cardLeading;
  final Widget Function(int)? cardTrailing;
  final Widget Function(int) cardBody;
  final Function(int)? onCardPressed;
  final double? cardHeight;
  final double fontSize;
  final EdgeInsetsGeometry? cardPadding;
  final EdgeInsetsGeometry? cardMargin;
  final bool showScrollbar;

  const MyCardList({
    super.key,
    required this.itemCount,
    required this.cardBody,
    this.isCardDraggable = false,
    this.onSwipeDelete,
    this.onReorder,
    this.footer,
    this.onLoadMore,
    this.cardColor,
    this.cardLeading,
    this.cardTrailing,
    this.onCardPressed,
    this.cardHeight,
    this.fontSize = 14,
    this.cardPadding,
    this.cardMargin,
    this.showScrollbar = true,
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
