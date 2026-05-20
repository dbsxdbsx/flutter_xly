part of '../../scaffold.dart';


/// 自适应导航项
class MyAdaptiveNavigationItem {
  /// 图标
  final Widget icon;

  /// 选中时的图标（可选）
  final Widget? selectedIcon;

  /// 标签文本
  final String label;

  /// 副标题（仅在 Large 1200dp+ 层级显示）
  final String? subtitle;

  /// 分组名称（仅在 Large 1200dp+ 层级显示分组标题）
  /// 相同 group 值的连续项归为一组，首项上方显示分组标题
  final String? group;

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
    this.subtitle,
    this.group,
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
