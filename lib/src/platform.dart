import 'dart:io' as io;

class MyPlatform {
  static bool get isMobile =>
      io.Platform.isAndroid || io.Platform.isIOS || io.Platform.isFuchsia;
  static bool get isDesktop =>
      io.Platform.isWindows || io.Platform.isMacOS || io.Platform.isLinux;

  static bool get isAndroid => io.Platform.isAndroid;
  static bool get isIOS => io.Platform.isIOS;
  static bool get isFuchsia => io.Platform.isFuchsia;
  static bool get isWindows => io.Platform.isWindows;
  static bool get isMacOS => io.Platform.isMacOS;
  static bool get isLinux => io.Platform.isLinux;
}
