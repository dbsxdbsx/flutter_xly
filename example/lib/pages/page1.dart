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
            Obx(() => MyMenuButton(
                  iconSize: 30.0,
                  iconColor: Colors.blue,
                  isPressed: controller.isMenuButtonActivated.value,
                  menuItems: [
                    MyMenuItem(
                      icon: Icons.engineering,
                      text: '加载内置引擎',
                      onTap: () {
                        toast('选择了加载内置引擎');
                        controller.isMenuButtonActivated.value =
                            !controller.isMenuButtonActivated.value;
                      },
                    ),
                    MyMenuItem(
                      text: '加载自定义引擎',
                      onTap: () => toast('加载自定义引擎功能暂未开放'),
                    ),
                    MyMenuItem(
                      icon: Icons.settings,
                      text: '高级选项',
                      subItems: [
                        MyMenuItem(
                          icon: Icons.speed,
                          text: '性能设置',
                          onTap: () => toast('打开性能设置'),
                        ),
                        MyMenuItem(
                          icon: Icons.security,
                          text: '安全选项',
                          onTap: () => toast('打开安全选项'),
                        ),
                        MyMenuItem(
                          icon: Icons.build,
                          text: '开发者工具',
                          subItems: [
                            MyMenuItem(
                              icon: Icons.bug_report,
                              text: '调试模式',
                              onTap: () => toast('开启调试模式'),
                            ),
                            MyMenuItem(
                              icon: Icons.code,
                              text: '控制台',
                              onTap: () => toast('打开控制台'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                )),
            SizedBox(height: 20.h),
            MyMenuButton(
              icon: Icons.more_vert,
              iconSize: 30.0,
              iconColor: Colors.green,
              menuItems: [
                MyMenuItem(
                  text: '选项A',
                  icon: Icons.star,
                  onTap: () => toast('选择了选项A'),
                ),
                MyMenuItem(
                  text: '选项B',
                  icon: Icons.favorite,
                  onTap: () => toast('选择了选项B'),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            MyButton(
              text: '切换菜单按钮状态',
              onPressed: controller.toggleMenuButtonState,
            ),
            SizedBox(height: 20.h),
            MyButton(
              text: '前往页面2',
              onPressed: controller.goToPage2,
            ),
            SizedBox(height: 20.h),
            MyButton(
              text: '连续显示多条Toast',
              onPressed: controller.showToast,
            ),
          ],
        ),
      ),
    ).showRightMenu(
      context: context,
      menuItems: [
        MyMenuItem(
          text: '选项1',
          onTap: () => toast('选择了选项1'),
        ),
        MyMenuItem(
          icon: Icons.looks_two,
          text: '选项2',
          onTap: () => toast('选择了选项2'),
        ),
        MyMenuItem(
          icon: Icons.more_horiz,
          text: '更多选项',
          subItems: [
            MyMenuItem(
              icon: Icons.info,
              text: '关于',
              subItems: [
                MyMenuItem(
                  icon: Icons.info_outline,
                  text: '版本信息',
                  onTap: () => toast('显示版本信息'),
                ),
                MyMenuItem(
                  icon: Icons.contact_support,
                  text: '联系我们',
                  onTap: () => toast('显示联系方式'),
                ),
              ],
            ),
            MyMenuItem(
              icon: Icons.help,
              text: '帮助',
              subItems: [
                MyMenuItem(
                  icon: Icons.help_outline,
                  text: '常见问题',
                  onTap: () => toast('显示常见问题'),
                ),
                MyMenuItem(
                  icon: Icons.book,
                  text: '用户手册',
                  onTap: () => toast('打开用户手册'),
                ),
              ],
            ),
            MyMenuItem(
              icon: Icons.settings,
              text: '设置',
              subItems: [
                MyMenuItem(
                  icon: Icons.language,
                  text: '语言设置',
                  onTap: () => toast('打开语言设置'),
                ),
                MyMenuItem(
                  icon: Icons.color_lens,
                  text: '主题设置',
                  onTap: () => toast('打开主题设置'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class Page1Controller extends GetxController {
  final isMenuButtonActivated = false.obs;

  void toggleMenuButtonState() {
    isMenuButtonActivated.value = !isMenuButtonActivated.value;
  }

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
