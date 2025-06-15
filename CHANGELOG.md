## 0.5.3

- 修复所有60个诊断消息（错误、警告、信息、提示）
- 将所有弃用的`withOpacity()`替换为`withValues(alpha: ...)`
- 修复弃用的颜色API（alpha、red、green、blue）
- 替换弃用的`addScopedWillPopCallback`为`addLocalHistoryEntry`
- 修复弃用的`dialogBackgroundColor`API
- 将所有`print`语句替换为`debugPrint`
- 移除未使用的代码元素和变量
- 修复私有类型在公共API中使用的问题
- 解决Windows平台CMake构建错误

## 0.5.2

- 修复README.md中底部菜单示例代码错误，将`MyBottomMenu.show()`更正为`MyDialogSheet.showBottom()`

## 0.5.1

- 修复`flutter_inset_box_shadow`依赖问题，更新为`flutter_inset_shadow`[git: 00fdbe0]

## 0.4.0

* 新增MyBottomMenu组件
* 新增MyEndOfListWidget组件
* 新增MyGroupBox组件
* 新增MyList和MyCardList组件
* 新增MyCard组件
* 给菜单组件新增阴影效果

## 0.3.0

* 新增Splash页面
* 新增MyDialog组件
* 新增通过Key返回上一页或退出App功能
* 新增MyApp.exit功能
* 其他细节优化


## 0.2.0

* 新增Focus拓展
* 新增MyButton组件
* 新增MyMenuItem组件
* 新增MyMenu组件
* 新增MyRouter组件
* 新增MyRouterOutlet组件
* 新增MyRouterOutletBuilder组件

## 0.1.0

* 新增MyApp.initialize功能
