import 'package:flutter/material.dart';

/// 网络延迟（ping）显示样式，与路径 API 无关。
class MyDelayDisplay {
  MyDelayDisplay._();

  /// 根据延迟毫秒数返回展示文案与颜色。
  static ({String text, Color color}) textAndColor(BigInt? delay) {
    String displayText = '--';
    Color textColor = Colors.grey;

    if (delay == null) {
      return (text: displayText, color: textColor);
    }

    final delayValue = delay.toInt();

    if (delayValue < 0) {
      displayText = '--';
      textColor = Colors.grey;
    } else {
      displayText = '${delayValue}ms';
      if (delayValue < 100) {
        textColor = Colors.green;
      } else if (delayValue < 500) {
        textColor = Colors.orange;
      } else {
        textColor = Colors.red;
      }
    }

    return (text: displayText, color: textColor);
  }

  /// 根据 [pingTimeFuture] 构建延迟 [Text]。
  static Widget widget({
    required Future<BigInt?>? pingTimeFuture,
    double? fontSize,
    TextAlign textAlign = TextAlign.end,
  }) {
    return FutureBuilder<BigInt?>(
      future: pingTimeFuture,
      builder: (context, snapshot) {
        final delayInfo = textAndColor(
          snapshot.connectionState == ConnectionState.waiting
              ? null
              : snapshot.data,
        );

        return Text(
          delayInfo.text,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            color: delayInfo.color,
          ),
        );
      },
    );
  }
}
