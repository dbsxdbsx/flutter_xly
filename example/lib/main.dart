import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';
import 'pages/page3.dart';
import 'pages/page4.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await MyApp.initialize(
    designSize: const Size(800, 600),
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
    ],
    keyToRollBack: LogicalKeyboardKey.backspace,
    exitInfoText: '自定义: 再按一次退出App',
    backInfoText: '自定义: 再按一次返回上一页',
    pageTransitionStyle: Transition.fade,
    globalFloatPanel: FloatPanel(
      panelWidth: 60,
      backgroundColor: const Color(0xFF222222),
      panelShape: PanelShape.rectangle,
      borderRadius: BorderRadius.circular(10),
      dockType: DockType.outside,
      panelButtonColor: Colors.blueGrey,
      customButtonColor: Colors.grey,
      dockActivate: true,
      buttons: const [
        CupertinoIcons.news,
        CupertinoIcons.person,
        CupertinoIcons.settings,
        CupertinoIcons.link,
        CupertinoIcons.minus,
        CupertinoIcons.xmark_circle
      ],
      onPressed: (index) {
        switch (index) {
          case 0:
            toast('新游戏按钮被点击');
            break;
          case 1:
            toast('新AI按钮被点击');
            break;
          case 2:
            toast('设置按钮被点击');
            break;
          case 3:
            toast('新链接按钮被点击');
            break;
          case 4:
            toast('最小化按钮被点击');
            break;
          case 5:
            MyDialog.showIos(
              content: '是否退出程序？',
              onLeftButtonPressed: () => MyApp.exit(),
              onRightButtonPressed: () {},
            );
            break;
          default:
            print("按下了默认按钮");
        }
      },
    ),
  );

}

class Routes {
  static const String page1 = '/page1';
  static const String page2 = '/page2';
  static const String page3 = '/page3';
  static const String page4 = '/page4';
}
