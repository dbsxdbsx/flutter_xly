import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

class Page5View extends GetView<Page5Controller> {
  const Page5View({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('URL启动器测试', style: TextStyle(fontSize: 18.sp)),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '点击下面的链接测试URL启动器:',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            _buildUrlSection(),
            const Spacer(),
            Center(
              child: MyButton(
                text: '返回第4页',
                onPressed: () => Get.back(),
                width: 120.w,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUrlItem(
          'GitHub',
          'https://github.com',
          Icons.code,
          Colors.black87,
        ),
        SizedBox(height: 16.h),
        _buildUrlItem(
          'Google',
          'https://google.com',
          Icons.search,
          Colors.blue,
        ),
        SizedBox(height: 16.h),
        _buildUrlItem(
          'Flutter官网',
          'https://flutter.dev',
          Icons.flutter_dash,
          Colors.blue[300]!,
        ),
        SizedBox(height: 16.h),
        _buildUrlItem(
          '百度',
          'https://baidu.com',
          Icons.language,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildUrlItem(String title, String url, IconData icon, Color color) {
    return MyUrlLauncher(
      url: url,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              color: color.withOpacity(0.7),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
}

class Page5Controller extends GetxController {
  // 控制器暂时不需要额外的逻辑
}
