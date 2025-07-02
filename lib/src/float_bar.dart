import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// It seems the HomeController is from the example app, so we should not import it here.
// Also, the global values should be defined here as default values.
const double testBarWidth = 60.0;
const double testBorderRadius = 10.0;

enum BarShape { rectangle, rounded }

enum DockType { inside, outside }

enum BarState { expanded, closed }

/// A model for buttons in the float bar.
///
/// Either [icon] or [child] must be provided, but not both.
class MyFloatBarButton {
  final IconData? icon;
  final Widget? child;

  MyFloatBarButton({this.icon, this.child})
      : assert(
            (icon != null || child != null) && !(icon != null && child != null),
            'Either icon or child must be provided, but not both.');
}

class FloatBoxController extends GetxController {
  // --- Dependencies ---
  // final HomeController homeCtrl = Get.find<HomeController>(); // This is a dependency from the example app, so we should remove it.

  // --- Configuration (passed from FloatBar widget) ---
  final List<MyFloatBarButton> buttons;
  final void Function(int)? onPressed;
  final double barWidth;
  final Color borderColor;
  final double borderWidth;
  final double iconSize;
  final IconData initialBarIcon;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color barButtonColor;
  final Color customButtonColor;
  final BarShape barShape;
  final double barOpenOffset;
  final int barAnimDuration;
  final Curve barAnimCurve;
  final DockType dockType;
  final double dockOffset;
  // final bool dockActivate; // If this needs to be reactive, make it RxBool
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;

  // --- Reactive State ---
  final Rx<BarState> barState = BarState.closed.obs;
  final RxDouble xOffset = 0.0.obs;
  final RxDouble yOffset = 0.0.obs; // Initialized in _initializePosition
  final Rx<IconData> barIcon;
  final RxList<bool> isFocusColors = <bool>[].obs;

  // --- Screen Size (updated by widget) ---
  final RxDouble _pageWidth = 0.0.obs;
  final RxDouble _pageHeight = 0.0.obs;

  // --- Internal State ---
  double _xOffsetRatio = 0.0; // Initialized in _initializePosition
  double _yOffsetRatio = 1 / 3; // Default initial ratio

  double _mouseOffsetX = 0.0;
  double _mouseOffsetY = 0.0;
  RxInt movementSpeed = 0.obs; // Made Rx for AnimatedPositioned duration

  double? _oldYOffset;
  double? _oldYOffsetRatio;
  bool _isFirstTimePositioning = true;

  FloatBoxController({
    required this.buttons,
    this.onPressed,
    required this.barWidth,
    required this.borderColor,
    required this.borderWidth,
    required this.iconSize,
    required this.initialBarIcon,
    required this.borderRadius,
    required this.backgroundColor,
    required this.barButtonColor,
    required this.customButtonColor,
    required this.barShape,
    required this.barOpenOffset,
    required this.barAnimDuration,
    required this.barAnimCurve,
    required this.dockType,
    required this.dockOffset,
    // required this.dockActivate,
    required this.dockAnimDuration,
    required this.dockAnimCurve,
    required this.innerButtonFocusColor,
    required this.customButtonFocusColor,
  }) : barIcon = initialBarIcon.obs {
    for (var i = 0; i < (buttons.length + 1); i++) {
      isFocusColors.add(false);
    }
  }

  void updateScreenSize(double pWidth, double pHeight) {
    bool screenSizeChanged =
        (_pageWidth.value != pWidth || _pageHeight.value != pHeight);

    if (pWidth <= 0 || pHeight <= 0) return; // Ignore invalid sizes

    _pageWidth.value = pWidth;
    _pageHeight.value = pHeight;

    if (_isFirstTimePositioning) {
      _initializePosition();
      _isFirstTimePositioning = false;
    } else if (screenSizeChanged) {
      // Handle re-scaling if screen size changes after initial setup
      // Recalculate absolute offsets based on preserved ratios
      xOffset.value = _pageWidth.value * _xOffsetRatio;
      yOffset.value = _pageHeight.value * _yOffsetRatio;

      // Ensure oldYOffset is also scaled if it exists
      if (_oldYOffsetRatio != null) {
        _oldYOffset = _pageHeight.value * _oldYOffsetRatio!;
      }

      _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
      _calcOffsetWhenForceDock(); // Re-apply docking logic
    }
  }

  void _initializePosition() {
    if (_pageWidth.value == 0 || _pageHeight.value == 0) return;

    xOffset.value = _pageWidth.value; // Start by assuming far right
    _getPoperDockXOffset(); // Calculate initial docked X
    _xOffsetRatio = xOffset.value / _pageWidth.value;
    // yOffsetRatio is already 1/3

    // Set initial yOffset based on ratio
    yOffset.value = _pageHeight.value * _yOffsetRatio;

    // Apply pan update logic for initial constraints and then force dock
    _adjustPositionOnPanUpdate(xOffset.value, yOffset.value, isReScale: true);
    _calcOffsetWhenForceDock();
  }

