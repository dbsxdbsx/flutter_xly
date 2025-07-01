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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await MyApp.initialize(
    appName: "myPackageApp",
    setTitleBarHidden: false,
    designSize: const Size(900, 700),
    // 添加服务配置，确保在ScreenUtil初始化后注册
    services: [
      MyService<ExampleService>(
        service: () => ExampleService(),
        permanent: true,
      ),
    ],
    routes: [
      MyRoute<Page1Controller>(
        path: Routes.page1,
        page: const Page1View(),
        controller: () => Page1Controller(),
      ),
      MyRoute<Page2Controller>(
        path: Routes.page2,
        page: const Page2View(),
        controller: () => Page2Controller(),
      ),
      MyRoute<Page3Controller>(
        path: Routes.page3,
        page: const Page3View(),
        controller: () => Page3Controller(),
      ),
      MyRoute<Page4Controller>(
        path: Routes.page4,
        page: const Page4View(),
        controller: () => Page4Controller(),
      ),
      MyRoute<Page5Controller>(
        path: Routes.page5,
        page: const Page5View(),
        controller: () => Page5Controller(),
      ),
      MyRoute<Page6Controller>(
        path: Routes.page6,
        page: const Page6View(),
        controller: () => Page6Controller(),
      ),
      MyRoute<Page7Controller>(
        path: Routes.page7,
        page: const Page7(),
        controller: () => Page7Controller(),
      ),
    ],
    splash: const MySplash(
      nextRoute: Routes.page1,
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
  );
}

/// 示例服务 - 演示如何在ScreenUtil初始化后安全使用.sp等扩展方法
class ExampleService extends GetxService {
  static ExampleService get to => Get.find();

  final windowDraggable = true.obs;
  final windowResizable = false.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    // 初始化SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 恢复窗口可拖动状态
    final savedDraggable = prefs.getBool('window_draggable') ?? true;
    windowDraggable.value = savedDraggable;
    await MyApp.setDraggableEnabled(savedDraggable);

    // 恢复窗口可调整大小状态
    final savedResizable = prefs.getBool('window_resizable') ?? true;
    windowResizable.value = savedResizable;
    await MyApp.setResizableEnabled(savedResizable);
  }

  Future<void> setWindowDraggable(bool enabled) async {
    windowDraggable.value = enabled;
    await MyApp.setDraggableEnabled(enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('window_draggable', enabled);
  }

  Future<void> setWindowResizable(bool enabled) async {
    windowResizable.value = enabled;
    await MyApp.setResizableEnabled(enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('window_resizable', enabled);
  }
}

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
  static const String page4 = '/page4';
  static const String page5 = '/page5';
  static const String page6 = '/page6';
  static const String page7 = '/page7';
}
