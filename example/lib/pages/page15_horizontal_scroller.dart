import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../main.dart';
import '../widgets/section_title.dart';

enum _DemoMode { manual, auto }

enum _DemoThemeChoice { system, light, dark }

class Page15HorizontalScrollerView
    extends GetView<Page15HorizontalScrollerController> {
  const Page15HorizontalScrollerView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
              '1. MySegmentedToggle 物理滑块 + MyHorizontalScroller 内部拖滑'),
          SizedBox(height: 6.h),
          Text(
            '拖动滑块体验不同窗口宽度；在左侧「手动 / 智能」上点击或按住左右轻拨，右侧地区条可用鼠标左键按住拖滑、悬停滚轮或点 < / >，均不会拖走母窗口（按住页面空白处仍可拖窗）。',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          Obx(() => Row(
                children: [
                  Text(
                    '模拟宽度：${controller.demoWidth.value.round()}dp',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: MyWindowDragExcludeZone(
                      child: Slider(
                        min: 220,
                        max: 680,
                        value: controller.demoWidth.value,
                        onChanged: (v) => controller.demoWidth.value = v,
                      ),
                    ),
                  ),
                ],
              )),
          SizedBox(height: 6.h),
          Obx(() {
            final width = controller.demoWidth.value;
            final mode = controller.mode.value;
            final selected = controller.selectedRegion.value;
            final stripBg = Colors.grey.shade50;

            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: width),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: stripBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    MySegmentedToggle<_DemoMode>(
                      value: mode,
                      onChanged: (next) {
                        controller.mode.value = next;
                        if (next == _DemoMode.manual) {
                          controller.selectedRegion.value = null;
                        } else if (next == _DemoMode.auto &&
                            mode == _DemoMode.auto) {
                          controller.selectedRegion.value = null;
                        }
                      },
                      options: [
                        MyToggleOption(
                          value: _DemoMode.manual,
                          label: '手动',
                          icon: Icons.lock_outline,
                          activeColor: Colors.blueGrey.shade700,
                          tooltip: '锁定当前选项',
                        ),
                        MyToggleOption(
                          value: _DemoMode.auto,
                          label: '智能',
                          icon: Icons.auto_awesome,
                          activeColor: Colors.blue.shade600,
                          tooltip: '按规则自动调度',
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 16.h,
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      color: Colors.black.withValues(alpha: 0.12),
                    ),
                    Expanded(
                      child: MyHorizontalScroller(
                        fadeColor: stripBg,
                        child: Row(
                          children: [
                            for (var i = 0;
                                i < controller.regions.length;
                                i++) ...[
                              _RegionChip(
                                label: controller.regions[i],
                                active: mode == _DemoMode.auto &&
                                    selected == controller.regions[i],
                                onTap: () {
                                  final region = controller.regions[i];
                                  if (mode == _DemoMode.auto &&
                                      selected == region) {
                                    controller.selectedRegion.value = null;
                                  } else {
                                    controller.mode.value = _DemoMode.auto;
                                    controller.selectedRegion.value = region;
                                  }
                                },
                              ),
                              if (i < controller.regions.length - 1)
                                SizedBox(width: 6.w),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 8.h),
          Obx(() {
            final mode = controller.mode.value;
            final modeText = switch (mode) {
              _DemoMode.auto => '智能自动',
              _DemoMode.manual => '手动锁定',
              null => '未连接（未选中）',
            };
            final region = controller.selectedRegion.value ?? '全局不限';
            return Wrap(
              spacing: 12.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '当前状态：$modeText · 地区：$region',
                  style: TextStyle(fontSize: 12.sp, color: Colors.blueGrey),
                ),
                TextButton(
                  onPressed: () {
                    controller.mode.value = null;
                    controller.selectedRegion.value = null;
                  },
                  child: const Text('模拟未连接(null)'),
                ),
              ],
            );
          }),
          SizedBox(height: 18.h),
          const SectionTitle('2. MySegmentedToggle 多段与紧凑自适应模式'),
          SizedBox(height: 8.h),
          Obx(() => Wrap(
                spacing: 16.w,
                runSpacing: 10.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MySegmentedToggle<_DemoThemeChoice>(
                      value: controller.themeChoice.value,
                      onChanged: (next) => controller.themeChoice.value = next,
                      options: [
                        MyToggleOption(
                          value: _DemoThemeChoice.system,
                          label: '跟随系统',
                          icon: Icons.brightness_auto_outlined,
                          activeColor: Colors.teal.shade600,
                        ),
                        MyToggleOption(
                          value: _DemoThemeChoice.light,
                          label: '浅色',
                          icon: Icons.light_mode_outlined,
                          activeColor: Colors.orange.shade600,
                        ),
                        MyToggleOption(
                          value: _DemoThemeChoice.dark,
                          label: '深色',
                          icon: Icons.dark_mode_outlined,
                          activeColor: Colors.indigo.shade600,
                        ),
                      ],
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: MySegmentedToggle<String>(
                      equalWidth: false,
                      value: controller.compactValue.value,
                      onChanged: (next) => controller.compactValue.value = next,
                      options: const [
                        MyToggleOption(value: 'all', label: '全部'),
                        MyToggleOption(value: 'unread', label: '仅看未读消息'),
                        MyToggleOption(value: 'starred', label: '星标'),
                      ],
                    ),
                  ),
                ],
              )),
          SizedBox(height: 18.h),
          const SectionTitle('3. 异步切换对比（乐观落位 vs 失败自动回弹）'),
          SizedBox(height: 6.h),
          Text(
            '模拟需要 800ms 才完成的异步切换（如远程同步状态）：开启「模拟失败」后再拖滑，滑块先丝滑落位，800ms 后自动平滑回弹回原槽位。',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          Obx(() {
            final displayMode =
                controller.asyncPendingMode.value ?? controller.asyncMode.value;
            return Wrap(
              spacing: 12.w,
              runSpacing: 8.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                MySegmentedToggle<_DemoMode>(
                  value: displayMode,
                  onChanged: controller._switchAsyncMode,
                  options: [
                    MyToggleOption(
                      value: _DemoMode.manual,
                      label: '手动',
                      icon: Icons.lock_outline,
                      activeColor: Colors.blueGrey.shade700,
                    ),
                    MyToggleOption(
                      value: _DemoMode.auto,
                      label: '智能',
                      icon: Icons.auto_awesome,
                      activeColor: Colors.blue.shade600,
                    ),
                  ],
                ),
                FilterChip(
                  label: const Text('模拟后台失败回滚'),
                  selected: controller.simulateAsyncFailure.value,
                  onSelected: (v) => controller.simulateAsyncFailure.value = v,
                ),
                Text(
                  controller.asyncStatusText.value,
                  style: TextStyle(fontSize: 11.5.sp, color: Colors.blueGrey),
                ),
              ],
            );
          }),
          SizedBox(height: 22.h),
          const SectionTitle('4. 彩色底色条 + 头/尾双向动态增删（按当前视图自适应）'),
          SizedBox(height: 6.h),
          Text(
            '头部增删：停在头部时直接展开推入，滚离头部后同帧锚定当前视野不跳飞并轻弹 <。\n'
            '尾部追加：支持「始终滚入视野（主动操作）」与「仅贴尾跟随（后台推送流，滚离尾部时不抢视角、轻弹 >）」。',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              MyButton(
                text: '头部新增',
                onPressed: controller.prependDynamicTag,
              ),
              MyButton(
                text: '尾部追加',
                onPressed: controller.appendDynamicTag,
              ),
              MyButton(
                text: '移除头部',
                onPressed: controller.removeFirstDynamicTag,
              ),
              MyButton(
                text: '移除末尾',
                onPressed: controller.removeLastDynamicTag,
              ),
              Obx(() => FilterChip(
                    label: const Text('尾部追加自动滚到尾部'),
                    selected: controller.trailingAutoReveal.value,
                    onSelected: (v) => controller.trailingAutoReveal.value = v,
                  )),
            ],
          ),
          SizedBox(height: 10.h),
          Obx(() {
            final tintBg = Color.alphaBlend(
              Colors.blue.withValues(alpha: 0.08),
              Colors.white,
            );
            final tags = controller.dynamicTags.toList(growable: false);
            return ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: tintBg,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 14.sp,
                      color: Colors.blue.shade700,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      '在用',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: NotificationListener<ScrollMetricsNotification>(
                        onNotification: (_) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            controller._syncDynamicScrollOffset();
                          });
                          return false;
                        },
                        child: MyHorizontalScroller(
                          controller: controller.dynamicScrollerController,
                          fadeColor: tintBg,
                          indicatorColor: Colors.blue.shade700,
                          child: _AnimatedDynamicTagsRow(tags: tags),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          SizedBox(height: 6.h),
          Obx(() {
            final offset = controller.dynamicScrollOffset.value;
            final scrolled = offset > 0.5;
            final status = scrolled
                ? '当前视图：已右滚 ${offset.round()}px（左侧增删锚定当前视野不跳飞）'
                : '当前视图：停在头部（左侧新增将直接展开推入视野）';
            return Wrap(
              spacing: 10.w,
              runSpacing: 4.h,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  status,
                  style: TextStyle(fontSize: 11.5.sp, color: Colors.blueGrey),
                ),
                if (scrolled)
                  TextButton(
                    onPressed:
                        controller.dynamicScrollerController.scrollToStart,
                    child: const Text('回到头部'),
                  ),
              ],
            );
          }),
          SizedBox(height: 24.h),
          MyButton(
            icon: Icons.arrow_back,
            text: '返回上一页',
            onPressed: () => Get.toNamed(MyRoutes.page14Paths),
            size: 80.w,
          ),
        ],
      ),
    );
  }
}

