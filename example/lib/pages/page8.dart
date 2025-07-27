import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../main.dart';

class Page8Controller extends GetxController {
  final notificationCount = 0.obs;

  /// 发送信息通知
  void sendInfoNotification() {
    final myNotify = MyNotify.to;
    notificationCount.value++;
    myNotify.show(
      "信息通知",
      "这是一条信息通知消息 #${notificationCount.value}",
      type: MyNotifyType.info,
    );
  }

  /// 发送警告通知
  void sendWarningNotification() {
    final myNotify = MyNotify.to;
    myNotify.show(
      "警告通知",
      "这是一条警告消息",
      type: MyNotifyType.warning,
    );
  }

  /// 发送错误通知
  void sendErrorNotification() {
    final myNotify = MyNotify.to;
    myNotify.show(
      "错误通知",
      "这是一条错误消息",
      type: MyNotifyType.error,
    );
  }

  /// 发送成功通知
  void sendSuccessNotification() {
    final myNotify = MyNotify.to;
    myNotify.show(
      "成功通知",
      "操作已成功完成",
      type: MyNotifyType.success,
    );
  }

  /// 发送定时通知
  void sendScheduledNotification() {
    final myNotify = MyNotify.to;
    final scheduledTime = DateTime.now().add(const Duration(seconds: 5));
    myNotify.schedule(
      "定时通知",
      "这是一条5秒后显示的定时通知",
      scheduledTime,
      type: MyNotifyType.info,
    );
    MyToast.showInfo("定时通知已设置，将在5秒后显示");
  }

  /// 请求通知权限
  void requestNotificationPermission() async {
    final myNotify = MyNotify.to;
    final granted = await myNotify.requestPermissions();
    if (granted) {
      MyToast.showOk("通知权限已获得");
    } else {
      MyToast.showError("通知权限被拒绝");
    }
  }

  /// 取消所有通知
  void cancelAllNotifications() {
    final myNotify = MyNotify.to;
    myNotify.cancelAll();
    MyToast.showInfo("所有通知已取消");
  }

  /// 显示通知状态
  void showNotificationStatus() {
    final myNotify = MyNotify.to;
    final isInitialized = myNotify.isInitialized;
    final hasPermission = myNotify.permissionGranted;

    MyToast.showInfo(
        "通知状态 - 初始化: ${isInitialized ? '是' : '否'}, 权限: ${hasPermission ? '已授权' : '未授权'}");
  }
}

class Page8View extends GetView<Page8Controller> {
  const Page8View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyTray 托盘功能演示'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 功能说明
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '托盘通知测试',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '直接使用 MyNotify 显示系统通知，支持跨平台（Android、iOS、macOS、Windows、Linux）',
                    style: TextStyle(fontSize: 14.sp, color: Colors.green[700]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 通知测试区域
            _buildSection(
              '托盘通知测试',
              [
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: '信息通知',
                        onPressed: controller.sendInfoNotification,
                        icon: Icons.info,
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '警告通知',
                        onPressed: controller.sendWarningNotification,
                        icon: Icons.warning,
                        backgroundColor: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: '错误通知',
                        onPressed: controller.sendErrorNotification,
                        icon: Icons.error,
                        backgroundColor: Colors.red,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '成功通知',
                        onPressed: controller.sendSuccessNotification,
                        icon: Icons.check_circle,
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Obx(() => Text(
                      '已发送通知数量: ${controller.notificationCount.value}',
                      style:
                          TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                    )),
              ],
            ),

            SizedBox(height: 24.h),

            // MyNotify 系统通知测试区域
            _buildSection(
              'MyNotify 系统通知测试',
              [
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: '定时通知',
                        onPressed: controller.sendScheduledNotification,
                        icon: Icons.schedule,
                        backgroundColor: Colors.purple,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '请求权限',
                        onPressed: controller.requestNotificationPermission,
                        icon: Icons.security,
                        backgroundColor: Colors.indigo,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: '取消所有',
                        onPressed: controller.cancelAllNotifications,
                        icon: Icons.clear_all,
                        backgroundColor: Colors.grey[600]!,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '通知状态',
                        onPressed: controller.showNotificationStatus,
                        icon: Icons.info_outline,
                        backgroundColor: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // 导航按钮
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyButton(
                  icon: Icons.arrow_back,
                  text: '返回第7页',
                  onPressed: () => Get.back(),
                  size: 80.w,
                ),
                MyButton(
                  icon: Icons.arrow_forward,
                  text: '前往第9页',
                  onPressed: () => Get.toNamed(MyRoutes.page9),
                  size: 80.w,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        SizedBox(height: 12.h),
        ...children,
      ],
    );
  }
}
