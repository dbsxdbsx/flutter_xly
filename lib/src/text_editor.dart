import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

/// A customizable text editor widget with support for dropdown suggestions and styling options.
///
/// This widget provides a rich text editing experience with features like:
/// * Dropdown suggestions
/// * Custom styling
/// * Clear button functionality
/// * Focus management
class MyTextEditor extends GetView<MyTextEditorController> {
  // Core properties
  final TextEditingController textController;
  final String label;
  final String? hint;
  final bool enabled;
  final bool readOnly;
  final bool clearable;
  final VoidCallback? onCleared;
  final ValueChanged<String>? onChanged;

  // Input properties
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;

  // Dropdown properties
  final Future<List<String>> Function()? getDropDownOptions;
  final ValueChanged<String>? onOptionSelected;
  final Widget Function(String)? leadingBuilder;
  final String Function(String)? displayStringForOption;
  final bool Function(String option, String input)? filterOption;
  final EdgeInsetsGeometry? dropDownItemPadding;
  final Color? dropdownHighlightColor;

  final int maxShowDropDownItems;
  // null=auto; true=below; false=above
  final bool? showListCandidateBelow;

  // Style properties - Size
  final double? height;
  final double? labelFontSize;
  final double? textFontSize;
  final double? hintFontSize;
  final double? borderRadius;
  final double? borderWidth;
  final double? contentPadding;
  final double? inSetVerticalPadding;
  final double? inSetHorizontalPadding;

  // Style properties - Color
  final Color normalBorderColor;
  final Color enabledBorderColor;
  final Color focusedBorderColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? labelColor;

  // Style properties - Font Weight
  final FontWeight? labelFontWeight;
  final FontWeight? textFontWeight;

  // Layout properties
  final bool isDense;
  final bool showScrollbar;
  final FloatingLabelBehavior floatingLabelBehavior;

  // Internal properties
  final String uniqueId;
  final GlobalKey _fieldKey = GlobalKey();

  // Default style constants
  static const double defaultLabelFontSize = 15.0;
  static const double defaultTextFontSize = 12.0;
  static const double defaultHintFontSize = 11.0;
  static const double defaultIconSize = 23.0;
  static const double defaultIconBoxSize = 32.0;

  static const double defaultHorizontalPadding = 4.0;
  static const double defaultVerticalPadding = 8.0;
  static const double defaultBorderRadius = 4.0;
  static const double defaultDropdownItemHorizontalPadding = 8.0;
  static const double defaultDropdownItemVerticalPadding = 12.0;
  static const double defaultDropdownItemSpacing = 8.0;
  static const double defaultTextEditorHeight = 48.0;
  static const double defaultDropdownItemHeight = 48.0;

  @override
  String? get tag => uniqueId;

  /// Creates a text editor with customizable properties.
  ///
  /// The [textController] and [label] parameters are required.
  MyTextEditor({
    super.key,
    // Core properties
    required this.textController,
    required this.label,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.clearable = false,
    this.onCleared,
    this.onChanged,

    // Input properties
    this.keyboardType,
    this.inputFormatters,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,

    // Dropdown properties
    this.getDropDownOptions,
    this.onOptionSelected,
    this.leadingBuilder,
    this.displayStringForOption,
    this.filterOption,
    this.dropDownItemPadding,
    this.dropdownHighlightColor,
    this.maxShowDropDownItems = 5,
    this.showListCandidateBelow,

    // Style properties - Size
    this.height,
    this.labelFontSize,
    this.textFontSize,
    this.hintFontSize,
    this.borderRadius,
    this.borderWidth,
    this.contentPadding,
    this.inSetVerticalPadding,
    this.inSetHorizontalPadding,

    // Style properties - Color
    this.normalBorderColor = const Color(0xFFE0E0E0),
    this.enabledBorderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = const Color(0xFF64B5F6),
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.labelColor,

    // Style properties - Font Weight
    this.labelFontWeight,
    this.textFontWeight,

    // Layout properties
    this.isDense = true,
    this.showScrollbar = true,
    this.floatingLabelBehavior = FloatingLabelBehavior.always,
  }) : uniqueId = UniqueKey().toString() {
    Get.put(MyTextEditorController(), tag: uniqueId);
  }

