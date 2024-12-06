import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';
import 'pages/page4.dart';
import 'pages/page5.dart';
import 'pages/page6.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MyApp.initialize(
    appName: "测试dbsx应用",
    setTitleBarHidden: false,
    designSize: const Size(900, 700),
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

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
  static const String page4 = '/page4';
  static const String page5 = '/page5';
  static const String page6 = '/page6';
}
