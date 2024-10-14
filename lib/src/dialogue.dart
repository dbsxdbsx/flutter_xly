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
    Color backgroundColor = const Color(0xFF2C2C2C), // 更深的背景色
    Color titleColor = Colors.white,
    Color contentColor = Colors.white70,
    Color leftButtonColor = Colors.blueAccent, // 更亮的蓝色
    Color rightButtonColor = Colors.redAccent, // 更亮的红色
    double borderRadius = 12,
    double elevation = 8,
    double barrierOpacity = 0.5,
  }) async {
    final result = await Get.dialog<ChosenOption>(
      AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(title, style: TextStyle(color: titleColor)),
        content: Text(content, style: TextStyle(color: contentColor)),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius)),
        elevation: elevation,
        actions: <Widget>[
          TextButton(
            onPressed: () {
              onLeftButtonPressed();
              Get.back(result: ChosenOption.left);
            },
            style: ButtonStyle(
              overlayColor:
                  WidgetStateProperty.all(leftButtonColor.withOpacity(0.1)),
            ),
            child:
                Text(leftButtonText, style: TextStyle(color: leftButtonColor)),
          ),
          TextButton(
            onPressed: () {
              if (onRightButtonPressed != null) {
                onRightButtonPressed();
              }
              Get.back(result: ChosenOption.right);
            },
            style: ButtonStyle(
              overlayColor:
                  WidgetStateProperty.all(rightButtonColor.withOpacity(0.1)),
            ),
            child: Text(rightButtonText,
                style: TextStyle(color: rightButtonColor)),
          ),
        ],
      ),
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(barrierOpacity),
    );

    return result ?? ChosenOption.canceled;
  }

  static Future<ChosenOption> showIos({
    String title = '提示',
    required String content,
    String leftButtonText = '是',
    String rightButtonText = '否',
    required VoidCallback onLeftButtonPressed,
    VoidCallback? onRightButtonPressed,
  }) async {
    final result = await Get.dialog<ChosenOption>(
      CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <Widget>[
          CupertinoDialogAction(
            child: Text(leftButtonText),
            onPressed: () {
              onLeftButtonPressed();
              Get.back(result: ChosenOption.left);
            },
          ),
          CupertinoDialogAction(
            child: Text(rightButtonText),
            onPressed: () {
              if (onRightButtonPressed != null) {
                onRightButtonPressed();
              }
              Get.back(result: ChosenOption.right);
            },
          ),
        ],
      ),
      barrierDismissible: true,
    );

    return result ?? ChosenOption.canceled;
  }
}
