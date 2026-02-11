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
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('FloatPanel 禁用样式演示', fontSize: 20.sp),
          SizedBox(height: 12.h),
          Wrap(spacing: 12.w, runSpacing: 12.h, children: [
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
          SectionTitle('浮动面板按钮禁用状态控制', fontSize: 20.sp),
          SizedBox(height: 8.h),
          Wrap(spacing: 12.w, runSpacing: 12.h, children: [
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
          SectionTitle('浮动面板按钮常亮控制', fontSize: 20.sp),
          SizedBox(height: 8.h),
          Wrap(spacing: 12.w, runSpacing: 12.h, children: [
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
          SizedBox(height: 24.h),
          SectionTitle('运行时动态配置', fontSize: 20.sp),
          SizedBox(height: 8.h),
          Wrap(spacing: 12.w, runSpacing: 12.h, children: [
            MyButton(
              text: '添加按钮4',
              onPressed: () {
                final items = FloatPanel.to.items;
                if (items.any((e) => e.id == 'page4')) return;
                items.add(FloatPanelIconBtn(
                  icon: Icons.filter_4,
                  id: 'page4',
                  onTap: () => MyToast.showInfo('按钮4被点击'),
                ));
              },
            ),
            MyButton(
              text: '移除最后一个按钮',
              onPressed: () {
                final items = FloatPanel.to.items;
                if (items.isNotEmpty) items.removeLast();
              },
            ),
            MyButton(
              text: '横向展开: 左到右',
              onPressed: () => FloatPanel.to.configure(
                horizontalExpandMode: HorizontalExpandMode.leftToRight,
              ),
            ),
            MyButton(
              text: '横向展开: 右到左',
              onPressed: () => FloatPanel.to.configure(
                horizontalExpandMode: HorizontalExpandMode.rightToLeft,
              ),
            ),
            MyButton(
              text: '横向展开: 关闭',
              onPressed: () => FloatPanel.to.configure(
                horizontalExpandMode: HorizontalExpandMode.none,
              ),
            ),
            MyButton(
              text: '仅左右停靠',
              onPressed: () =>
                  FloatPanel.to.configure(dockToAllEdges: false),
            ),
            MyButton(
              text: '四边停靠',
              onPressed: () =>
                  FloatPanel.to.configure(dockToAllEdges: true),
            ),
            MyButton(
              text: '恢复全部默认',
              onPressed: () => FloatPanel.to.resetToDefault(),
            ),
          ]),
        ],
      ),
    );
  }
}
