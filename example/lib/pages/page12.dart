import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

import '../widgets/section_title.dart';

class Page12View extends GetView<Page12Controller> {
  const Page12View({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 场景 1：基础用法（compact 紧凑模式，默认） ──
          const SectionTitle('基础 TabView（compact 紧凑，默认）'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 200.h,
            child: const MyTabView(
              tabs: [
                MyTab(label: '标签一'),
                MyTab(label: '标签二'),
                MyTab(label: '标签三'),
              ],
              children: [
                _DemoContent(
                  icon: Icons.looks_one,
                  label: '第一个标签的内容',
                  color: Colors.blue,
                ),
                _DemoContent(
                  icon: Icons.looks_two,
                  label: '第二个标签的内容',
                  color: Colors.green,
                ),
                _DemoContent(
                  icon: Icons.looks_3,
                  label: '第三个标签的内容',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── 场景 1b：stretched 拉伸模式 ──
          const SectionTitle('stretched 拉伸模式'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 200.h,
            child: const MyTabView(
              tabBarFit: MyTabBarFit.stretched,
              tabs: [
                MyTab(label: '标签一'),
                MyTab(label: '标签二'),
                MyTab(label: '标签三'),
              ],
              children: [
                _DemoContent(
                  icon: Icons.looks_one,
                  label: '第一个标签的内容（stretched 模式）',
                  color: Colors.blue,
                ),
                _DemoContent(
                  icon: Icons.looks_two,
                  label: '第二个标签的内容（stretched 模式）',
                  color: Colors.green,
                ),
                _DemoContent(
                  icon: Icons.looks_3,
                  label: '第三个标签的内容（stretched 模式）',
                  color: Colors.orange,
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── 场景 2：底部 Tab + 两种模式并排对比 ──
          const SectionTitle('底部 Tab：stretched vs compact 对比'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 200.h,
            child: Row(
              children: [
                // 左侧：compact（默认）
                Expanded(
                  child: Column(
                    children: [
                      Text('compact（默认）',
                          style: TextStyle(
                              fontSize: 11.sp, color: Colors.grey.shade600)),
                      SizedBox(height: 4.h),
                      const Expanded(
                        child: MyTabView(
                          position: MyTabPosition.bottom,
                          tabs: [
                            MyTab(label: '棋谱'),
                            MyTab(label: '日志'),
                          ],
                          children: [
                            _DemoContent(
                                icon: Icons.menu_book,
                                label: '棋谱内容',
                                color: Colors.red),
                            _DemoContent(
                                icon: Icons.article,
                                label: '日志内容',
                                color: Colors.blueGrey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                // 右侧：stretched
                Expanded(
                  child: Column(
                    children: [
                      Text('stretched',
                          style: TextStyle(
                              fontSize: 11.sp, color: Colors.grey.shade600)),
                      SizedBox(height: 4.h),
                      const Expanded(
                        child: MyTabView(
                          position: MyTabPosition.bottom,
                          tabBarFit: MyTabBarFit.stretched,
                          tabs: [
                            MyTab(label: '棋谱'),
                            MyTab(label: '日志'),
                          ],
                          children: [
                            _DemoContent(
                                icon: Icons.menu_book,
                                label: '棋谱内容',
                                color: Colors.red),
                            _DemoContent(
                                icon: Icons.article,
                                label: '日志内容',
                                color: Colors.blueGrey),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── 场景 3：自定义样式 + 带图标 ──
          const SectionTitle('自定义样式（带图标 + 自定义配色）'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 180.h,
            child: MyTabView(
              tabBarBackgroundColor: Colors.grey.shade200,
              contentBorderColor: Colors.grey.shade300,
              tabs: [
                MyTab(
                  label: '下载',
                  icon: Icon(Icons.download, size: 14.sp),
                  activeColor: Colors.blue.shade100,
                  activeTextStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                MyTab(
                  label: '上传',
                  icon: Icon(Icons.upload, size: 14.sp),
                  activeColor: Colors.green.shade100,
                  activeTextStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
                MyTab(
                  label: '历史',
                  icon: Icon(Icons.history, size: 14.sp),
                  activeColor: Colors.orange.shade100,
                  activeTextStyle: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
              children: const [
                _DemoContent(
                    icon: Icons.download, label: '下载列表区域', color: Colors.blue),
                _DemoContent(
                    icon: Icons.upload, label: '上传列表区域', color: Colors.green),
                _DemoContent(
                    icon: Icons.history, label: '历史记录区域', color: Colors.orange),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── 场景 4：带切换动画 ──
          const SectionTitle('带切换动画（FadeTransition）'),
          SizedBox(height: 8.h),
          SizedBox(
            height: 160.h,
            child: MyTabView(
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              transitionDuration: const Duration(milliseconds: 400),
              tabs: const [
                MyTab(label: '淡入淡出 A'),
                MyTab(label: '淡入淡出 B'),
              ],
              children: const [
                _DemoContent(
                    icon: Icons.animation,
                    label: '页面 A（切换时有淡入淡出效果）',
                    color: Colors.purple),
                _DemoContent(
                    icon: Icons.animation,
                    label: '页面 B（切换时有淡入淡出效果）',
                    color: Colors.teal),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── 导航按钮 ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MyButton(
                icon: Icons.arrow_back,
                text: '返回上页',
                onPressed: () => Get.toNamed(MyRoutes.page11),
                size: 80.w,
              ),
            ],
          ),
          SizedBox(height: 16.h),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 演示用辅助组件
// ─────────────────────────────────────────────────────────

/// 通用内容占位
class _DemoContent extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DemoContent({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32.w, color: color.withValues(alpha: 0.6)),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// 控制器
// ─────────────────────────────────────────────────────────

class Page12Controller extends GetxController {}
