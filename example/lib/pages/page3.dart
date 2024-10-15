import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

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

  void goToPage4() {
    Get.toNamed(Routes.page4);
  }
}

class Page3View extends StatelessWidget {
  const Page3View({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Page3Controller>(
      builder: (controller) => Scaffold(
        appBar: AppBar(
          title: Text('第3页', style: TextStyle(fontSize: 18.sp)),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('这是第3页的内容', style: TextStyle(fontSize: 16.sp)),
              SizedBox(height: 20.h),
              MyButton(
                text: '前往可拖动卡片列表',
                onPressed: controller.goToPage4,
                width: 200.w,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
