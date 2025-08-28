import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page10.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';
import 'pages/page4.dart';
import 'pages/page5.dart';
import 'pages/page6.dart';
import 'pages/page7.dart';
import 'pages/page8.dart';
import 'pages/page9.dart';
import 'services/example_service.dart';
import 'widgets/float_bar_navigation.dart';
import 'widgets/platform_info_widget.dart';

void main() async {
  await MyApp.initialize(
    appName: "示例App",
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
      MyService<ExampleService>(
        service: () => ExampleService(),
        permanent: true,
      ),
      MyService<FloatBarNavController>(
        service: () => FloatBarNavController(),
        permanent: true,
      ),
      MyService<MyNotify>(
        service: () => MyNotify(),
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
        ),
        body: Stack(
          children: [
            child!,
            getFloatBar(),
          ],
        ),
        drawer: const [
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '组件展示',
            route: MyRoutes.page1,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: '样式测试',
            route: MyRoutes.page2,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers),
            label: '弹窗对话',
            route: MyRoutes.page3,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.view_list_outlined),
            selectedIcon: Icon(Icons.view_list),
            label: '列表管理',
            route: MyRoutes.page4,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.link),
            selectedIcon: Icon(Icons.link_outlined),
            label: 'URL启动器',
            route: MyRoutes.page5,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.edit),
            selectedIcon: Icon(Icons.edit_outlined),
            label: '文本编辑器',
            route: MyRoutes.page6,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.tune),
            selectedIcon: Icon(Icons.tune_outlined),
            label: '自定义编辑框',
            route: MyRoutes.page7,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.notifications),
            selectedIcon: Icon(Icons.notifications_active),
            label: '通知功能测试',
            route: MyRoutes.page8,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.system_update_alt),
            selectedIcon: Icon(Icons.system_update_alt_outlined),
            label: '托盘功能测试',
            route: MyRoutes.page9,
          ),
          MyAdaptiveNavigationItem(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz_outlined),
            label: 'LoadingDot演示',
            route: MyRoutes.page10,
          ),
        ],
        trailing: const PlatformInfoWidget(),
      );
    },
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
}
