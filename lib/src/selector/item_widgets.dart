part of '../../selector.dart';

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
