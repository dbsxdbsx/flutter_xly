import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xly/xly.dart';

void main() {
  group('FloatPanel highlight logic', () {
    setUp(() {
      // 每个测试前，重置并注册一个新的 FloatPanel 服务
      if (Get.isRegistered<FloatPanel>()) {
        Get.delete<FloatPanel>(force: true);
      }
      Get.put<FloatPanel>(FloatPanel());

      // 配置一个带 id 的按钮，便于联动测试
      FloatPanel.to.configure(items: const [
        FloatPanelIconBtn(icon: Icons.ac_unit, id: 'btn1'),
      ]);
    });

    test('setHighlighted(true/false) 应更新 highlightedIds 集合', () {
      expect(FloatPanel.to.highlightedIds.contains('btn1'), isFalse);

      FloatPanel.to.iconBtn('btn1').setHighlighted(true);
      expect(FloatPanel.to.highlightedIds.contains('btn1'), isTrue);

      FloatPanel.to.iconBtn('btn1').setHighlighted(false);
      expect(FloatPanel.to.highlightedIds.contains('btn1'), isFalse);
    });

    test('toggleHighlighted() 应在 true/false 间切换', () {
      expect(FloatPanel.to.iconBtn('btn1').isHighlighted, isFalse);
      FloatPanel.to.iconBtn('btn1').toggleHighlighted();
      expect(FloatPanel.to.iconBtn('btn1').isHighlighted, isTrue);
      FloatPanel.to.iconBtn('btn1').toggleHighlighted();
      expect(FloatPanel.to.iconBtn('btn1').isHighlighted, isFalse);
    });

    test('常亮(highlighted) 不影响启用/禁用语义', () {
      // 初始启用
      expect(FloatPanel.to.iconBtn('btn1').isEnabled, isTrue);

      // 设置常亮不应改变 isEnabled
      FloatPanel.to.iconBtn('btn1').setHighlighted(true);
      expect(FloatPanel.to.iconBtn('btn1').isEnabled, isTrue);

      // 禁用后 isEnabled 为 false，但依然可以保持常亮状态为 true（语义独立）
      FloatPanel.to.iconBtn('btn1').setEnabled(false);
      expect(FloatPanel.to.iconBtn('btn1').isEnabled, isFalse);
      expect(FloatPanel.to.iconBtn('btn1').isHighlighted, isTrue);
    });
  });
}
