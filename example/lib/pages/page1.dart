import 'package:example/main.dart';
import 'package:example/utils.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../services/example_service.dart';

class Page1View extends GetView<Page1Controller> {
  const Page1View({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: const Text('第1页')),
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle('按钮测试'),
                  SizedBox(height: 8.h),
                  _buildButtonSection(),
                  SizedBox(height: 12.h),
                  _buildSectionTitle('菜单按钮测试'),
                  SizedBox(height: 8.h),
                  _buildMenuButtonSection(),
                  SizedBox(height: 12.h),
                  _buildSectionTitle('窗口控制测试'),
                  SizedBox(height: 8.h),
                  _buildWindowControlSection(),
                  SizedBox(height: 12.h),
                  _buildToastTestSection(),
                  SizedBox(height: 8.h),
                  _buildNavigationSection(),
                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        ).showRightMenu(
          context: context,
          menuElements: _buildRightMenuItems(),
          style: const MyMenuStyle(shadowRatio: 0.2),
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
        MyButton(
          icon: Icons.exit_to_app,
          text: '退出应用',
          onPressed: controller.confirmExitApp,
        ),
        SizedBox(width: 16.w),
        MyButton(
          icon: Icons.arrow_forward,
          text: '前往第2页',
          onPressed: controller.goToPage2,
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Obx(() => MyButton(
                    text:
                        '允许拖动窗口: ${MyApp.isDraggableEnabled() ? "已开启" : "已关闭"}',
                    onPressed: controller.toggleDraggable,
                  )),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Obx(() => MyButton(
                    text:
                        '允许手动调整窗口尺寸: ${controller.isWindowControlEnabled.value ? "已开启" : "已关闭"}',
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
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: Obx(() => MyButton(
                    text:
                        '显示标题栏: ${controller.showTitleBar.value ? "已开启" : "已关闭"}',
                    onPressed: controller.toggleTitleBar,
                  )),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // 窗口停靠按钮
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: MyButton(
                text: '停靠到左上角',
                onPressed: controller.dockToTopLeft,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MyButton(
                text: '停靠到右上角',
                onPressed: controller.dockToTopRight,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MyButton(
                text: '停靠到左下角',
                onPressed: controller.dockToBottomLeft,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MyButton(
                text: '停靠到右下角',
                onPressed: controller.dockToBottomRight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToastTestSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Toast测试'),
        SizedBox(height: 8.h),
        // 顶部和底部Toast测试区域
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '顶部/底部Toast',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    text: '显示顶部警告提示',
                    onPressed: () => controller.showUpWarnToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '显示顶部错误提示',
                    onPressed: () => controller.showUpErrorToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '显示顶部信息提示',
                    onPressed: () => controller.showUpInfoToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '显示底部提示',
                    onPressed: () => controller.showBottomToast(),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 12.h),
        // 中间Toast测试区域
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '中间Toast',
              style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    text: '成功提示',
                    onPressed: () => controller.showOkToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '信息提示',
                    onPressed: () => controller.showInfoToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '警告提示',
                    onPressed: () => controller.showWarnToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '错误提示',
                    onPressed: () => controller.showErrorToast(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  flex: 2, // 左边按钮占用2份空间
                  child: MyButton(
                    text: '连续显示Toast',
                    onPressed: controller.showToast,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 2, // 右半边整体占用2份空间
                  child: Row(
                    children: [
                      Expanded(
                        child: MyButton(
                          text: '显示永久加载',
                          onPressed: () => controller.showPermanentSpinner(),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: MyButton(
                          text: '关闭加载动画',
                          onPressed: () => controller.hideSpinner(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: MyButton(
                    text: '复合提示：加载+完成',
                    onPressed: () => controller.testCompoundSpinnerThenToast(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '自动关闭加载(3秒)',
                    onPressed: () => controller.showAutoCloseSpinner(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              children: [
                Expanded(
                  child: MyButton(
                    text: '静默成功测试',
                    onPressed: () => controller.testSilentSuccess(),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: MyButton(
                    text: '静默失败测试',
                    onPressed: () => controller.testSilentFailure(),
                  ),
                ),
              ],
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
  final showTitleBar = (!MyApp.isTitleBarHidden()).obs;

  @override
  void onInit() {
    super.onInit();
    // 初始化时获取当前标题栏状态
    showTitleBar.value = !MyApp.isTitleBarHidden();

    // 从ExampleService同步拖动设置状态
    _syncDraggableState();
    // 从ExampleService同步可调整大小的状态
    _syncResizableState();
  }

  /// 从ExampleService同步拖动设置状态
  void _syncDraggableState() {
    try {
      final exampleService = ExampleService.to;
      // 监听ExampleService中的拖动设置变化
      exampleService.windowDraggable.listen((isDraggable) {
        enableDraggable.value = isDraggable;
      });
      // 初始化时同步状态
      enableDraggable.value = exampleService.windowDraggable.value;
    } catch (e) {
      // 如果ExampleService还没有初始化，使用MyApp的状态
      enableDraggable.value = MyApp.isDraggableEnabled();
    }
  }

  /// 从ExampleService同步可调整大小的状态
  void _syncResizableState() {
    try {
      final exampleService = ExampleService.to;
      // 监听ExampleService中的可调整大小设置变化
      exampleService.windowResizable.listen((isResizable) {
        isWindowControlEnabled.value = isResizable;
      });
      // 初始化时同步状态
      isWindowControlEnabled.value = exampleService.windowResizable.value;
    } catch (e) {
      // 如果ExampleService还没有初始化，使用MyApp的状态
      isWindowControlEnabled.value = MyApp.isResizableEnabled();
    }
  }

  void toggleMenuButtonState() {
    isMenuButtonActivated.value = !isMenuButtonActivated.value;
  }

  void goToPage2() {
    goToPage(Routes.page2);
  }

  void showToast() async {
    // 展示普通 toast 之间的堆叠效果
    MyToast.show('第一条消息');
    await Future.delayed(const Duration(milliseconds: 500));
    MyToast.show('第二条消息', stackPreviousToasts: true);
    await Future.delayed(const Duration(milliseconds: 500));
    MyToast.show('第三条消息', stackPreviousToasts: true);

    await Future.delayed(const Duration(seconds: 2));

    // 展示非堆叠效果
    MyToast.show(
      '新消息 (不堆叠)',
    );
    await Future.delayed(const Duration(milliseconds: 500));
    MyToast.show(
      '又一条新消息 (不堆叠)',
    );
  }

  void confirmExitApp() async {
    // 复用FloatBar中的退出确认对话框
    await showExitConfirmDialog();
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
    final newState = !isWindowControlEnabled.value;

    // 通过ExampleService设置新状态，以实现持久化
    await ExampleService.to.setWindowResizable(newState);

    // 更新本地状态以保持UI同步（实际上会被listen回调覆盖，但为了即时响应可以保留）
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

    // 同时保存到ExampleService以持久化设置
    await ExampleService.to.setWindowDraggable(newState);

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
      // opacity: 0.9,
    );
  }

  void showPermanentSpinner() {
    MyToast.showSpinner(
      message: '永久加载中...',
      spinnerColor: Colors.blue,
      textStyle: TextStyle(
        fontSize: 16.sp,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  void hideSpinner() {
    MyToast.hideAll();
  }

  void showAutoCloseSpinner() {
    MyToast.showSpinner(
      message: '加载中(3秒后自动关闭)...',
      spinnerColor: Colors.green,
      textStyle: TextStyle(
        fontSize: 16.sp,
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
      duration: const Duration(seconds: 3),
    );
  }

  void toggleTitleBar() async {
    try {
      final newState = !showTitleBar.value;
      await MyApp.setTitleBarHidden(!newState);
      showTitleBar.value = newState;
      MyToast.show('标题栏${newState ? "已显示" : "已隐藏"}');
    } catch (e) {
      MyToast.showUpError('切换标题栏失败: $e');
    }
  }

  void testCompoundSpinnerThenToast() async {
    // 场景1：使用默认提示
    // 场景1：使用默认提示
    await MyToast.showLoadingThenToast(
      loadingMessage: 'task1:正在加载数据...',
      task: () async {
        await Future.delayed(const Duration(seconds: 1));
        return (true, 'task1结果:数据加载完成！');
      },
      spinnerColor: Colors.blue,
    );

    // 场景2：自定义警告提示
    await MyToast.showLoadingThenToast(
      stackPreviousToasts: true,
      loadingMessage: 'task2结果:正在处理数据...',
      task: () async {
        await Future.delayed(const Duration(seconds: 1));
        return (false, 'task2结果:数据格式不正确，请检查后重试');
      },
      spinnerColor: Colors.green,
      onWarn: (message) {
        MyToast.showUpWarn("task2,自定义警告"); // 使用顶部警告样式
      },
    );

    // 场景3：自定义成功和错误提示
    await MyToast.showLoadingThenToast(
      loadingMessage: 'task3:正在保存\n(不堆叠)\n...',
      task: () async {
        await Future.delayed(const Duration(seconds: 1));
        if (DateTime.now().second % 2 == 0) {
          throw Exception('task3结果:网络连接错误');
        }
        return (true, 'task3结果:保存成功！');
      },
      spinnerColor: Colors.orange,
      // onOk: (message) {
      //   MyToast.showBottom(message); // 使用底部提示样式
      // },
      onError: (error) {
        MyToast.showUpError('保存失败'); // 使用顶部错误样式
      },
    );
  }

  void showOkToast() {
    MyToast.showOk(
      '操作成功完成！',
    );
  }

  void showWarnToast() {
    MyToast.showWarn(
      '请检查输入数据',
    );
  }

  void showErrorToast() {
    MyToast.showError(
      '发生错误：无法连接服务器',
    );
  }

  void showInfoToast() {
    MyToast.showInfo(
      '这是一条信息提示',
    );
  }

  void testSilentSuccess() async {
    await MyToast.showLoadingThenToast(
      loadingMessage: '正在执行静默（结果成功）的操作...',
      task: () async {
        await Future.delayed(const Duration(seconds: 1));
        return (true, null); // 返回成功但不显示任何提示
      },
      spinnerColor: Colors.purple,
    );
  }

  void testSilentFailure() async {
    await MyToast.showLoadingThenToast(
      loadingMessage: '正在执行静默（结果失败）的操作...',
      task: () async {
        await Future.delayed(const Duration(seconds: 1));
        return (false, ""); // 返回失败但不显示任何提示
      },
      spinnerColor: Colors.orange,
    );
  }

  /// 停靠窗口到左上角
  void dockToTopLeft() async {
    final success = await MyApp.dockToCorner(WindowCorner.topLeft);
    if (success) {
      MyToast.show('窗口已停靠到左上角');
    } else {
      MyToast.showUpError('停靠窗口失败');
    }
  }

  /// 停靠窗口到右上角
  void dockToTopRight() async {
    final success = await MyApp.dockToCorner(WindowCorner.topRight);
    if (success) {
      MyToast.show('窗口已停靠到右上角');
    } else {
      MyToast.showUpError('停靠窗口失败');
    }
  }

  /// 停靠窗口到左下角
  void dockToBottomLeft() async {
    final success = await MyApp.dockToCorner(WindowCorner.bottomLeft);
    if (success) {
      MyToast.show('窗口已停靠到左下角');
    } else {
      MyToast.showUpError('停靠窗口失败');
    }
  }

  /// 停靠窗口到右下角
  void dockToBottomRight() async {
    final success = await MyApp.dockToCorner(WindowCorner.bottomRight);
    if (success) {
      MyToast.show('窗口已停靠到右下角');
    } else {
      MyToast.showUpError('停靠窗口失败');
    }
  }
}
