import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'logger.dart';

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
///     MyAdaptiveNavigationItem(
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
  final List<MyAdaptiveNavigationItem>? drawer;

  /// 导航项列表（已废弃，请使用drawer参数）
  @Deprecated('使用drawer参数代替。此参数将在未来版本中移除。')
  final List<MyAdaptiveNavigationItem>? items;

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

  /// 小屏幕断点宽度（默认600.w）
  final double smallBreakpoint;

  /// 大屏幕断点宽度（默认840.w）
  final double largeBreakpoint;

  /// 初始选中的导航项索引
  final int initialSelectedIndex;

  /// 是否始终显示侧边栏滚动条
  /// 默认为false，只在需要时显示
  final bool alwaysShowScrollbar;

  /// 是否自动滚动到选中的导航项
  /// 默认为true，当路由变化时自动滚动让选中项可见
  final bool autoScrollToSelected;

  /// 获取实际使用的导航项列表
  List<MyAdaptiveNavigationItem>? get _effectiveDrawer => drawer;

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
    this.alwaysShowScrollbar = false,
    this.autoScrollToSelected = true,
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

  // 路由到索引的映射
  final Map<String, int> _routeToIndexMap = {};

  // 路由监听器
  Timer? _routeTimer;
  String? _lastRoute;

  // 侧边栏滚动控制器
  final ScrollController _drawerScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialSelectedIndex;
    _buildRouteMapping();

    // 延迟同步，确保路由系统已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncWithCurrentRoute();
      _setupRouteListener();
    });
  }

  @override
  void didUpdateWidget(MyScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 当drawer项目发生变化时，重新构建映射
    if (widget._effectiveDrawer != oldWidget._effectiveDrawer) {
      _buildRouteMapping();
      _syncWithCurrentRoute();
    }
  }

  @override
  void dispose() {
    _routeTimer?.cancel();
    _drawerScrollController.dispose();
    super.dispose();
  }

  /// 设置路由监听器
  void _setupRouteListener() {
    // 使用高频定时检查，确保即时响应
    _routeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final currentRoute = Get.currentRoute;
      if (currentRoute != _lastRoute) {
        _lastRoute = currentRoute;
        _syncWithCurrentRoute();
      }
    });
  }

  /// 构建路由到索引的映射
  void _buildRouteMapping() {
    _routeToIndexMap.clear();
    final effectiveDrawer = widget._effectiveDrawer;

    if (effectiveDrawer != null) {
      for (int i = 0; i < effectiveDrawer.length; i++) {
        final item = effectiveDrawer[i];
        if (item.route != null) {
          _routeToIndexMap[item.route!] = i;
        }
      }
    }
  }

  /// 根据当前路由同步选中状态
  void _syncWithCurrentRoute() {
    try {
      final currentRoute = Get.currentRoute;
      final index = _routeToIndexMap[currentRoute];

      if (index != null && index != _selectedIndex) {
        setState(() {
          _selectedIndex = index;
        });

        // 根据配置决定是否自动滚动到选中项
        if (widget.autoScrollToSelected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToSelectedItem();
          });
        }
      }
    } catch (e) {
      // 如果Get路由系统还未初始化，忽略错误
    }
  }

  /// 自动滚动到当前选中的导航项
  void _scrollToSelectedItem() {
    if (!mounted || _routeToIndexMap.isEmpty) return;

    final selectedIndex = _selectedIndex;
    final totalItems = widget._effectiveDrawer?.length ?? 0;

    if (selectedIndex < 0 || selectedIndex >= totalItems) return;

    // 检查ScrollController是否已附加且有有效的position
    if (!_drawerScrollController.hasClients) return;

    try {
      // 计算每个导航项的高度（包含margin）
      // Container margin: 4.h * 2 = 8.h
      // Padding: 16.h * 2 = 32.h
      // 图标和文字的高度大约: 24.h
      final itemHeight = (8.h + 32.h + 24.h); // 约64.h

      // 计算目标位置
      final targetPosition = selectedIndex * itemHeight;

      // 获取可视区域高度
      final viewportHeight = _drawerScrollController.position.viewportDimension;

      // 计算居中对齐的滚动位置
      final centeredPosition =
          targetPosition - (viewportHeight / 2) + (itemHeight / 2);

      // 限制在有效范围内
      final maxScrollExtent = _drawerScrollController.position.maxScrollExtent;
      final clampedPosition = centeredPosition.clamp(0.0, maxScrollExtent);

      // 平滑滚动到目标位置
      _drawerScrollController.animateTo(
        clampedPosition,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } catch (e) {
      // 如果滚动失败，忽略错误
    }
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
        final item = effectiveDrawer[index];

        // 优先使用自定义onTap，如果没有则使用route自动导航
        if (item.onTap != null) {
          () async {
            try {
              await item.onTap!();
            } catch (e, s) {
              XlyLogger.error('MyAdaptiveNavigationItem.onTap error', e, s);
            }
          }();
        } else if (item.route != null) {
          Get.toNamed(item.route!);
        }
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
              scrollController: _drawerScrollController,
              alwaysShowScrollbar: widget.alwaysShowScrollbar,
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
            builder: (_) {
              if (isSmallScreen) {
                return widget.body ?? const SizedBox.shrink();
              }
              // 中/大屏：将AppBar包在内容区域的内层Scaffold中，避免占据侧边栏顶部空间
              return Scaffold(
                appBar: widget.appBar,
                body: widget.body ?? const SizedBox.shrink(),
              );
            },
          ),
        },
      ),
    );

    // 检查是否需要显示抽屉
    final shouldShowDrawer =
        isSmallScreen && !widget.useBottomNavigationOnSmall;

    // 处理AppBar：
    // - 小屏幕：放在外层Scaffold（需要汉堡菜单/系统行为）
    // - 中/大屏：不在外层放置，由内容区域内部自己渲染，避免挤占侧边栏顶部空间
    PreferredSizeWidget? effectiveAppBar = isSmallScreen ? widget.appBar : null;
    if (isSmallScreen &&
        shouldShowDrawer &&
        widget.appBar != null &&
        widget.appBar is! AppBar) {
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
                width: 56.w, // 标准AppBar leading宽度
                alignment: Alignment.center,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    borderRadius: BorderRadius.circular(20.r),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.menu,
                        size: 24.w,
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
          ? CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.escape): () {
                  _scaffoldKey.currentState?.closeDrawer();
                },
              },
              child: Focus(
                autofocus: true,
                child: Drawer(
                  width: (screenWidth * widget.drawerWidthRatio)
                      .clamp(200.w, 304.w),
                  child: _CustomExtendedNavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) {
                      _scaffoldKey.currentState?.closeDrawer();
                      handleDestinationSelected(index);
                    },
                    destinations: destinations,
                    trailing: widget.trailing,
                    scrollController: _drawerScrollController,
                    alwaysShowScrollbar: widget.alwaysShowScrollbar,
                  ),
                ),
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
class MyAdaptiveNavigationItem {
  /// 图标
  final Widget icon;

  /// 选中时的图标（可选）
  final Widget? selectedIcon;

  /// 标签文本
  final String label;

  /// 点击回调
  final FutureOr<void> Function()? onTap;

  /// 通知徽章数量（可选）
  final int? badgeCount;

  /// 关联的路由路径（可选）
  /// 用于自动同步drawer选中状态与当前路由
  final String? route;

  const MyAdaptiveNavigationItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    this.onTap,
    this.badgeCount,
    this.route,
  });

  /// 转换为Flutter标准的NavigationDestination
  NavigationDestination toNavigationDestination() {
    Widget iconWidget = icon;

    // 如果有徽章数量，添加徽章
    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        isLabelVisible: true,
        label: Text(
          '$badgeCount',
          style: TextStyle(fontSize: 10.sp), // 响应式徽章字体大小
        ),
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
      width: 72.w, // 标准NavigationRail的紧凑宽度
      color: theme.navigationRailTheme.backgroundColor ?? colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 导航项列表 - 添加顶部padding以匹配标准NavigationRail的行为
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(
                  top: 8.h, bottom: 12.h), // 减少顶部padding，让菜单项更靠近顶部
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final destination = destinations[index];
                final isSelected = index == selectedIndex;

                return Container(
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
