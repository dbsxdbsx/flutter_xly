import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  group('MyFloatPanel highlight logic', () {
    setUp(() {
      // 每个测试前，重置并注册一个新的 MyFloatPanel 服务
      if (Get.isRegistered<MyFloatPanel>()) {
        Get.delete<MyFloatPanel>(force: true);
      }
      Get.put<MyFloatPanel>(MyFloatPanel());

      // 配置一个带 id 的按钮，便于联动测试
      MyFloatPanel.to.configure(items: const [
        MyFloatPanelIconBtn(icon: Icons.ac_unit, id: 'btn1'),
      ]);
    });

    test('setHighlighted(true/false) 应更新 highlightedIds 集合', () {
      expect(MyFloatPanel.to.highlightedIds.contains('btn1'), isFalse);

      MyFloatPanel.to.iconBtn('btn1').setHighlighted(true);
      expect(MyFloatPanel.to.highlightedIds.contains('btn1'), isTrue);

      MyFloatPanel.to.iconBtn('btn1').setHighlighted(false);
      expect(MyFloatPanel.to.highlightedIds.contains('btn1'), isFalse);
    });

    test('toggleHighlighted() 应在 true/false 间切换', () {
      expect(MyFloatPanel.to.iconBtn('btn1').isHighlighted, isFalse);
      MyFloatPanel.to.iconBtn('btn1').toggleHighlighted();
      expect(MyFloatPanel.to.iconBtn('btn1').isHighlighted, isTrue);
      MyFloatPanel.to.iconBtn('btn1').toggleHighlighted();
      expect(MyFloatPanel.to.iconBtn('btn1').isHighlighted, isFalse);
    });

    test('常亮(highlighted) 不影响启用/禁用语义', () {
      // 初始启用
      expect(MyFloatPanel.to.iconBtn('btn1').isEnabled, isTrue);

      // 设置常亮不应改变 isEnabled
      MyFloatPanel.to.iconBtn('btn1').setHighlighted(true);
      expect(MyFloatPanel.to.iconBtn('btn1').isEnabled, isTrue);

      // 禁用后 isEnabled 为 false，但依然可以保持常亮状态为 true（语义独立）
      MyFloatPanel.to.iconBtn('btn1').setEnabled(false);
      expect(MyFloatPanel.to.iconBtn('btn1').isEnabled, isFalse);
      expect(MyFloatPanel.to.iconBtn('btn1').isHighlighted, isTrue);
    });
  });
}
