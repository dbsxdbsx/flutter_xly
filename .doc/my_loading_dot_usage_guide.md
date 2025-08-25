# MyLoadingDot 使用指南

## 概述

MyLoadingDot 是 xly_flutter_package 中的多点动态加载指示器组件，专为各种加载场景设计。它提供了四种不同的动画效果，支持高度自定义，并能自适应容器宽度，是一个轻量级且功能强大的加载指示器解决方案。

## 主要特性

### 🎯 核心功能
- **多种动画效果**：支持fade（淡入淡出）、bounce（弹跳）、scale（缩放）、wave（波动）四种动画类型
- **自适应布局**：自动适应容器宽度，智能调整点大小和间距，避免越界
- **低性能开销**：单控制器驱动多点相位动画，高效节能
- **防同步机制**：支持随机化起始相位，避免多实例同步问题
- **灵活配置**：支持自定义点数量、大小、间距、颜色、动画周期等参数

### 🎨 动画类型详解

#### 1. Fade（淡入淡出）- 默认
- **效果**：点的透明度在0.3-1.0之间周期性变化
- **适用场景**：通用加载、"正在输入"提示
- **视觉特点**：温和、不干扰，适合长时间显示

#### 2. Bounce（弹跳）
- **效果**：点在垂直方向上下弹跳，同时透明度变化
- **适用场景**：活跃的加载场景、游戏界面
- **视觉特点**：动感强烈，吸引注意力

#### 3. Scale（缩放）
- **效果**：点的大小在0.6-1.0倍之间缩放，配合透明度变化
- **适用场景**：按钮加载状态、紧凑空间
- **视觉特点**：脉冲感强，占用空间相对固定

#### 4. Wave（波动）
- **效果**：轻微的垂直波动配合透明度变化
- **适用场景**：优雅的加载场景、高端应用
- **视觉特点**：柔和波动，视觉舒适

### ⚡ 性能优化
- **单控制器架构**：所有点共享一个AnimationController，减少资源消耗
- **相位错峰**：通过数学计算实现点之间的相位差，无需多个控制器
- **智能布局**：LayoutBuilder动态计算最优尺寸，避免重复计算
- **内存友好**：组件销毁时自动释放动画控制器资源

## 基础用法

### 1. 最简单的使用
```dart
// 默认fade动画，3个点
MyLoadingDot()
```

### 2. "正在输入"场景（推荐）
```dart
// 专门为聊天"正在输入"优化的工厂方法
MyLoadingDot.typing(
  size: 6.w,
  gap: 2.w,
  color: Colors.grey,
)
```

### 3. 自定义动画类型
```dart
// 弹跳动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.bounce,
  size: 8.w,
  gap: 3.w,
  color: Colors.blue,
)

// 缩放动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.scale,
  size: 10.w,
  gap: 4.w,
  color: Colors.green,
)

// 波动动画
MyLoadingDot(
  dotAnimation: MyLoadingDotAnimation.wave,
  size: 8.w,
  gap: 3.w,
  color: Colors.purple,
)
```

## 高级配置

### 1. 自定义点数量和周期
```dart
MyLoadingDot(
  dotCount: 5,                                    // 5个点
  period: const Duration(milliseconds: 1400),     // 更慢的动画周期
  phaseShift: 0.2,                               // 整体相位偏移
  size: 8.w,
  gap: 2.w,
  color: Colors.blueGrey,
)
```

### 2. 禁用随机起始相位
```dart
MyLoadingDot(
  randomizeStartPhase: false,  // 多个实例将同步动画
  dotAnimation: MyLoadingDotAnimation.fade,
)
```

### 3. 响应式尺寸适配
```dart
// 推荐：使用flutter_screenutil的响应式单位
MyLoadingDot(
  size: 12.w,      // 响应式宽度
  gap: 4.w,        // 响应式间距
  color: Theme.of(context).primaryColor,
)
```

## 实际应用场景

### 1. 聊天界面"正在输入"
```dart
Row(
  children: [
    // 使用专门的typing工厂方法
    MyLoadingDot.typing(
      size: 6.w,
      gap: 2.w,
      color: Colors.grey,
    ),
    SizedBox(width: 8.w),
    Text('AI 正在输入…'),
  ],
)
```

