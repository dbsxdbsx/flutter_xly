import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../controllers/display_controller.dart';
import '../core/ui_constants.dart';
import '../models/monitor_settings.dart';
import '../services/monitor_settings_service.dart';

class BrightnessView extends GetView<DisplayController> {
  const BrightnessView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: UIConstants.standardPadding,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 紧凑的显示器控制卡片
              _buildCompactControlCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建紧凑的显示器控制卡片
  Widget _buildCompactControlCard() {
    return Card(
      child: Padding(
        padding: UIConstants.cardPadding,
        child: Column(
          children: [
            // 集成式标题行：标题、显示器信息和设置按钮
            Row(
              children: [
                // 可点击的显示器图标（集成刷新功能）
                Tooltip(
                  message: '点击刷新显示器状态',
                  child: GestureDetector(
                    onTap: controller.isLoading.value
                        ? null
                        : controller.refreshBrightness,
                    child: Container(
                      padding: UIConstants.standardPadding,
                      decoration: BoxDecoration(
                        color: Get.theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          UIConstants.smallBorderRadius,
                        ),
                        border: Border.all(
                          color: Get.theme.primaryColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Obx(
                        () => AnimatedRotation(
                          turns: controller.isLoading.value ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 1000),
                          child: Icon(
                            controller.isLoading.value
                                ? Icons.refresh
                                : Icons.monitor,
                            size: UIConstants.largeIconSize,
                            color: Get.theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                UIHelpers.smallHorizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Light - 屏幕亮度调节',
                        style: Get.textTheme.titleMedium?.copyWith(
                          fontSize: UIConstants.titleFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Obx(
                        () => controller.monitorName.value.isNotEmpty
                            ? Text(
                                controller.monitorName.value,
                                style: Get.textTheme.bodySmall?.copyWith(
                                  color: Get.theme.colorScheme.primary,
                                  fontSize: UIConstants.smallFontSize,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                // 集成的设置按钮
                Obx(
                  () => IconButton(
                    onPressed: controller.monitorName.value.isEmpty
                        ? null
                        : () => _showSettingsDialog(),
                    icon: Stack(
                      children: [
                        Icon(Icons.settings, size: UIConstants.iconSize),
                        // 配置数量指示器
                        if (controller.availableConfigs.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(2.w),
                              decoration: BoxDecoration(
                                color: Get.theme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16.w,
                                minHeight: 16.h,
                              ),
                              child: Text(
                                '${controller.availableConfigs.length}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    tooltip: '显示器配置管理',
                  ),
                ),
              ],
            ),

            UIHelpers.largeVerticalSpace,

            // VCP控制方块网格
            _buildVcpControlGrid(),

            UIHelpers.largeVerticalSpace,

            // 全键禁用控制区域
            _buildAllKeysControlArea(),
            UIHelpers.mediumVerticalSpace,

            // Windows键禁用控制区域
            _buildWindowsKeyControlArea(),

            UIHelpers.mediumVerticalSpace,

            // 强制CapsLock开启控制区域
            _buildForceCapslockControlArea(),
          ],
        ),
      ),
    );
  }

  /// 显示设置管理对话框
  void _showSettingsDialog() {
    MyDialogSheet.showBottom(height: 420.h, child: _buildSettingsContent());
  }

  /// 底部弹层内容
  Widget _buildSettingsContent() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Get.theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              Icon(
                Icons.save_alt,
                size: UIConstants.iconSize,
                color: Get.theme.primaryColor,
              ),
              UIHelpers.smallHorizontalSpace,
              Text(
                '显示器配置',
                style: Get.textTheme.titleLarge?.copyWith(
                  fontSize: UIConstants.titleFontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Obx(
                () => controller.availableConfigs.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Get.theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${controller.availableConfigs.length}个配置',
                          style: Get.textTheme.bodySmall?.copyWith(
                            fontSize: UIConstants.smallFontSize,
                            color: Get.theme.primaryColor,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              UIHelpers.smallHorizontalSpace,
              IconButton(
                onPressed: () => Get.back(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          UIHelpers.largeVerticalSpace,

          // 配置选择区域
          Obx(
            () => controller.availableConfigs.isNotEmpty
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选择配置:',
                        style: Get.textTheme.bodyLarge?.copyWith(
                          fontSize: UIConstants.bodyFontSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      UIHelpers.mediumVerticalSpace,
                      // 下拉列表和操作按钮行
                      Row(
                        children: [
                          // MyTextEditor - 支持输入和下拉选择
                          Expanded(child: _buildConfigTextEditor()),

                          // 操作按钮组
                          Row(
                            children: [
                              // 保存配置按钮
                              Obx(
                                () => IconButton(
                                  onPressed: controller.isLoading.value ||
                                          controller
                                              .monitorName.value.isEmpty ||
                                          controller
                                              .selectedConfigName.value.isEmpty
                                      ? null
                                      : () => _handleSaveConfig(),
                                  icon: Icon(
                                    Icons.save,
                                    size: UIConstants.iconSize,
                                    color: Get.theme.primaryColor,
                                  ),
                                  tooltip: '保存配置',
                                ),
                              ),

                              // 加载配置按钮
                              Obx(
                                () => IconButton(
                                  onPressed: controller.isLoading.value ||
                                          controller
                                              .selectedConfigName.value.isEmpty
                                      ? null
                                      : () {
                                          controller.loadSavedSettings(
                                            controller.selectedConfigName.value,
                                          );
                                          Get.back(); // 加载后关闭对话框
                                        },
                                  icon: Icon(
                                    Icons.download,
                                    size: UIConstants.iconSize,
                                    color: Get.theme.primaryColor,
                                  ),
                                  tooltip: '加载配置',
                                ),
                              ),

                              // 以下按钮仅在选中配置时显示
                              if (controller
                                  .selectedConfigName.value.isNotEmpty) ...[
                                // 重命名配置按钮
                                Obx(
                                  () => IconButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () => _showRenameConfigDialog(),
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: UIConstants.iconSize,
                                      color: Get.theme.primaryColor,
                                    ),
                                    tooltip: '重命名选中的配置',
                                  ),
                                ),

                                // 删除配置按钮
                                Obx(
                                  () => IconButton(
                                    onPressed: controller.isLoading.value
                                        ? null
                                        : () => _showDeleteConfirmDialog(),
                                    icon: Icon(
                                      Icons.delete_outline,
                                      size: UIConstants.iconSize,
                                      color: Get.theme.colorScheme.error,
                                    ),
                                    tooltip: '删除选中的配置',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      UIHelpers.largeVerticalSpace,
                    ],
                  )
                : Column(
                    children: [
                      Icon(
                        Icons.settings_suggest,
                        size: 48.w,
                        color: Get.theme.disabledColor,
                      ),
                      UIHelpers.mediumVerticalSpace,
                      Text(
                        '暂无保存的配置',
                        style: Get.textTheme.bodyMedium?.copyWith(
                          color: Get.theme.disabledColor,
                        ),
                      ),
                      UIHelpers.largeVerticalSpace,
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  /// 处理保存配置逻辑
  void _handleSaveConfig() async {
    final configName = controller.selectedConfigName.value.trim();
    if (configName.isEmpty) {
      MyToast.showError('请输入或选择配置名称');
      return;
    }

    // 检查配置是否已存在
    final canSaveDirectly = await controller.checkAndSaveCurrentSettings(
      configName,
    );
    if (!canSaveDirectly) {
      // 配置已存在，获取已存在的配置数据并显示覆盖确认对话框
      final existingSettings = await MonitorSettingsService.to
          .getMonitorSettings(controller.monitorName.value, configName);
      if (existingSettings != null) {
        _showSaveOverwriteConfirmDialog(
          configName,
          existingSettings,
          controller,
        );
      }
    }
  }

  /// 显示重命名配置对话框
  void _showRenameConfigDialog() {
    final oldConfigName = controller.selectedConfigName.value;
    final configNameController = TextEditingController(text: oldConfigName);

    Get.dialog(
      AlertDialog(
        title: const Text('重命名配置'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('重命名配置 "$oldConfigName"'),
            UIHelpers.mediumVerticalSpace,
            TextField(
              controller: configNameController,
              decoration: const InputDecoration(
                labelText: '新配置名称',
                hintText: '例如：工作模式、游戏模式、夜间模式',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (value) {
                final newConfigName = value.trim();
                if (newConfigName.isNotEmpty &&
                    newConfigName != oldConfigName) {
                  Get.back();
                  controller.renameSavedSettings(oldConfigName, newConfigName);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final newConfigName = configNameController.text.trim();
              if (newConfigName.isNotEmpty && newConfigName != oldConfigName) {
                Get.back();
                controller.renameSavedSettings(oldConfigName, newConfigName);
              }
            },
            child: const Text('重命名'),
          ),
        ],
      ),
    );
  }

  /// 构建配置文本编辑器（支持输入和下拉选择）
  Widget _buildConfigTextEditor() {
    return MyTextEditor(
      textController: controller.configNameTextController,
      label: '配置选择',
      hint: '输入新配置名称或选择现有配置',
      getDropDownOptions: () async => controller.availableConfigs.toList(),
      onOptionSelected: (option) {
        controller.selectedConfigName.value = option;
      },
      onChanged: (value) {
        if (controller.selectedConfigName.value != value) {
          controller.selectedConfigName.value = value;
        }
      },
      maxShowDropDownItems: 2,
      showListCandidateBelow: false,
    );
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    final configName = controller.selectedConfigName.value;

    Get.dialog(
      AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除配置 "$configName" 吗？'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Get.back();
              controller.deleteSavedSettings(configName);
            },
            child: Text(
              '删除',
              style: TextStyle(color: Get.theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建VCP控制方块网格
  Widget _buildVcpControlGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      crossAxisSpacing: UIConstants.mediumSpacing,
      mainAxisSpacing: UIConstants.mediumSpacing,
      children: [
        _buildVcpControlTile(
          title: '亮度',
          icon: Icons.brightness_6,
          value: controller.brightness,
          onChanged: controller.setBrightness,
          isSupported: controller.supportsBrightness,
          vcpCode: 0x10,
        ),
        _buildVcpControlTile(
          title: '对比度',
          icon: Icons.contrast,
          value: controller.contrast,
          onChanged: controller.setContrast,
          isSupported: controller.supportsContrast,
          vcpCode: 0x12,
        ),
        _buildVcpControlTile(
          title: '背光',
          icon: Icons.lightbulb_outline,
          value: controller.backlight,
          onChanged: controller.setBacklight,
          isSupported: controller.supportsBacklight,
          vcpCode: 0x13,
        ),
        _buildVcpControlTile(
          title: '锐利度',
          icon: Icons.tune,
          value: controller.sharpness,
          onChanged: controller.setSharpness,
          isSupported: controller.supportsSharpness,
          vcpCode: 0x87,
        ),
      ],
    );
  }

  /// 构建VCP控制方块
  Widget _buildVcpControlTile({
    required String title,
    required IconData icon,
    required RxDouble value,
    required Function(double) onChanged,
    required RxBool isSupported,
    required int vcpCode,
  }) {
    return Obx(
      () => Container(
        padding: UIConstants.cardPadding,
        decoration: BoxDecoration(
          color: isSupported.value
              ? Get.theme.cardColor
              : Get.theme.disabledColor.withValues(alpha: 0.1),
          border: Border.all(
            color: isSupported.value
                ? Get.theme.primaryColor.withValues(alpha: 0.2)
                : Get.theme.disabledColor.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 图标和标题
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: UIConstants.iconSize,
                  color: isSupported.value
                      ? Get.theme.primaryColor
                      : Get.theme.disabledColor,
                ),
                UIHelpers.smallHorizontalSpace,
                Text(
                  title,
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontSize: UIConstants.bodyFontSize,
                    color: isSupported.value
                        ? Get.theme.colorScheme.onSurface
                        : Get.theme.disabledColor,
                  ),
                ),
              ],
            ),

            UIHelpers.mediumVerticalSpace,

            // 数值显示
            Text(
              '${value.value.round()}%',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontSize: UIConstants.percentageFontSize,
                fontWeight: FontWeight.bold,
                color: isSupported.value
                    ? Get.theme.colorScheme.primary
                    : Get.theme.disabledColor,
              ),
            ),

            UIHelpers.smallVerticalSpace,

            // 滑块控制
            Slider(
              value: value.value,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: isSupported.value ? onChanged : null,
              activeColor: isSupported.value
                  ? Get.theme.primaryColor
                  : Get.theme.disabledColor,
              inactiveColor: isSupported.value
                  ? Get.theme.primaryColor.withValues(alpha: 0.3)
                  : Get.theme.disabledColor.withValues(alpha: 0.3),
            ),

            // VCP代码显示
            Text(
              'VCP: 0x${vcpCode.toRadixString(16).toUpperCase()}',
              style: Get.textTheme.bodySmall?.copyWith(
                fontSize: UIConstants.smallFontSize,
                color: Get.theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建Windows键禁用控制区域
  Widget _buildWindowsKeyControlArea() {
    return Container(
      padding: UIConstants.cardPadding,
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        border: Border.all(
          color: Get.theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          // 图标
          Icon(
            Icons.keyboard,
            size: UIConstants.iconSize,
            color: Get.theme.primaryColor,
          ),
          UIHelpers.smallHorizontalSpace,

          // 标题和描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '禁用Windows键',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontSize: UIConstants.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '防止游戏中误按Windows键',
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontSize: UIConstants.smallFontSize,
                    color: Get.theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // 开关
          Obx(
            () => Switch(
              value: controller.isWindowsKeyDisabled.value,
              onChanged: controller.isAllKeysDisabled.value
                  ? null
                  : controller.setWindowsKeyDisabled,
              activeThumbColor: Get.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建“禁用所有键盘输入”控制区域
  Widget _buildAllKeysControlArea() {
    return Container(
      padding: UIConstants.cardPadding,
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        border: Border.all(
          color: Get.theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          // 图标
          Icon(
            Icons.block,
            size: UIConstants.iconSize,
            color: Get.theme.colorScheme.error,
          ),
          UIHelpers.smallHorizontalSpace,

          // 标题和描述
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '禁用所有键盘输入',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontSize: UIConstants.bodyFontSize,
                    fontWeight: FontWeight.w600,
                    color: Get.theme.colorScheme.error,
                  ),
                ),
                Text(
                  '开启后将拦截一切键盘按键（鼠标不受影响），用于防误触或锁定键盘',
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontSize: UIConstants.smallFontSize,
                    color: Get.theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

          // 开关
          Obx(
            () => Switch(
              value: controller.isAllKeysDisabled.value,
              onChanged: controller.setAllKeysDisabled,
              activeThumbColor: Get.theme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建“强制CapsLock开启”控制区域
  Widget _buildForceCapslockControlArea() {
    return Container(
      padding: UIConstants.cardPadding,
      decoration: BoxDecoration(
        color: Get.theme.cardColor,
        border: Border.all(
          color: Get.theme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(UIConstants.cardBorderRadius),
      ),
      child: Row(
        children: [
          Icon(
            Icons.keyboard_capslock,
            size: UIConstants.iconSize,
            color: Get.theme.primaryColor,
          ),
          UIHelpers.smallHorizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '强制CapsLock开启',
                  style: Get.textTheme.titleSmall?.copyWith(
                    fontSize: UIConstants.bodyFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '无论按下CapsLock与否，始终保持大写模式（仅影响键盘，鼠标不受影响）',
                  style: Get.textTheme.bodySmall?.copyWith(
                    fontSize: UIConstants.smallFontSize,
                    color: Get.theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: controller.isForceCapslockOn.value,
              onChanged: controller.setForceCapslockOn,
              activeThumbColor: Get.theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// 显示保存时的覆盖确认对话框（独立函数）
void _showSaveOverwriteConfirmDialog(
  String configName,
  MonitorSettings existingSettings,
  DisplayController controller,
) {
  Get.dialog(
    AlertDialog(
      title: const Text('配置已存在'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('配置 "$configName" 已存在。'),
          UIHelpers.mediumVerticalSpace,
          Text(
            '设置对比：',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          UIHelpers.smallVerticalSpace,
          _buildSettingComparisonRowStatic(
            '亮度',
            existingSettings.brightness.toInt(),
            controller.brightness.value.toInt(),
          ),
          _buildSettingComparisonRowStatic(
            '对比度',
            existingSettings.contrast.toInt(),
            controller.contrast.value.toInt(),
          ),
          _buildSettingComparisonRowStatic(
            '背光',
            existingSettings.backlight.toInt(),
            controller.backlight.value.toInt(),
          ),
          _buildSettingComparisonRowStatic(
            '锐度',
            existingSettings.sharpness.toInt(),
            controller.sharpness.value.toInt(),
          ),
          UIHelpers.mediumVerticalSpace,
          Text(
            '是否要用当前设置覆盖原有配置？',
            style: Get.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('取消')),
        TextButton(
          onPressed: () {
            Get.back();
            controller.saveCurrentSettings(configName);
          },
          child: Text(
            '覆盖',
            style: TextStyle(color: Get.theme.colorScheme.secondary),
          ),
        ),
      ],
    ),
  );
}

/// 构建设置对比行的静态版本（用于独立函数）
Widget _buildSettingComparisonRowStatic(
  String label,
  int oldValue,
  int newValue,
) {
  final hasChanged = oldValue != newValue;

  return Padding(
    padding: EdgeInsets.symmetric(vertical: 2.h),
    child: Row(
      children: [
        SizedBox(
          width: 50.w,
          child: Text(
            '$label:',
            style: Get.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$oldValue%',
          style: Get.textTheme.bodySmall?.copyWith(
            color: hasChanged ? Get.theme.colorScheme.outline : null,
            decoration: hasChanged ? TextDecoration.lineThrough : null,
          ),
        ),
        if (hasChanged) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Icon(
              Icons.arrow_forward,
              size: 16.w,
              color: Get.theme.colorScheme.secondary,
            ),
          ),
          Text(
            '$newValue%',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Get.theme.colorScheme.secondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              '(无变化)',
              style: Get.textTheme.bodySmall?.copyWith(
                color: Get.theme.colorScheme.outline,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