  String _displayStringForOption(String option) {
    if (displayStringForOption != null) {
      return displayStringForOption!(option);
    }
    return option;
  }

  bool _filterOption(String option, String input) {
    if (filterOption != null) {
      return filterOption!(option, input);
    }
    return _displayStringForOption(
      option,
    ).toLowerCase().contains(input.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    if (getDropDownOptions == null) {
      return _buildTextField(context);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<List<String>>(
          future: getDropDownOptions!(),
          builder: (context, snapshot) {
            final openDirection = _computeOpenDirection(context);
            return RawAutocomplete<String>(
              textEditingController: textController,
              focusNode: controller.focusNode,
              optionsViewOpenDirection: openDirection,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (!enabled) return <String>[];

                // 如果刚刚选择了一个选项，不显示下拉列表
                if (controller.justSelected) {
                  controller.updateCurrentOptions([]);
                  return <String>[];
                }

                final allOptions = snapshot.data ?? <String>[];

                if (textEditingValue.text.isNotEmpty) {
                  final filteredOptions = allOptions
                      .where(
                        (option) =>
                            _filterOption(option, textEditingValue.text),
                      )
                      .toList();

                  // 更新控制器中的选项列表，用于键盘导航
                  controller.updateCurrentOptions(filteredOptions);
                  return filteredOptions;
                }
                controller.updateCurrentOptions(allOptions);
                return allOptions;
              },
              onSelected: (String selected) {
                controller.markJustSelected();
                onOptionSelected?.call(selected);
                controller.setDropdownOpen(false);
                controller.clearHighlight();
              },
              optionsViewBuilder: (context, onSelected, options) {
                // 只有在用户没有手动关闭下拉列表时才显示
                final shouldShow =
                    options.isNotEmpty && !controller.manuallyClosedDropdown;
                // 避免在build期间触发响应式更新，延迟到frame结束
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controller.setDropdownOpen(shouldShow);
                });
                final dropdownWidth = constraints.maxWidth;

                // 让 RawAutocomplete 控制展开方向（3.35+），我们仅提供内容和尺寸
                return _buildDropdownList(
                  context,
                  onSelected,
                  options,
                  dropdownWidth,
                );
              },
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                return _buildTextField(
                  context,
                  onSuffixIconTap: () {
                    if (enabled) {
                      focusNode.requestFocus();
                      final currentText = textEditingController.text;
                      textEditingController.text = ' ';
                      Future.microtask(() {
                        textEditingController.text = currentText;
                        textEditingController.selection =
                            TextSelection.collapsed(
                          offset: currentText.length,
                        );
                      });
                      onFieldSubmitted();
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    BuildContext context, {
    VoidCallback? onSuffixIconTap,
  }) {
    return Focus(
      key: _fieldKey,
      onKeyEvent: (node, event) {
        // 处理按键按下和重复事件（支持按住键快速导航）
        if (event is KeyDownEvent || event is KeyRepeatEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
              if (controller.isDropdownOpen) {
                controller.navigateDown();
                return KeyEventResult.handled;
              }
              break;
            case LogicalKeyboardKey.arrowUp:
              if (controller.isDropdownOpen) {
                controller.navigateUp();
                return KeyEventResult.handled;
              }
              break;
            case LogicalKeyboardKey.enter:
              // Enter键只在按下时处理，不处理重复事件
              if (event is KeyDownEvent && controller.isDropdownOpen) {
                final selected = controller.selectHighlighted();
                if (selected != null) {
                  controller.markJustSelected();
                  onOptionSelected?.call(selected);
                  controller.setDropdownOpen(false);
                  controller.clearHighlight();
                  return KeyEventResult.handled;
                }
              }
              break;
            case LogicalKeyboardKey.escape:
              // Escape键只在按下时处理，不处理重复事件
              if (event is KeyDownEvent) {
                if (controller.isDropdownOpen) {
                  // 如果下拉列表打开，关闭下拉列表并标记为手动关闭
                  controller.setDropdownOpen(false);
                  controller.clearHighlight();
                  controller.markDropdownManuallyClosed();
                  return KeyEventResult.handled;
                } else if (node.hasFocus) {
                  // 如果编辑器有焦点但下拉列表关闭，让编辑器失去焦点
                  controller.focusNode.unfocus();
                  return KeyEventResult.handled;
                }
              }
              break;
            default:
              break;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: textController,
        focusNode: controller.focusNode,
        enabled: enabled && !readOnly,
        readOnly: readOnly,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: (value) {
          controller.updateHasText(value);
          // 用户开始输入时，重置手动关闭标志，允许下拉列表重新显示
          controller.resetManuallyClosedFlag();
          onChanged?.call(value);
        },
        maxLines: maxLines,
        textAlign: textAlign,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(
          fontSize: (textFontSize ?? defaultTextFontSize).sp,
          height: 1.0,
          color: textColor,
          fontWeight: textFontWeight,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: (labelFontSize ?? defaultLabelFontSize).sp,
            color: enabled ? labelColor : Colors.grey,
            fontWeight: labelFontWeight,
          ),
          hintText: hint,
          hintStyle: TextStyle(
            color: hintColor ?? Colors.grey[400],
            fontSize: (hintFontSize ?? defaultHintFontSize).sp,
            height: 1.0,
          ),
          isDense: true,
          filled: backgroundColor != null,
          fillColor: backgroundColor,
          floatingLabelBehavior: floatingLabelBehavior,
          contentPadding: _getEditorBoxContentPadding(),
          border: _buildBorder(normalBorderColor),
          enabledBorder: _buildBorder(enabledBorderColor),
          focusedBorder: _buildBorder(focusedBorderColor),
          suffixIcon: _buildSuffixIcon(onSuffixIconTap),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(VoidCallback? onSuffixIconTap) {
    if (getDropDownOptions != null) {
      return SizedBox(
        width: defaultIconBoxSize.w,
        height: defaultIconBoxSize.h,
        child: Center(
          child: IconButton(
            iconSize: defaultIconSize.w,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onPressed: onSuffixIconTap,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              maxWidth: defaultIconBoxSize.w,
              maxHeight: defaultIconBoxSize.h,
              minWidth: defaultIconBoxSize.w,
              minHeight: defaultIconBoxSize.h,
            ),
            splashRadius: (defaultIconBoxSize / 2).r,
          ),
        ),
      );
    }

    if (clearable) {
      return Obx(() {
        if (!controller.hasText) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: defaultIconBoxSize.w,
          height: defaultIconBoxSize.h,
          child: Center(
            child: IconButton(
              iconSize: defaultIconSize.w,
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                textController.clear();
                controller.updateHasText('');
                onCleared?.call();
              },
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                maxWidth: defaultIconBoxSize.w,
                maxHeight: defaultIconBoxSize.h,
                minWidth: defaultIconBoxSize.w,
                minHeight: defaultIconBoxSize.h,
              ),
              splashRadius: (defaultIconBoxSize / 2).r,
            ),
          ),
        );
      });
    }

    return null;
  }

  // 基于当前输入框位置与可用空间，计算候选面板展开方向（3.35+）
  OptionsViewOpenDirection _computeOpenDirection(BuildContext context) {
    // 1) 明确指定：true=向下，false=向上
    if (showListCandidateBelow != null) {
      return showListCandidateBelow!
          ? OptionsViewOpenDirection.down
          : OptionsViewOpenDirection.up;
    }

    // 2) 自动：基于可用空间与预计高度选择
    final ctx = _fieldKey.currentContext;
    if (ctx == null) {
      return OptionsViewOpenDirection.down;
    }
    final box = ctx.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (box == null || overlay == null) {
      return OptionsViewOpenDirection.down;
    }

    final fieldTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final fieldSize = box.size;
    final overlaySize = overlay.size;
    final spaceBelow =
        overlaySize.height - (fieldTopLeft.dy + fieldSize.height);
    final spaceAbove = fieldTopLeft.dy;

    // 以“完整显示预计高度”为标准选择方向（优先向下）
    final double itemHeight = defaultDropdownItemHeight.h;
    final double expectedHeight = itemHeight * maxShowDropDownItems;

    if (spaceBelow >= expectedHeight || spaceBelow >= spaceAbove) {
      return OptionsViewOpenDirection.down;
    }
    return OptionsViewOpenDirection.up;
  }

  Widget _buildDropdownList(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
    double dropdownWidth,
  ) {
    final scrollController = ScrollController();

    // 将ScrollController和参数传递给控制器
    controller.setDropdownScrollController(scrollController);
    controller.setDropdownParameters(itemHeight: defaultDropdownItemHeight.h);

    // 计算实际需要的高度
    final double itemHeight = defaultDropdownItemHeight.h;
    final int totalOptions = options.length;
    final int displayItems = totalOptions.clamp(1, maxShowDropDownItems);
    double desiredHeight = itemHeight * displayItems;

    // 根据展开方向裁剪高度；位置交由 RawAutocomplete 控制
    final dir = _computeOpenDirection(context);
    if (_fieldKey.currentContext != null) {
      final box = _fieldKey.currentContext!.findRenderObject() as RenderBox?;
      final overlay =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (box != null && overlay != null) {
        final fieldTopLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
        final fieldSize = box.size;
        final overlaySize = overlay.size;
        final spaceBelow =
            overlaySize.height - (fieldTopLeft.dy + fieldSize.height);
        final spaceAbove = fieldTopLeft.dy;
        if (dir == OptionsViewOpenDirection.down) {
          desiredHeight = desiredHeight.clamp(0, spaceBelow);
        } else {
          desiredHeight = desiredHeight.clamp(0, spaceAbove);
        }
      }
    }

    final double finalHeight = desiredHeight;

    final Widget dropdownWidget = Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: finalHeight,
            maxWidth: dropdownWidth,
            minWidth: dropdownWidth,
          ),
          child: Scrollbar(
            controller: scrollController,
            thumbVisibility: showScrollbar,
            child: _buildDropdownListContent(
              context,
              onSelected,
              options,
              scrollController,
            ),
          ),
        ),
      ),
    );

    // 不做位移，位置完全由 RawAutocomplete 确定
    return SizedBox(
      height: finalHeight,
      width: dropdownWidth,
      child: Align(alignment: Alignment.topLeft, child: dropdownWidget),
    );
  }

  Widget _buildDropdownListContent(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
    ScrollController scrollController,
  ) {
    return Obx(() {
      final highlighted = controller.highlightedOption;
      final allOptions = options.toList(); // 使用所有选项，不限制数量
      return ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        itemCount: allOptions.length, // 显示所有选项
        itemBuilder: (context, index) =>
            _buildDropdownItem(allOptions[index], highlighted, onSelected),
      );
    });
  }

