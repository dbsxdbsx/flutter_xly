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
  final double? dropdownMaxHeight;
  final int maxShowDropDownItems;

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

  // Default style constants
  static const double defaultLabelFontSize = 15.0;
  static const double defaultTextFontSize = 12.0;
  static const double defaultHintFontSize = 11.0;
  static const double defaultIconSize = 23.0;
  static const double defaultIconBoxSize = 32.0;
  static const double defaultDropdownMaxHeight = 200.0;
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
    this.dropdownMaxHeight = 200,
    this.maxShowDropDownItems = 5,

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
    return _displayStringForOption(option)
        .toLowerCase()
        .contains(input.toLowerCase());
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
            return RawAutocomplete<String>(
              textEditingController: textController,
              focusNode: controller.focusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (!enabled) return <String>[];
                final allOptions = snapshot.data ?? <String>[];

                if (textEditingValue.text.isNotEmpty) {
                  return allOptions.where(
                    (option) => _filterOption(option, textEditingValue.text),
                  );
                }
                return allOptions;
              },
              onSelected: (String selected) {
                onOptionSelected?.call(selected);
                controller.setDropdownOpen(false);
              },
              optionsViewBuilder: (context, onSelected, options) {
                controller.setDropdownOpen(options.isNotEmpty);
                final dropdownWidth = constraints.maxWidth;

                return _buildDropdownList(
                  context,
                  onSelected,
                  options,
                  dropdownWidth,
                );
              },
              fieldViewBuilder: (context, textEditingController, focusNode,
                  onFieldSubmitted) {
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
      onKeyEvent: (node, event) {
        if (!controller.isDropdownOpen) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.arrowDown:
            case LogicalKeyboardKey.arrowUp:
            case LogicalKeyboardKey.enter:
              // Let RawAutocomplete handle these keys when dropdown is open
              return KeyEventResult.skipRemainingHandlers;
            default:
              return KeyEventResult.ignored;
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

  Widget _buildDropdownList(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
    double dropdownWidth,
  ) {
    final scrollController = ScrollController();
    final visibleOptions = options.take(maxShowDropDownItems).toList();

    // 计算实际需要的高度
    final double itemHeight = defaultDropdownItemHeight.h;
    final double adaptiveHeight = itemHeight * visibleOptions.length;
    final double maxHeight = dropdownMaxHeight ?? defaultDropdownMaxHeight.h;
    final double finalHeight = adaptiveHeight.clamp(0, maxHeight);

    return Align(
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
  }

  Widget _buildDropdownListContent(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
    ScrollController scrollController,
  ) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;

        final optionsList = options.toList();
        final currentIndex = controller.highlightedOption == null
            ? -1
            : optionsList.indexOf(controller.highlightedOption as String);

        switch (event.logicalKey) {
          case LogicalKeyboardKey.arrowDown:
            final nextIndex =
                currentIndex < optionsList.length - 1 ? currentIndex + 1 : 0;
            controller.setHighlightedOption(optionsList[nextIndex]);
            return KeyEventResult.handled;

          case LogicalKeyboardKey.arrowUp:
            final previousIndex =
                currentIndex > 0 ? currentIndex - 1 : optionsList.length - 1;
            controller.setHighlightedOption(optionsList[previousIndex]);
            return KeyEventResult.handled;

          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.space:
            if (controller.highlightedOption != null) {
              onSelected(controller.highlightedOption as String);
              return KeyEventResult.handled;
            }
            break;

          default:
            break;
        }
        return KeyEventResult.ignored;
      },
      child: Obx(() {
        final highlighted = controller.highlightedOption;
        final visibleOptions = options.take(maxShowDropDownItems).toList();
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.zero,
          itemCount: visibleOptions.length,
          itemBuilder: (context, index) => _buildDropdownItem(
            visibleOptions[index],
            highlighted,
            onSelected,
          ),
        );
      }),
    );
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
        FocusManager.instance.primaryFocus?.requestFocus();
      },
      child: InkWell(
        onTap: () => onSelected(option),
        child: Container(
          height: defaultDropdownItemHeight.h,
          color: isHighlighted
              ? (dropdownHighlightColor ?? Colors.blue.withOpacity(0.1))
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

  void setHighlightedOption(String? option) =>
      _highlightedOption.value = option;
  String? get highlightedOption => _highlightedOption.value;

  void updateHasText(String text) {
    _hasText.value = text.isNotEmpty;
  }

  bool get hasText => _hasText.value;
}
