import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../logger.dart';

enum MyDialogChosen { left, right, canceled }

class MyDialog {
  static Future<MyDialogChosen> show({
    required Widget content,
    FutureOr<void> Function()? onLeftButtonPressed,
    FutureOr<void> Function()? onRightButtonPressed,
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
    bool barrierDismissible = true,
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
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<MyDialogChosen> showIos({
    required Widget content,
    FutureOr<void> Function()? onLeftButtonPressed,
    FutureOr<void> Function()? onRightButtonPressed,
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
    bool barrierDismissible = true,
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
      barrierDismissible: barrierDismissible,
    );
  }

  static Future<MyDialogChosen> _showDialog({
    required Widget dialog,
    double? barrierOpacity,
    bool barrierDismissible = true,
  }) async {
    final result = await Get.dialog<MyDialogChosen>(
      dialog,
      barrierDismissible: barrierDismissible,
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
    required FutureOr<void> Function()? onLeftButtonPressed,
    required FutureOr<void> Function()? onRightButtonPressed,
    required bool isMaterial,
  }) {
    Future<void> onLeftPressed() async {
      if (onLeftButtonPressed != null) {
        try {
          await onLeftButtonPressed();
        } catch (e, s) {
          XlyLogger.error('onLeftButtonPressed error', e, s);
        }
      }
      Get.back(result: MyDialogChosen.left);
    }

    Future<void> onRightPressed() async {
      if (onRightButtonPressed != null) {
        try {
          await onRightButtonPressed();
        } catch (e, s) {
          XlyLogger.error('onRightButtonPressed error', e, s);
        }
      }
      Get.back(result: MyDialogChosen.right);
    }

    if (isMaterial) {
      return [
        TextButton(
          onPressed: onLeftPressed,
          style: ButtonStyle(
            overlayColor: leftButtonColor != null
                ? WidgetStateProperty.all(
                    leftButtonColor.withValues(alpha: 0.1))
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
                ? WidgetStateProperty.all(
                    rightButtonColor.withValues(alpha: 0.1))
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
