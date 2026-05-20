part of '../../scaffold.dart';


/// Expanded 层级侧边栏（256dp，图标+文字）
class _CustomExpandedNavigationRail extends StatelessWidget {
  const _CustomExpandedNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.trailing,
    this.scrollController,
    this.alwaysShowScrollbar = false,
  });

  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget? trailing;
  final ScrollController? scrollController;
  final bool alwaysShowScrollbar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 256.w, // 固定宽度，类似extended NavigationRail
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 导航项列表 - 使用更大的垂直间距
          Expanded(
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: alwaysShowScrollbar,
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                itemCount: destinations.length,
                itemBuilder: (context, index) {
                  final destination = destinations[index];
                  final isSelected = index == selectedIndex;

                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 4.h), // 增加垂直间距
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.secondaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => onDestinationSelected(index),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h, // 增加垂直内边距
                          ),
                          child: Row(
                            children: [
                              // 图标
                              IconTheme(
                                data: IconThemeData(
                                  color: isSelected
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
                                  size: 24.w,
                                ),
                                child: isSelected &&
                                        destination.selectedIcon != null
                                    ? destination.selectedIcon!
                                    : destination.icon,
                              ),
                              SizedBox(width: 12.w),
                              // 文字标签
                              Expanded(
                                child: Text(
                                  destination.label,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: isSelected
                                        ? colorScheme.onSecondaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 14.sp, // 显式设置响应式字体大小
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // 底部额外内容 - 添加适当的内边距
          if (trailing != null)
            Padding(
              padding: EdgeInsets.all(12.w),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// Medium 层级侧边栏（72dp，仅图标 + hover Tooltip）
class _CustomCompactNavigationRail extends StatelessWidget {
  const _CustomCompactNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 72.w,
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(top: 8.h, bottom: 12.h),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Tooltip(
                  message: destination.label,
                  preferBelow: false,
                  waitDuration: const Duration(milliseconds: 400),
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4.h),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () => onDestinationSelected(index),
                        child: Container(
                          width: 56.w,
                          height: 56.h,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.secondaryContainer
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Center(
                            child: IconTheme(
                              data: IconThemeData(
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurfaceVariant,
                                size: 24.w,
                              ),
                              child:
                                  isSelected && destination.selectedIcon != null
                                      ? destination.selectedIcon!
                                      : destination.icon,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Large / XLarge 层级导航抽屉（支持分组标题、副标题、Header）
///
/// 通过参数控制 Large 与 XLarge 的视觉差异：
/// - [width]: Large=304dp, XLarge=360dp
/// - [inlineTrailing]: XLarge 时 trailing 内嵌到列表末尾
/// - [extraSpacing]: XLarge 时使用更宽松的间距
class _CustomNavigationDrawer extends StatelessWidget {
  const _CustomNavigationDrawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.items,
    this.navigationHeader,
    this.trailing,
    this.scrollController,
    this.alwaysShowScrollbar = false,
    this.width,
    this.inlineTrailing = false,
    this.extraSpacing = false,
  });

  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<MyAdaptiveNavigationItem> items;
  final Widget? navigationHeader;
  final Widget? trailing;
  final ScrollController? scrollController;
  final bool alwaysShowScrollbar;

  /// 导航抽屉宽度，为 null 时自动填满父容器（用于 Compact 抽屉）
  final double? width;

  /// 为 true 时 trailing 内嵌在导航列表末尾（XLarge 模式）
  final bool inlineTrailing;

  /// 为 true 时使用更宽松的间距（XLarge 模式）
  final bool extraSpacing;

  /// 构建带角标的图标
  Widget _buildIconWithBadge(MyAdaptiveNavigationItem item, bool isSelected) {
    Widget iconWidget = isSelected && item.selectedIcon != null
        ? item.selectedIcon!
        : item.icon;
    if (item.badgeCount != null && item.badgeCount! > 0) {
      iconWidget = Badge(
        isLabelVisible: true,
        label: Text('${item.badgeCount}', style: TextStyle(fontSize: 10.sp)),
        child: iconWidget,
      );
    }
    return iconWidget;
  }

  /// 构建导航项列表（含分组标题）
  List<Widget> _buildNavigationItems(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Widget> widgets = [];
    String? lastGroup;

    // 判断是否有任何 group 数据（有才显示分组标题）
    final hasGroups = items.any((item) => item.group != null);
    // 判断是否有任何 subtitle 数据
    final hasSubtitles = items.any((item) => item.subtitle != null);

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isSelected = i == selectedIndex;

      // 分组标题：当 group 值变化时插入
      if (hasGroups && item.group != null && item.group != lastGroup) {
        if (widgets.isNotEmpty) {
          widgets.add(SizedBox(height: 8.h));
          widgets.add(Divider(
            height: 1,
            indent: extraSpacing ? 20.w : 16.w,
            endIndent: extraSpacing ? 20.w : 16.w,
          ));
          widgets.add(SizedBox(height: 8.h));
        }
        widgets.add(
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: extraSpacing ? 20.w : 16.w,
              vertical: 8.h,
            ),
            child: Text(
              item.group!,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
        lastGroup = item.group;
      }

      // 导航项
      widgets.add(
        Container(
          margin: EdgeInsets.symmetric(
            vertical: extraSpacing ? 6.h : 4.h,
            horizontal: extraSpacing ? 16.w : 12.w,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.secondaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12.r),
              onTap: () => onDestinationSelected(i),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: extraSpacing ? 18.h : 16.h,
                ),
                child: Row(
                  children: [
                    // 图标
                    IconTheme(
                      data: IconThemeData(
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurfaceVariant,
                        size: 24.w,
                      ),
                      child: _buildIconWithBadge(item, isSelected),
                    ),
                    SizedBox(width: 12.w),
                    // 标签 + 副标题
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            item.label,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurfaceVariant,
                              fontSize: 14.sp,
                            ),
                          ),
                          if (hasSubtitles && item.subtitle != null) ...[
                            SizedBox(height: 2.h),
                            Text(
                              item.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                        .withValues(alpha: 0.7)
                                    : colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.6),
                                fontSize: 11.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // XLarge 模式：trailing 内嵌到列表末尾
    if (inlineTrailing && trailing != null) {
      widgets.add(SizedBox(height: 16.h));
      widgets.add(Divider(
        height: 1,
        indent: extraSpacing ? 20.w : 16.w,
        endIndent: extraSpacing ? 20.w : 16.w,
      ));
      widgets.add(Padding(
        padding: EdgeInsets.all(16.w),
        child: trailing!,
      ));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 顶部 Header
        if (navigationHeader != null) ...[
          navigationHeader!,
          Divider(
            height: 1,
            indent: extraSpacing ? 20.w : 16.w,
            endIndent: extraSpacing ? 20.w : 16.w,
          ),
        ],
        // 导航项列表
        Expanded(
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: alwaysShowScrollbar,
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              children: _buildNavigationItems(context),
            ),
          ),
        ),
        // 底部固定 trailing（非内嵌模式）
        if (!inlineTrailing && trailing != null)
          Padding(
            padding: EdgeInsets.all(12.w),
            child: trailing!,
          ),
      ],
    );

    if (width != null) {
      return Container(
        width: width,
        color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
        child: content,
      );
    }

    // width 为 null 时填满父容器（用于 Compact 抽屉内部）
    return ColoredBox(
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: content,
    );
  }
}
