import 'package:example/main.dart';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page2View extends GetView<Page2Controller> {
  const Page2View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('第2页')),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('图标位置测试（普通样式）'),
            SizedBox(height: 16.h),
            _buildIconPositionTests(),
            SizedBox(height: 24.h),
            _buildSectionTitle('按钮形状测试'),
            SizedBox(height: 16.h),
            _buildShapeTests(),
            SizedBox(height: 24.h),
            _buildSectionTitle('其他样式测试'),
            SizedBox(height: 16.h),
            _buildOtherStyleTests(),
            const Spacer(),
            _buildFocusableText(),
            SizedBox(height: 24.h),
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildIconPositionTests() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MyButton(
          text: '左图标',
          onPressed: () => MyToast.show('左图标按钮被点击'),
          icon: Icons.arrow_back,
          iconPosition: MyIconPosition.left,
        ).setFocus(focusKey: 'left_icon_button'),
        MyButton(
          text: '右图标',
          onPressed: () => MyToast.show('右图标按钮被点击'),
          icon: Icons.arrow_forward,
          iconPosition: MyIconPosition.right,
        ).setFocus(focusKey: 'right_icon_button'),
        MyButton(
          text: '上图标',
          onPressed: () => MyToast.show('上图标按钮被点击'),
          icon: Icons.arrow_upward,
          iconPosition: MyIconPosition.top,
          size: 58,
        ).setFocus(focusKey: 'top_icon_button'),
        MyButton(
          text: '下图标',
          onPressed: () => MyToast.show('下图标按钮被点击'),
          icon: Icons.arrow_downward,
          iconPosition: MyIconPosition.bottom,
          size: 58,
        ).setFocus(focusKey: 'bottom_icon_button'),
      ],
    );
  }

  Widget _buildShapeTests() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        MyButton(
          text: '普通',
          onPressed: () => MyToast.show('普通按钮被点击'),
          icon: Icons.touch_app,
          shape: MyButtonShape.normal,
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 8,
          cornerRadius: 0.8,
        ).setFocus(focusKey: 'normal_button'),
        MyButton(
          text: '立方体',
          onPressed: () => MyToast.show('立方体按钮被点击'),
          icon: Icons.view_in_ar,
          shape: MyButtonShape.cube,
          size: 70,
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black87,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.amber.shade300, Colors.amber.shade700],
          ),
        ).setFocus(focusKey: 'cube_button'),
        MyButton(
          text: '圆形',
          onPressed: () => MyToast.show('圆形按钮被点击'),
          icon: Icons.radio_button_checked,
          shape: MyButtonShape.round,
          size: 70,
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 10,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.green.shade300, Colors.green.shade700],
          ),
        ).setFocus(focusKey: 'round_button'),
        MyButton(
          text: '立方',
          onPressed: () => MyToast.show('简单立方按钮被点击'),
          icon: Icons.crop_square,
          shape: MyButtonShape.cube,
        ).setFocus(focusKey: 'simple_cube_button'),
        MyButton(
          text: '圆形',
          onPressed: () => MyToast.show('简单圆形按钮被点击'),
          icon: Icons.circle_outlined,
          shape: MyButtonShape.round,
        ).setFocus(focusKey: 'simple_round_button'),
      ],
    );
  }

  Widget _buildOtherStyleTests() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MyButton(
          text: '渐变背景',
          onPressed: () => MyToast.show('渐变背景按钮被点击'),
          icon: Icons.gradient,
          shape: MyButtonShape.normal, // 确保使用普通形状
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.pink, Colors.purple, Colors.green],
          ),
        ).setFocus(focusKey: 'gradient_button'),
        MyButton(
          text: '自定义轮廓',
          onPressed: () => MyToast.show('自定义轮廓按钮被点击'),
          icon: Icons.brush,
          outlineColor: Colors.red,
          outlineWidth: 2,
        ).setFocus(focusKey: 'custom_outline_button'),
        MyButton(
          text: '圆角普通',
          onPressed: () => MyToast.show('圆角普通按钮被点击'),
          icon: Icons.rounded_corner,
          shape: MyButtonShape.normal,
          cornerRadius: 1.0, // 最大圆角
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ).setFocus(focusKey: 'rounded_normal_button'),
        MyButton(
          text: '圆角立方',
          onPressed: () => MyToast.show('圆角立方按钮被点击'),
          icon: Icons.view_in_ar,
          shape: MyButtonShape.cube,
          size: 70,
          cornerRadius: 1.0, // 最大圆角
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
        ).setFocus(focusKey: 'rounded_cube_button'),
        MyButton(
          text: '锐角立方',
          onPressed: () => MyToast.show('锐角立方按钮被点'),
          icon: Icons.change_history,
          shape: MyButtonShape.cube,
          size: 70,
          cornerRadius: 0.1, // 设置较小的圆角半径
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ).setFocus(focusKey: 'sharp_cube_button'),
      ],
    );
  }

  Widget _buildFocusableText() {
    return Text(
      '这是一个可聚焦的文本',
      style: TextStyle(fontSize: 18.sp),
    ).setFocus(
      focusKey: 'focusable_text',
      onPressed: () => MyToast.show('文本被聚焦并点击'),
      opacity: true,
      focusedBorderColor: Colors.green,
      borderWidth: 2,
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MyButton(
          icon: Icons.arrow_back,
          text: '返回第1页',
          onPressed: controller.goToPage1,
        ).setFocus(focusKey: 'go_back_button'),
        MyButton(
          icon: Icons.arrow_forward,
          text: '前往第3页',
          onPressed: controller.goToPage3,
        ).setFocus(focusKey: 'go_to_page3_button'),
      ],
    );
  }
}

class Page2Controller extends GetxController {
  final focusController = Get.put(XlyFocusController());

  void goToPage1() {
    goToPage(Routes.page1);
  }

  void goToPage3() {
    goToPage(Routes.page3);
  }
}
