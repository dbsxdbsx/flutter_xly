import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum MyDialogChosen { left, right, canceled }

class MyDialog {
  static Future<MyDialogChosen> show({
    required Widget content,
    VoidCallback? onLeftButtonPressed,
    VoidCallback? onRightButtonPressed,
    String title = '提示',
    String leftButtonText = '取消',
    String rightButtonText = '确定',
    Color? backgroundColor,
    Color? titleColor,
    Color? leftButtonColor = Colors.black54,
    Color? rightButtonColor = Colors.blue,
    double? borderRadius,
    double? elevation,
    double? barrierOpacity,
  }) async {
    return _showDialog(
      dialog: AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        content: content,
        shape: borderRadius != null
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius))
            : null,
        elevation: elevation,
        actions: _buildActions(
          leftButtonText: leftButtonText,
          rightButtonText: rightButtonText,
          leftButtonColor: leftButtonColor,
          rightButtonColor: rightButtonColor,
          onLeftButtonPressed: onLeftButtonPressed,
          onRightButtonPressed: onRightButtonPressed,
          isMaterial: true,
        ),
      ),
      barrierOpacity: barrierOpacity,
    );
  }

  static Future<MyDialogChosen> showIos({
    required Widget content,
    VoidCallback? onLeftButtonPressed,
    VoidCallback? onRightButtonPressed,
    String title = '提示',
    String leftButtonText = '取消',
    String rightButtonText = '确定',
    Color? backgroundColor,
    Color? titleColor,
    Color? leftButtonColor = CupertinoColors.systemGrey,
    Color? rightButtonColor = CupertinoColors.systemBlue,
    double? borderRadius,
    double? elevation,
    double? barrierOpacity,
  }) async {
    return _showDialog(
      dialog: CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(color: titleColor),
        ),
        content: content,
        actions: _buildActions(
          leftButtonText: leftButtonText,
          rightButtonText: rightButtonText,
          leftButtonColor: leftButtonColor,
          rightButtonColor: rightButtonColor,
          onLeftButtonPressed: onLeftButtonPressed,
          onRightButtonPressed: onRightButtonPressed,
          isMaterial: false,
        ),
      ),
      barrierOpacity: barrierOpacity,
    );
  }

  static Future<MyDialogChosen> _showDialog({
    required Widget dialog,
    double? barrierOpacity,
  }) async {
    final result = await Get.dialog<MyDialogChosen>(
      dialog,
      barrierDismissible: true,
      barrierColor: barrierOpacity != null
          ? Colors.black.withValues(alpha: barrierOpacity)
          : null,
    );
    return result ?? MyDialogChosen.canceled;
  }

  static List<Widget> _buildActions({
    required String leftButtonText,
    required String rightButtonText,
    required Color? leftButtonColor,
    required Color? rightButtonColor,
    required VoidCallback? onLeftButtonPressed,
    required VoidCallback? onRightButtonPressed,
    required bool isMaterial,
  }) {
    void onLeftPressed() {
      if (onLeftButtonPressed != null) {
        onLeftButtonPressed();
      }
      Get.back(result: MyDialogChosen.left);
    }

    void onRightPressed() {
      if (onRightButtonPressed != null) {
        onRightButtonPressed();
      }
      Get.back(result: MyDialogChosen.right);
    }

    if (isMaterial) {
      return [
        TextButton(
          onPressed: onLeftPressed,
          style: ButtonStyle(
            overlayColor: leftButtonColor != null
                ? WidgetStateProperty.all(leftButtonColor.withValues(alpha: 0.1))
                : null,
          ),
          child: Text(
            leftButtonText,
            style: TextStyle(color: leftButtonColor),
          ),
        ),
        TextButton(
          onPressed: onRightPressed,
          style: ButtonStyle(
            overlayColor: rightButtonColor != null
                ? WidgetStateProperty.all(rightButtonColor.withValues(alpha: 0.1))
                : null,
          ),
          child: Text(
            rightButtonText,
            style: TextStyle(color: rightButtonColor),
          ),
        ),
      ];
    }

    return [
      CupertinoDialogAction(
        onPressed: onLeftPressed,
        child: Text(
          leftButtonText,
          style: TextStyle(color: leftButtonColor),
        ),
      ),
      CupertinoDialogAction(
        onPressed: onRightPressed,
        child: Text(
          rightButtonText,
          style: TextStyle(color: rightButtonColor),
        ),
      ),
    ];
  }
}
