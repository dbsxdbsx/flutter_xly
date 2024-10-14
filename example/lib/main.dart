import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    // splash: const MySplash(
    //   nextRoute: Routes.page1,
    //   lottieAssetPath: 'assets/animation/splash_loading.json',
    //   appTitle: 'My Awesome App',
    //   backgroundColor: Colors.blueGrey,
    //   splashDuration: Duration(seconds: 3),
    //   textColor: Colors.white,
    //   fontSize: 60,
    //   fontWeight: FontWeight.bold,
    //   lottieWidth: 250,
    //   spaceBetween: 30,
    //   transition: Transition.circularReveal,
    //   transitionDuration: Duration(milliseconds: 1000),
    // ),
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
    ],
    keyToRollBack: LogicalKeyboardKey.backspace,
    exitInfoText: '自定义: 再按一次退出App',
    backInfoText: '自定义: 再按一次返回上一页',
    pageTransitionStyle: Transition.fade,
  );
}

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
}
