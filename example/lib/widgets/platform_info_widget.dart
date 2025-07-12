import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// 平台信息显示组件
///
/// 显示当前运行平台的详细信息，包括平台名称和各平台检测状态
/// 适用于在侧边栏底部显示系统信息
class PlatformInfoWidget extends StatelessWidget {
  const PlatformInfoWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8.w),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 6.w),
              Text(
                '系统信息',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // 当前平台信息
          _buildInfoRow(
            '平台',
            MyPlatform.platformName,
            context,
          ),
          SizedBox(height: 4.h),

          _buildInfoRow(
            '类型',
            MyPlatform.isDesktop
                ? '桌面'
                : MyPlatform.isMobile
                    ? '移动'
                    : MyPlatform.isWeb
                        ? 'Web'
                        : '未知',
            context,
          ),
          SizedBox(height: 8.h),

          // 平台检测状态
          Text(
            '平台支持',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6.h),

          Wrap(
            spacing: 4.w,
            runSpacing: 4.h,
            children: [
              _buildPlatformChip('Win', MyPlatform.isWindows, context),
              _buildPlatformChip('Mac', MyPlatform.isMacOS, context),
              _buildPlatformChip('Linux', MyPlatform.isLinux, context),
              _buildPlatformChip('Android', MyPlatform.isAndroid, context),
              _buildPlatformChip('iOS', MyPlatform.isIOS, context),
              _buildPlatformChip('Web', MyPlatform.isWeb, context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformChip(String name, bool isActive, BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10.w),
        border: Border.all(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          color: isActive
              ? Theme.of(context).colorScheme.onPrimaryContainer
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
