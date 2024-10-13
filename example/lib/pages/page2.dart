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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyButton(
              text: '返回页面1',
              onPressed: controller.goToPage1,
            ).setFocus(
                // opacity: true,
                // focusedBorderColor: Colors.blue,
                ),
            SizedBox(height: 20),
            Text(
              '这是一个可聚焦的文本',
              style: TextStyle(fontSize: 18),
            ).setFocus(
              focusKey: 'focusable_text',
              onPressed: () => toast('Text focused and pressed'),
              opacity: true,
              focusedBorderColor: Colors.green,
              borderWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

class Page2Controller extends GetxController {
  final focusController = Get.put(XlyFocusController());

  void goToPage1() {
    goToPage(Routes.page1);
  }

  @override
  void onInit() {
    super.onInit();
    // 可以在这里设置初始焦点
    // focusController.setFocus('button_back');
  }
}
