import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ChosenOption { left, right, canceled }

class MyDialog {
  static Future<ChosenOption> show({
    required String content,
    required VoidCallback onLeftButtonPressed,
    VoidCallback? onRightButtonPressed,
    String title = '提示',
    String leftButtonText = '好的',
    String rightButtonText = '取消',
    Color backgroundColor = const Color(0xFF2C2C2C),
    Color titleColor = Colors.white,
    Color contentColor = Colors.white70,
    Color leftButtonColor = Colors.blueAccent,
    Color rightButtonColor = Colors.redAccent,
    double borderRadius = 12,
    double elevation = 8,
    double barrierOpacity = 0.5,
  }) async {
    return _showDialog(
      dialog: AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(content, style: TextStyle(color: contentColor)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)),
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

  static Future<ChosenOption> showIos({
    required String content,
    required VoidCallback onLeftButtonPressed,
    VoidCallback? onRightButtonPressed,
    String title = '提示',
    String leftButtonText = '好的',
    String rightButtonText = '取消',
    Color backgroundColor = Colors.white,
    Color titleColor = CupertinoColors.black,
    Color contentColor = CupertinoColors.black,
    Color leftButtonColor = CupertinoColors.systemBlue,
    Color rightButtonColor = CupertinoColors.systemRed,
    double borderRadius = 12,
    double elevation = 8,
    double barrierOpacity = 0.5,
  }) async {
    return _showDialog(
      dialog: CupertinoAlertDialog(
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(content, style: TextStyle(color: contentColor)),
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

  static Future<ChosenOption> _showDialog({
    required Widget dialog,
    required double barrierOpacity,
  }) async {
    final result = await Get.dialog<ChosenOption>(
      dialog,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(barrierOpacity),
    );
    return result ?? ChosenOption.canceled;
  }

  static List<Widget> _buildActions({
    required String leftButtonText,
    required String rightButtonText,
    required Color leftButtonColor,
    required Color rightButtonColor,
    required VoidCallback onLeftButtonPressed,
    required VoidCallback? onRightButtonPressed,
    required bool isMaterial,
  }) {
    void onLeftPressed() {
      onLeftButtonPressed();
      Get.back(result: ChosenOption.left);
    }

    void onRightPressed() {
      if (onRightButtonPressed != null) {
        onRightButtonPressed();
      }
      Get.back(result: ChosenOption.right);
    }

    if (isMaterial) {
      return [
        TextButton(
          onPressed: onLeftPressed,
          style: ButtonStyle(
            overlayColor:
                WidgetStateProperty.all(leftButtonColor.withOpacity(0.1)),
          ),
          child: Text(leftButtonText, style: TextStyle(color: leftButtonColor)),
        ),
        TextButton(
          onPressed: onRightPressed,
          style: ButtonStyle(
            overlayColor:
                WidgetStateProperty.all(rightButtonColor.withOpacity(0.1)),
          ),
          child:
              Text(rightButtonText, style: TextStyle(color: rightButtonColor)),
        ),
      ];
    }

    return [
      CupertinoDialogAction(
        onPressed: onLeftPressed,
        child: Text(leftButtonText, style: TextStyle(color: leftButtonColor)),
      ),
      CupertinoDialogAction(
        onPressed: onRightPressed,
        child: Text(rightButtonText, style: TextStyle(color: rightButtonColor)),
      ),
    ];
  }
}
