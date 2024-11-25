import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xly/xly.dart';

class MyTextEditor extends GetView<MyTextEditorController> {
  final TextEditingController textController;
  final String label;
  final String? hint;
  final TextInputType? keyboardType;
  final bool isDense;
  final double? labelFontSize;
  final double? textFontSize;
  final double? hintFontSize;
  final double? inSetVerticalPadding;
  final double? inSetHorizontalPadding;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final double? height;
  final Color normalBorderColor;
  final Color enabledBorderColor;
  final Color focusedBorderColor;
  final FloatingLabelBehavior floatingLabelBehavior;

  // 下拉列表相关属性
  final Future<List<String>> Function()? getDropDownOptions;
  final ValueChanged<String>? onOptionSelected;
  final Widget Function(String)? leadingBuilder;
  final String Function(String)? displayStringForOption;
  final bool Function(String option, String input)? filterOption;
  final double? dropdownMaxHeight;
  final Color? dropdownHighlightColor;
  final bool enabled;

  // Add a unique identifier field
  final String uniqueId;

  final bool showScrollbar;

  // 添加新的样式相关属性
  final double? contentPadding;
  final double? borderRadius;
  final double? borderWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? labelColor;
  final FontWeight? labelFontWeight;
  final FontWeight? textFontWeight;

  // 添加新的功能属性
  final bool clearable;
  final VoidCallback? onClear;
  final bool readOnly;
  final String? errorText;
  final String? helperText;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;

  @override
  String? get tag => uniqueId;

  MyTextEditor({
    super.key,
    required this.textController,
    required this.label,
    this.hint,
    this.keyboardType,
    this.isDense = true,
    this.labelFontSize,
    this.textFontSize,
    this.hintFontSize,
    this.inSetVerticalPadding,
    this.inSetHorizontalPadding,
    this.inputFormatters,
    this.onChanged,
    this.maxLines = 1,
    this.height,
    this.normalBorderColor = const Color(0xFFE0E0E0),
    this.enabledBorderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = const Color(0xFF64B5F6),
    this.floatingLabelBehavior = FloatingLabelBehavior.always,
    this.getDropDownOptions,
    this.onOptionSelected,
    this.leadingBuilder,
    this.displayStringForOption,
    this.filterOption,
    this.dropdownMaxHeight = 200,
    this.dropdownHighlightColor,
    this.enabled = true,
    this.showScrollbar = true,
    this.contentPadding,
    this.borderRadius,
    this.borderWidth,
    this.backgroundColor,
    this.textColor,
    this.hintColor,
    this.labelColor,
    this.labelFontWeight,
    this.textFontWeight,
    this.clearable = false,
    this.onClear,
    this.readOnly = false,
    this.errorText,
    this.helperText,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
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
    return SizedBox(
      height: height,
      child: Focus(
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
          onChanged: onChanged,
          maxLines: maxLines,
          textAlign: textAlign,
          textAlignVertical: textAlignVertical,
          style: TextStyle(
            fontSize: textFontSize ?? 12.sp,
            height: 1.0,
            color: textColor,
            fontWeight: textFontWeight,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontSize: labelFontSize ?? 15.sp,
              color: enabled ? labelColor : Colors.grey,
              fontWeight: labelFontWeight,
            ),
            hintText: hint,
            hintStyle: TextStyle(
              color: hintColor ?? Colors.grey[400],
              fontSize: hintFontSize ?? 11.sp,
              height: 1.0,
            ),
            errorText: errorText,
            helperText: helperText,
            isDense: isDense,
            filled: backgroundColor != null,
            fillColor: backgroundColor,
            floatingLabelBehavior: floatingLabelBehavior,
            contentPadding: _getContentPadding(),
            border: _buildBorder(normalBorderColor),
            enabledBorder: _buildBorder(enabledBorderColor),
            focusedBorder: _buildBorder(focusedBorderColor),
            suffixIcon: _buildSuffixIcon(onSuffixIconTap),
          ),
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(VoidCallback? onSuffixIconTap) {
    if (getDropDownOptions != null) {
      return SizedBox(
        width: 32.w,
        height: 32.h,
        child: Center(
          child: IconButton(
            iconSize: 23.w,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            onPressed: onSuffixIconTap,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(
              maxWidth: 32.w,
              maxHeight: 32.h,
              minWidth: 32.w,
              minHeight: 32.h,
            ),
            splashRadius: 16.r,
          ),
        ),
      );
    }

    if (clearable && textController.text.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear, color: Colors.grey),
        onPressed: () {
          textController.clear();
          onClear?.call();
        },
      );
    }

    return null;
  }

  Widget _buildDropdownList(
    BuildContext context,
    void Function(String) onSelected,
    Iterable<String> options,
    double dropdownWidth,
  ) {
    // Create a ScrollController for the dropdown list
    final scrollController = ScrollController();

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: dropdownMaxHeight ?? 200.h,
            maxWidth: dropdownWidth,
            minWidth: dropdownWidth,
          ),
          child: Scrollbar(
            controller: scrollController, // Add controller to Scrollbar
            thumbVisibility: showScrollbar,
            child: _buildDropdownListContent(
              context,
              onSelected,
              options,
              scrollController, // Pass controller to content builder
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
    ScrollController scrollController, // Add ScrollController parameter
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
        return ListView.builder(
          controller: scrollController, // Add controller to ListView
          padding: EdgeInsets.zero,
          itemCount: options.length,
          itemBuilder: (context, index) => _buildDropdownItem(
            options.elementAt(index),
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
        // 确保鼠标悬停时保持焦点
        FocusManager.instance.primaryFocus?.requestFocus();
      },
      child: InkWell(
        onTap: () => onSelected(option),
        child: Container(
          color: isHighlighted
              ? (dropdownHighlightColor ?? Colors.blue.withOpacity(0.1))
              : null,
          padding: _getContentPadding(),
          child: Row(
            children: [
              if (leadingBuilder != null) ...[
                leadingBuilder!(option),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  _displayStringForOption(option),
                  style: TextStyle(
                    fontSize: textFontSize ?? 12.sp,
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

  EdgeInsetsGeometry _getContentPadding() {
    if (inSetHorizontalPadding != null && inSetVerticalPadding != null) {
      return EdgeInsets.symmetric(
        horizontal: inSetHorizontalPadding!,
        vertical: inSetVerticalPadding!,
      );
    }
    if (inSetHorizontalPadding != null) {
      return EdgeInsets.symmetric(horizontal: inSetHorizontalPadding!);
    }
    if (inSetVerticalPadding != null) {
      return EdgeInsets.symmetric(vertical: inSetVerticalPadding!);
    }
    return EdgeInsets.symmetric(
      horizontal: 16.w,
      vertical: 8.h,
    );
  }

  OutlineInputBorder _buildBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(4.r),
      borderSide: BorderSide(color: color),
    );
  }
}

class MyTextEditorController extends GetxController {
  final _currentFocus = ''.obs;
  final _dropdownOpen = false.obs;
  final _highlightedOption = Rxn<String>();

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

  void setFocus(String key) => _currentFocus.value = key;
  String get currentFocus => _currentFocus.value;

  void setDropdownOpen(bool open) => _dropdownOpen.value = open;
  bool get isDropdownOpen => _dropdownOpen.value;

  void setHighlightedOption(String? option) =>
      _highlightedOption.value = option;
  String? get highlightedOption => _highlightedOption.value;
}
