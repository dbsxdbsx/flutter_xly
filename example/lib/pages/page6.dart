import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

class Page6View extends GetView<Page6Controller> {
  const Page6View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('文本编辑器测试', style: TextStyle(fontSize: 18.sp)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('基础文本编辑器'),
            SizedBox(height: 16.h),
            _buildBasicEditors(),
            SizedBox(height: 24.h),
            _buildSectionTitle('带下拉列表的编辑器'),
            SizedBox(height: 16.h),
            _buildDropdownEditors(),
            SizedBox(height: 24.h),
            _buildSectionTitle('自定义样式编辑器'),
            SizedBox(height: 16.h),
            _buildStyledEditors(),
            SizedBox(height: 24.h),
            Center(
              child: MyButton(
                icon: Icons.arrow_back,
                text: '返回上一页',
                onPressed: () => Get.back(),
              ),
            ),
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

  Widget _buildBasicEditors() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: MyTextEditor(
                  textController: controller.basicController,
                  label: '基础输入',
                  hint: '请输入文本',
                  clearable: true,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: MyTextEditor(
                  textController: controller.numberController,
                  label: '数字输入',
                  hint: '请输入数字',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        MyTextEditor(
          textController: controller.multilineController,
          label: '多行输入',
          hint: '请输入多行文本',
          maxLines: 3,
          height: 100.h,
        ),
      ],
    );
  }

  Widget _buildDropdownEditors() {
    return Column(
      children: [
        MyTextEditor(
          textController: controller.colorController,
          label: '颜色选择',
          hint: '选择或输入颜色',
          getDropDownOptions: controller.getColors,
          onOptionSelected: (value) => controller.colorController.text = value,
          leadingBuilder: (option) => Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: controller.getColorFromName(option),
              shape: BoxShape.circle,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        MyTextEditor(
          textController: controller.countryController,
          label: '国家选择',
          hint: '选择或输入国家',
          getDropDownOptions: controller.getCountries,
          onOptionSelected: (value) =>
              controller.countryController.text = value,
          leadingBuilder: (option) => Icon(
            Icons.flag,
            size: 20.w,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStyledEditors() {
    return Column(
      children: [
        MyTextEditor(
          textController: controller.styledController1,
          label: '自定义样式输入框',
          hint: '自定义样式输入框',
          clearable: true,
          onCleared: () => MyToast.show('清除了自定义样式输入框的内容'),
          borderRadius: 50.r,
          borderWidth: 2,
          backgroundColor: Colors.blue[50],
          focusedBorderColor: Colors.blue,
        ),
        SizedBox(height: 16.h),
        MyTextEditor(
          textController: controller.styledController2,
          label: '自定义边框颜色',
          hint: '红色边框示例',
          normalBorderColor: Colors.red,
          enabledBorderColor: Colors.red,
          focusedBorderColor: Colors.red,
        ),
        SizedBox(height: 16.h),
        MyTextEditor(
          textController: controller.styledController3,
          label: '自定义标签颜色',
          hint: '绿色标签示例',
          labelColor: Colors.green,
          focusedBorderColor: Colors.green,
        ),
      ],
    );
  }
}

class Page6Controller extends GetxController {
  final basicController = TextEditingController();
  final numberController = TextEditingController();
  final multilineController = TextEditingController();
  final colorController = TextEditingController();
  final countryController = TextEditingController();
  final styledController1 = TextEditingController();
  final styledController2 = TextEditingController();
  final styledController3 = TextEditingController();

  @override
  void onClose() {
    basicController.dispose();
    numberController.dispose();
    multilineController.dispose();
    colorController.dispose();
    countryController.dispose();
    styledController1.dispose();
    styledController2.dispose();
    styledController3.dispose();
    super.onClose();
  }

  Future<List<String>> getColors() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      '红色',
      '蓝色',
      '绿色',
      '黄色',
      '紫色',
      '橙色',
      '粉色',
      '棕色',
    ];
  }

  Color getColorFromName(String name) {
    switch (name) {
      case '红色':
        return Colors.red;
      case '蓝色':
        return Colors.blue;
      case '绿色':
        return Colors.green;
      case '黄色':
        return Colors.yellow;
      case '紫色':
        return Colors.purple;
      case '橙色':
        return Colors.orange;
      case '粉色':
        return Colors.pink;
      case '棕色':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  Future<List<String>> getCountries() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      '中国',
      '美国',
      '日本',
      '韩国',
      '英国',
      '法国',
      '德国',
      '意大利',
      '俄罗斯',
      '加拿大',
    ];
  }
}
