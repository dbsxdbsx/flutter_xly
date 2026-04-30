import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../widgets/section_title.dart';

class Page11Controller extends GetxController {}

class Page11View extends GetView<Page11Controller> {
  const Page11View({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<Page11Controller>()) Get.put(Page11Controller());
    return SingleChildScrollView(
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
          SectionTitle('FloatPanel Tooltip 定位验证', fontSize: 20.sp),
          SizedBox(height: 8.h),
          Text(
            '展开浮动条后，将它拖到左、右、上、下边缘，再悬停按钮。竖向浮动条的 Tooltip 会出现在远离屏幕边缘的一侧；横向浮动条会在上方或下方避让整个浮动条。',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: 8.h),
          Wrap(spacing: 12.w, runSpacing: 12.h, children: [
            MyButton(
              text: '设置长 Tooltip',
              onPressed: () {
                FloatPanel.to.items.value = [
                  FloatPanelIconBtn(
                    icon: Icons.filter_1,
                    id: 'page1',
                    tooltip: '长提示：左侧停靠时应显示在右侧，并且不覆盖整条浮动面板。',
                    onTap: () => MyToast.showInfo('Tooltip 演示按钮1'),
                  ),
                  FloatPanelIconBtn(
                    icon: Icons.filter_2,
                    id: 'page2',
                    tooltip: '长提示：右侧停靠时应显示在左侧，宽度会按可用空间自动收敛。',
                    onTap: () => MyToast.showInfo('Tooltip 演示按钮2'),
                  ),
                  FloatPanelIconBtn(
                    icon: Icons.filter_3,
                    id: 'page3',
                    tooltip: '长提示：四边停靠后拖到顶部或底部，横向展开时应根据位置显示在下方或上方。',
                    onTap: () => MyToast.showInfo('Tooltip 演示按钮3'),
                  ),
                ];
              },
            ),
            MyButton(
              text: '恢复默认 Tooltip',
              onPressed: () => FloatPanel.to.resetToDefault(),
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
                  tooltip: '动态添加的按钮4：用于验证运行时新增按钮也能使用智能 Tooltip。',
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
            Obx(() {
              final mode = FloatPanel.to.horizontalExpandMode.value;
              // 文字代表"点击之后会切换到的方向"。
              final String label;
              final HorizontalExpandMode next;
              switch (mode) {
                case HorizontalExpandMode.leftToRight:
                  label = '展开方向: 切换为右到左';
                  next = HorizontalExpandMode.rightToLeft;
                  break;
                case HorizontalExpandMode.rightToLeft:
                  label = '展开方向: 切换为左到右';
                  next = HorizontalExpandMode.leftToRight;
                  break;
                case HorizontalExpandMode.none:
                  label = '展开方向: 切换为左到右';
                  next = HorizontalExpandMode.leftToRight;
                  break;
              }
              return MyButton(
                text: label,
                onPressed: () =>
                    FloatPanel.to.configure(horizontalExpandMode: next),
              );
            }),
            Obx(() {
              final isOff = FloatPanel.to.horizontalExpandMode.value ==
                  HorizontalExpandMode.none;
              return MyButton(
                text: isOff ? '横向展开: 已关闭' : '横向展开: 已开启',
                onPressed: () => FloatPanel.to.configure(
                  horizontalExpandMode: isOff
                      ? HorizontalExpandMode.leftToRight
                      : HorizontalExpandMode.none,
                ),
              );
            }),
            Obx(() {
              final allEdges = FloatPanel.to.dockToAllEdges.value;
              return MyButton(
                text: allEdges ? '停靠: 四边' : '停靠: 仅左右',
                onPressed: () => FloatPanel.to.configure(
                  dockToAllEdges: !allEdges,
                ),
              );
            }),
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
