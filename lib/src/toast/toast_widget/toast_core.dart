import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Toast extends StatelessWidget {
  final Widget child;
  final bool dismissOthers;
  final Duration duration;
  final Alignment alignment;
  final Duration animationDuration;
  final Curve animationCurve;

  const Toast({
    super.key,
    required this.child,
    this.dismissOthers = false,
    required this.duration,
    required this.alignment,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
  });

  static final RxList<_ToastEntry> _toasts = <_ToastEntry>[].obs;

  static void show(
    Widget widget, {
    bool dismissOthers = false,
    Duration duration = const Duration(seconds: 2),
    Alignment alignment = Alignment.center,
    Duration animationDuration = const Duration(milliseconds: 200),
    Curve animationCurve = Curves.easeOutCubic,
    Key? key,
  }) {
    if (dismissOthers) {
      dismissAll();
    }

    final entry = _ToastEntry(
      widget: widget,
      duration: duration,
      alignment: alignment,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      key: key,
    );
    _toasts.add(entry);

    if (duration != const Duration(days: 365)) {
      Future.delayed(duration, () {
        _toasts.remove(entry);
      });
    }
  }

  static void dismiss(Key key) {
    _toasts.removeWhere((entry) => entry.key == key);
  }

  static void dismissAll() {
    _toasts.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          child,
          Obx(() => Stack(
                textDirection: TextDirection.ltr,
                children: _toasts.map((entry) {
                  return Positioned.fill(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: entry.animationDuration,
                      curve: entry.animationCurve,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0.0, 20.0 * (1 - value)),
                            child: child!,
                          ),
                        );
                      },
                      child: Container(
                        alignment: entry.alignment,
                        padding: const EdgeInsets.all(16),
                        child: entry.widget,
                      ),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }
}

class _ToastEntry {
  final Widget widget;
  final Duration duration;
  final Alignment alignment;
  final Duration animationDuration;
  final Curve animationCurve;
  final Key? key;

  _ToastEntry({
    required this.widget,
    required this.duration,
    required this.alignment,
    required this.animationDuration,
    required this.animationCurve,
    this.key,
  });
}
