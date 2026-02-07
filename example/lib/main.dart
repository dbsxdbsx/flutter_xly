import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page10.dart';
import 'pages/page11.dart';
import 'pages/page12.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';
import 'pages/page4.dart';
import 'pages/page5.dart';
import 'pages/page6.dart';
import 'pages/page7.dart';
import 'pages/page8.dart';
import 'pages/page9.dart';
import 'services/example_service.dart';
import 'widgets/platform_info_widget.dart';

void main() async {
  await MyApp.initialize(
    appName: "测试用例 test",

    enableDebugLogging: true, // 开发时启用调试日志
    showWindowOnInit: false,
    focusWindowOnInit: false,

    setTitleBarHidden: false,
    designSize: const Size(900, 700),
    // 使用新的简化托盘配置方式
    tray: MyTray(
      // iconPath: "assets/tray_icons_for_test/tray.ico", // 明确指定图标路径，兼容Debug/Release
      tooltip: "XLY示例应用的托盘tooltip",
      menuItems: [
        MyTrayMenuItem(
          label: '恢复显示',
          onTap: () => MyTray.to.pop(),
        ),
        const MyTrayMenuItem.separator(),
        MyTrayMenuItem(
          label: '退出应用',
          onTap: () => exit(0),
        ),
      ],
    ),

    services: [
      // 同步服务示例 - 使用 service 参数（传统方式）
      MyService<ExampleService>(
        service: () => ExampleService(),
        permanent: true,
      ),

      // 异步服务示例 - 使用 asyncService 参数（新方式）
      // 虽然 MyNotify 本身不需要异步初始化，但这里展示了
      // 即使是同步服务也可以用 asyncService 方式注册
      // 这对于测试和未来可能的异步需求很有用
      MyService<MyNotify>(
        asyncService: () async => MyNotify(),
        permanent: true,
      ),
    ],
    routes: [
      MyRoute<Page1Controller>(
        path: MyRoutes.page1,
        page: const Page1View(),
        controller: () => Page1Controller(),
      ),
      MyRoute<Page2Controller>(
        path: MyRoutes.page2,
        page: const Page2View(),
        controller: () => Page2Controller(),
      ),
      MyRoute<Page3Controller>(
        path: MyRoutes.page3,
        page: const Page3View(),
        controller: () => Page3Controller(),
      ),
      MyRoute<Page4Controller>(
        path: MyRoutes.page4,
        page: const Page4View(),
        controller: () => Page4Controller(),
      ),
      MyRoute<Page5Controller>(
        path: MyRoutes.page5,
        page: const Page5View(),
        controller: () => Page5Controller(),
      ),
      MyRoute<Page6Controller>(
        path: MyRoutes.page6,
        page: const Page6View(),
        controller: () => Page6Controller(),
      ),
      MyRoute<Page7Controller>(
        path: MyRoutes.page7,
        page: const Page7(),
        controller: () => Page7Controller(),
      ),
      MyRoute<Page8Controller>(
        path: MyRoutes.page8,
        page: const Page8View(),
        controller: () => Page8Controller(),
      ),
      MyRoute<Page9Controller>(
        path: MyRoutes.page9,
        page: const Page9View(),
        controller: () => Page9Controller(),
      ),
      MyRoute<Page10Controller>(
        path: MyRoutes.page10,
        page: const Page10View(),
        controller: () => Page10Controller(),
      ),
      MyRoute<Page11Controller>(
        path: MyRoutes.page11,
        page: const Page11View(),
        controller: () => Page11Controller(),
      ),
      MyRoute<Page12Controller>(
        path: MyRoutes.page12,
        page: const Page12View(),
        controller: () => Page12Controller(),
      ),
    ],
    splash: const MySplash(
      nextRoute: MyRoutes.page1,
      lottieAssetPath: 'assets/animation/splash_loading.json',
      appTitle: '😜My Awesome App😜',
      backgroundColor: Colors.blueGrey,
      splashDuration: Duration(seconds: 3),
      textColor: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
      lottieWidth: 250,
      spaceBetween: 30,
    ),
    pageTransitionStyle: Transition.fade,
    draggable: false,
    resizable: true,
    doubleClickToFullScreen: true,
    keyToRollBack: LogicalKeyboardKey.escape,
    exitInfoText: '自定义: 再按一次退出App',
    backInfoText: '自定义: 再按一次返回上一页',
    appBuilder: (context, child) {
      return MyScaffold(
        appBar: AppBar(
          title: const Text('测试应用'),
          centerTitle: true,
          backgroundColor: Colors.grey.withValues(alpha: 0.3),
          elevation: 0,
          // 断点指示器：实时显示当前层级和窗口宽度
          actions: const [_BreakpointIndicator()],
        ),
        body: child!,
        // ── 导航项（含 group 分组 + subtitle 副标题，Large+ 层级自动显示） ──
        drawer: const [
          // ─ 展示测试 ─
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '组件展示',
            subtitle: '各类基础 Widget 测试',
            group: '展示测试',
            route: MyRoutes.page1,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: '样式测试',
            subtitle: '主题与样式调试',
            group: '展示测试',
            route: MyRoutes.page2,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: '弹窗对话',
            subtitle: 'Dialog 与 BottomSheet',
            group: '展示测试',
            route: MyRoutes.page3,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: '列表管理',
            subtitle: '列表与数据展示',
            group: '展示测试',
            route: MyRoutes.page4,
          ),
          // ─ 功能测试 ─
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.link),
            selectedIcon: Icon(Icons.link_outlined),
            label: 'URL启动器',
            subtitle: '外部链接跳转',
            group: '功能测试',
            route: MyRoutes.page5,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.edit),
            selectedIcon: Icon(Icons.edit_outlined),
            label: '文本编辑器',
            subtitle: '富文本编辑组件',
            group: '功能测试',
            route: MyRoutes.page6,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune_outlined),
            label: '自定义编辑框',
            subtitle: '输入框定制化',
            group: '功能测试',
            route: MyRoutes.page7,
          ),
          // ─ 系统功能 ─
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.notifications),
            selectedIcon: Icon(Icons.notifications_active),
            label: '通知功能测试',
            subtitle: '本地通知推送',
            group: '系统功能',
            route: MyRoutes.page8,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.system_update_alt),
            selectedIcon: Icon(Icons.system_update_alt_outlined),
            label: '托盘功能测试',
            subtitle: '系统托盘交互',
            group: '系统功能',
            route: MyRoutes.page9,
          ),
          // ─ 动画样式 ─
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz_outlined),
            label: 'LoadingDot演示',
            subtitle: '加载动画效果',
            group: '动画样式',
            route: MyRoutes.page10,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.palette),
            selectedIcon: Icon(Icons.palette_outlined),
            label: 'FloatPanel样式',
            subtitle: '浮动面板定制',
            group: '动画样式',
            route: MyRoutes.page11,
          ),
          // ─ 面板组件 ─
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.tab_outlined),
            selectedIcon: Icon(Icons.tab),
            label: 'TabView 面板',
            subtitle: '分段选项卡组件',
            group: '面板组件',
            route: MyRoutes.page12,
          ),
        ],
        // 导航顶部 Header（Large+ 层级及 Compact 抽屉中显示）
        navigationHeader: const _NavigationHeader(),
        trailing: const PlatformInfoWidget(),
      );
    },
    // 全局浮动面板通过 floatPanel 参数自动挂载（新：items 方式）
    floatPanel: FloatPanel()
      ..configure(
        items: [
          FloatPanelIconBtn(
            icon: Icons.filter_1,
            id: 'page1',
            onTap: () {
              Get.toNamed(MyRoutes.page1);
            },
          ),
          FloatPanelIconBtn(
            icon: Icons.filter_2,
            id: 'page2',
            onTap: () {
              Get.toNamed(MyRoutes.page2);
            },
          ),
          FloatPanelIconBtn(
            icon: Icons.filter_3,
            id: 'page3',
            onTap: () {
              Get.toNamed(MyRoutes.page3);
            },
          ),
        ],
        // NOTE:示例：自定义样式和动画（可选，全部有默认值）
        // borderColor: Colors.blueGrey.withValues(alpha: 0.3),
        // initialPanelIcon: Icons.apps,
        // panelAnimDuration: 700,
        // panelAnimCurve: Curves.easeInOutCubic,
        // dockAnimDuration: 250,
        // dockAnimCurve: Curves.fastOutSlowIn,
      ),
  );
}

