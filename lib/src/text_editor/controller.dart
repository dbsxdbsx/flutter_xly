part of '../../text_editor.dart';

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

  /// 最近一次打开候选列表的触发来源（输入/焦点/箭头）
  _OpenTrigger _lastOpenTrigger = _OpenTrigger.focus;

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
      // 记录为“焦点触发”，并允许重新展示下拉
      _lastOpenTrigger = _OpenTrigger.focus;
      resetManuallyClosedFlag();
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
