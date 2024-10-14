import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
    splash: const MySplash(
      nextRoute: Routes.page1,
      lottieAssetPath: 'assets/animation/splash_loading.json',
      appTitle: 'My Awesome App',
      backgroundColor: Colors.blueGrey,
      splashDuration: Duration(seconds: 3),
      textColor: Colors.white,
      fontSize: 60,
      fontWeight: FontWeight.bold,
      lottieWidth: 250,
      spaceBetween: 30,
      transition: Transition.circularReveal,
      transitionDuration: Duration(milliseconds: 1000),
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
    ],
  );
}

class Routes {
  static const page1 = '/page1';
  static const page2 = '/page2';
}
