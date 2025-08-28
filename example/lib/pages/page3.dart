import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page3View extends GetView<Page3Controller> {
  const Page3View({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('对话框演示页面',
                    style: TextStyle(
                        fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 30.h),

                // MyDialog 示例
                Text('MyDialog - 标准对话框',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 10.h,
                  alignment: WrapAlignment.center,
                  children: [
                    MyButton(
                      text: '确认(可关)',
                      onPressed: controller.showConfirmDialog,
                      width: 160.w,
                    ),
                    MyButton(
                      text: 'iOS(可关)',
                      onPressed: controller.showIosDialog,
                      width: 160.w,
                    ),
                    MyButton(
                      text: '删除(严格)',
                      onPressed: controller.showDeleteDialog,
                      width: 160.w,
                    ),
                  ],
                ),

                SizedBox(height: 30.h),

                // MyDialogSheet 示例
                Text('MyDialogSheet - 自定义对话框',
                    style: TextStyle(
                        fontSize: 16.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 10.h,
                  alignment: WrapAlignment.center,
                  children: [
                    MyButton(
                      text: '底部菜单',
                      onPressed: controller.showBottomSheet,
                      width: 140.w,
                    ),
                    MyButton(
                      text: '设置面板',
                      onPressed: controller.showCenterDialog,
                      width: 140.w,
                    ),
                    MyButton(
                      text: '用户信息',
                      onPressed: controller.showUserInfoDialog,
                      width: 140.w,
                    ),
                  ],
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
    Get.toNamed(MyRoutes.page2);
  }

  void goToPage1() {
    goToPage(MyRoutes.page1);
  }

  void goToPage4() {
    Get.toNamed(MyRoutes.page4);
  }

  // MyDialog 示例方法
  void showConfirmDialog() async {
    final result = await MyDialog.show(
      title: '确认操作',
      content: const Text('确定要执行这个操作吗？'),
      leftButtonText: '取消',
      rightButtonText: '确定',
    );

    switch (result) {
      case MyDialogChosen.left:
        MyToast.show('用户取消了操作');
        break;
      case MyDialogChosen.right:
        MyToast.showOk('操作已确认');
        break;
      case MyDialogChosen.canceled:
        MyToast.show('对话框被关闭');
        break;
    }
  }

  void showIosDialog() async {
    final result = await MyDialog.showIos(
      title: '提示',
      content: const Text('这是iOS风格的对话框'),
      leftButtonText: '否',
      rightButtonText: '是',
    );

    switch (result) {
      case MyDialogChosen.left:
        MyToast.show('选择了否');
        break;
      case MyDialogChosen.right:
        MyToast.show('选择了是');
        break;
      case MyDialogChosen.canceled:
        MyToast.show('对话框被关闭');
        break;
    }
  }

  void showDeleteDialog() async {
    final result = await MyDialog.show(
      title: '删除文件',
      content: const Text('此操作不可撤销，确定删除吗？'),
      leftButtonText: '取消',
      rightButtonText: '删除',
      rightButtonColor: Colors.red,
      titleColor: Colors.red,
      barrierDismissible: false, // 严格模态
    );

    if (result == MyDialogChosen.right) {
      MyToast.showOk('文件已删除');
    } else if (result == MyDialogChosen.left) {
      MyToast.show('取消删除');
    }
  }

  void showBottomSheet() {
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
              color: Colors.blue.withValues(alpha: 0.1),
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

  // MyDialogSheet 示例方法
  void showUserInfoDialog() async {
    final result = await MyDialogSheet.showCenter<String>(
      title: '用户信息',
      titleFontSize: 20.sp,
      centerTitle: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),
          CircleAvatar(
            radius: 40.r,
            backgroundColor: Colors.blue.withValues(alpha: 0.1),
            child: Icon(Icons.person, size: 40.sp, color: Colors.blue),
          ),
          SizedBox(height: 16.h),
          Text('张三',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
          Text('高级开发工程师',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
          SizedBox(height: 20.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(Icons.phone, '电话', () {
                Get.back(result: 'phone');
              }),
              _buildActionButton(Icons.email, '邮件', () {
                Get.back(result: 'email');
              }),
              _buildActionButton(Icons.message, '消息', () {
                Get.back(result: 'message');
              }),
            ],
          ),
          SizedBox(height: 10.h),
        ],
      ),
      contentPadding: EdgeInsets.all(20.w),
    );

    if (result != null) {
      MyToast.show('选择了: $result');
    }
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(icon, size: 24.sp, color: Colors.blue),
            SizedBox(height: 4.h),
            Text(label, style: TextStyle(fontSize: 12.sp)),
          ],
        ),
      ),
    );
  }

  void showCenterDialog() {
    MyDialogSheet.showCenter(
      title: '设置对话框',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.settings, size: 24.sp),
            title: Text('设置项 1', style: TextStyle(fontSize: 16.sp)),
            onTap: () => MyToast.show('点击了设置项 1'),
          ),
          ListTile(
            leading: Icon(Icons.info, size: 24.sp),
            title: Text('设置项 2', style: TextStyle(fontSize: 16.sp)),
            onTap: () => MyToast.show('点击了设置项 2'),
          ),
        ],
      ),
      onConfirm: () {
        MyToast.show('确认设置');
        Get.back();
      },
      onExit: () {
        MyToast.show('取消设置');
        Get.back();
      },
    );
  }
}