  void onInnerButtonTap() {
    movementSpeed.value = barAnimDuration;
    if (barState.value == BarState.expanded) {
      barState.value = BarState.closed;
      _calcOffsetWhenForceDock();
      barIcon.value = initialBarIcon; // Reset to initial icon (e.g., Icons.add)
    } else {
      barState.value = BarState.expanded;
      _calcOffsetWhenExpand();
      barIcon.value = CupertinoIcons.minus_circle_fill;
    }
  }

  void onPanStartGesture(Offset globalPosition) {
    _mouseOffsetX = globalPosition.dx - xOffset.value;
    _mouseOffsetY = globalPosition.dy - yOffset.value;
  }

  void onPanUpdateGesture(Offset globalPosition) {
    _adjustPositionOnPanUpdate(globalPosition.dx, globalPosition.dy);
    // Update ratios after position change
    if (_pageWidth.value > 0) _xOffsetRatio = xOffset.value / _pageWidth.value;
    if (_pageHeight.value > 0) {
      _yOffsetRatio = yOffset.value / _pageHeight.value;
    }
  }

  void _adjustPositionOnPanUpdate(double globalDx, double globalDy,
      {bool isReScale = false}) {
    movementSpeed.value = 0;

    double newY = isReScale ? globalDy : globalDy - _mouseOffsetY;
    if (newY < 0 + _dockBoundary()) {
      newY = 0 + _dockBoundary();
    }
    if (newY > (_pageHeight.value - currentBarHeight) - _dockBoundary()) {
      newY = (_pageHeight.value - currentBarHeight) - _dockBoundary();
    }
    yOffset.value = newY;

    double newX = isReScale ? globalDx : globalDx - _mouseOffsetX;
    if (newX < 0 + _dockBoundary()) {
      newX = 0 + _dockBoundary();
    }
    if (newX > (_pageWidth.value - barWidth) - _dockBoundary()) {
      newX = (_pageWidth.value - barWidth) - _dockBoundary();
    }
    xOffset.value = newX;

    if (!isReScale) {
      _oldYOffset = null;
      _oldYOffsetRatio = null;
    } else if (_oldYOffsetRatio != null && _pageHeight.value > 0) {
      _oldYOffset = _oldYOffsetRatio! * _pageHeight.value;
    }
  }

  void onPanEndGesture() {
    _calcOffsetWhenForceDock();
    // Update ratios after docking
    if (_pageWidth.value > 0) _xOffsetRatio = xOffset.value / _pageWidth.value;
    if (_pageHeight.value > 0) {
      _yOffsetRatio = yOffset.value / _pageHeight.value;
    }
  }

  void setButtonFocus(int index, bool focused) {
    if (index >= 0 && index < isFocusColors.length) {
      isFocusColors[index] = focused;
    }
  }

  double _dockBoundary() {
    if (dockType == DockType.inside) return dockOffset;
    return -dockOffset;
  }

  BorderRadius get currentBorderRadius {
    if (barShape == BarShape.rectangle) return borderRadius;
    return BorderRadius.circular(barWidth);
  }

  double get currentBarHeight {
    if (barState.value == BarState.expanded) {
      return barWidth * (buttons.length + 1) + borderWidth;
    }
    return barWidth + (borderWidth * 2);
  }

  void _calcBarYOffsetWhenOpening() {
    if (yOffset.value < 0) {
      _updateOldYOffset();
      yOffset.value = 0.0 + barWidth + borderWidth + _dockBoundary();
    } else {
      if (yOffset.value + currentBarHeight >
          _pageHeight.value + _dockBoundary()) {
        final newYOffsetValue =
            _pageHeight.value - currentBarHeight + _dockBoundary();
        if (newYOffsetValue != yOffset.value) {
          _updateOldYOffset();
          yOffset.value = newYOffsetValue;
        }
      } else {
        _oldYOffset = null; // Already captured by yOffset.value
        _updateOldYOffset(); // Effectively captures current yOffset into _oldYOffset
      }
    }
  }

  void _updateOldYOffset({bool setNull = false}) {
    if (setNull || _pageHeight.value == 0) {
      _oldYOffset = null;
      _oldYOffsetRatio = null;
    } else {
      _oldYOffset = yOffset.value;
      _oldYOffsetRatio = _oldYOffset! / _pageHeight.value;
    }
  }

  double _openDockLeft() {
    if (_pageWidth.value == 0) {
      return xOffset.value; // Avoid division by zero if not initialized
    }
    if (xOffset.value < (_pageWidth.value / 2)) {
      return barOpenOffset;
    }
    return ((_pageWidth.value - barWidth)) - (barOpenOffset);
  }

