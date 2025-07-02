import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// 显示退出应用确认对话框 - 可被FloatBar和Page1Controller复用
Future<void> showExitConfirmDialog() async {
  final result = await MyDialog.show(
    content: const Text('确定要退出应用吗？'),
    leftButtonText: '取消',
    rightButtonText: '确定',
  );

  if (result == MyDialogChosen.right) {
    await MyApp.exit();
  }
}
