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
            SizedBox(height: 20.h),
            MyButton(
              text: '显示底部菜单',
              onPressed: controller.showBottomMenu,
              icon: Icons.menu,
            ).setFocus(focusKey: 'show_bottom_menu_button'),
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

  void showBottomMenu() {
    MyBottomMenu.show(
      height: 300.h,
      child: MyBottomMenuContent(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '从剪贴板添加',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 24.sp),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMenuItem(
                  Icons.content_paste, '从剪贴板添加', () => toast('从剪贴板添加')),
              _buildMenuItem(Icons.edit, '手动输入', () => toast('手动输入')),
            ],
          ),
          SizedBox(height: 30.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '添加 WARP',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 10.h),
          MyButton(
            text: '添加 WARP',
            onPressed: () => toast('添加 WARP'),
            icon: Icons.add,
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(icon, size: 30.sp, color: Colors.blue),
          ),
          SizedBox(height: 10.h),
          Text(text, style: TextStyle(fontSize: 14.sp)),
        ],
      ),
    );
  }
}
