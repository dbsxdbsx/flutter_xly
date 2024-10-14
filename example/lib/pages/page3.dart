import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page3View extends GetView<Page3Controller> {
  const Page3View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 3')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '欢迎来到页面3',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            MyButton(
              text: '返回页面2',
              onPressed: controller.goToPage2,
              icon: Icons.arrow_back,
            ).setFocus(focusKey: 'back_to_page2_button'),
            SizedBox(height: 20.h),
            MyButton(
              text: '返回页面1',
              onPressed: controller.goToPage1,
              icon: Icons.home,
            ).setFocus(focusKey: 'back_to_page1_button'),
          ],
        ),
      ),
    );
  }
}

class Page3Controller extends GetxController {
  void goToPage2() {
    Get.back();
  }

  void goToPage1() {
    goToPage(Routes.page1);
  }
}
