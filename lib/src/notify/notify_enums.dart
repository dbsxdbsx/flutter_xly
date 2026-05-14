/// 通知类型枚举
enum MyNotifyType {
  /// 信息通知
  info,

  /// 警告通知
  warning,

  /// 错误通知
  error,

  /// 成功通知
  success,
}

/// 系统通知被平台策略静默时的应用内兜底策略。
enum MyNotifyFallbackPolicy {
  /// 不显示应用内兜底提示。
  never,

  /// 仅 Windows 平台显示应用内兜底提示。
  windowsOnly,

  /// 所有平台都显示应用内兜底提示。
  always,
}

/// Windows 专注助手 / 勿扰模式状态。
enum MyNotifyWindowsFocusAssistMode {
  /// 当前平台不支持该诊断。
  unavailable,

  /// 当前系统未能返回可识别状态。
  unknown,

  /// 关闭，普通通知可以弹出横幅。
  off,

  /// 仅优先通知，普通通知通常会直接进入操作中心。
  priorityOnly,

  /// 仅限闹钟，普通通知不会弹出横幅。
  alarmsOnly,
}
