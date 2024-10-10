import 'package:get/get.dart';

/// 封装 Get.toNamed 的导航函数
///
/// [routeName] 是要导航到的路由名称
/// [arguments] 是可选的，用于传递给下一个页面的参数
/// [preventDuplicates] 是可选的，用于防止重复导航到同一页面
/// [parameters] 是可选的，用于传递查询参数
void goToPage(
  String routeName, {
  dynamic arguments,
  bool preventDuplicates = true,
  Map<String, String>? parameters,
}) {
  Get.toNamed(
    routeName,
    arguments: arguments,
    preventDuplicates: preventDuplicates,
    parameters: parameters,
  );
}