part of '../../selector.dart';

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