class _DynamicTagAnimEntry {
  _DynamicTagAnimEntry({
    required this.label,
    required this.controller,
  })  : sizeAnim = CurvedAnimation(
          parent: controller,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
        fadeAnim = CurvedAnimation(
          parent: controller,
          curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
          reverseCurve: const Interval(0.0, 0.85, curve: Curves.easeIn),
        );

  final String label;
  final AnimationController controller;
  final Animation<double> sizeAnim;
  final Animation<double> fadeAnim;
  bool exiting = false;
}

class _AnimatedDynamicTagsRow extends StatefulWidget {
  const _AnimatedDynamicTagsRow({required this.tags});

  final List<String> tags;

  @override
  State<_AnimatedDynamicTagsRow> createState() =>
      _AnimatedDynamicTagsRowState();
}

class _AnimatedDynamicTagsRowState extends State<_AnimatedDynamicTagsRow>
    with TickerProviderStateMixin {
  static const Duration _animDuration = Duration(milliseconds: 240);

  final List<_DynamicTagAnimEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    for (final tag in widget.tags) {
      final entry = _createEntry(tag, initialValue: 1.0);
      _entries.add(entry);
    }
  }

  @override
  void didUpdateWidget(covariant _AnimatedDynamicTagsRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcile(widget.tags);
  }

