/// 解析可写文件时使用的根目录类型（配合 [MyPlatform.resolveFile]）。
enum MyFileRoot {
  /// 安装目录：桌面为 exe 所在目录；移动为应用文档目录（与 [MyPlatform.installDirectory] / [MyPlatform.getAppDirectory] 一致）。
  install,

  /// 用户数据目录：须先 [MyUserDataPaths.setRoot]。
  userData,
}
