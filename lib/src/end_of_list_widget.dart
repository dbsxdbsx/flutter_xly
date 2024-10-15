import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyEndOfListWidget extends StatelessWidget {
  final bool isLoading;
  final bool hasError;
  final bool hasMoreData;
  final VoidCallback onRetry;
  final String loadingText;
  final String errorText;
  final String deadLineText;
  final IconData? icon;
  final String? subDeadLineText;
  final double dividerFontSize;
  final Color dividerColor;
  final FontWeight dividerFontWeight;
  final double textFontSize;
  final Color textColor;
  final FontWeight textFontWeight;
  final bool useSliver;

  const MyEndOfListWidget({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.hasMoreData,
    required this.onRetry,
    this.loadingText = '正在加载更多...',
    this.errorText = '加载失败，请重试',
    this.deadLineText = '我是有底线的',
    this.icon = Icons.sentiment_satisfied_alt,
    this.subDeadLineText = '已经到底啦，休息一下吧',
    this.dividerFontSize = 12,
    this.dividerColor = Colors.grey,
    this.dividerFontWeight = FontWeight.w300,
    this.textFontSize = 12,
    this.textColor = Colors.grey,
    this.textFontWeight = FontWeight.w300,
    this.useSliver = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = _buildContent();
    return useSliver ? SliverToBoxAdapter(child: content) : content;
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingWidget();
    } else if (hasError) {
      return _buildErrorWidget();
    } else if (!hasMoreData) {
      return _buildEndOfListWidget();
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget _buildLoadingWidget() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2.w),
            SizedBox(width: 10.w),
            Text(loadingText, style: TextStyle(fontSize: textFontSize.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Center(
          child: Text(errorText,
              style: TextStyle(fontSize: textFontSize.sp, color: Colors.red)),
        ),
      ),
    );
  }

  Widget _buildEndOfListWidget() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildGradientDivider(true)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Text(
                  deadLineText,
                  style: TextStyle(
                    fontSize: dividerFontSize.sp,
                    color: dividerColor,
                    fontWeight: dividerFontWeight,
                  ),
                ),
              ),
              Expanded(child: _buildGradientDivider(false)),
            ],
          ),
          if (icon != null) ...[
            SizedBox(height: 10.h),
            Icon(
              icon,
              color: Colors.grey[400],
              size: 24.sp,
            ),
          ],
          if (subDeadLineText != null) ...[
            SizedBox(height: 5.h),
            Text(
              subDeadLineText!,
              style: TextStyle(
                fontSize: textFontSize.sp,
                color: textColor,
                fontWeight: textFontWeight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGradientDivider(bool isLeft) {
    var highGradient = 1.0;
    var lowGradient = 0.2;
    return Container(
      height: 1.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey[300]!.withOpacity(isLeft ? lowGradient : highGradient),
            Colors.grey[300]!.withOpacity(isLeft ? highGradient : lowGradient),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}
