import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';

/// 自适应根脚手架
///
/// 根据屏幕尺寸自动切换显示模式：
/// - 小屏幕：传统抽屉式导航或底部导航栏
/// - 中等屏幕：收缩的图标式侧边栏
/// - 大屏幕：完整的展开式侧边栏
///
/// 使用方式类似传统Flutter Scaffold，但增加了自适应导航功能：
/// ```dart
/// MyScaffold(
///   appBar: AppBar(title: Text('My App')),
///   drawer: [
///     AdaptiveNavigationItem(
///       icon: Icon(Icons.home),
///       label: '首页',
///       onTap: () => controller.switchToPage(0),
///     ),
///   ],
///   body: Obx(() => pages[controller.currentIndex]),
/// )
/// ```
class MyScaffold extends StatefulWidget {
  /// 导航项列表（可选）
  /// 当提供时，会根据屏幕尺寸显示为抽屉、侧边栏或底部导航栏
  final List<AdaptiveNavigationItem>? drawer;

  /// 导航项列表（已废弃，请使用drawer参数）
  @Deprecated('使用drawer参数代替。此参数将在未来版本中移除。')
  final List<AdaptiveNavigationItem>? items;

  /// 页面列表（已废弃）
  @Deprecated('不再需要pages参数。请在body中处理页面切换逻辑。此参数将在未来版本中移除。')
  final List<Widget>? pages;

  /// 主体内容
  /// 类似传统Scaffold的body参数
  final Widget? body;

  /// 侧边栏底部额外内容（可选）
  final Widget? trailing;

  /// 是否在小屏幕使用底部导航栏而不是抽屉
  final bool useBottomNavigationOnSmall;

  /// 应用栏（可选）
  final PreferredSizeWidget? appBar;

  /// 浮动操作按钮（可选）
  final Widget? floatingActionButton;

  /// 抽屉宽度比例（相对于屏幕宽度）
  final double drawerWidthRatio;

  /// 小屏幕断点宽度（默认600px）
  final double smallBreakpoint;

  /// 大屏幕断点宽度（默认840px）
  final double largeBreakpoint;

  /// 初始选中的导航项索引
  final int initialSelectedIndex;

  /// 获取实际使用的导航项列表
  List<AdaptiveNavigationItem>? get _effectiveDrawer => drawer;

  const MyScaffold({
    super.key,
    this.drawer,
    @Deprecated('使用drawer参数代替') this.items,
    @Deprecated('不再需要pages参数') this.pages,
    this.body,
    this.trailing,
    this.useBottomNavigationOnSmall = false,
    this.appBar,
    this.floatingActionButton,
    this.drawerWidthRatio = 0.88,
    this.smallBreakpoint = 600.0,
    this.largeBreakpoint = 840.0,
    this.initialSelectedIndex = 0,
  }) : assert(
          drawer == null || items == null,
          '不能同时提供drawer和items参数，请使用drawer参数。',
        );

  @override
  State<MyScaffold> createState() => _MyScaffoldState();
}

class _MyScaffoldState extends State<MyScaffold> {
  late int _selectedIndex;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final effectiveDrawer = widget._effectiveDrawer;

    // 如果没有导航项，直接返回简单的Scaffold
    if (effectiveDrawer == null || effectiveDrawer.isEmpty) {
      return Scaffold(
        key: _scaffoldKey,
        appBar: widget.appBar,
        floatingActionButton: widget.floatingActionButton,
        body: widget.body,
      );
    }

    // 转换为NavigationDestination
    final destinations =
        effectiveDrawer.map((item) => item.toNavigationDestination()).toList();

    // 判断当前屏幕尺寸
    final isSmallScreen = screenWidth < widget.smallBreakpoint;

    // 统一的onDestinationSelected处理逻辑
    void handleDestinationSelected(int index) {
      setState(() {
        _selectedIndex = index;
      });
      if (index < effectiveDrawer.length) {
        effectiveDrawer[index].onTap?.call();
      }
    }

