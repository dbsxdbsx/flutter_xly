import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../main.dart';
import '../widgets/section_title.dart';

// ============================================================================
// View
// ============================================================================

class Page13View extends GetView<Page13Controller> {
  const Page13View({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('MySelector 选择器测试'),
                SizedBox(height: 16.h),
                _buildModelSelectorDemo(),
                SizedBox(height: 24.h),
                _buildTagSelectorDemo(),
                SizedBox(height: 24.h),
                _buildCountrySelectorDemo(),
                SizedBox(height: 24.h),
                _buildCustomItemDemo(),
                SizedBox(height: 24.h),
                _buildImperativeDemo(),
                SizedBox(height: 16.h),
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
                text: '返回第12页',
                onPressed: () => Get.toNamed(MyRoutes.page12),
                size: 80.w,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ======================= Demo 1: AI 模型选择器（Controller 模式）=======================

  Widget _buildModelSelectorDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI 模型选择器',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('Controller 模式 · 搜索 + clearOption + footerBuilder',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        // 触发按钮：通过 Obx 响应 controller.modelCtrl 状态变化
        Obx(() => _ModelTriggerButton(
              label: controller.modelCtrl.selectedTitle ?? '选择模型',
              badges: controller.modelCtrl.selectedItem?.badges,
              itemCount: controller.modelCtrl.items.length,
              onTap: (ctx) => controller.modelCtrl.show(ctx),
            )),
      ],
    );
  }

  // ======================= Demo 2: 标签选择器（Controller 模式）=======================

  Widget _buildTagSelectorDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('标签选择器',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('Controller 模式 · allowReselect（再次点击已选项即可取消）',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        Builder(builder: (ctx) {
          return Obx(() => MyButton(
                text: controller.tagCtrl.selectedTitle != null
                    ? '当前标签: ${controller.tagCtrl.selectedTitle}'
                    : '选择标签',
                onPressed: () => controller.tagCtrl.show(ctx),
              ));
        }),
      ],
    );
  }

  // ======================= Demo 3: 带搜索的国家选择（Controller 模式）=======================

  Widget _buildCountrySelectorDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('国家选择（带搜索）',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('Controller 模式 · clearOption + allowReselect 同时启用',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        Builder(builder: (ctx) {
          return Obx(() => MyButton(
                text: controller.countryCtrl.selectedTitle != null
                    ? '已选: ${controller.countryCtrl.selectedTitle}'
                    : '选择国家',
                onPressed: () => controller.countryCtrl.show(ctx),
              ));
        }),
      ],
    );
  }

  // ======================= Demo 4: 自定义 Item Builder（Controller 模式）=======================

  Widget _buildCustomItemDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('自定义 Item 渲染',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('Controller 模式 · 完全自定义样式，无清除（强制有值场景）',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        Builder(builder: (ctx) {
          return Obx(() => MyButton(
                text: controller.priorityCtrl.selectedTitle != null
                    ? '优先级: ${controller.priorityCtrl.selectedTitle}'
                    : '选择优先级',
                onPressed: () => controller.priorityCtrl.show(ctx),
              ));
        }),
      ],
    );
  }

  // ======================= Demo 5: 命令式（一次性调用）=======================

  Widget _buildImperativeDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('命令式（一次性调用）',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
        SizedBox(height: 4.h),
        Text('MySelector.show() 底层 API，适合临时/无需持久化状态的场景',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey)),
        SizedBox(height: 8.h),
        Builder(builder: (ctx) {
          return MyButton(
            text: '临时选一个颜色',
            onPressed: () => controller.showColorOnce(ctx),
          );
        }),
      ],
    );
  }
}

// ============================================================================
// 模型触发按钮（模仿 Cursor 底栏风格）
// ============================================================================

class _ModelTriggerButton extends StatelessWidget {
  final String label;
  final List<Widget>? badges;
  final int itemCount;
  final void Function(BuildContext) onTap;

