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

class MyCardList<T> extends StatefulWidget {
  final List<T> items;
  final bool isCardDraggable;
  final Function(int, int)? onReorder;
  final Widget? footer;
  final Function(T, bool)? onCardPressed;
  final Future<void> Function()? onLoadMore;
  final Widget Function(T item)? itemBuilder;

  // Card style and behavior properties
  final double cardHeight;
  final double fontSize;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry cardMargin;
  final Color cardColor;
  final Color? cardTextColor;
  final double cardElevation;
  final double cardBorderRadius;
  final Function(int)? onSwipeDelete;
  final Widget? cardLeading;
  final Widget Function(int)? cardTrailing;
  final TextStyle? cardTextStyle;
  final BoxDecoration? cardDecoration;
  final Widget? cardDeleteBackground;
  final bool showScrollbar;

  const MyCardList({
    super.key,
    required this.items,
    this.isCardDraggable = false,
    this.onReorder,
    this.footer,
    this.onCardPressed,
    this.onLoadMore,
    this.itemBuilder,
    // Card customization properties with defaults
    this.cardHeight = 60,
    this.fontSize = 16,
    this.cardPadding = const EdgeInsets.all(16),
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.cardColor = Colors.white,
    this.cardTextColor,
    this.cardElevation = 2,
    this.cardBorderRadius = 8,
    this.onSwipeDelete,
    this.cardLeading,
    this.cardTrailing,
    this.cardTextStyle,
    this.cardDecoration,
    this.cardDeleteBackground,
    this.showScrollbar = true,
  });

  @override
  State<MyCardList<T>> createState() => _MyCardListState<T>();
}

class _MyCardListState<T> extends State<MyCardList<T>> {
  final ScrollController _scrollController = ScrollController();

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
    return MyList<T>(
      items: widget.items,
      isDraggable: widget.isCardDraggable,
      scrollController: _scrollController,
      onReorder: widget.onReorder,
      itemBuilder: (context, index) => MyCard(
        key: widget.isCardDraggable
            ? ValueKey('card_${widget.items[index].toString()}_$index')
            : null,
        text: widget.itemBuilder != null
            ? widget.itemBuilder!(widget.items[index]).toString()
            : widget.items[index].toString(),
        isDraggable: widget.isCardDraggable,
        index: widget.isCardDraggable ? index : null,
        onPressed: widget.onCardPressed != null
            ? () => widget.onCardPressed!(
                widget.items[index], widget.isCardDraggable)
            : null,
        enableSwipeToDelete: widget.onSwipeDelete != null,
        onSwipeDeleted: widget.onSwipeDelete != null
            ? () => widget.onSwipeDelete!(index)
            : null,
        height: widget.cardHeight,
        fontSize: widget.fontSize,
        padding: widget.cardPadding,
        margin: widget.cardMargin,
        backgroundColor: widget.cardColor,
        textColor: widget.cardTextColor,
        elevation: widget.cardElevation,
        borderRadius: widget.cardBorderRadius,
        leading: widget.cardLeading,
        trailing: widget.cardTrailing?.call(index),
        textStyle: widget.cardTextStyle,
        decoration: widget.cardDecoration,
        deleteBackground: widget.cardDeleteBackground,
      ),
      footer: widget.footer,
      showScrollbar: widget.showScrollbar,
    );
  }
}