    // 自适应布局，支持所有屏幕尺寸
    final adaptiveLayout = AdaptiveLayout(
      primaryNavigation: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          // 中等屏幕：收缩的侧边栏（仅图标）
          Breakpoints.medium: SlotLayout.from(
            key: const Key('primaryNavigation'),
            builder: (_) => _CustomCompactNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: handleDestinationSelected,
              destinations: destinations,
            ),
          ),
          // 大屏幕：展开的侧边栏（图标+文字+额外内容）
          Breakpoints.large: SlotLayout.from(
            key: const Key('primaryNavigationLarge'),
            builder: (context) => _CustomExtendedNavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: handleDestinationSelected,
              destinations: destinations,
              trailing: widget.trailing,
            ),
          ),
        },
      ),
      body: SlotLayout(
        config: <Breakpoint, SlotLayoutConfig>{
          Breakpoints.standard: SlotLayout.from(
            key: const Key('body'),
            inAnimation: AdaptiveScaffold.fadeIn,
            outAnimation: AdaptiveScaffold.fadeOut,
            builder: (_) => widget.body ?? const SizedBox.shrink(),
          ),
        },
      ),
    );

    // 检查是否需要显示抽屉
    final shouldShowDrawer =
        isSmallScreen && !widget.useBottomNavigationOnSmall;

    // 处理AppBar - 为非标准AppBar添加自定义汉堡包图标
    PreferredSizeWidget? effectiveAppBar = widget.appBar;
    if (shouldShowDrawer && widget.appBar != null && widget.appBar is! AppBar) {
      // 对于非标准AppBar（如_DynamicAppBar），包装一个带汉堡包图标的容器
      effectiveAppBar = PreferredSize(
        preferredSize: widget.appBar!.preferredSize,
        child: Stack(
          children: [
            widget.appBar!,
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 56, // 标准AppBar leading宽度
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.menu,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final scaffold = Scaffold(
      key: _scaffoldKey,
      appBar: effectiveAppBar,
      floatingActionButton: widget.floatingActionButton,

      // 小屏幕时显示抽屉（如果不使用底部导航栏）
      drawer: shouldShowDrawer
          ? Drawer(
              width:
                  (screenWidth * widget.drawerWidthRatio).clamp(200.0, 304.0),
              child: _CustomExtendedNavigationRail(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  _scaffoldKey.currentState?.closeDrawer();
                  handleDestinationSelected(index);
                },
                destinations: destinations,
                trailing: widget.trailing,
              ),
            )
          : null,

      // 始终使用AdaptiveLayout以确保Overlay可用
      body: adaptiveLayout,

      // 小屏幕底部导航栏（可选）
      bottomNavigationBar: isSmallScreen && widget.useBottomNavigationOnSmall
          ? NavigationBar(
              selectedIndex: _selectedIndex,
              destinations: destinations,
              onDestinationSelected: handleDestinationSelected,
            )
          : null,
    );

    // 如果需要显示抽屉且有AppBar，包装一个Overlay以支持Tooltip
    if (shouldShowDrawer && widget.appBar != null) {
      return Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => scaffold,
          ),
        ],
      );
    }

    return scaffold;
  }
}

/// 自适应导航项
class AdaptiveNavigationItem {
  /// 图标
  final Widget icon;

  /// 选中时的图标（可选）
  final Widget? selectedIcon;

  /// 标签文本
  final String label;

  /// 点击回调
  final VoidCallback? onTap;

  /// 通知徽章数量（可选）
  final int? badgeCount;

  const AdaptiveNavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.onTap,
    this.badgeCount,
  });

  /// 转换为Flutter标准的NavigationDestination
  NavigationDestination toNavigationDestination() {
    Widget iconWidget = icon;

    // 如果有徽章数量，添加徽章
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        isLabelVisible: true,
        label: Text('$badgeCount'),
        child: icon,
      );
    }

    return NavigationDestination(
      icon: iconWidget,
      selectedIcon: selectedIcon,
      label: label,
    );
  }
}

/// 自定义的扩展NavigationRail，支持整行高亮
class _CustomExtendedNavigationRail extends StatelessWidget {
  const _CustomExtendedNavigationRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.trailing,
  });

  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 256, // 固定宽度，类似extended NavigationRail
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 导航项列表 - 使用更大的垂直间距
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4), // 增加垂直间距
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onDestinationSelected(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16, // 增加垂直内边距
                        ),
                        child: Row(
                          children: [
                            // 图标
                            IconTheme(
                              data: IconThemeData(
                                color: isSelected
                                    ? colorScheme.onSecondaryContainer
                                    : colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                              child:
                                  isSelected && destination.selectedIcon != null
                                      ? destination.selectedIcon!
                                      : destination.icon,
                            ),
                            const SizedBox(width: 12),
                            // 文字标签
                            Expanded(
                              child: Text(
                                destination.label,
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: isSelected
                                      ? colorScheme.onSecondaryContainer
                                      : colorScheme.onSurfaceVariant,
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
          // 底部额外内容 - 添加适当的内边距
          if (trailing != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: trailing!,
            ),
        ],
      ),
    );
  }
}

/// 自定义的紧凑NavigationRail，用于中等屏幕（min模式）
/// 只显示图标，菜单项从顶部开始排列，不预留汉堡菜单按钮空间
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
      width: 72, // 标准NavigationRail的紧凑宽度
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 导航项列表 - 添加顶部padding以匹配标准NavigationRail的行为
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(
                  top: 8, bottom: 12), // 减少顶部padding，让菜单项更靠近顶部
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onDestinationSelected(index),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.secondaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: IconTheme(
                            data: IconThemeData(
                              color: isSelected
                                  ? colorScheme.onSecondaryContainer
                                  : colorScheme.onSurfaceVariant,
                              size: 24,
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
