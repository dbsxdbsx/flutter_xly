import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page1View extends GetView<Page1Controller> {
  const Page1View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page 1')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            MyButton(
              text: '前往页面2',
              onPressed: controller.goToPage2,
            ),
            SizedBox(height: 20.h),
            MyButton(
              text: '连续显示多条Toast',
              onPressed: controller.showToast,
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    ).showRightMenu(
      context: context,
      menuItems: [
        MyMenuItem(
          text: '选项1',
          icon: Icons.looks_one,
          onTap: () => toast('选择了选项1!!!!!!!!!!!!!!!!!!!!'),
        ),
        MyMenuItem(
          text: '选项2',
          icon: Icons.looks_two,
          onTap: () => toast('选择了选项2'),
        ),
      ],
    );
  }
}

class Page1Controller extends GetxController {
  void goToPage2() {
    goToPage(Routes.page2);
  }

  void showToast() async {
    toast('这是一条测试Toast消息1');
    await Future.delayed(const Duration(seconds: 1));
    toast('这是一条测试Toast消息2');
    await Future.delayed(const Duration(seconds: 1));
    toast('这是一条测试Toast消息3', stackToasts: true);
  }
}
