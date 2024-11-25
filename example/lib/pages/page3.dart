import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page3View extends GetView<Page3Controller> {
  const Page3View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('第3页', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('这是第3页的内容', style: TextStyle(fontSize: 16.sp)),
                  SizedBox(height: 20.h),
                  MyButton(
                    text: '显示底部菜单',
                    onPressed: controller.showBottomMenu,
                    width: 200.w,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20.w),
            child: _buildNavigationSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MyButton(
          icon: Icons.arrow_back,
          text: '返回第2页',
          onPressed: controller.goToPage2,
        ),
        SizedBox(width: 12.w),
        MyButton(
          icon: Icons.arrow_forward,
          text: '前往第4页',
          onPressed: controller.goToPage4,
        ),
      ],
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
    MyDialogSheet.showBottom(
      height: 300.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              '从剪贴板添加',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildMenuItem(
                  Icons.content_paste, '从剪贴板添加', () => MyToast.show('从剪贴板添加')),
              _buildMenuItem(Icons.edit, '手动输入', () => MyToast.show('手动输入')),
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
            onPressed: () => MyToast.show('添加 WARP'),
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

  void goToPage4() {
    Get.toNamed(Routes.page4);
  }
}