  Border? get currentBarBorder {
    if (borderWidth <= 0) return null;
    return Border.all(color: borderColor, width: borderWidth);
  }

  void _calcOffsetWhenForceDock() {
    if (barState.value == BarState.closed) {
      movementSpeed.value = dockAnimDuration;
      _getPoperDockXOffset();
      if (_oldYOffset != null && yOffset.value != _oldYOffset!) {
        yOffset.value = _oldYOffset!;
      }
    }
  }

  void _getPoperDockXOffset() {
    if (_pageWidth.value == 0) return;
    double center = xOffset.value + (barWidth / 2);
    final dockEdgeOffset = (center < _pageWidth.value / 2)
        ? -barWidth // Corrected: Dock to left edge, making it half off-screen like original
        : (_pageWidth.value - barWidth); // Dock to right edge
    xOffset.value = dockEdgeOffset - _dockBoundary();
  }

  void _calcOffsetWhenExpand() {
    xOffset.value = _openDockLeft();
    _calcBarYOffsetWhenOpening();
  }
}

class MyFloatBar extends StatelessWidget {
  // Changed to StatelessWidget
  final Key? barKey; // Optional key for multiple instances
  final Color borderColor;
  final double borderWidthInput; // Renamed to avoid conflict
  final double barWidthInput; // Renamed
  final double iconSizeInput; // Renamed
  final IconData initialBarIcon;
  final BorderRadius? borderRadiusInput; // Renamed
  final Color backgroundColor;
  final Color barButtonColor;
  final Color customButtonColor;
  final BarShape barShape;
  final double barOpenOffsetInput; // Renamed
  final int barAnimDuration;
  final Curve barAnimCurve;
  final DockType dockType;
  // dockOffset is calculated from barWidthInput
  final bool dockActivate;
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final List<MyFloatBarButton> buttons;
  final void Function(int)? onPressed;
  final Color innerButtonFocusColor;
  final Color customButtonFocusColor;

  // Calculated properties, to be passed to controller
  final double finalBarWidth;
  final double finalBorderWidth;
  final double finalIconSize;
  final BorderRadius finalBorderRadius;
  final double finalBarOpenOffset;
  final double finalDockOffset;

  MyFloatBar({
    this.barKey, // Use this key as the tag for Get.put/Get.find
    this.buttons = const [],
    this.borderColor = const Color(0xFF333333),
    this.borderWidthInput = 0,
    this.barWidthInput = testBarWidth,
    this.iconSizeInput = 24,
    this.initialBarIcon = Icons.add,
    this.borderRadiusInput,
    this.backgroundColor = const Color(0xFF333333),
    this.barButtonColor = Colors.white,
    this.customButtonColor = Colors.white,
    this.barShape = BarShape.rounded,
    this.barOpenOffsetInput = 5.0,
    this.barAnimDuration = 600,
    this.barAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.dockType = DockType.outside,
    this.dockAnimDuration = 300,
    this.dockAnimCurve = Curves.fastLinearToSlowEaseIn,
    this.onPressed,
    this.innerButtonFocusColor = Colors.blue,
    this.customButtonFocusColor = Colors.red,
    this.dockActivate = false,
  })  : finalBarWidth = barWidthInput * (barWidthInput / testBarWidth),
        finalBorderWidth = borderWidthInput * (barWidthInput / testBarWidth),
        finalIconSize = iconSizeInput * (barWidthInput / testBarWidth),
        finalBorderRadius = borderRadiusInput ??
            BorderRadius.circular(
                testBorderRadius * (barWidthInput / testBarWidth)),
        finalBarOpenOffset =
            barOpenOffsetInput * (barWidthInput / testBarWidth),
        finalDockOffset = (barWidthInput * (barWidthInput / testBarWidth)) / 2,
        super(key: barKey) {
    // Pass barKey to super
    // Initialize and register the controller
    // Use a unique tag if multiple instances, barKey.toString() can be a good tag.
    Get.put(
      FloatBoxController(
        buttons: buttons,
        onPressed: onPressed,
        barWidth: finalBarWidth,
        borderColor: borderColor,
        borderWidth: finalBorderWidth,
        iconSize: finalIconSize,
        initialBarIcon: initialBarIcon,
        borderRadius: finalBorderRadius,
        backgroundColor: backgroundColor,
        barButtonColor: barButtonColor,
        customButtonColor: customButtonColor,
        barShape: barShape,
        barOpenOffset: finalBarOpenOffset,
        barAnimDuration: barAnimDuration,
        barAnimCurve: barAnimCurve,
        dockType: dockType,
        dockOffset: finalDockOffset,
        // dockActivate: dockActivate, // Not used in controller directly yet
        dockAnimDuration: dockAnimDuration,
        dockAnimCurve: dockAnimCurve,
        innerButtonFocusColor: innerButtonFocusColor,
        customButtonFocusColor: customButtonFocusColor,
      ),
      tag: barKey?.toString(), // Use the provided key as tag
    );
  }

