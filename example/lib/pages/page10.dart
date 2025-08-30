import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../widgets/section_title.dart';

class Page10Controller extends GetxController {}

class Page10View extends GetView<Page10Controller> {
  const Page10View({super.key});

  Widget _buildTitle(String text) => SectionTitle(
        text,
        fontSize: 16.sp,
        padding: EdgeInsets.symmetric(vertical: 8.h),
      );

  Widget _demoCard(String title, Widget child) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[800])),
          SizedBox(height: 8.h),
          child,
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Transform.translate(
      offset: Offset(4.w, 4.h),
      child: SizedBox(
        height: 20.w,
        width: 20.w,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: MyLoadingDot.typing(
              size: 6.w,
              gap: 2.w,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyLoadingDot 演示'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitle('兼容“正在输入”调用方式'),
            _demoCard(
                '默认typing() 适配示例',
                Row(children: [
                  _buildLoadingIndicator(),
                  SizedBox(width: 8.w),
                  const Text('AI 正在输入…'),
                ])),
            _buildTitle('变体与尺寸'),
            _demoCard(
                'fade - 基础呼吸',
                Row(children: [
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.fade,
                      size: 6.w,
                      gap: 2.w,
                      color: Colors.grey),
                  SizedBox(width: 16.w),
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.fade,
                      size: 10.w,
                      gap: 3.w,
                      color: Colors.blue),
                  SizedBox(width: 16.w),
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.fade,
                      size: 14.w,
                      gap: 4.w,
                      color: Colors.green),
                ])),
            _demoCard(
                'bounce - 竖直弹跳',
                Row(children: [
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.bounce,
                      size: 6.w,
                      gap: 2.w,
                      color: Colors.deepOrange),
                  SizedBox(width: 16.w),
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.bounce,
                      size: 10.w,
                      gap: 3.w,
                      color: Colors.purple),
                ])),
            _demoCard(
                'scale - 缩放脉冲',
                Row(children: [
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.scale,
                      size: 8.w,
                      gap: 3.w,
                      color: Colors.teal),
                  SizedBox(width: 16.w),
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.scale,
                      size: 12.w,
                      gap: 4.w,
                      color: Colors.redAccent),
                ])),
            _demoCard(
                'wave - 轻微波动',
                Row(children: [
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.wave,
                      size: 8.w,
                      gap: 3.w,
                      color: Colors.indigo),
                  SizedBox(width: 16.w),
                  MyLoadingDot(
                      dotAnimation: MyLoadingDotAnimation.wave,
                      size: 12.w,
                      gap: 4.w,
                      color: Colors.brown),
                ])),
            _buildTitle('自定义参数：dotCount/period/phaseShift'),
            _demoCard(
                '5个点 + 更慢节奏',
                MyLoadingDot(
                  dotCount: 5,
                  period: const Duration(milliseconds: 1400),
                  phaseShift: 0.2,
                  size: 8.w,
                  gap: 2.w,
                  color: Colors.blueGrey,
                  dotAnimation: MyLoadingDotAnimation.fade,
                )),
          ],
        ),
      ),
    );
  }
}
