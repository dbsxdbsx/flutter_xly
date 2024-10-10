import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import 'pages/page1.dart';
import 'pages/page2.dart';

void main() async {
  await MyApp.initialize(
    designSize: const Size(800, 600),
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
