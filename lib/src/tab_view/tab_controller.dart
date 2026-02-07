import 'package:flutter/foundation.dart';

/// Tab 控制器，管理当前选中的 Tab 索引
///
/// 基于 [ChangeNotifier]，与 Flutter 标准 [TabController] 的设计理念一致。
/// 可以在 GetxController 中持有并使用，在 `onClose()` 中调用 [dispose] 释放。
///
/// 示例：
/// ```dart
/// final ctrl = MyTabController(length: 3);
/// ctrl.index = 1; // 切换到第二个 Tab
/// ctrl.addListener(() => print('当前: ${ctrl.index}'));
/// ```
class MyTabController extends ChangeNotifier {
  /// 创建 Tab 控制器
  ///
  /// [initialIndex] 初始选中索引，默认为 0
  /// [length] Tab 总数量，必须大于 0
  MyTabController({
    int initialIndex = 0,
    required this.length,
  })  : assert(length > 0, 'Tab 数量必须大于 0'),
        assert(
          initialIndex >= 0 && initialIndex < length,
          '初始索引 ($initialIndex) 必须在 [0, $length) 范围内',
        ),
        _index = initialIndex;

  /// Tab 总数量
  final int length;

  /// 当前选中的 Tab 索引
  int get index => _index;
  int _index;

  set index(int value) {
    assert(
      value >= 0 && value < length,
      '索引 ($value) 必须在 [0, $length) 范围内',
    );
    if (_index == value) return;
    _index = value;
    notifyListeners();
  }
}
