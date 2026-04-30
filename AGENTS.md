# AGENTS.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

`xly` is a Flutter utility package (not a standalone app) targeting desktop platforms primarily (Windows/macOS/Linux) with some mobile support. It re-exports several third-party packages (`get`, `flutter_screenutil`, `window_manager`, `screen_retriever`, `get_storage`) so consumers don't need to depend on them separately.

## Commands

### Setup & Clean
```bash
flutter clean && flutter pub get
```
Or via `just`:
```bash
just clean
```

### Run Tests
```bash
flutter test
```
Run a single test file:
```bash
flutter test test/async_service_test.dart
```

### Lint
```bash
flutter analyze
```

### CLI Tools (run from consumer app directories)
```bash
dart run xly                                    # interactive menu
dart run xly:generate icon "path/to/icon.png"  # generate app icons for all platforms
dart run xly:rename all "App Name"             # rename app across all platforms
dart run xly:win_setup                         # patch windows/runner/flutter_window.cpp for silent startup
```

## Architecture

### Library Entry Point (`lib/xly.dart`)
The public API is exposed via a single `library xly` file that:
- **Re-exports** third-party packages wholesale (get, flutter_screenutil, window_manager, etc.)
- **Exports** individual source modules from `lib/src/`
- **Declares two `part` files** (`src/app.dart` and `src/float_panel.dart`) which are tightly coupled to the library and share its imports

Only `app.dart` and `float_panel.dart` use `part of '../xly.dart'`. All other `lib/src/` files are standalone modules exported normally.

### `analysis_options.yaml` Exclusions
`lib/xly.dart` and all of `user_code/**` are excluded from the Dart analyzer.

### Core Modules

**`src/app.dart`** (part file, ~1000+ lines) — The primary entry point for consumers. Contains:
- `MyApp.initialize(...)` — async static method that boots the entire app: ScreenUtil, GetStorage, window_manager, single-instance detection, tray/FloatPanel registration, and installable error handlers (`FlutterError.onError` + `PlatformDispatcher.instance.onError`). Optional `enableZoneGuard` (default `false` since 0.38.2) wraps init in `runZonedGuarded` for the rare case of needing to intercept `print` / `Timer` / `Microtask`. See `.doc/error_handling.md` for design rationale.
- `MyRoute<T>` — pairs a route path, page widget, and GetX controller factory
- `MyService<T>` — wraps GetX service registration; supports both sync (`service`) and async (`asyncService`) factories
- `WindowSettings`, `CustomDragArea`, `MyDragProtectedArea` — window drag/interaction helpers

**`src/float_panel.dart`** (part file) — `FloatPanel extends GetxService`: a draggable, dockable, expandable overlay panel. Configured via `FloatPanel.to.configure(...)`. Uses reactive GetX state for all visual properties.

**`src/scaffold.dart`** — `MyScaffold`: adaptive navigation scaffold with 5 breakpoint tiers (Compact/Medium/Expanded/Large/XLarge) using `flutter_adaptive_scaffold`. Supports `drawer` items, `navigationHeader`, `trailing`, and `body`. Listens to GetX route changes via a timer to sync selected nav item.

**`src/tray/`** — `MyTray extends GetxService`: system tray management. Registered via `MyService<MyTray>`. Provides `hide()`, `pop()`, `notify()`, `setContextMenu()`. On Windows, uses `bringAppToFront: true` workaround for tray menu dismissal bug.

**`src/smart_dock/`** — `SmartDockManager`: window edge-docking behavior (like QQ's edge-hide/hover-reveal). Controlled via `SmartDockManager.setSmartEdgeDocking(enabled: bool)`.

**`src/toast/`** — `MyToast`: static methods for toast/snackbar messages (`show`, `showOk`, `showWarn`, `showError`, `showInfo`, `showSpinner`, `showLoadingThenToast`). Uses internal `Toast` widget (not ok_toast).

**`src/single_instance.dart`** — `SingleInstanceManager`: prevents duplicate app instances using a TCP port lock; activates the existing window if a second launch is attempted.

**`src/platform.dart`** — `MyPlatform`: static platform detection helpers (`isDesktop`, `isMobile`, `isWindows`, etc.) and cross-platform file/permission utilities.

**`src/selector/`** — `MySelector` / `MySelectorController`: a floating popover selector with search, keyboard nav, and optional item clearing.

**`src/tab_view/`** — `MyTabView` / `MySegmentedControl`: macOS-style segmented tab switcher with animated selection slider.

**`src/notify/`** — `MyNotify`: local notifications (via `flutter_local_notifications`), supports scheduled notifications.

### CLI Tools (`bin/`)
- `bin/xly.dart` — unified interactive CLI entry; delegates to sub-commands
- `bin/generate.dart` — icon generation, delegates to `tool/icon_generator.dart`
- `bin/rename.dart` — renames app display name across platform manifests
- `bin/win_setup.dart` — patches `windows/runner/flutter_window.cpp` to suppress auto-show on startup (required for silent-start apps)

### GetX Conventions
- All services use `GetxService` and are accessed via `SomeService.to` (i.e., `Get.find<T>()`)
- Controllers use `GetxController` and are registered per-route via `MyRoute.registerController()`
- Reactive state uses `.obs`; UI subscribes with `Obx(...)`
- Navigation: use `Get.toNamed`, `Get.back`, `Get.dialog`; `Get.context`/`Get.key` for context/NavigatorState

### State Sharing Between `part` Files
`MyApp._globalEnableDraggable`, `_globalEnableResizable`, `_globalEnableDoubleClickMaximize`, and `_globalEnableAspectRatio` are `ValueNotifier`-like global statics on `MyApp` (defined in `app.dart`) and accessed directly by `float_panel.dart` and `MyDragProtectedArea` since they share the same library scope.

## Notes

- The `navigatorKey` parameter was removed from `MyApp.initialize`. Use `Get.key`, `Get.context`, or `Get.dialog` instead.
- **Exception handling & Zone strategy** (since 0.38.2): `MyApp.initialize` defaults to `installErrorHandlers: true` + `enableZoneGuard: false`. Detailed decision record (library vs application boundary, why Zone Guard is no longer default, `Zone mismatch` pitfalls, recommended patterns for Sentry / Crashlytics) lives in `.doc/error_handling.md`.
- For non-ASCII paths or app names in CLI tools, use the `dart run xly:<command>` syntax directly (not the interactive menu) to avoid terminal encoding issues on Windows.
- The `user_code/` directory is excluded from analysis and is intended for scratch/test consumer code.
- UI reference patterns: `D:\DATA\BaiduSyncdisk\project\personal\test_repo\macos_ui` (per cursor rule).
