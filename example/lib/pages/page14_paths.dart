import 'dart:io';

import 'package:flutter/material.dart';
import 'package:xly/xly.dart';

/// MyPaths（app / userData 双轨）演示页。
class Page14Paths extends StatelessWidget {
  const Page14Paths({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Page14PathsController>(
      init: Page14PathsController(),
      builder: (c) => Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MyPaths / DirStore / Session',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '系统选夹见 package:xly/picker.dart（MyPicker.dir）',
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'appDir: ${c.appDirText}',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  if (c.userDataSummary != null) ...[
                    SizedBox(height: 8.h),
                    Text(c.userDataSummary!, style: TextStyle(fontSize: 12.sp)),
                  ],
                  SizedBox(height: 16.h),
                  MyButton(
                    text: '写入 userData 测试文件',
                    onPressed: c.writeUserDataProbe,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.w),
            child: MyButton(
              icon: Icons.arrow_back,
              text: '返回',
              onPressed: () => Get.back(),
            ),
          ),
        ],
      ),
    );
  }
}

class Page14PathsController extends GetxController {
  String appDirText = '';
  String? userDataSummary;

  @override
  void onInit() {
    super.onInit();
    try {
      appDirText = MyPaths.appDir;
    } catch (e) {
      appDirText = e.toString();
    }
    final dir = Directory.systemTemp.createTempSync('xly_example_ud_');
    MyPaths.setUserDataDir(dir.path);
    userDataSummary = '已 setUserDataDir: ${MyPaths.userDataDir}';
  }

  Future<void> writeUserDataProbe() async {
    final file = await MyPaths.userDataDirFile('paths_demo.json');
    await MyPaths.atomicWriteString(file, '{"ok":true}');
    userDataSummary = '已写入 ${file.path}\n内容: ${await file.readAsString()}';
    update();
  }
}
