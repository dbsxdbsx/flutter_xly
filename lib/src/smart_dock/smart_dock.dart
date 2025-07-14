/// 智能停靠模块
///
/// 提供窗口智能停靠功能，包括边缘停靠和角落停靠
///
/// 主要功能：
/// - 自动检测窗口拖拽到屏幕边界的行为
/// - 智能判断边缘停靠或角落停靠
/// - 鼠标悬停显示/隐藏窗口
/// - 窗口焦点状态管理
/// - 流畅的动画效果
///
/// 使用示例：
/// ```dart
/// // 启用智能停靠
/// await SmartDockManager.setSmartEdgeDocking(
///   enabled: true,
///   visibleWidth: 5.0,
/// );
///
/// // 禁用智能停靠
/// await SmartDockManager.setSmartEdgeDocking(enabled: false);
///
/// // 停止所有功能
/// await SmartDockManager.stopAll();
/// ```
library;

// 公开接口
export 'smart_dock_manager.dart' show SmartDockManager;

// 内部组件（通常不需要直接使用）
// export 'window_animator.dart' show WindowAnimator, WindowAnimationPresets;
// export 'dock_detector.dart' show DockDetector, DockDetectionResult, DockPositions;
// export 'mouse_tracker.dart' show MouseTracker, MouseTrackingState;
// export 'window_focus_manager.dart' show WindowFocusManager;