  Widget _buildDropdownItem(
    String option,
    String? highlighted,
    void Function(String) onSelected,
  ) {
    final isHighlighted = identical(option, highlighted);

    return MouseRegion(
      onEnter: (_) {
        controller.setHighlightedOption(option);
      },
      child: InkWell(
        onTap: () => onSelected(option),
        child: Container(
          height: defaultDropdownItemHeight.h,
          color: isHighlighted
              ? (dropdownHighlightColor ?? Colors.blue.withValues(alpha: 0.1))
              : null,
          padding: dropDownItemPadding ??
              EdgeInsets.symmetric(
                horizontal: defaultDropdownItemHorizontalPadding.w,
                vertical: defaultDropdownItemVerticalPadding.h,
              ),
          child: Row(
            children: [
              if (leadingBuilder != null) ...[
                leadingBuilder!(option),
                SizedBox(width: defaultDropdownItemSpacing.w),
              ],
              Expanded(
                child: Text(
                  _displayStringForOption(option),
                  style: TextStyle(
                    fontSize: (textFontSize ?? defaultTextFontSize).sp,
                    color: isHighlighted ? Colors.blue[700] : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  EdgeInsetsGeometry _getEditorBoxContentPadding() {
    final double verticalPadding =
        ((defaultTextEditorHeight - (textFontSize ?? defaultTextFontSize)) / 2)
            .h;

    if (inSetHorizontalPadding != null && inSetVerticalPadding != null) {
      return EdgeInsets.symmetric(
        horizontal: inSetHorizontalPadding!,
        vertical: inSetVerticalPadding!,
      );
    }
    if (inSetHorizontalPadding != null) {
      return EdgeInsets.symmetric(
        horizontal: inSetHorizontalPadding!,
        vertical: verticalPadding,
      );
    }
    if (inSetVerticalPadding != null) {
      return EdgeInsets.symmetric(
        horizontal: defaultHorizontalPadding.w,
        vertical: inSetVerticalPadding!,
      );
    }
    return EdgeInsets.symmetric(
      vertical: verticalPadding,
      horizontal: defaultHorizontalPadding.w,
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultBorderRadius.r),
      borderSide: BorderSide(color: color),
    );
  }
}

/// Controller for managing the text editor's state and functionality.
class MyTextEditorController extends GetxController {
  /// Whether the text editor has focus
  final _hasFocus = false.obs;

  /// Whether the dropdown is currently open
  final _isDropdownOpen = false.obs;

  /// The currently highlighted dropdown option
  final _highlightedOption = Rxn<String>();

  /// Whether the text editor contains any text
  final _hasText = false.obs;

  /// Current available options for keyboard navigation
  final _currentOptions = <String>[].obs;

  /// Current highlighted index for keyboard navigation
  final _highlightedIndex = (-1).obs;

  /// Flag to indicate if an option was just selected
  final _justSelected = false.obs;

  /// Flag to indicate if user manually closed the dropdown
  final _manuallyClosedDropdown = false.obs;

  /// 展开方向（Flutter 3.35+）
  final _optionsDirection = OptionsViewOpenDirection.down.obs;
  OptionsViewOpenDirection get optionsDirection => _optionsDirection.value;
  void setOptionsDirection(OptionsViewOpenDirection dir) =>
      _optionsDirection.value = dir;

  /// ScrollController for dropdown list
  ScrollController? _dropdownScrollController;

  /// Dropdown item height for scroll calculation
  double _itemHeight = 48.0;

  late final FocusNode focusNode;

  @override
  void onInit() {
    super.onInit();
    focusNode = FocusNode();
    focusNode.addListener(_onFocusChange);
  }

  @override
  void onClose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    super.onClose();
  }

  void _onFocusChange() {
    if (focusNode.hasFocus) {
      setDropdownOpen(true);
    }
  }

  void setFocus(String key) => _hasFocus.value = true;
  bool get hasFocus => _hasFocus.value;

  void setDropdownOpen(bool open) => _isDropdownOpen.value = open;
  bool get isDropdownOpen => _isDropdownOpen.value;

  void setHighlightedOption(String? option) {
    _highlightedOption.value = option;
    // 同步更新索引，确保键盘导航从正确位置继续
    if (option != null) {
      final index = _currentOptions.indexOf(option);
      if (index != -1) {
        _highlightedIndex.value = index;
      }
    } else {
      _highlightedIndex.value = -1;
    }
  }

  String? get highlightedOption => _highlightedOption.value;

  void updateHasText(String text) {
    _hasText.value = text.isNotEmpty;
  }

  bool get hasText => _hasText.value;

  /// Update current options for keyboard navigation
  void updateCurrentOptions(List<String> options) {
    _currentOptions.value = options;
    // 重置高亮索引
    _highlightedIndex.value = -1;
    _highlightedOption.value = null;
  }

  /// Clear highlight
  void clearHighlight() {
    _highlightedOption.value = null;
    _highlightedIndex.value = -1;
  }

  /// Mark that an option was just selected
  void markJustSelected() {
    _justSelected.value = true;
    // 延迟重置标志，给optionsBuilder时间响应
    Future.delayed(const Duration(milliseconds: 100), () {
      _justSelected.value = false;
    });
  }

  /// Check if an option was just selected
  bool get justSelected => _justSelected.value;

  /// Check if user manually closed the dropdown
  bool get manuallyClosedDropdown => _manuallyClosedDropdown.value;

  /// Mark that user manually closed the dropdown
  void markDropdownManuallyClosed() {
    _manuallyClosedDropdown.value = true;
  }

  /// Reset the manually closed flag (when user starts typing or focuses)
  void resetManuallyClosedFlag() {
    _manuallyClosedDropdown.value = false;
  }

  /// Set dropdown scroll controller
  void setDropdownScrollController(ScrollController? controller) {
    _dropdownScrollController = controller;
  }

  /// Set dropdown parameters for scroll calculation
  void setDropdownParameters({required double itemHeight}) {
    _itemHeight = itemHeight;
  }

  /// Navigate to next option
  void navigateDown() {
    if (_currentOptions.isEmpty) return;

    final currentIndex = _highlightedIndex.value;
    int nextIndex;

    if (currentIndex == -1) {
      // 如果没有选中任何项，选中第一项
      nextIndex = 0;
    } else if (currentIndex < _currentOptions.length - 1) {
      // 如果不是最后一项，移动到下一项
      nextIndex = currentIndex + 1;
    } else {
      // 如果已经是最后一项，保持在最后一项
      nextIndex = currentIndex;
    }

    _highlightedIndex.value = nextIndex;
    _highlightedOption.value = _currentOptions[nextIndex];

    // 自动滚动到可见位置（使用实际的widget属性）
    _scrollToIndex(nextIndex);
  }

  /// Navigate to previous option
  void navigateUp() {
    if (_currentOptions.isEmpty) return;

    final currentIndex = _highlightedIndex.value;
    int previousIndex;

    if (currentIndex == -1) {
      // 如果没有选中任何项，选中最后一项
      previousIndex = _currentOptions.length - 1;
    } else if (currentIndex > 0) {
      // 如果不是第一项，移动到上一项
      previousIndex = currentIndex - 1;
    } else {
      // 如果已经是第一项，保持在第一项
      previousIndex = currentIndex;
    }

    _highlightedIndex.value = previousIndex;
    _highlightedOption.value = _currentOptions[previousIndex];

    // 自动滚动到可见位置（使用实际的widget属性）
    _scrollToIndex(previousIndex);
  }

  /// Scroll the dropdown so that the item at [index] is fully visible.
  /// This version uses the actual viewport dimension and maxScrollExtent
  /// from the ScrollController instead of an estimated visible item count.
  void _scrollToIndex(int index) {
    final controller = _dropdownScrollController;
    if (controller == null || !controller.hasClients) return;

    final position = controller.position;

    // 如果内容高度不超过可视高度，无需滚动
    final contentHeight = _currentOptions.length * _itemHeight;
    final viewportHeight = position.viewportDimension;
    if (contentHeight <= viewportHeight) return;

    final double currentOffset = position.pixels;
    final double viewportTop = currentOffset;
    final double viewportBottom = viewportTop + viewportHeight;

    // 当前项的上下边界
    final double itemTop = index * _itemHeight;
    final double itemBottom = itemTop + _itemHeight;

    double? targetOffset;
    if (itemTop < viewportTop) {
      // 目标项在可视区上方：把它对齐到顶部
      targetOffset = itemTop;
    } else if (itemBottom > viewportBottom) {
      // 目标项在可视区下方：把它对齐到底部（让其整个露出）
      targetOffset = itemBottom - viewportHeight;
    }

    if (targetOffset != null) {
      final double clampedOffset = targetOffset.clamp(
        0.0,
        position.maxScrollExtent,
      );

      // 若正在滚动，先停止到当前像素，避免动画叠加造成抖动
      if (position.isScrollingNotifier.value) {
        controller.jumpTo(controller.offset);
      }

      controller.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  /// Select current highlighted option
  String? selectHighlighted() {
    if (_highlightedIndex.value >= 0 &&
        _highlightedIndex.value < _currentOptions.length) {
      return _currentOptions[_highlightedIndex.value];
    }
    return null;
  }
}