/// 应用路由定义
class MyRoutes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
  static const String page4 = '/page4';
  static const String page5 = '/page5';
  static const String page6 = '/page6';
  static const String page7 = '/page7';
  static const String page8 = '/page8';
  static const String page9 = '/page9';
  static const String page10 = '/page10';
  static const String page11 = '/page11';
  static const String page12 = '/page12';
}

// ─────────────────────────────────────────────────────────
// 示例辅助组件
// ─────────────────────────────────────────────────────────

/// 导航侧边栏顶部 Header（Large+ 层级及 Compact 抽屉中显示）
class _NavigationHeader extends StatelessWidget {
  const _NavigationHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.w,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.science_outlined,
              size: 22.w,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'XLY 示例',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Flutter Package Demo',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 实时断点层级指示器（放在 AppBar actions 中）
///
/// 拖动窗口时可直观看到层级切换，方便理解 5 层级自适应行为
class _BreakpointIndicator extends StatelessWidget {
  const _BreakpointIndicator();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final (tierName, tierColor) = _getTierInfo(width);

    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: tierColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: tierColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Text(
            '$tierName  ${width.toInt()}dp',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: tierColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 根据宽度返回层级名称和对应颜色
  (String, Color) _getTierInfo(double width) {
    // 使用 MyScaffold 默认断点值：600 / 840 / 1200 / 1600
    if (width < 600) return ('Compact', Colors.deepOrange);
    if (width < 840) return ('Medium', Colors.amber.shade800);
    if (width < 1200) return ('Expanded', Colors.teal);
    if (width < 1600) return ('Large', Colors.blue);
    return ('XLarge', Colors.deepPurple);
  }
}
