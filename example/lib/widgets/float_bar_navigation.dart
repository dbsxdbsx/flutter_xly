import 'package:example/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../main.dart';

/// FloatBar导航控制器
class FloatBarNavController extends GetxController {
  final buttons = <MyFloatBarButton>[
    MyFloatBarButton(icon: Icons.menu), // Navigation menu button
    MyFloatBarButton(icon: CupertinoIcons.minus), // Minimize window button
    MyFloatBarButton(icon: CupertinoIcons.xmark_circle), // Exit app button
  ].obs;

  void updateButtons(String route) {
    // Simplified: no special handling for any specific route
    buttons.value = [
      MyFloatBarButton(icon: Icons.menu), // Navigation menu button
      MyFloatBarButton(icon: CupertinoIcons.minus), // Minimize window button
      MyFloatBarButton(icon: CupertinoIcons.xmark_circle), // Exit app button
    ];
  }
}

/// 获取FloatBar组件
Widget getFloatBar() {
  final ctrl = Get.find<FloatBarNavController>();
  return Obx(
    () => MyFloatBar(
      barWidthInput: 60,
      backgroundColor: const Color(0xFF222222),
      barShape: BarShape.rectangle,
      borderRadiusInput: BorderRadius.circular(10),
      dockType: DockType.outside,
      barButtonColor: Colors.blueGrey,
      customButtonColor: Colors.grey,
      dockActivate: true,
      buttons: ctrl.buttons.toList(),
      onPressed: (index) {
        final context = navigatorKey.currentContext;
        if (context == null) return;

        if (index == 0) {
          // Navigation menu button
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('选择页面'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPageButton(context, '第1页', Routes.page1),
                    _buildPageButton(context, '第2页', Routes.page2),
                    _buildPageButton(context, '第3页', Routes.page3),
                    _buildPageButton(context, '第4页', Routes.page4),
                    _buildPageButton(context, '第5页', Routes.page5),
                    _buildPageButton(context, '第6页', Routes.page6),
                    _buildPageButton(context, '第7页', Routes.page7),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('取消'),
                  ),
                ],
              );
            },
          );
        } else if (index == 1) {
          // Minimize window button
          windowManager.minimize();
        } else if (index == 2) {
          // Exit app button
          showExitConfirmDialog();
        }
      },
    ),
  );
}

/// 构建页面按钮
Widget _buildPageButton(BuildContext context, String title, String route) {
  final ctrl = Get.find<FloatBarNavController>();
  return SizedBox(
    width: double.infinity,
    child: TextButton(
      onPressed: () {
        ctrl.updateButtons(route);
        Navigator.of(context).pop();
        Get.toNamed(route);
      },
      child: Text(title),
    ),
  );
}
