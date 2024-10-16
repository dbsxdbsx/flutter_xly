import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class MyList extends StatelessWidget {
  final List<String> items;
  final bool isDraggable;
  final ScrollController scrollController;
  final Function(int, int)? onReorder;
  final Widget Function(BuildContext, int) itemBuilder;
  final Widget? footer;

  const MyList({
    super.key,
    required this.items,
    this.isDraggable = false,
    required this.scrollController,
    this.onReorder,
    required this.itemBuilder,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: scrollController,
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
  final List<String> items;
  final bool isDraggable;
  final Function(int, int)? onReorder;
  final Widget? footer;
  final Function(String, bool) onCardPressed;
  final Future<void> Function()? onLoadMore;
  final bool enableSwipeToDelete;
  final bool enableBtnToDelete;
  final Function(int)? onDelete;
  final double cardHeight;
  final double fontSize;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry cardMargin;
  final Color cardColor;

  const MyCardList({
    super.key,
    required this.items,
    this.isDraggable = false,
    this.onReorder,
    this.footer,
    required this.onCardPressed,
    this.onLoadMore,
    this.enableSwipeToDelete = false,
    this.enableBtnToDelete = false,
    this.onDelete,
    this.cardHeight = 60,
    this.fontSize = 16,
    this.cardPadding = const EdgeInsets.all(16),
    this.cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    this.cardColor = Colors.white,
  });

  @override
  _MyCardListState createState() => _MyCardListState();
}

class _MyCardListState extends State<MyCardList> {
  late ScrollController _scrollController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (!_isLoading && widget.onLoadMore != null) {
      setState(() {
        _isLoading = true;
      });
      await widget.onLoadMore!();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MyList(
      items: widget.items,
      isDraggable: widget.isDraggable,
      scrollController: _scrollController,
      onReorder: widget.onReorder,
      itemBuilder: (context, index) => MyCard(
        key: widget.isDraggable ? ValueKey(widget.items[index]) : null,
        text: widget.items[index],
        isDraggable: widget.isDraggable,
        index: widget.isDraggable ? index : null,
        onPressed: () =>
            widget.onCardPressed(widget.items[index], widget.isDraggable),
        enableSwipeToDelete: widget.enableSwipeToDelete,
        enableBtnToDelete: widget.enableBtnToDelete,
        onDelete:
            widget.onDelete != null ? () => widget.onDelete!(index) : null,
        height: widget.cardHeight,
        fontSize: widget.fontSize,
        padding: widget.cardPadding,
        margin: widget.cardMargin,
        backgroundColor: widget.cardColor,
      ),
      footer: widget.footer,
    );
  }
}
