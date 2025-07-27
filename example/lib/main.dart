import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';
import 'pages/page4.dart';
import 'pages/page5.dart';
import 'pages/page6.dart';
import 'pages/page7.dart';
import 'pages/page8.dart';
import 'services/example_service.dart';
import 'widgets/float_bar_navigation.dart';
import 'widgets/platform_info_widget.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await MyApp.initialize(
    appName: "示例App",
    setTitleBarHidden: false,
    designSize: const Size(900, 700),
    enableTray: true,
    trayTooltip: "XLY 示例应用",
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
      MyService<MyTray>(
        service: () => MyTray(
          iconPath: "assets/icons/tray.ico",
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
    navigatorKey: navigatorKey,
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
        ),
        body: Stack(
          children: [
            child!,
            getFloatBar(),
          ],
        ),
        drawer: [
          AdaptiveNavigationItem(
            icon: const Icon(Icons.home),
            selectedIcon: const Icon(Icons.home_filled),
            label: '第1页',
            onTap: () {
              Get.toNamed(MyRoutes.page1);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.widgets),
            selectedIcon: const Icon(Icons.widgets_outlined),
            label: '第2页',
            onTap: () {
              Get.toNamed(MyRoutes.page2);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.menu),
            selectedIcon: const Icon(Icons.menu_open),
            label: '第3页',
            onTap: () {
              Get.toNamed(MyRoutes.page3);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.view_list),
            selectedIcon: const Icon(Icons.list),
            label: '第4页',
            onTap: () {
              Get.toNamed(MyRoutes.page4);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.link),
            selectedIcon: const Icon(Icons.link_outlined),
            label: 'URL启动器',
            onTap: () {
              Get.toNamed(MyRoutes.page5);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.edit),
            selectedIcon: const Icon(Icons.edit_outlined),
            label: '文本编辑器',
            onTap: () {
              Get.toNamed(MyRoutes.page6);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.tune),
            selectedIcon: const Icon(Icons.tune_outlined),
            label: 'SpinBox',
            onTap: () {
              Get.toNamed(MyRoutes.page7);
            },
          ),
          AdaptiveNavigationItem(
            icon: const Icon(Icons.system_update_alt),
            selectedIcon: const Icon(Icons.system_update_alt_outlined),
            label: '托盘功能',
            onTap: () {
              Get.toNamed(MyRoutes.page8);
            },
          ),
        ],
        trailing: const Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: PlatformInfoWidget(),
          ),
        ),
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
}
