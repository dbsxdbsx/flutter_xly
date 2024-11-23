import 'package:example/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page1View extends GetView<Page1Controller> {
  const Page1View({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('第1页')),
          body: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('按钮测试'),
                SizedBox(height: 16.h),
                _buildButtonSection(),
                SizedBox(height: 24.h),
                _buildSectionTitle('菜单按钮测试'),
                SizedBox(height: 16.h),
                _buildMenuButtonSection(),
                SizedBox(height: 24.h),
                _buildSectionTitle('窗口控制测试'),
                SizedBox(height: 16.h),
                _buildWindowControlSection(),
                SizedBox(height: 24.h),
                _buildToastTestSection(),
                const Spacer(),
                _buildNavigationSection(),
              ],
            ),
          ),
        ).showRightMenu(
          context: context,
          menuElements: _buildRightMenuItems(),
          style: const MyMenuStyle(shadowRatio: 0.2),
        ),
        MyFloatPanel(
          panelWidth: 60,
          backgroundColor: const Color(0xFF222222),
          panelShape: PanelShape.rectangle,
          borderRadius: BorderRadius.circular(10),
          dockType: DockType.outside,
          panelButtonColor: Colors.blueGrey,
          customButtonColor: Colors.grey,
          dockActivate: true,
          items: [
            MyFloatPanelItem(
              icon: CupertinoIcons.news,
              onPressed: () => controller.onToolButtonPressed('新游戏按钮被点击'),
            ),
            MyFloatPanelItem(
              icon: CupertinoIcons.person,
              onPressed: () => controller.onToolButtonPressed('新AI按钮被点击'),
            ),
            MyFloatPanelItem(
              icon: CupertinoIcons.settings,
              onPressed: () => controller.getSettingSheet(context),
            ),
            MyFloatPanelItem(
              icon: CupertinoIcons.link,
              onPressed: () => controller.onToolButtonPressed('新链接按钮被点击'),
            ),
            MyFloatPanelItem(
              icon: CupertinoIcons.minus,
              onPressed: () => controller.minimizeWindow(),
            ),
            MyFloatPanelItem.divider(), // 添加分隔符
            MyFloatPanelItem(
              icon: CupertinoIcons.xmark_circle,
              onPressed: () => controller.showExitConfirmation(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        MyButton(
          text: '打开默认（安卓）风格对话框',
          onPressed: () => _showDialog(false),
        ),
        MyButton(
          text: '打开iOS风格对话框',
          onPressed: () => _showDialog(true),
        ),
      ],
    );
  }

  void _showDialog(bool isIos) {
    final showMethod = isIos ? MyDialog.showIos : MyDialog.show;
    showMethod(
      content: Text('这是一个${isIos ? 'iOS 风格的' : ''}测试对话框'),
    ).then((result) {
      switch (result) {
        case MyDialogChosen.left:
          MyToast.show('选择了${isIos ? '否' : '取消'}');
          break;
        case MyDialogChosen.right:
          MyToast.show('选择了${isIos ? '是' : '确定'}');
          break;
        case MyDialogChosen.canceled:
          MyToast.show('对话框被关闭');
          break;
      }
    });
  }

  Widget _buildMenuButtonSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Obx(() => MyMenuButton(
              iconSize: 30.w,
              iconColor: Colors.blue,
              isPressed: controller.isMenuButtonActivated.value,
              menuItems: _buildComplexMenuItems(),
            )),
        MyMenuButton(
          icon: Icons.more_vert,
          iconSize: 25.w,
          iconColor: Colors.green,
          menuItems: _buildSimpleMenuItems(),
        ),
        MyButton(
          text: '切换菜单按钮状态',
          onPressed: controller.toggleMenuButtonState,
        ),
      ],
    );
  }

  Widget _buildNavigationSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: MyButton(
            text: '前往第2页',
            onPressed: controller.goToPage2,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: MyButton(
            text: '退出应用',
            onPressed: controller.confirmExitApp,
          ),
        ),
      ],
    );
  }

  List<MyMenuItem> _buildComplexMenuItems() {
    return [
      MyMenuItem(
        icon: Icons.engineering,
        text: '加载内置引擎',
        onTap: () {
          MyToast.show('选择了加载内置引擎');
          controller.toggleMenuButtonState();
        },
      ),
      MyMenuItem(
        text: '加载自定义引擎',
        onTap: () => MyToast.show('加载自定义引擎功能暂未开放'),
      ),
      MyMenuItem(
        icon: Icons.settings,
        text: '高级选项',
        subItems: _buildAdvancedOptions(),
      ),
    ];
  }

  List<MyMenuItem> _buildAdvancedOptions() {
    return [
      MyMenuItem(
        icon: Icons.speed,
        text: '性能设置',
        onTap: () => MyToast.show('打开性能设置'),
      ),
      MyMenuItem(
        icon: Icons.security,
        text: '安全选项',
        onTap: () => MyToast.show('开安全选项'),
      ),
      MyMenuItem(
        icon: Icons.build,
        text: '开发者工具',
        subItems: _buildDeveloperTools(),
      ),
    ];
  }

  List<MyMenuItem> _buildDeveloperTools() {
    return [
      MyMenuItem(
        icon: Icons.bug_report,
        text: '调试模式',
        onTap: () => MyToast.show('开启调试模式'),
      ),
      MyMenuItem(
        icon: Icons.code,
        text: '控制台',
        onTap: () => MyToast.show('打开控制台'),
      ),
    ];
  }

  List<MyMenuItem> _buildSimpleMenuItems() {
    return [
      MyMenuItem(
        text: '选项A',
        icon: Icons.star,
        onTap: () => MyToast.show('选择了选项A'),
      ),
      MyMenuItem(
        text: '选项B',
        icon: Icons.favorite,
        onTap: () => MyToast.show('选择了选项B'),
      ),
    ];
  }

  List<MyMenuElement> _buildRightMenuItems() {
    return [
      MyMenuItem(
        text: '选项1',
        onTap: () => MyToast.show('选择了选项1'),
      ),
      MyMenuDivider(),
      MyMenuItem(
        icon: Icons.looks_two,
        text: '选项2！',
        onTap: () => MyToast.show('选择了选项2'),
      ),
      MyMenuDivider(),
      MyMenuItem(
        icon: Icons.more_horiz,
        text: '多选项',
        subItems: _buildMultiOptions(),
      ),
    ];
  }

  List<MyMenuElement> _buildMultiOptions() {
    return [
      MyMenuItem(
        icon: Icons.info,
        text: '关于',
        subItems: _buildAboutOptions(),
      ),
      MyMenuDivider(thicknessMultiplier: 0.7),
      MyMenuItem(
        icon: Icons.help,
        text: '帮助',
        subItems: _buildHelpOptions(),
      ),
      MyMenuItem(
        icon: Icons.settings,
        text: '设置',
        subItems: _buildSettingsOptions(),
      ),
    ];
  }

  List<MyMenuItem> _buildAboutOptions() {
    return [
      MyMenuItem(
        icon: Icons.info_outline,
        text: '版本信息',
        onTap: () => MyToast.show('显示版本信息'),
      ),
      MyMenuItem(
        icon: Icons.contact_support,
        text: '联系我们',
        onTap: () => MyToast.show('显示联系方式'),
      ),
    ];
  }

  List<MyMenuItem> _buildHelpOptions() {
    return [
      MyMenuItem(
        icon: Icons.help_outline,
        text: '常见问题',
        onTap: () => MyToast.show('显示常见问题'),
      ),
      MyMenuItem(
        icon: Icons.book,
        text: '用户手册',
        onTap: () => MyToast.show('打开用户手册'),
      ),
    ];
  }

  List<MyMenuElement> _buildSettingsOptions() {
    return [
      MyMenuItem(
        icon: Icons.language,
        text: '语言设置',
        onTap: () => MyToast.show('打开语言设置'),
      ),
      MyMenuDivider(),
      MyMenuItem(
        icon: Icons.color_lens,
        text: '主题设置',
        onTap: () => MyToast.show('打开主题设置'),
      ),
    ];
  }

  Widget _buildWindowControlSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Obx(() => MyButton(
                text: '允许拖动窗口: ${MyApp.isDraggableEnabled() ? "已开启" : "已关闭"}',
                onPressed: controller.toggleDraggable,
              )),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Obx(() => MyButton(
                text:
                    '允许手动调整窗口尺寸: ${MyApp.isResizableEnabled() ? "已开启" : "已关闭"}',
                onPressed: controller.toggleWindowControls,
              )),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Obx(() => MyButton(
                text:
                    '允许双击最大化: ${MyApp.isDoubleClickFullScreenEnabled() ? "已开启" : "已关闭"}',
                onPressed: controller.toggleDoubleClickFullScreen,
              )),
        ),
      ],
    );
  }

  Widget _buildToastTestSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Toast测试'),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: MyButton(
                text: '连续显示多条Toast',
                onPressed: controller.showToast,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: MyButton(
                text: '显示顶部警告',
                onPressed: () => controller.showUpWarnToast(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: MyButton(
                text: '显示顶部错误',
                onPressed: () => controller.showUpErrorToast(),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: MyButton(
                text: '显示顶部提示',
                onPressed: () => controller.showUpInfoToast(),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: MyButton(
                text: '显示底部提示',
                onPressed: () => controller.showBottomToast(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class Page1Controller extends GetxController {
  final isMenuButtonActivated = false.obs;
  final isWindowControlEnabled = MyApp.isResizableEnabled().obs;
  final enableDoubleClickFullScreen =
      MyApp.isDoubleClickFullScreenEnabled().obs;
  final enableDraggable = MyApp.isDraggableEnabled().obs;

  void toggleMenuButtonState() {
    isMenuButtonActivated.value = !isMenuButtonActivated.value;
  }

  void goToPage2() {
    goToPage(Routes.page2);
  }

  void showToast() async {
    MyToast.show('这是一条测试Toast消息1');
    await Future.delayed(const Duration(seconds: 1));
    MyToast.show('这是一条测试Toast消息2');
    await Future.delayed(const Duration(seconds: 1));
    MyToast.show('这是一条测试Toast消息3', stackToasts: true);
  }

  void confirmExitApp() async {
    final result = await MyDialog.show(
      content: const Text('确定要退出应用吗？'),
      leftButtonText: '取消',
      rightButtonText: '确定',
    );

    if (result == MyDialogChosen.right) {
      await MyApp.exit();
    }
  }

  void onToolButtonPressed(String message) {
    MyToast.show(message);
  }

  void getSettingSheet(BuildContext context) {
    // 实现设置面板的逻辑
    MyToast.show('打开设置面板');
  }

  void minimizeWindow() {
    // 实现最小化窗口的逻辑
    MyToast.show('窗口已最小化');
  }

  void showExitConfirmation(BuildContext context) async {
    final result = await MyDialog.showIos(
      content: const Text('是否退出程序？'),
    );

    if (result == MyDialogChosen.left) {
      await MyApp.exit();
    }
  }

  void toggleWindowControls() async {
    // 获取当前状态的反状态
    final newState = !MyApp.isResizableEnabled();

    // 设置新状态
    await MyApp.setResizableEnabled(newState);

    // 更新本地状态以保持UI同步
    isWindowControlEnabled.value = newState;

    // 显示提示
    MyToast.show('允许手动调整窗口尺寸${newState ? "已启用" : "已禁用"}');
  }

  void toggleDoubleClickFullScreen() async {
    // 获取当前状态的反状态
    final newState = !MyApp.isDoubleClickFullScreenEnabled();

    // 设置新状态
    await MyApp.setDoubleClickFullScreenEnabled(newState);

    // 更新本地状态以保持UI同步
    enableDoubleClickFullScreen.value = newState;

    // 显示提示
    MyToast.show('允许双击最大化${newState ? "已启用" : "已禁用"}');
  }

  void toggleDraggable() async {
    // 获取当前状态的反状态
    final newState = !MyApp.isDraggableEnabled();

    // 设置新状态
    await MyApp.setDraggableEnabled(newState);

    // 更新本地状态以保持UI同步
    enableDraggable.value = newState;

    // 显示提示
    MyToast.show('允许拖动窗口${newState ? "已启用" : "已禁用"}');
  }

  void showUpWarnToast() {
    MyToast.showUpWarn('这是一条警告消息示例');
  }

  void showUpErrorToast() {
    MyToast.showUpError('这是一条错误消息示例');
  }

  void showUpInfoToast() {
    MyToast.showUpInfo('这是一条信息提示示例');
  }

  void showBottomToast() {
    MyToast.showBottom(
      '这是一条底部提示消息',
      opacity: 0.9,
    );
  }
}