  @override
  Widget build(BuildContext context) {
    // Find controller using the same tag
    final FloatBoxController ctrl =
        Get.find<FloatBoxController>(tag: barKey?.toString());

    ctrl.updateScreenSize(
        MediaQuery.of(context).size.width, MediaQuery.of(context).size.height);

    return Obx(() => AnimatedPositioned(
          duration: Duration(milliseconds: ctrl.movementSpeed.value),
          top: ctrl.yOffset.value,
          left: ctrl.xOffset.value,
          curve: ctrl.dockAnimCurve, // Use config from controller constructor
          child: AnimatedContainer(
            duration: Duration(milliseconds: ctrl.barAnimDuration),
            width: ctrl.barWidth,
            height: ctrl.currentBarHeight,
            decoration: BoxDecoration(
              color: ctrl.backgroundColor,
              borderRadius: ctrl.currentBorderRadius,
              border: ctrl.currentBarBorder,
            ),
            curve: ctrl.barAnimCurve,
            child: Material(
              type: MaterialType.transparency,
              child: Wrap(
                direction: Axis.horizontal,
                children: [
                  GestureDetector(
                    onPanEnd: (_) => ctrl.onPanEndGesture(),
                    onPanStart: (details) =>
                        ctrl.onPanStartGesture(details.globalPosition),
                    onPanUpdate: (details) =>
                        ctrl.onPanUpdateGesture(details.globalPosition),
                    onTap: () => ctrl.onInnerButtonTap(),
                    child: MouseRegion(
                      onEnter: (_) => ctrl.setButtonFocus(0, true),
                      onExit: (_) => ctrl.setButtonFocus(0, false),
                      cursor: SystemMouseCursors.click,
                      child: Obx(() => _FloatButton(
                            // Main button uses a simple Icon
                            button: MyFloatBarButton(icon: ctrl.barIcon.value),
                            color: ctrl.barButtonColor,
                            focusColor: ctrl.innerButtonFocusColor,
                            iconSize: ctrl.iconSize,
                            size: ctrl.barWidth,
                            hightLight: ctrl.isFocusColors.isNotEmpty
                                ? ctrl.isFocusColors[0]
                                : false,
                          )),
                    ),
                  ),
                  Obx(() => Visibility(
                        visible: ctrl.barState.value == BarState.expanded,
                        child: Column(
                          children: List.generate(
                            ctrl.buttons.length,
                            (index) {
                              bool isEnabled = true;
                              return GestureDetector(
                                onPanStart: (details) => ctrl
                                    .onPanStartGesture(details.globalPosition),
                                onPanUpdate: (details) => ctrl
                                    .onPanUpdateGesture(details.globalPosition),
                                onTap: () {
                                  if (ctrl.onPressed != null) {
                                    ctrl.onPressed!(index);
                                  }
                                },
                                child: MouseRegion(
                                  onEnter: (_) =>
                                      ctrl.setButtonFocus(index + 1, true),
                                  onExit: (_) =>
                                      ctrl.setButtonFocus(index + 1, false),
                                  cursor: SystemMouseCursors.click,
                                  child: Obx(() {
                                    final button = ctrl.buttons[index];
                                    return _FloatButton(
                                      key: ValueKey(
                                          'float_button_${index}_$isEnabled'),
                                      button: button,
                                      color: ctrl.customButtonColor,
                                      focusColor: ctrl.customButtonFocusColor,
                                      iconSize: ctrl.iconSize,
                                      size: ctrl.barWidth,
                                      hightLight:
                                          ctrl.isFocusColors.length > index + 1
                                              ? ctrl.isFocusColors[index + 1]
                                              : false,
                                      enabled: isEnabled,
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      )),
                ],
              ),
            ),
          ),
        ));
  }
}

class _FloatButton extends StatelessWidget {
  final double size;
  final bool hightLight;
  final Color color;
  final Color focusColor;
  final bool enabled;
  final MyFloatBarButton button;
  final double iconSize;

  const _FloatButton({
    super.key,
    required this.size,
    required this.hightLight,
    required this.color,
    required this.focusColor,
    required this.button,
    required this.iconSize,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (button.child != null) {
      content = button.child!;
    } else {
      content = Icon(
        button.icon,
        size: iconSize,
        color: hightLight ? focusColor : color,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      // The background highlight is removed to favor changing the icon color on hover.
      // decoration: BoxDecoration(
      //   color: hightLight ? focusColor.withOpacity(0.2) : Colors.transparent,
      // ),
      child: Center(
        child: Opacity(
          opacity: enabled ? 1.0 : 0.4,
          child: content,
        ),
      ),
    );
  }
}