  _DynamicTagAnimEntry _createEntry(String label, {double initialValue = 0.0}) {
    final controller = AnimationController(
      vsync: this,
      duration: _animDuration,
      reverseDuration: const Duration(milliseconds: 200),
      value: initialValue,
    );
    final entry = _DynamicTagAnimEntry(label: label, controller: controller);
    controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && entry.exiting) {
        if (!mounted) return;
        setState(() {
          _entries.remove(entry);
          entry.controller.dispose();
        });
      }
    });
    return entry;
  }

  void _reconcile(List<String> nextTags) {
    final nextSet = nextTags.toSet();
    for (final entry in _entries) {
      if (nextSet.contains(entry.label)) {
        if (entry.exiting) {
          entry.exiting = false;
          entry.controller.forward();
        }
      } else if (!entry.exiting) {
        entry.exiting = true;
        entry.controller.reverse();
      }
    }

    final existing = {for (final e in _entries) e.label};
    for (var i = 0; i < nextTags.length; i++) {
      final tag = nextTags[i];
      if (existing.contains(tag)) continue;
      final entry = _createEntry(tag);
      final insertAt = i.clamp(0, _entries.length);
      _entries.insert(insertAt, entry);
      existing.add(tag);
      entry.controller.forward();
    }
  }

  @override
  void dispose() {
    for (final entry in _entries) {
      entry.controller.dispose();
    }
    _entries.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final entry in _entries)
          ClipRect(
            key: ValueKey<String>(entry.label),
            child: SizeTransition(
              axis: Axis.horizontal,
              alignment: AlignmentDirectional.centerStart,
              sizeFactor: entry.sizeAnim,
              child: FadeTransition(
                opacity: entry.fadeAnim,
                child: Container(
                  margin: EdgeInsets.only(right: 6.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    entry.label,
                    style: TextStyle(fontSize: 11.sp),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RegionChip extends StatelessWidget {
  const _RegionChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: active ? Colors.blue.shade600 : Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: active ? Colors.blue.shade700 : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class Page15HorizontalScrollerController extends GetxController {
  final demoWidth = 350.0.obs;
  final mode = Rxn<_DemoMode>(_DemoMode.auto);
  final selectedRegion = RxnString();
  final themeChoice = _DemoThemeChoice.system.obs;
  final compactValue = 'all'.obs;

  final asyncMode = _DemoMode.manual.obs;
  final asyncPendingMode = Rxn<_DemoMode>();
  final simulateAsyncFailure = false.obs;
  final asyncStatusText = '真实态：手动'.obs;
  int _asyncSeq = 0;

  Future<void> _switchAsyncMode(_DemoMode next) async {
    if (asyncPendingMode.value != null) return;
    final seq = ++_asyncSeq;
    final nextLabel = next == _DemoMode.auto ? '智能' : '手动';
    asyncPendingMode.value = next;
    asyncStatusText.value = '后台切换「$nextLabel」中…（800ms）';
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (seq != _asyncSeq) return;
    if (simulateAsyncFailure.value) {
      asyncPendingMode.value = null;
      final realLabel = asyncMode.value == _DemoMode.auto ? '智能' : '手动';
      asyncStatusText.value = '切换失败，已回弹至：$realLabel';
      return;
    }
    asyncMode.value = next;
    asyncPendingMode.value = null;
    asyncStatusText.value = '真实态：$nextLabel（已完成）';
  }

  final regions = const [
    '日本',
    '美国',
    '新加坡',
    '台湾',
    '香港',
    '韩国',
    '英国',
    '德国',
    '加拿大',
  ];

  final dynamicScrollerController = MyHorizontalScrollerController();
  final dynamicScrollOffset = 0.0.obs;
  final trailingAutoReveal = true.obs;

  final dynamicTags = <String>[
    'channel-1: 节点A',
    'channel-2: 节点B',
    'channel-3: 节点C',
  ].obs;

  int _headSeq = 1;
  int _tailSeq = 4;

  @override
  void onInit() {
    super.onInit();
    dynamicScrollerController.addListener(_syncDynamicScrollOffset);
  }

  void _syncDynamicScrollOffset() {
    if (!dynamicScrollerController.hasClients) return;
    final next = dynamicScrollerController.offset;
    if ((next - dynamicScrollOffset.value).abs() >= 0.5) {
      dynamicScrollOffset.value = next;
    }
  }

  @override
  void onClose() {
    dynamicScrollerController.removeListener(_syncDynamicScrollOffset);
    dynamicScrollerController.dispose();
    super.onClose();
  }

  void prependDynamicTag() {
    dynamicScrollerController.prepareLeadingChange(
      anchorDuration: const Duration(milliseconds: 340),
      pulseLeadingIndicator: true,
    );
    dynamicTags.insert(0, 'head-$_headSeq: 新左侧$_headSeq');
    _headSeq++;
  }

  void appendDynamicTag() {
    dynamicScrollerController.notifyTrailingChange(
      reveal: trailingAutoReveal.value
          ? MyHorizontalTrailingReveal.always
          : MyHorizontalTrailingReveal.ifAtEnd,
      revealDuration: const Duration(milliseconds: 340),
    );
    dynamicTags.add('channel-$_tailSeq: 节点$_tailSeq');
    _tailSeq++;
  }

  void removeFirstDynamicTag() {
    if (dynamicTags.isEmpty) return;
    dynamicScrollerController.prepareLeadingChange(
      anchorDuration: const Duration(milliseconds: 300),
      pulseLeadingIndicator: false,
    );
    dynamicTags.removeAt(0);
  }

  void removeLastDynamicTag() {
    if (dynamicTags.isEmpty) return;
    dynamicScrollerController.notifyTrailingChange(
      reveal: MyHorizontalTrailingReveal.never,
      pulseTrailingIndicator: false,
    );
    dynamicTags.removeLast();
  }
}
