import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../main.dart';
import '../services/example_service.dart';

class Page9Controller extends GetxController {
  final isHidden = false.obs;

  /// 隐藏到托盘并显示通知
  void hideWithNotification() {
    final myTray = MyTray.to;
    final myNotify = MyNotify.to;
    myTray.hide();
    // 用户明确操作时显示系统通知
    myNotify.show("已隐藏到托盘", "点击托盘图标可恢复窗口", type: MyNotifyType.info);
    isHidden.value = true;
  }

  /// 静默隐藏（不显示通知）
  void silentHide() {
    final myTray = MyTray.to;
    myTray.hide(); // 不显示任何消息
    isHidden.value = true;
  }

  /// 恢复窗口
  void restoreWindow() {
    final myTray = MyTray.to;
    myTray.pop();
    isHidden.value = false;
  }

  /// 设置自定义托盘菜单
  void setCustomTrayMenu() {
    final myTray = MyTray.to;
    myTray.setContextMenu([
      MyTrayMenuItem(
        label: '显示主窗口',
        onTap: () => myTray.pop(),
      ),
      const MyTrayMenuItem.separator(),
      MyTrayMenuItem(
        label: '发送通知',
        onTap: () => _sendTestNotification(),
      ),
      MyTrayMenuItem(
        label: '通知类型',
        submenu: [
          MyTrayMenuItem(
            label: '信息通知',
            onTap: () => _sendInfoNotification(),
          ),
          MyTrayMenuItem(
            label: '警告通知',
            onTap: () => _sendWarningNotification(),
          ),
          MyTrayMenuItem(
            label: '错误通知',
            onTap: () => _sendErrorNotification(),
          ),
          MyTrayMenuItem(
            label: '成功通知',
            onTap: () => _sendSuccessNotification(),
          ),
        ],
      ),
      const MyTrayMenuItem.separator(),
      MyTrayMenuItem(
        label: '退出应用',
        onTap: () => ExampleService.to.exitApp(),
      ),
    ]);

    MyToast.showInfo("自定义托盘菜单已设置");
  }

  /// 切换图标为正常状态
  void setNormalIcon() {
    final myTray = MyTray.to;
    myTray.setIcon("windows/runner/resources/app_icon.ico");
    MyToast.showInfo("图标已切换为正常状态");
  }

  /// 切换图标为警告状态（使用同一个图标演示）
  void setWarningIcon() {
    final myTray = MyTray.to;
    myTray.setIcon("windows/runner/resources/app_icon.ico");
    MyToast.showInfo("图标已切换为警告状态（演示）");
  }

  /// 切换图标为错误状态（使用同一个图标演示）
  void setErrorIcon() {
    final myTray = MyTray.to;
    myTray.setIcon("windows/runner/resources/app_icon.ico");
    MyToast.showInfo("图标已切换为错误状态（演示）");
  }

  /// 切换图标为忙碌状态（使用同一个图标演示）
  void setBusyIcon() {
    final myTray = MyTray.to;
    myTray.setIcon("windows/runner/resources/app_icon.ico");
    MyToast.showInfo("图标已切换为忙碌状态（演示）");
  }

  // 私有方法用于托盘菜单回调
  void _sendTestNotification() {
    final myNotify = MyNotify.to;
    myNotify.show("测试通知", "这是一条测试通知消息", type: MyNotifyType.info);
  }

  void _sendInfoNotification() {
    final myNotify = MyNotify.to;
    myNotify.show("信息通知", "这是一条信息通知消息", type: MyNotifyType.info);
  }

  void _sendWarningNotification() {
    final myNotify = MyNotify.to;
    myNotify.show("警告通知", "这是一条警告消息", type: MyNotifyType.warning);
  }

  void _sendErrorNotification() {
    final myNotify = MyNotify.to;
    myNotify.show("错误通知", "这是一条错误消息", type: MyNotifyType.error);
  }

  void _sendSuccessNotification() {
    final myNotify = MyNotify.to;
    myNotify.show("成功通知", "操作已成功完成", type: MyNotifyType.success);
  }
}

class Page9View extends GetView<Page9Controller> {
  const Page9View({super.key});

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
                    'MyTray 托盘功能说明',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'MyTray 托盘功能：\n'
                    '• 支持最小化窗口到系统托盘\n'
                    '• 支持自定义托盘右键菜单\n'
                    '• 支持状态驱动的图标切换（可选）\n'
                    '• 仅在桌面平台（Windows/macOS/Linux）可用\n'
                    '• 托盘图标位于任务栏通知区域',
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // 托盘操作区域
            _buildSection(
              '托盘操作',
              [
                MyButton(
                  text: '隐藏到托盘',
                  onPressed: controller.hideWithNotification,
                  icon: Icons.minimize,
                  backgroundColor: Colors.orange,
                  width: double.infinity,
                ),
                SizedBox(height: 12.h),
                MyButton(
                  text: '静默隐藏',
                  onPressed: controller.silentHide,
                  icon: Icons.visibility_off,
                  backgroundColor: Colors.grey,
                  width: double.infinity,
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 图标状态控制区域
            _buildSection(
              '图标状态控制',
              [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '注意：图标状态功能需要在初始化时启用状态驱动模式，当前为演示模式',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.amber[800],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        text: '正常',
                        onPressed: controller.setNormalIcon,
                        icon: Icons.check_circle,
                        backgroundColor: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '警告',
                        onPressed: controller.setWarningIcon,
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
                        text: '错误',
                        onPressed: controller.setErrorIcon,
                        icon: Icons.error,
                        backgroundColor: Colors.red,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: MyButton(
                        text: '忙碌',
                        onPressed: controller.setBusyIcon,
                        icon: Icons.hourglass_empty,
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 菜单设置区域
            _buildSection(
              '托盘菜单设置',
              [
                MyButton(
                  text: '设置自定义托盘菜单',
                  onPressed: controller.setCustomTrayMenu,
                  icon: Icons.menu,
                  backgroundColor: Colors.purple,
                  width: double.infinity,
                ),
                SizedBox(height: 12.h),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    '提示：设置后右键点击托盘图标可查看自定义菜单',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 24.h),

            // 状态显示
            Obx(() => _buildSection(
                  '当前状态',
                  [
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: controller.isHidden.value
                            ? Colors.orange.withValues(alpha: 0.1)
                            : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: controller.isHidden.value
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            controller.isHidden.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: controller.isHidden.value
                                ? Colors.orange[700]
                                : Colors.green[700],
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            controller.isHidden.value ? '窗口已隐藏到托盘' : '窗口正常显示',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: controller.isHidden.value
                                  ? Colors.orange[700]
                                  : Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                )),

            // 导航按钮
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyButton(
                  icon: Icons.arrow_back,
                  text: '返回第8页',
                  onPressed: () => Get.toNamed(MyRoutes.page8),
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