  const _ModelTriggerButton({
    required this.label,
    this.badges,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badges != null && badges!.isNotEmpty) ...[
              SizedBox(width: 6.w),
              ...badges!,
            ],
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF4F6BFE).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                '$itemCount',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4F6BFE),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Icon(Icons.unfold_more, size: 14.w, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Controller
// ============================================================================

class Page13Controller extends GetxController {
  // ---- Demo 1: 模型选择器 ----

  late final MySelectorController<String> modelCtrl;

  // ---- Demo 2: 标签选择器 ----

  late final MySelectorController<String> tagCtrl;

  // ---- Demo 3: 国家选择器 ----

  late final MySelectorController<String> countryCtrl;

  // ---- Demo 4: 优先级（自定义渲染）----

  late final MySelectorController<int> priorityCtrl;

  @override
  void onInit() {
    super.onInit();

    modelCtrl = MySelectorController<String>(
      items: _modelItems,
      clearOption: const MySelectorClearOption(label: '不使用模型'),
      showSearch: true,
      searchHint: '搜索模型…',
      footerBuilder: (context, dismiss) => InkWell(
        onTap: () {
          dismiss();
          MyToast.show('打开模型管理页面');
        },
        hoverColor: Colors.grey.shade50,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 11.h),
          child: Row(
            children: [
              SizedBox(width: 13.w),
              Icon(Icons.add_circle_outline_rounded,
                  size: 14.w, color: Colors.grey.shade600),
              SizedBox(width: 8.w),
              Text('添加更多模型',
                  style:
                      TextStyle(fontSize: 12.sp, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
      onChanged: (item) => MyToast.show(
          item == null ? '已清除模型选择' : '已选择: ${item.title}'),
    );

    tagCtrl = MySelectorController<String>(
      items: _tagItems,
      allowReselect: true,
      style: MySelectorStyle(panelWidth: 180),
    );

    countryCtrl = MySelectorController<String>(
      items: _countryItems,
      clearOption: MySelectorClearOption(
        label: '不限国家',
        leading: Icon(Icons.public_off_outlined,
            size: 14.w, color: Colors.grey.shade400),
        subtitle: '显示所有地区内容',
      ),
      allowReselect: true,
      showSearch: true,
      searchHint: '搜索国家…',
      style: MySelectorStyle(panelWidth: 280),
    );

    priorityCtrl = MySelectorController<int>(
      items: _priorityItems,
      style: MySelectorStyle(panelWidth: 240),
      itemBuilder: (context, item, isSelected) {
        final color = _priorityColors[item.value];
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color:
                isSelected ? color.withValues(alpha: 0.08) : Colors.transparent,
          ),
          child: Row(
            children: [
              Container(
                width: 8.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          color: isSelected ? color : Colors.black87,
                        )),
                    if (item.subtitle != null)
                      Text(item.subtitle!,
                          style: TextStyle(
                              fontSize: 10.sp, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, size: 18.w, color: color),
            ],
          ),
        );
      },
    );
  }

  // ---- Demo 5: 命令式一次性调用（保留底层 API 示范）----

  static const _colorItems = <MySelectorItem<String>>[
    MySelectorItem(value: 'red', title: '红色'),
    MySelectorItem(value: 'green', title: '绿色'),
    MySelectorItem(value: 'blue', title: '蓝色'),
    MySelectorItem(value: 'yellow', title: '黄色'),
  ];

  Future<void> showColorOnce(BuildContext ctx) async {
    final result = await MySelector.show<String>(
      triggerContext: ctx,
      items: _colorItems,
    );
    final changed = result.changed;
    if (changed?.item != null) {
      MyToast.show('你选了: ${changed!.item!.title}');
    }
  }

  // ============================================================
  // 静态数据
  // ============================================================

  static final _modelItems = <MySelectorItem<String>>[
    MySelectorItem(
      value: 'gemini-3.1-pro',
      title: 'Gemini 3.1 Pro Preview',
      subtitle: 'google · gemini-3.1-pro-preview',
      badges: [
        _badge(Icons.image, Colors.blue),
        _badge(Icons.music_note, Colors.red),
        _badge(Icons.videocam, Colors.orange),
        _badge(Icons.attach_file, Colors.green),
      ],
    ),
    MySelectorItem(
      value: 'gpt-4o',
      title: 'GPT-4o',
      subtitle: 'openai · gpt-4o-2025-01',
      badges: [
        _badge(Icons.image, Colors.blue),
        _badge(Icons.music_note, Colors.red),
      ],
    ),
    MySelectorItem(
      value: 'claude-4-sonnet',
      title: 'Claude 4 Sonnet',
      subtitle: 'anthropic · claude-4-sonnet-20260214',
      badges: [_badge(Icons.image, Colors.blue)],
    ),
    const MySelectorItem(
      value: 'minimax-m2.5',
      title: 'MiniMax M2.5',
      subtitle: 'minimax · minimax-m2.5',
    ),
    MySelectorItem(
      value: 'mistral-small',
      title: 'Mistral Small 3.1 24B (free)',
      subtitle: 'mistralai · mistral-small-3.1-24b-instruct',
      badges: [_badge(Icons.image, Colors.blue)],
    ),
    const MySelectorItem(
      value: 'trinity-large',
      title: 'Trinity Large Preview (free)',
      subtitle: 'arcee-ai · trinity-large-preview',
    ),
    const MySelectorItem(
      value: 'step-3.5-flash',
      title: 'Step 3.5 Flash (free)',
      subtitle: 'stepfun · step-3.5-flash',
    ),
    MySelectorItem(
      value: 'deepseek-r1',
      title: 'DeepSeek R1 0528',
      subtitle: 'deepseek · deepseek-r1-0528',
      badges: [_badge(Icons.image, Colors.blue)],
    ),
  ];

  static Widget _badge(IconData icon, Color color) {
    return Container(
      width: 14.r,
      height: 14.r,
      margin: EdgeInsets.only(right: 2.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 8.r, color: color),
    );
  }

  static final _tagItems = <MySelectorItem<String>>[
    MySelectorItem(value: 'important', title: '重要', leading: _dot(Colors.red)),
    MySelectorItem(value: 'work', title: '工作', leading: _dot(Colors.blue)),
    MySelectorItem(value: 'personal', title: '个人', leading: _dot(Colors.green)),
    MySelectorItem(value: 'study', title: '学习', leading: _dot(Colors.orange)),
    MySelectorItem(value: 'idea', title: '灵感', leading: _dot(Colors.purple)),
  ];

  static Widget _dot(Color color) {
    return Container(
      width: 10.r,
      height: 10.r,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  static final _countryItems = <MySelectorItem<String>>[
    MySelectorItem(
        value: 'cn',
        title: '中国',
        subtitle: 'China',
        leading: Text('🇨🇳', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'us',
        title: '美国',
        subtitle: 'United States',
        leading: Text('🇺🇸', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'jp',
        title: '日本',
        subtitle: 'Japan',
        leading: Text('🇯🇵', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'kr',
        title: '韩国',
        subtitle: 'South Korea',
        leading: Text('🇰🇷', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'gb',
        title: '英国',
        subtitle: 'United Kingdom',
        leading: Text('🇬🇧', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'fr',
        title: '法国',
        subtitle: 'France',
        leading: Text('🇫🇷', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'de',
        title: '德国',
        subtitle: 'Germany',
        leading: Text('🇩🇪', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'it',
        title: '意大利',
        subtitle: 'Italy',
        leading: Text('🇮🇹', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'ru',
        title: '俄罗斯',
        subtitle: 'Russia',
        leading: Text('🇷🇺', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'ca',
        title: '加拿大',
        subtitle: 'Canada',
        leading: Text('🇨🇦', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'au',
        title: '澳大利亚',
        subtitle: 'Australia',
        leading: Text('🇦🇺', style: TextStyle(fontSize: 18.sp))),
    MySelectorItem(
        value: 'br',
        title: '巴西',
        subtitle: 'Brazil',
        leading: Text('🇧🇷', style: TextStyle(fontSize: 18.sp))),
  ];

  static final _priorityItems = <MySelectorItem<int>>[
    const MySelectorItem(value: 0, title: '紧急', subtitle: '需要立即处理'),
    const MySelectorItem(value: 1, title: '高', subtitle: '近期完成'),
    const MySelectorItem(value: 2, title: '中', subtitle: '正常排期'),
    const MySelectorItem(value: 3, title: '低', subtitle: '有空再做'),
  ];

  static const _priorityColors = [
    Colors.red,
    Colors.orange,
    Colors.blue,
    Colors.grey,
  ];
}
