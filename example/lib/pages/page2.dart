import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page2View extends GetView<Page2Controller> {
  const Page2View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 2')),
      body: Center(
        child: MyButton(
          text: '返回页面1',
          onPressed: controller.goToPage1,
        ),
      ),
    );
  }
}

class Page2Controller extends GetxController {
  void goToPage1() {
    goToPage(Routes.page1);
  }
}
