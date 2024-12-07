import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

/// 文本编辑器测试页面
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
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Center(
      child: MyButton(
        icon: Icons.arrow_back,
        text: '返回上一页',
        onPressed: () => Get.back(),
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
          // maxShowDropDownItems: 6,
          getDropDownOptions: controller.getColors,
          onOptionSelected: controller.onColorSelected,
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
          onOptionSelected: controller.onCountrySelected,
          leadingBuilder: (option) => Flag.fromCode(
            controller.getCountryCode(option),
            width: 24.w,
            height: 24.w,
            borderRadius: 4,
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
          onCleared: controller.onStyled1Cleared,
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

/// 文本编辑器测试页面控制器
class Page6Controller extends GetxController {
  // 文本控制器
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
    _disposeControllers();
    super.onClose();
  }

  void _disposeControllers() {
    basicController.dispose();
    numberController.dispose();
    multilineController.dispose();
    colorController.dispose();
    countryController.dispose();
    styledController1.dispose();
    styledController2.dispose();
    styledController3.dispose();
  }

  // 回调方法
  void onColorSelected(String value) => colorController.text = value;
  void onCountrySelected(String value) => countryController.text = value;
  void onStyled1Cleared() => MyToast.show('清除了自定义样式输入框的内容');

  /// 获取颜色选项列表
  Future<List<String>> getColors() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return [
      '红色',
      '深红色',
      '粉红色',
      '蓝色',
      '深蓝色',
      '浅蓝色',
      '绿色',
      '深绿色',
      '浅绿色',
      '黄色',
      '金色',
      '橙色',
      '紫色',
      '深紫色',
      '粉色',
      '棕色',
      '深棕色',
      '灰色',
      '深灰色',
      '浅灰色',
      '青色',
      '深青色',
      '琥珀色',
      '靛蓝色',
      '石灰色',
      '栗色',
      '橄榄绿',
      '珊瑚色',
      '天蓝色',
      '蓝绿色',
    ];
  }

  /// 根据颜色名称获取对应的Color对象
  Color getColorFromName(String name) {
    const defaultColor = Colors.grey;
    final colorMap = {
      '红色': Colors.red,
      '深红色': Colors.red[900],
      '粉红色': Colors.red[200],
      '蓝色': Colors.blue,
      '深蓝色': Colors.blue[900],
      '浅蓝色': Colors.blue[200],
      '绿色': Colors.green,
      '深绿色': Colors.green[900],
      '浅绿色': Colors.green[200],
      '黄色': Colors.yellow,
      '金色': Colors.amber,
      '橙色': Colors.orange,
      '紫色': Colors.purple,
      '深紫色': Colors.purple[900],
      '粉色': Colors.pink,
      '棕色': Colors.brown,
      '深棕色': Colors.brown[900],
      '灰色': Colors.grey,
      '深灰色': Colors.grey[800],
      '浅灰色': Colors.grey[300],
      '青色': Colors.cyan,
      '深青色': Colors.cyan[900],
      '琥珀色': Colors.amber[700],
      '靛蓝色': Colors.indigo,
      '石灰色': Colors.lime,
      '栗色': Colors.brown[600],
      '橄榄绿': const Color(0xFF808000),
      '珊瑚色': Colors.deepOrange[200],
      '天蓝色': Colors.lightBlue,
      '蓝绿色': Colors.teal,
    };
    return colorMap[name] ?? defaultColor;
  }

  /// 获取国家选项列表
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

  /// 根据国家名称获取对应的国家代码
  FlagsCode getCountryCode(String countryName) {
    final countryCodeMap = {
      '中国': FlagsCode.CN,
      '美国': FlagsCode.US,
      '日本': FlagsCode.JP,
      '韩国': FlagsCode.KR,
      '英国': FlagsCode.GB,
      '法国': FlagsCode.FR,
      '德国': FlagsCode.DE,
      '意大利': FlagsCode.IT,
      '俄罗斯': FlagsCode.RU,
      '加拿大': FlagsCode.CA,
    };

    return countryCodeMap[countryName] ?? FlagsCode.UN;
  }
}
