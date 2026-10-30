/// 兼容旧导入路径：实现已并入 `package:xly/app.dart`（画面要直接读门闩的私有状态）。
library;

export '../app.dart'
    show
        MySplash,
        MySplashTexts,
        MySplashStatus,
        MySplashHandle,
        MySplashClip,
        MySplashAnimationTiming;
