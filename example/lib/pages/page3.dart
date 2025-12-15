import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' as raw_get;
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

                // Overlay 问题测试（已修复）
                // 自 Flutter 3.38.1 起，GetX 的 overlayContext 在对话框关闭后可能失效
                // 参考: https://github.com/jonataslaw/getx/issues/3425
                Text('✅ Overlay 问题测试',
                    style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.green)),
                SizedBox(height: 8.h),
                Text(
                  'Flutter 3.38.1+ Overlay 问题已修复',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
                SizedBox(height: 15.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 10.h,
                  alignment: WrapAlignment.center,
                  children: [
                    MyButton(
                      text: '顶部Snackbar',
                      onPressed: controller.testRawSnackbarInDialog,
                      backgroundColor: Colors.green.shade100,
                    ),
                    MyButton(
                      text: '顶部Toast',
                      onPressed: controller.testMyToastInDialog,
                      backgroundColor: Colors.green.shade100,
                    ),
                    MyButton(
                      text: '中间Toast',
                      onPressed: controller.testCenterToastInDialog,
                      backgroundColor: Colors.blue.shade100,
                    ),
                    MyButton(
                      text: '底部Toast',
                      onPressed: controller.testBottomToastInDialog,
                      backgroundColor: Colors.green.shade100,
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

  // ========== Overlay 问题测试 ==========
  // 自 Flutter 3.38.1 起，GetX 的 overlayContext 在对话框关闭后可能失效
  // 导致 "No Overlay widget found" 异常
  // 已通过在 GetMaterialApp builder 中包裹 Overlay 修复
  // 参考: https://github.com/jonataslaw/getx/issues/3425

  /// 测试原生 Get.snackbar 在对话框关闭回调中的行为
  void testRawSnackbarInDialog() {
    MyDialogSheet.showCenter(
      title: '原生 Get.snackbar 测试',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '点击"确认"后将直接调用原生 Get.snackbar\n'
            '已通过在 App 根部包裹 Overlay 修复\n'
            '现在可以正常工作',
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '✅ 已修复：应该正常显示',
            style: TextStyle(fontSize: 12.sp, color: Colors.green),
          ),
        ],
      ),
      onConfirm: () {
        // 先关闭对话框
        Get.back();
        // 然后直接调用原生 Get.snackbar（可能失败）
        raw_get.Get.snackbar(
          '原生测试',
          '这是直接调用 Get.snackbar 的测试',
          snackPosition: raw_get.SnackPosition.TOP,
          backgroundColor: Colors.amber[50],
          colorText: Colors.amber[900],
          duration: const Duration(seconds: 3),
        );
      },
      onExit: () {
        Get.back();
      },
    );
  }

  /// 测试 MyToast.showUpWarn 在对话框关闭回调中的行为
  /// ✅ 这应该是安全的，因为内部有保护性处理
  void testMyToastInDialog() {
    MyDialogSheet.showCenter(
      title: '顶部 Toast 测试',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '点击"确认"后将调用 MyToast.showUpWarn\n'
            '已通过在 App 根部包裹 Overlay 修复',
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '✅ 已修复：应该正常显示',
            style: TextStyle(fontSize: 12.sp, color: Colors.green),
          ),
        ],
      ),
      onConfirm: () {
        Get.back();
        MyToast.showUpWarn('这是顶部 Toast 的测试');
      },
      onExit: () {
        Get.back();
      },
    );
  }

  /// 测试 MyToast.show（中间 Toast）在对话框关闭回调中的行为
  /// ✅ 使用自定义 Toast 实现，不依赖 GetX Overlay，天然安全
  void testCenterToastInDialog() {
    MyDialogSheet.showCenter(
      title: '中间 Toast 测试',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '点击"确认"后将调用 MyToast.show\n'
            '使用自定义 Toast 实现\n'
            '不依赖 GetX Overlay',
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '✅ 天然安全：不依赖 GetX',
            style: TextStyle(fontSize: 12.sp, color: Colors.blue),
          ),
        ],
      ),
      onConfirm: () {
        Get.back();
        MyToast.show('这是中间 Toast 的测试');
      },
      onExit: () {
        Get.back();
      },
    );
  }

  /// 测试 MyToast.showBottom（底部 Toast）在对话框关闭回调中的行为
  /// 使用 Get.showSnackbar，依赖 GetX Overlay
  void testBottomToastInDialog() {
    MyDialogSheet.showCenter(
      title: '底部 Toast 测试',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '点击"确认"后将调用 MyToast.showBottom\n'
            '使用 Get.showSnackbar 实现\n'
            '依赖 GetX Overlay',
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '✅ 已修复：App 根部包裹 Overlay',
            style: TextStyle(fontSize: 12.sp, color: Colors.green),
          ),
        ],
      ),
      onConfirm: () {
        Get.back();
        MyToast.showBottom('这是底部 Toast 的测试');
      },
      onExit: () {
        Get.back();
      },
    );
  }
}
