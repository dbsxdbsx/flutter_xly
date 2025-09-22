import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../widgets/section_title.dart';

class Page11Controller extends GetxController {}

class Page11View extends GetView<Page11Controller> {
  const Page11View({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<Page11Controller>()) Get.put(Page11Controller());
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('FloatPanel 禁用样式演示', fontSize: 20),
          SizedBox(height: 12.h),
          Wrap(spacing: 12, runSpacing: 12, children: [
            MyButton(
              text: '恢复默认（黄色X）',
              onPressed: () {
                FloatPanel.to.disabledStyle.value =
                    const DisabledStyle.defaultX();
              },
            ),
            MyButton(
              text: '变体：仅变暗（无X）',
              onPressed: () {
                FloatPanel.to.disabledStyle.value =
                    const DisabledStyle.dimOnly();
              },
            ),
            MyButton(
              text: '自定义叠加（红色⚠）',
              onPressed: () {
                FloatPanel.to.disabledStyle.value =
                    DisabledStyle.custom((iconSize) {
                  return Icon(Icons.warning_amber,
                      color: Colors.redAccent, size: iconSize * 0.9);
                });
              },
            ),
          ]),
          SizedBox(height: 24.h),
          const SectionTitle('浮动面板按钮禁用状态控制', fontSize: 20),
          SizedBox(height: 8.h),
          Wrap(spacing: 12, runSpacing: 12, children: [
            MyButton(
              text: '禁用浮动面板按钮1',
              onPressed: () => FloatPanel.to.iconBtn('page1').setEnabled(false),
            ),
            MyButton(
              text: '禁用浮动面板按钮2',
              onPressed: () => FloatPanel.to.iconBtn('page2').setEnabled(false),
            ),
            MyButton(
              text: '禁用浮动面板按钮3',
              onPressed: () => FloatPanel.to.iconBtn('page3').setEnabled(false),
            ),
            MyButton(
              text: '切换浮动面板按钮2可用性',
              onPressed: () => FloatPanel.to.iconBtn('page2').toggleEnabled(),
            ),
            MyButton(
              text: '禁用全部浮动面板按钮',
              onPressed: () {
                for (final item in FloatPanel.to.items) {
                  final id = item.id;
                  if (id != null) {
                    FloatPanel.to.iconBtn(id).setEnabled(false);
                  }
                }
              },
            ),
            MyButton(
              text: '启用全部浮动面板按钮',
              onPressed: () => FloatPanel.to.iconBtns.enableAll(),
            ),
          ]),
          SizedBox(height: 24.h),
          const SectionTitle('浮动面板按钮常亮控制', fontSize: 20),
          SizedBox(height: 8.h),
          Wrap(spacing: 12, runSpacing: 12, children: [
            MyButton(
              text: '设置按钮1常亮',
              onPressed: () =>
                  FloatPanel.to.iconBtn('page1').setHighlighted(true),
            ),
            MyButton(
              text: '取消按钮1常亮',
              onPressed: () =>
                  FloatPanel.to.iconBtn('page1').setHighlighted(false),
            ),
            MyButton(
              text: '切换按钮2常亮',
              onPressed: () =>
                  FloatPanel.to.iconBtn('page2').toggleHighlighted(),
            ),
            MyButton(
              text: '清空全部常亮',
              onPressed: () => FloatPanel.to.highlightedIds.clear(),
            ),
          ]),
        ],
      ),
    );
  }
}
