/// 智能停靠（`SmartDockManager`）子入口。
///
/// `import 'package:xly/smart_dock.dart';`
library;

export 'src/smart_dock/smart_dock.dart';

import 'src/smart_dock/smart_dock_manager.dart' show SmartDockManager;

/// 与 [AGENTS.md] 命名表一致的别名（与 [SmartDockManager] 同一类型）。
typedef MySmartDock = SmartDockManager;