### 2. 按钮加载状态
```dart
ElevatedButton(
  onPressed: isLoading ? null : _handleSubmit,
  child: isLoading 
    ? MyLoadingDot(
        dotAnimation: MyLoadingDotAnimation.scale,
        size: 4.w,
        gap: 1.w,
        color: Colors.white,
        dotCount: 3,
      )
    : Text('提交'),
)
```

### 3. 列表底部加载更多
```dart
Container(
  padding: EdgeInsets.all(16.w),
  child: Center(
    child: MyLoadingDot(
      dotAnimation: MyLoadingDotAnimation.bounce,
      size: 8.w,
      gap: 3.w,
      color: Theme.of(context).primaryColor,
    ),
  ),
)
```

### 4. 全屏加载覆盖层
```dart
Stack(
  children: [
    // 主要内容
    YourMainContent(),
    
    // 加载覆盖层
    if (isLoading)
      Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyLoadingDot(
                dotAnimation: MyLoadingDotAnimation.wave,
                size: 12.w,
                gap: 4.w,
                color: Colors.white,
                dotCount: 4,
              ),
              SizedBox(height: 16.h),
              Text(
                '加载中...',
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            ],
          ),
        ),
      ),
  ],
)
```

## 参数详解

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `size` | `double` | `6.0` | 单个圆点直径，建议使用`.w`单位 |
| `gap` | `double` | `2.0` | 圆点间距，建议使用`.w`单位 |
| `dotCount` | `int` | `3` | 点数量，必须大于0 |
| `color` | `Color` | `Color(0xFF666666)` | 圆点颜色 |
| `period` | `Duration` | `Duration(milliseconds: 900)` | 动画周期 |
| `dotAnimation` | `MyLoadingDotAnimation` | `fade` | 动画类型 |
| `phaseShift` | `double` | `0.0` | 相位偏移（0~1），用于整体移动波形 |
| `randomizeStartPhase` | `bool` | `true` | 是否随机化起始相位 |

## 最佳实践

### 1. 尺寸建议
- **小型场景**（按钮内）：`size: 4.w, gap: 1.w`
- **中型场景**（正在输入）：`size: 6.w, gap: 2.w`
- **大型场景**（全屏加载）：`size: 10.w, gap: 4.w`

### 2. 动画选择
- **长时间显示**：使用`fade`，视觉干扰最小
- **需要吸引注意**：使用`bounce`，动感强烈
- **空间受限**：使用`scale`，占用空间相对固定
- **高端应用**：使用`wave`，视觉效果优雅

### 3. 颜色搭配
```dart
// 跟随主题色
color: Theme.of(context).primaryColor

// 适应背景
color: isDarkMode ? Colors.white70 : Colors.black54

// 状态指示
color: isError ? Colors.red : Colors.blue
```

### 4. 性能考虑
- 避免同时显示过多实例（建议不超过3-5个）
- 在不需要时及时移除组件，释放动画资源
- 对于长列表中的加载项，考虑使用懒加载

## 注意事项

1. **容器宽度**：组件会自动适应容器宽度，但在无限宽度容器中会使用默认尺寸
2. **动画生命周期**：组件会自动管理动画控制器的生命周期，无需手动处理
3. **多实例同步**：默认启用随机起始相位，避免多个实例同步动画
4. **响应式适配**：强烈建议使用`.w`和`.h`单位确保跨设备一致性

## 故障排除

### 问题：动画不流畅
**解决方案**：检查是否在高频重建的Widget中使用，考虑使用`const`构造函数或缓存实例

### 问题：多个实例动画同步
**解决方案**：确保`randomizeStartPhase`为`true`（默认值）

### 问题：在小容器中显示异常
**解决方案**：组件会自动适应容器宽度，如果仍有问题，可以手动调整`size`和`gap`参数

### 问题：颜色显示不正确
**解决方案**：检查是否受到父Widget的颜色过滤器影响，或者主题设置是否正确
