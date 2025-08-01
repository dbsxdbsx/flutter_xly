import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// 自定义编辑框 测试页面
class Page7 extends StatelessWidget {
  const Page7({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Page7Controller>(
      init: Page7Controller(),
      builder: (controller) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '基础用法',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildBasicEditBoxes(controller),
                  SizedBox(height: 32.h),
                  Text(
                    '自定义样式',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildStyledEditBoxes(controller),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyButton(
                  icon: Icons.arrow_back,
                  text: '返回第6页',
                  onPressed: () => Get.back(),
                  size: 80.w,
                ),
                MyButton(
                  icon: Icons.system_update_alt,
                  text: '托盘功能',
                  onPressed: () => Get.toNamed('/page8'),
                  size: 80.w,
                  backgroundColor: Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicEditBoxes(Page7Controller controller) {
    return Column(
      children: [
        // 基础自定义编辑框
        MySpinBox(
          label: '基础自定义编辑框',
          initialValue: controller.basicValue,
          min: 0,
          max: 100,
          onChanged: controller.onBasicValueChanged,
        ),
        SizedBox(height: 16.h),
        // 可编辑的自定义编辑框
        MySpinBox(
          label: '可编辑的自定义编辑框（最大10000）',
          initialValue: controller.editableValue,
          min: 0,
          max: 10000,
          enableEdit: true,
          onChanged: controller.onEditableValueChanged,
        ),
        SizedBox(height: 16.h),
        // 带步长的自定义编辑框
        MySpinBox(
          label: '步长为5的自定义编辑框',
          initialValue: controller.steppedValue,
          min: 0,
          max: 100,
          step: 5,
          onChanged: controller.onSteppedValueChanged,
        ),
        SizedBox(height: 16.h),
        // 带后缀的自定义编辑框
        MySpinBox(
          label: '带后缀的自定义编辑框',
          initialValue: controller.suffixValue,
          min: 0,
          max: 100,
          suffix: 'px',
          onChanged: controller.onSuffixValueChanged,
        ),
      ],
    );
  }

  Widget _buildStyledEditBoxes(Page7Controller controller) {
    return Column(
      children: [
        // 自定义字体大小
        MySpinBox(
          label: '自定义字体大小',
          initialValue: controller.styledValue1,
          min: 0,
          max: 100,
          labelFontSize: 18.sp,
          centerTextFontSize: 16.sp,
          spinIconSize: 24.sp,
          onChanged: controller.onStyledValue1Changed,
        ),
        SizedBox(height: 16.h),
        // 自定义按钮大小
        MySpinBox(
          label: '自定义按钮大小',
          initialValue: controller.styledValue2,
          min: 0,
          max: 100,
          spinButtonSize: 40.w,
          spinIconSize: 28.sp,
          onChanged: controller.onStyledValue2Changed,
        ),
        SizedBox(height: 16.h),
        // 自定义内边距
        MySpinBox(
          label: '自定义内边距',
          initialValue: controller.styledValue3,
          min: 0,
          max: 100,
          inSetVerticalPadding: 16.h,
          inSetHorizontalPadding: 16.w,
          onChanged: controller.onStyledValue3Changed,
        ),
      ],
    );
  }
}

/// 自定义编辑框 测试页面控制器
class Page7Controller extends GetxController {
  // 基础自定义编辑框的值
  double basicValue = 50;
  double editableValue = 50;
  double steppedValue = 50;
  double suffixValue = 50;

  // 自定义样式编辑框的值
  double styledValue1 = 50;
  double styledValue2 = 50;
  double styledValue3 = 50;

  void onBasicValueChanged(double value) {
    basicValue = value;
    update();
  }

  void onEditableValueChanged(double value) {
    editableValue = value;
    update();
  }

  void onSteppedValueChanged(double value) {
    steppedValue = value;
    update();
  }

  void onSuffixValueChanged(double value) {
    suffixValue = value;
    update();
  }

  void onStyledValue1Changed(double value) {
    styledValue1 = value;
    update();
  }

  void onStyledValue2Changed(double value) {
    styledValue2 = value;
    update();
  }

  void onStyledValue3Changed(double value) {
    styledValue3 = value;
    update();
  }
}
