# Flutter 学习笔记 09：工程化与打包

> 适用前提：已经完成 Day 8（主题与动画）。本机 Flutter 3.47.5 / Dart 3.13.4，所有命令和模板配置都按这个版本核对过。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 9。
> 本笔记的目标：把「能在模拟器上跑的 demo」变成「能装到别人手机上、能发给市场、三个月后还维护得动」的项目——目录分层、多环境配置、静态检查、日志规范、图标与启动图、release 签名打包，以及打包报错怎么自救。

## 目录

- [1. 从 uniapp 到 Flutter：工程化怎么对应](#1-从-uniapp-到-flutter工程化怎么对应)
- [2. 目录分层：lib/ 该怎么组织](#2-目录分层lib-该怎么组织)
- [3. 多环境：dev / prod 一套代码](#3-多环境dev--prod-一套代码)
- [4. 依赖与版本管理](#4-依赖与版本管理)
- [5. 代码质量与日志](#5-代码质量与日志)
- [6. 资源与品牌：图标、启动图、assets](#6-资源与品牌图标启动图assets)
- [7. Android 打包全流程：签名、apk、aab](#7-android-打包全流程签名apkaab)
- [8. 常见打包报错急救表](#8-常见打包报错急救表)
- [9. 上架前检查清单](#9-上架前检查清单)
- [10. 今日最小项目：重构 + 出包 + 装机验证](#10-今日最小项目重构--出包--装机验证)
- [11. 速查表](#11-速查表)
- [12. 今日自检](#12-今日自检)

## 1. 从 uniapp 到 Flutter：工程化怎么对应

你在 uniapp 里其实已经做过一轮「工程化」了：`pages.json` 管页面、`manifest.json` 管应用信息、`.env` 管环境、HBuilderX 负责云打包。Flutter 做的是同一批事，只是零件换个名字：

| uniapp | Flutter | 备注 |
| --- | --- | --- |
| `pages.json`（路由 + 导航栏） | 路由写在代码里（`Navigator` / `go_router`） | Day 4 已学 |
| `manifest.json`（应用名 / 图标 / 权限） | `AndroidManifest.xml` + 图标工具 + `Info.plist` | 本篇第 6、7 节 |
| `.env` / `process.env.UNI_XXX` | `--dart-define` / `--dart-define-from-file` | 本篇第 3 节 |
| `package.json` 的 scripts | 直接敲 `flutter build`，或用脚本封装 | 本篇第 10 节 |
| ESLint / Prettier | `analysis_options.yaml` + `flutter analyze` / `dart format` | 本篇第 5 节 |
| `npm run build` / 云打包 | `flutter build apk --release` / `appbundle` | 本篇第 7 节 |
| `console.log` | `debugPrint` + 日志封装（release 自动关） | 本篇第 5 节 |
| 微信 / 应用市场审核 | Google Play、各安卓市场、App Store 审核 | 本篇第 9 节 |

> 心智模型：**工程化的目标不是「显得专业」，而是让三个场景不出事**——
> ① 三个月后的你重新打开项目，不用问任何人就能跑起来；
> ② 同事接手时，能凭目录猜到代码在哪；
> ③ 发版时不会因为「忘了改地址 / 忘了改版本号」翻车。
> 本篇每一条都对着这三个场景。

## 2. 目录分层：lib/ 该怎么组织

### 2.1 两种主流风格

| 风格 | 长什么样 | 适合 |
| --- | --- | --- |
| **按层分（layer-first）** | `models/` `services/` `state/` `pages/` `widgets/` | 中小项目（我们这个商城 Demo）、功能数量少、团队小 |
| **按功能分（feature-first）** | `features/cart/` `features/product/`，每个功能内部再分 data/domain/ui | 大项目、多团队并行、功能之间边界清晰 |

两种都不算错。**学习期先用「按层分」**，等一个功能目录里超过 20 个文件、或者两个人同时改同一层时，再考虑按功能拆。

### 2.2 一份可以直接抄的结构

把 Day 6 ~ Day 8 攒下来的东西归位之后，长这样：

```
lib/
├── main.dart                  # 只做三件事：初始化绑定 / 预加载 prefs / runApp
├── app.dart                   # MaterialApp：主题、路由、环境角标
├── core/                      # 全项目通用的基础设施
│   ├── env.dart               # 环境配置（dev / prod 的 baseUrl 等）
│   ├── logger.dart            # 统一日志（release 自动关）
│   ├── network/
│   │   └── dio_client.dart    # Dio 实例 + 拦截器（Day 6 的成果）
│   └── storage/
│       ├── prefs.dart         # prefsProvider（Day 7 的成果）
│       └── app_database.dart  # sqflite 单例 + DAO（Day 7 的成果）
├── models/                    # 纯数据模型：Product / User / CartItem
├── services/                  # 接口封装：ProductApi / AuthApi
├── state/                     # 全局状态：cart / auth / themeMode
├── theme/
│   └── app_theme.dart         # Day 8 的主题文件
├── pages/                     # 页面（一个页面对应一个文件）
│   ├── login_page.dart
│   ├── product_list_page.dart
│   ├── product_detail_page.dart
│   └── profile_page.dart
└── widgets/                   # 可复用的通用组件
    ├── cart_badge.dart
    └── fav_button.dart
```

### 2.3 每层「该做什么 / 不该做什么」

这张表比目录名重要得多——**分层的本质是约束依赖方向**：

| 层 | 该做什么 | 不该做什么 |
| --- | --- | --- |
| `pages/` | 布局 + 交互 + 调状态 | ❌ 直接写 HTTP、直接写 SQL、直接读 prefs |
| `widgets/` | 通用 UI，入参出参都是数据 | ❌ 依赖具体业务状态（否则没法复用） |
| `state/` | 业务状态与流程编排（登录、加购、切主题） | ❌ import 具体页面、直接拼 UI |
| `services/` | 调接口、JSON ↔ 模型、错误翻译 | ❌ 碰 UI、碰 Theme |
| `models/` | 字段 + `fromJson` / `toJson` / `fromMap` | ❌ 写网络与业务逻辑 |
| `core/` | 全局基础设施（dio、prefs、日志、环境） | ❌ 依赖具体业务模块 |

依赖方向永远是**单向往下**：`pages → state → services → models`，加上大家都可用的 `core` 和 `theme`。一旦出现 `models` 反过来 import `pages`，说明该拆了。

### 2.4 命名规范（省掉一半的争论）

| 对象 | 规范 | 例子 |
| --- | --- | --- |
| 文件名 | 全小写 + 下划线 | `product_detail_page.dart` |
| 类名 | 大驼峰 | `ProductDetailPage` |
| 变量 / 方法 | 小驼峰 | `fetchProducts()` |
| 私有 | 下划线开头 | `_ProductCard`、`_loading` |
| 常量 | `lowerCamelCase` 或全大写 | `kPageSize`、`maxRetry` |
| 页面文件 | 以 `_page` 结尾 | `login_page.dart` |

> 新手最容易忽略的一条：**一个页面文件超过 300 行，就该把里面的小部件抽成 `widgets/` 或同文件顶部的私有 Widget**。别让一个 `build` 方法长到几百行——Flutter 的 Widget 就是给你拆的。

### 2.5 什么时候「不要」分层

一个只有 3 个页面的 demo，硬拆 8 个目录只会让你多写一堆 import。判断标准很简单：

> **当你在 `lib/` 里找文件要花 5 秒以上，就该分层了；当某个目录里只有 1 个文件，那层就是多余的。**

## 3. 多环境：dev / prod 一套代码

### 3.1 为什么不能「手动改代码切环境」

最原始的做法是建一个常量文件，发版前手动把地址改成生产、发完再改回来。问题很明显：

1. 只要有一次忘了改，**测试包连生产库**（或者更糟：生产包连测试库，用户数据全乱）；
2. 合并代码时两边都在改同一行，冲突不断；
3. 没法同时装两个环境包在同一台手机上对比。

正确做法：**环境值在「编译时」注入，代码里只读不写。**

### 3.2 三种方案对比

| 方案 | 怎么用 | 优点 | 缺点 |
| --- | --- | --- | --- |
| 常量文件 + 手动切换 | `Env.baseUrl = xxx` | 简单 | 容易忘记改，容易带上线（❌ 别用） |
| `--dart-define` | 命令行传参 | 一行命令切环境，CI 友好 | 参数多时命令很长 |
| `--dart-define-from-file` | 读 JSON 文件 | **最舒服**：配置进版本库、命令短、能复用 | 要维护几个 json 文件 |
| flavor（Android/iOS 原生） | Gradle productFlavors + Xcode scheme | 能同时装多套、不同图标名 | 配置繁琐，要动 Gradle 和 Xcode |

> 学习期推荐 **`--dart-define-from-file`**；团队要「同一台机器装 dev / prod 两个包」时才上 flavor。

### 3.3 代码侧：一个 Env 类收口

```dart
// lib/core/env.dart
/// 所有环境相关的值都在这里读，其他地方不许再出现 baseUrl 字面量
class Env {
  /// 编译期注入：flutter run --dart-define=API_BASE_URL=...
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'https://dummyjson.com');

  static const String appName =
      String.fromEnvironment('APP_NAME', defaultValue: '商城 Demo');

  static const bool enableHttpLog =
      bool.fromEnvironment('ENABLE_HTTP_LOG', defaultValue: true);

  /// 给开发者看的标记：非生产环境显示角标
  static const String envLabel =
      String.fromEnvironment('ENV_LABEL', defaultValue: 'DEV');

  static bool get isProd => envLabel.toUpperCase() == 'PROD';
}
```

用法（Dio 只认 `Env.apiBaseUrl`）：

```dart
final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));

if (Env.enableHttpLog) {      // 生产包自动不打请求日志
  dio.interceptors.add(LogInterceptor());
}
```

### 3.4 配置文件侧：两份 JSON

```json
// config/dev.json
{
  "API_BASE_URL": "https://dummyjson.com",
  "APP_NAME": "商城 Demo DEV",
  "ENABLE_HTTP_LOG": true,
  "ENV_LABEL": "DEV"
}
```

```json
// config/prod.json
{
  "API_BASE_URL": "https://dummyjson.com",
  "APP_NAME": "商城 Demo",
  "ENABLE_HTTP_LOG": false,
  "ENV_LABEL": "PROD"
}
```

> 真实项目里这两个文件的 `API_BASE_URL` 会指向不同域名（`api-dev.example.com` / `api.example.com`）。这里用同一个地址只是因为练习 API只有一个。

### 3.5 三条常用命令

```bash
# 开发调试：读 dev.json
flutter run --dart-define-from-file=config/dev.json

# 打生产包：读 prod.json
flutter build apk --release --dart-define-from-file=config/prod.json

# 临时覆盖单个值（优先级高于文件）
flutter run --dart-define-from-file=config/dev.json --dart-define=ENV_LABEL=LOCAL
```

### 3.6 四个必须记住的细节

1. **`String.fromEnvironment` 是编译期常量**：值在使用时必须能算出来，所以要写成 `static const`（不能是 `static final`，也不能在运行时改）。改了值必须**重新编译**，热重载不会生效。
2. **类型要对应**：`bool` 用 `bool.fromEnvironment`、`int` 用 `int.fromEnvironment`。用字符串传 `"true"` 再 `== 'true'` 也能跑，但更容易写错。
3. **别用 `Platform.environment`**：那是「运行时的宿主环境变量」，在手机上没有你构建时传的那些值——只有 `fromEnvironment` 系列才认识 `--dart-define`。
4. **要能一眼看出当前环境**：在非生产包里挂个角标（第 10 节会给代码）。上线前最怕的就是「装错包」，能一眼看出来就能省一次事故。

`config/*.json` 建议**提交进版本库**（它只放非敏感的配置）。真正的密钥（第三方 Key）不要写进这里——`--dart-define` 的值会以明文存在产物里，能被反编译出来。

> 一句话原则：**baseUrl、开关、环境标签这类「配置」放 dart-define；密钥、Token 这类「秘密」放服务端或安全存储，永远别放进客户端包。**

## 4. 依赖与版本管理

### 4.1 pubspec 里那几个符号是什么意思

```yaml
name: shopping_demo
description: 学习用商城 Demo
publish_to: 'none'        # 防止误发布到 pub.dev
version: 1.2.0+7          # 版本名 + 构建号（Android 的 versionName + versionCode）

environment:
  sdk: ^3.13.0            # 允许的 Dart SDK 范围

dependencies:
  dio: ^5.9.0
  shared_preferences: ^2.5.3
  sqflite: ^2.4.2
  flutter_riverpod: ^3.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0    # 新版模板自带
```

**`^x.y.z` 是「兼容更新」的约定**（caret 约束），意思是「至少 `x.y.z`，但主版本号不能变」：

| 写法 | 允许的版本范围 | 什么时候用 |
| --- | --- | --- |
| `^5.9.0` | `>=5.9.0 <6.0.0` | **最常用**：小版本更新自动拿到 bug 修复 |
| `5.9.0` | 只允许 `5.9.0` | 依赖有兼容问题时临时锁死 |
| `any` | 任意版本 | ❌ 不要用 |
| `>=5.9.0 <6.0.0` | 显式范围 | 需要精确控制时 |

### 4.2 常用命令

```bash
flutter pub add dio                 # 加依赖（自动选版本并写进 pubspec）
flutter pub add --dev flutter_launcher_icons   # 加开发依赖
flutter pub remove dio              # 删依赖
flutter pub get                     # 按 pubspec 拉依赖（改完 pubspec 后跑）
flutter pub outdated                # 看哪些依赖有新版本
flutter pub deps --style=compact    # 看依赖树（排查「谁引入了这个包」）
```

升级要谨慎：

```bash
flutter pub upgrade                 # 在约束范围内升到最新（相对安全）
flutter pub upgrade --major-versions # 升主版本（可能有破坏性改动，升完必须回归测试）
```

> 升级依赖的标准动作：**升 → `flutter analyze` → 跑关键页面 → 提交一次独立的 commit**。别把「升级依赖」和「加功能」混在一个提交里，出问题时根本分不清是谁的锅。

### 4.3 `pubspec.lock` 要不要提交？

| 项目类型 | 提交 lock？ | 原因 |
| --- | --- | --- |
| **App（应用）** | ✅ 提交 | 保证你、同事、CI 装到的是同一批版本，避免「我这儿好好的」 |
| 纯 Dart/Flutter 库（要发 pub.dev） | ❌ 不提交 | 库要兼容多版本，锁死反而坏事 |

我们做的是 App，所以 `.lock` 进版本库，别加进 `.gitignore`。

### 4.4 选依赖的三个判断标准

1. **能不能不用它？** 官方 SDK 能做到的（`dart:convert`、`http`、`shared_preferences`）就别引三方。
2. **它活得好不好？** 看 pub.dev 的 Likes、Pub Points、最后更新时间、支持平台。两年没更新的包，谨慎。
3. **它进了包体积吗？** 每个依赖都是包体积和维护成本，`--analyze-size` 能看清谁占地方（第 7 节讲）。

## 5. 代码质量与日志

### 5.1 analysis_options.yaml：把规矩写进配置

新建项目自带的 `analysis_options.yaml` 已经包含了一套官方推荐规则：

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  exclude:
    - build/**
    - android/**
    - ios/**
```

在此基础上，常用几条自定义（按需开）：

```yaml
analyzer:
  errors:
    avoid_print: error          # 把「到处 print」直接当错误拦下来

linter:
  rules:
    - prefer_single_quotes      # 统一用单引号
    - require_trailing_commas   # 给「末尾逗号」：格式化更稳定，diff 更干净
    - unawaited_futures         # 忘了 await 的 Future 会提醒你
    - avoid_print
```

> 这两句话要形成肌肉记忆：**改完代码跑 `flutter analyze`，提交前跑 `dart format .`**。
> `flutter analyze` 是「静态检查」（不用运行就能发现类型/空安全/漏 await 的问题），`dart format` 是「统一排版」（团队没有格式争论，diff 只看真实改动）。

想要更严格的团队规范，可以再加 `very_good_analysis` 这类规则集；个人项目用 `flutter_lints` + 上面几条就够。

### 5.2 日志：为什么不能到处 `print`

| 方式 | 问题 |
| --- | --- |
| `print` | release 包里照样输出；可能把 Token、手机号打进日志；官方 lint 直接标红 |
| `debugPrint` | 内部做了限流（不会因为疯狂输出卡住 UI），但仍是「调试用」，release 里也会打 |
| 统一封装 + `kDebugMode` | **推荐**：一处控制开关，将来换崩溃上报也只改一个文件 |

```dart
// lib/core/logger.dart
import 'package:flutter/foundation.dart';

class Log {
  /// 调试日志：只在 debug / profile 里输出
  static void d(String message) {
    if (kDebugMode) debugPrint('[D] $message');
  }

  /// 错误日志：生产环境应该在这里接崩溃上报（Crashlytics / Sentry / 自建）
  static void e(String message, [Object? error]) {
    if (kDebugMode) debugPrint('[E] $message ${error ?? ''}');
    // TODO: 生产接入错误上报，例如 FirebaseCrashlytics.instance.recordError(error, stack);
  }
}
```

配合三个编译期常量区分环境（它们在**编译时**就确定了，release 包里 `kDebugMode` 分支会被裁掉）：

| 常量 | debug | profile | release |
| --- | --- | --- | --- |
| `kDebugMode` | ✅ | ❌ | ❌ |
| `kProfileMode` | ❌ | ✅ | ❌ |
| `kReleaseMode` | ❌ | ❌ | ✅ |

顺手把 Day 6 的一个隐患修掉——**生产包不该打 HTTP 日志**（请求头里可能有 Token）：

```dart
final dio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));

if (kDebugMode) {
  dio.interceptors.add(LogInterceptor()); // 只在调试期打印请求日志
}
```

### 5.3 兜住「未捕获的异常」

线上崩溃要能看到，至少先把兜底接上：

```dart
void main() {
  // Flutter 框架层的错误（build / layout / 手势回调里的异常）
  FlutterError.onError = (details) {
    Log.e('FlutterError', details.exception);
    // 生产：FlutterError.presentError(details); 或上报到崩溃平台
  };

  // 异步 / 平台层的错误（Future 里没被 catch 的异常也会走这里）
  PlatformDispatcher.instance.onError = (error, stack) {
    Log.e('未捕获异常', error);
    return true; // 返回 true 表示「已处理」，避免直接崩掉
  };

  runApp(const ProviderScope(child: ShopApp()));
}
```

### 5.4 两个容易忽略的细节

1. **`assert` 只在 debug 生效**：`assert` 会被 release 编译器直接删掉。所以**业务校验不能用 `assert`**，要用 if 判断后抛异常或提示。
2. **日志里不要出现敏感信息**：Token、密码、手机号、身份证号一律不打。真要看请求内容，也只打长度或掩码后的值。这条在上架审核和用户投诉里都可能踩雷。

## 6. 资源与品牌：图标、启动图、assets

### 6.1 assets：图片、字体怎么进包

1. 建目录：`assets/images/logo.png`；
2. **在 `pubspec.yaml` 里声明**（这一步最容易忘，忘记就报 `Unable to load asset`）：

```yaml
flutter:
  uses-material-design: true

  assets:
    - assets/images/            # 以 / 结尾 = 包含该目录下的所有文件（不含子目录）
    - assets/images/icons/bag.png  # 单个文件要写全路径
```

3. 代码里用：

```dart
Image.asset('assets/images/logo.png')
```

多分辨率（可选）：把不同倍率的图放到 `2.0x/`、`3.0x/` 子目录里，仍然按「不带倍率的路径」引用，系统会自动挑最合适的那张：

```
assets/images/logo.png
assets/images/2.0x/logo.png
assets/images/3.0x/logo.png
```

```dart
Image.asset('assets/images/logo.png') // 引用方式不变
```

自定义字体（可选，中文项目多数直接用系统字体）：

```yaml
flutter:
  fonts:
    - family: NumberFont
      fonts:
        - asset: assets/fonts/number_regular.ttf
        - asset: assets/fonts/number_bold.ttf
          weight: 700
```

### 6.2 应用名：改掉默认的项目名

| 平台 | 改哪里 |
| --- | --- |
| Android | `android/app/src/main/AndroidManifest.xml` 的 `android:label="商城 Demo"` |
| iOS | `ios/Runner/Info.plist` 的 `CFBundleDisplayName` |

### 6.3 App 图标：一行命令换掉 Flutter 默认图标

默认的蓝色 Flutter 图标不可能上架。用 `flutter_launcher_icons` 一次生成所有尺寸：

```bash
flutter pub add --dev flutter_launcher_icons
```

```yaml
# pubspec.yaml（版本以 pub.dev 最新为准）
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"     # 建议 1024×1024，无透明边缘
  adaptive_icon_background: "#6750A4"        # Android 自适应图标的底色
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

```bash
dart run flutter_launcher_icons
```

### 6.4 启动图：别让用户看见白屏

App 启动时先显示的是「原生启动图」，Flutter 引擎起来后才是第一帧。默认是纯白/纯黑，切过去会闪一下。用 `flutter_native_splash` 生成：

```bash
flutter pub add --dev flutter_native_splash
```

```yaml
flutter_native_splash:
  color: "#6750A4"
  image: assets/splash/splash_logo.png
  android_12:
    color: "#6750A4"
    image: assets/splash/splash_logo_android12.png
```

```bash
dart run flutter_native_splash:create     # 生成原生文件
dart run flutter_native_splash:remove     # 想撤销时
```

### 6.5 版本号：发版的身份证

```yaml
# pubspec.yaml
version: 1.2.0+7   # 1.2.0 = 版本名（用户看到的）
                   # 7     = 构建号（市场判断「哪个更新」的依据，每次发版必须 +1）
```

规则：

- **构建号只能涨不能降**，同一个构建号提交两次会被市场拒；
- 临时覆盖不用改文件：`flutter build apk --release --build-name=1.2.0 --build-number=8`；
- 对应关系：Android = `versionName` / `versionCode`，iOS = `CFBundleShortVersionString` / `CFBundleVersion`。

## 7. Android 打包全流程：签名、apk、aab

### 7.1 先看清你的工具链版本

```bash
flutter doctor -v
```

重点看三项：Flutter 版本、Android toolchain（SDK / 许可）、Java 版本。任何一项有红叉，先修完再打包，否则后面会以各种奇怪的方式报错。

Flutter 3.47.5 新建项目的默认配置（了解这些数字，看到报错才知道对不上）：

| 项 | 默认值 | 写在哪 |
| --- | --- | --- |
| `compileSdk` | 36 | `android/app/build.gradle.kts` → `flutter.compileSdkVersion` |
| `minSdk` | 24 | 同上 → `flutter.minSdkVersion`（Android 7.0 起） |
| `targetSdk` | 36 | 同上 → `flutter.targetSdkVersion` |
| Gradle | 9.3.1 | `android/gradle/wrapper/gradle-wrapper.properties` |
| AGP（Android Gradle Plugin） | 9.1.0 | `android/settings.gradle.kts` |
| Kotlin | 2.4.0 | `android/settings.gradle.kts` |
| Java | 17 | `android/app/build.gradle.kts` → `JavaVersion.VERSION_17` |

> 注意：新版模板用的是 **Kotlin DSL**（`build.gradle.kts`），不是老文章里的 Groovy（`build.gradle`）。语法不一样，看到 `signingConfigs { ... }` 里带 `=` 别慌。

### 7.2 为什么必须自己签名

1. **debug 签名不能上架**：市场只接受 release 签名的包；
2. **升级必须同一个签名**：Android 用签名判断「这是不是同一个 App 的新版本」。签名换了，用户只能卸载重装（数据全丢）；
3. **keystore 丢了就等于 App 废了**：你再也发不出「同一个 App」的更新。所以生成完立刻备份（网盘 + 本地，密码单独存放）。

### 7.3 步骤一：生成 keystore（只做一次）

```powershell
# PowerShell（Windows）
keytool -genkey -v -keystore $env:USERPROFILE\upload-keystore.jks `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

```bash
# macOS / Linux
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

几个参数的意思：`-alias upload` 是别名（后面 `key.properties` 要对应）、`-validity 10000` 是有效期天数（约 27 年，够用）、`-keyalg RSA -keysize 2048` 是算法与长度。

> 如果提示 `keytool 不是内部或外部命令`：它随 JDK 一起安装。用 `flutter doctor -v` 找到 Java 路径（Android Studio 一般自带 JBR），然后直接用全路径，例如
> `"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v ...`。

### 7.4 步骤二：写 `android/key.properties`

```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=upload
storeFile=C:/Users/Ming/upload-keystore.jks
```

> ⚠️ 路径用**正斜杠**（`C:/Users/...`）最省事。Java 的 properties 文件里 `\` 是转义符，写 `C:\Users\...` 会被吃掉字符，表现为「找不到 keystore 文件」。

好消息：模板自带的 `android/.gitignore` 里已经写好了忽略规则，`key.properties` 和 `*.jks` 不会被提交：

```
key.properties
**/*.keystore
**/*.jks
```

所以放心把 keystore 放在项目外面（比如用户目录），只要路径对就行。

### 7.5 步骤三：改 `android/app/build.gradle.kts`

在文件**最顶部**加两个 import 和读取逻辑：

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

然后改 `android { }` 块里的三处（其余保持模板原样）：

```kotlin
android {
    namespace = "com.example.shopping_demo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.shopping_demo" // ⚠️ 上架后不能再改
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode           // 来自 pubspec 的 +7
        versionName = flutter.versionName           // 来自 pubspec 的 1.2.0
    }

    // ① 新增：定义 release 签名
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            // ② 把模板里的 signingConfigs.getByName("debug") 换成 release
            signingConfig = signingConfigs.getByName("release")

            // ③ 可选：开启代码压缩 / 资源裁剪（第一次打包建议先注释掉，跑通再开）
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
```

注意 `applicationId`：它是**应用在市场里的唯一身份**，上架后不能改（改了就是另一个 App）。所以别用 `com.example.xxx`，正式项目要用自己的域名反写，例如 `com.yourname.shopping`。

### 7.6 步骤四：打包

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define-from-file=config/prod.json
```

产物路径：

```
build/app/outputs/flutter-apk/app-release.apk
```

三种常见打法：

| 命令 | 产物 | 什么时候用 |
| --- | --- | --- |
| `flutter build apk --release` | `app-release.apk`（一个包，含全部 ABI） | 自己测试、发给同事装 |
| `flutter build apk --release --split-per-abi` | `app-armeabi-v7a-release.apk` / `app-arm64-v8a-release.apk` / `app-x86_64-release.apk` | 按 CPU 架构分发，**每个包更小** |
| `flutter build appbundle --release` | `build/app/outputs/bundle/release/app-release.aab` | **上架 Google Play**（由市场按机型下发最优体积） |

体积相关的现实：一个「空 Flutter 项目」的 release apk 大约 7–15MB（引擎占大头）；`--split-per-abi` 通常能省下三分之一左右。想看清谁占地方：

```bash
flutter build apk --release --analyze-size --target-platform android-arm64
# 会生成体积分析文件，用 DevTools 的 "App Size" 打开看构成
```

### 7.7 步骤五：混淆与符号表（可选，但上线前值得做）

```bash
flutter build apk --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define-from-file=config/prod.json
```

两件事要记住：

1. **`--split-debug-info` 生成的符号文件要保存**（每个发出去的版本都要留一份）。线上崩溃的堆栈是混淆过的，只有配上对应版本的符号文件才能还原成可读代码；
2. **混淆 + R8 之后要完整回归一遍**：有些库用反射，需要额外的 keep 规则。真遇到问题，先在 `android/app/proguard-rules.pro` 里加：

```proguard
# android/app/proguard-rules.pro
-keep class com.example.shopping_demo.** { *; }
-keepattributes *Annotation*
```

实在查不出来，就先把 `isMinifyEnabled` 关掉验证是不是混淆导致的——**先定位，再修**。

### 7.8 装机验证：这一步不能省

```bash
flutter devices                                   # 看设备有没有连上
adb install -r build/app/outputs/flutter-apk/app-release.apk   # -r = 覆盖安装
# 或者
flutter install --release

# 调试 release 包（能看到日志、但跑的是 release 代码）
flutter run --release
```

装机后**必须走完整链路**：启动 → 登录 → 列表 → 详情 → 加购 → 退出 → 杀进程重开（验证登录态）。这一步能逮住 80% 的「release 才出现」问题。

## 8. 常见打包报错急救表

先记住**通用三步**：① 读完整报错的**最后几行**（Flutter/Gradle 通常直接告诉你该怎么办）；② `flutter clean` + `flutter pub get` 重来一次；③ 还不行就 `flutter build apk --release --verbose` 看真实原因。下面是高频的具体情况：

| 报错关键词 | 真正原因 | 怎么修 |
| --- | --- | --- |
| `Unsupported class file major version 6x` / `requires Java 17` | JDK 版本和 Gradle/AGP 对不上 | 装 JDK 17 以上；`flutter config --jdk-dir="C:\Program Files\Java\jdk-17"`，或让 Android Studio 的 Gradle JDK 指向 17 |
| `Minimum supported Gradle version is 9.1.0` | wrapper 里的 Gradle 太旧 | 改 `android/gradle/wrapper/gradle-wrapper.properties` 的 `distributionUrl` 到 `gradle-9.3.1-all.zip` |
| `Could not find method ...` / AGP 9 语法报错 | 老项目用旧 DSL / 老插件 | 用新版模板重建 android 目录：`flutter create --platforms=android .`（会覆盖模板文件，注意备份自定义内容） |
| `Execution failed for task ':app:processReleaseManifest'`，且 release 下**网络全挂** | release 清单缺 `INTERNET` 权限 | 在 `android/app/src/main/AndroidManifest.xml` 加 `<uses-permission android:name="android.permission.INTERNET"/>` |
| `Keystore file not found` / `Keystore was tampered with` / `Invalid keystore format` | `key.properties` 路径错 / 密码错 / 别名错 | 路径用正斜杠；核对 `keyAlias`、两个密码；确认文件确实存在 |
| `Failed to read key from store` | 别名或密码与生成时不一致 | 重新核对；必要时重新生成 keystore（会换签名，不能用于已上架 App 的更新） |
| `Duplicate class` / `Resource shrinker` 报错 | 依赖冲突或资源裁剪过猛 | 先关 `isShrinkResources` / `isMinifyEnabled` 验证；再查依赖冲突（`flutter pub deps --style=compact`） |
| `MissingPluginException` | 新加的插件没注册（热重载不生效） | 完全重启 App（不是热重载）；必要时 `flutter clean` 后重装 |
| 卡在 `Running Gradle task 'assembleRelease'` 很久 / 下载超时 | 网络问题（拉 Gradle 发行包与 Maven 依赖） | 配代理或在 `settings.gradle.kts` 的 `repositories` 里换国内镜像；`--verbose` 看卡在哪一步 |
| `No signature found` / 安装失败提示签名不一致 | 装了 debug 版或另一个签名的同包名 App | 先卸载旧包再装；确认 `applicationId` 是否变过 |
| 打包成功但**白屏 / 无法请求接口** | 缺权限、`baseUrl` 指错环境、明文 HTTP 被拦 | 用 `flutter run --release` 看日志；确认 `--dart-define-from-file` 传的是生产配置；明文接口加 HTTPS 或临时 `usesCleartextTraffic` |
| 体积突然暴涨 | 新依赖 / 未压缩图片 / 没分 ABI | `--analyze-size` 看构成，优先压缩图片资源、按 ABI 拆包 |

版本兼容矩阵（自己改版本时对照，别乱升）：

| 组合 | 最低要求 |
| --- | --- |
| AGP 9.0.x | Gradle ≥ 9.1.0 |
| AGP 8.0 及以上 | Java ≥ 17 |
| Java 17 | Gradle ≥ 7.3 |
| Java 21 | Gradle ≥ 8.4 |
| Java 25 | Gradle ≥ 9.1.0 |

## 9. 上架前检查清单

按顺序过一遍，每条都能回答「是」再发版：

| # | 检查项 | 说明 |
| --- | --- | --- |
| 1 | 版本号递增了吗？ | `pubspec.yaml` 的 `version: x.y.z+N`，每次发版 `N` 必须 +1 |
| 2 | 环境指向对吗？ | release 包用的是 `config/prod.json`；装到手机上第一眼看环境角标 |
| 3 | 图标、应用名、启动图换了吗？ | 还是默认 Flutter 图标 / 项目名 = 一眼假 |
| 4 | 权限是否最小化？ | 只留真正用到的（联网、相机…），多余权限会被市场和用户质疑 |
| 5 | release 还会打日志吗？ | HTTP 日志、Token、密码一律不能出现在生产日志里（用 `kDebugMode` 关掉） |
| 6 | 崩溃上报接了吗？ | 至少 `FlutterError.onError` + `PlatformDispatcher.instance.onError` |
| 7 | 混淆跑通了吗？ | 开了 R8 / obfuscate 后完整回归；符号文件已保存 |
| 8 | 敏感数据存对地方了吗？ | Token 用 `flutter_secure_storage`（Day 7 的建议） |
| 9 | 签名文件备份了吗？ | keystore + 密码分开备份，丢了发不了更新 |
| 10 | 真机全链路走过了吗？ | 启动 → 登录 → 列表 → 详情 → 加购 → 退出 → 重开 |
| 11 | 隐私合规材料齐吗？ | 隐私政策、用户协议、权限使用说明（各市场都要） |
| 12 | `targetSdk` 达标吗？ | 新上架一般要求跟进最新的 targetSdk（当前模板是 36） |

## 10. 今日最小项目：重构 + 出包 + 装机验证

### 10.1 重构前 vs 重构后

Day 6 ~ Day 8 的代码大概率长这样——**所有东西都塞在 `main.dart` 里**：

```
重构前
lib/
└── main.dart     # 1000+ 行：prefs、dio、拦截器、主题、页面、组件全在里面
```

```
重构后（用第 2.2 节的结构）
lib/
├── main.dart                    # 只剩初始化 + runApp（30 行左右）
├── app.dart                     # MaterialApp：主题、环境角标、首页
├── core/
│   ├── env.dart                 # 环境配置
│   ├── logger.dart              # 日志
│   ├── network/dio_client.dart  # Dio + 拦截器
│   └── storage/
│       ├── prefs.dart
│       └── app_database.dart
├── models/product.dart
├── services/product_api.dart
├── state/
│   ├── app_state.dart           # cart / products
│   ├── auth.dart                # 登录态
│   └── theme_mode.dart
├── theme/app_theme.dart
├── pages/
│   ├── login_page.dart
│   ├── product_list_page.dart
│   ├── product_detail_page.dart
│   └── profile_page.dart
└── widgets/
    ├── cart_badge.dart
    ├── env_banner.dart
    └── fav_button.dart
```

### 10.2 操作步骤（照顺序做）

1. **建目录**（Windows PowerShell）：

```powershell
cd 你的项目目录
New-Item -ItemType Directory -Force lib\core\network, lib\core\storage, lib\models, lib\services, lib\state, lib\theme, lib\pages, lib\widgets
```

2. **搬代码**：在 IDE 里拖动 / 重命名文件（VS Code 的「移动文件」和 F2 重命名会**自动更新 import**；手动复制粘贴最容易漏 import）。
3. **抽 `core/env.dart`**：用第 3.3 节那份，把代码里所有 `baseUrl` 字面量替换掉。
4. **抽 `core/logger.dart`**：用第 5.2 节那份，把 `print` / `debugPrint` 换掉。
5. **抽 `core/network/dio_client.dart`**：把 Day 6 的 dio 与拦截器收进来，顺手加上「生产不打日志」的判断。
6. **抽 `core/storage/`**：Day 7 的 `prefsProvider`、`AppDatabase` 各归其位。
7. **抽 `state/` 与 `pages/`**：把全局状态和页面分开，页面里不许再出现 `Dio` / `SharedPreferences`。
8. **`main.dart` 瘦身**，`app.dart` 装配 MaterialApp。
9. **检查**：`flutter analyze` 必须 `No issues found!`，再 `dart format .` 统一格式。
10. **出包**：按第 7 节走一遍 release 打包 + 装机验证。

### 10.3 关键文件：main.dart 与 app.dart

```dart
// lib/main.dart —— 只做三件事
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/logger.dart';
import 'core/storage/prefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) => Log.e('FlutterError', details.exception);
  PlatformDispatcher.instance.onError = (error, stack) {
    Log.e('未捕获异常', error);
    return true;
  };

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const ShopApp(),
    ),
  );
}
```

```dart
// lib/app.dart —— 装配 App：主题 + 环境角标 + 首页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'pages/product_list_page.dart';
import 'state/theme_mode.dart';
import 'theme/app_theme.dart';
import 'widgets/env_banner.dart';

class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: Env.appName,                     // 应用名也来自环境配置
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // 用 builder 把所有页面包起来，非生产环境右上角挂角标
      builder: (context, child) => EnvBanner(child: child ?? const SizedBox.shrink()),
      home: const ProductListPage(),
    );
  }
}
```

```dart
// lib/core/network/dio_client.dart —— 生产包不打印请求日志
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../env.dart';
import '../../state/auth.dart'; // Day 7 的 AuthInterceptor

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl, // 唯一的环境入口
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));

  if (kDebugMode && Env.enableHttpLog) {
    dio.interceptors.add(LogInterceptor());
  }
  return dio;
});
```

### 10.4 环境角标：一眼分清 dev 包和 prod 包

```dart
// lib/widgets/env_banner.dart
import 'package:flutter/material.dart';

import '../core/env.dart';

/// 非生产环境下，右上角挂一个「DEV」角标：装错包一眼就能看出来
class EnvBanner extends StatelessWidget {
  const EnvBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (Env.isProd) return child; // 生产包没有角标

    return Stack(
      children: [
        child,
        Positioned(
          top: 0,
          right: 0,
          child: SafeArea(
            child: IgnorePointer( // 别挡住真实的点击
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.orange.withValues(alpha: 0.9),
                child: Text(
                  Env.envLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

### 10.5 一个发版脚本：把「记得做的事」变成一条命令

```powershell
# scripts/build_prod.ps1 —— 发版前跑这一条就够了
$ErrorActionPreference = "Stop"

Write-Host "1/4 清理旧产物" -ForegroundColor Cyan
flutter clean
flutter pub get

Write-Host "2/4 静态检查（必须 No issues found）" -ForegroundColor Cyan
flutter analyze

Write-Host "3/4 打生产包（AAB，上架用）" -ForegroundColor Cyan
flutter build appbundle --release `
  --obfuscate `
  --split-debug-info=build/symbols `
  --dart-define-from-file=config/prod.json

Write-Host "4/4 完成" -ForegroundColor Green
Write-Host "产物：build/app/outputs/bundle/release/app-release.aab"
Write-Host "符号表：build/symbols —— 必须归档，线上崩溃排查要用！"
```

用的时候记得两件事：**把 `pubspec.yaml` 的构建号 +1**，以及**确认 `config/prod.json` 指向生产地址**。

### 10.6 运行后验证六件事

1. `flutter analyze` 输出 `No issues found!`，`dart format .` 没有额外改动。
2. 用 dev 配置跑起来，右上角有 **DEV 角标**；用 `--dart-define-from-file=config/prod.json` 打出来的包**没有角标**。
3. release apk 装到真机/模拟器后，能完整走通：启动 → 登录 → 列表 → 详情 → 加购 → 退出 → 杀进程重开（登录态还在）。
4. 图标、应用名、启动图都不是默认的 Flutter 样子。
5. release 包运行时，控制台**不再打印 HTTP 请求日志**（这是 `kDebugMode` 判断生效的证据）。
6. `--analyze-size` 看体积构成合理；`--split-per-abi` 出来的单架构包比整包明显更小。

## 11. 速查表

### 命令速查

| 命令 | 作用 |
| --- | --- |
| `flutter doctor -v` | 检查工具链（打包前必跑） |
| `flutter analyze` | 静态检查 |
| `dart format .` | 统一代码格式 |
| `flutter pub add <包>` / `remove` | 增删依赖 |
| `flutter pub outdated` | 查看可升级的依赖 |
| `flutter pub upgrade --major-versions` | 升级主版本（有破坏性，谨慎） |
| `flutter clean` | 清构建产物（打包前排错第一步） |
| `flutter run --dart-define-from-file=config/dev.json` | 按 dev 配置调试 |
| `flutter build apk --release --dart-define-from-file=config/prod.json` | 打生产 APK |
| `flutter build apk --release --split-per-abi` | 按 CPU 架构拆包（更小） |
| `flutter build appbundle --release` | 打 AAB（上架 Google Play） |
| `flutter build apk --release --obfuscate --split-debug-info=build/symbols` | 混淆 + 导出符号表 |
| `flutter build apk --release --analyze-size --target-platform android-arm64` | 体积分析 |
| `flutter run --release` | 在真机上跑 release 版看日志 |
| `adb install -r <apk>` | 覆盖安装 |
| `keytool -genkey -v -keystore ... -alias upload` | 生成签名文件 |

### 关键文件速查

| 文件 | 管什么 |
| --- | --- |
| `pubspec.yaml` | 依赖、版本号、assets、字体、图标/启动图配置 |
| `analysis_options.yaml` | lint 规则与静态检查配置 |
| `config/dev.json` / `config/prod.json` | 各环境的 dart-define 值 |
| `lib/core/env.dart` | 代码里唯一读环境的地方 |
| `android/key.properties` | 签名密码与 keystore 路径（**不进版本库**） |
| `android/app/build.gradle.kts` | applicationId、SDK 版本、签名配置、混淆开关 |
| `android/settings.gradle.kts` | AGP / Kotlin 版本、仓库、`:app` 模块 |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 版本 |
| `android/app/src/main/AndroidManifest.xml` | 应用名、权限、Activity 配置 |
| `android/app/proguard-rules.pro` | 混淆 keep 规则 |

### 核心写法

| 场景 | 写法 |
| --- | --- |
| 读环境值 | `static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: ...)` |
| 传环境值 | `--dart-define-from-file=config/prod.json` |
| 生产关日志 | `if (kDebugMode) dio.interceptors.add(LogInterceptor())` |
| 只在调试打日志 | `if (kDebugMode) debugPrint(...)` |
| 兜住崩溃 | `FlutterError.onError = ...; PlatformDispatcher.instance.onError = ...` |
| release 签名 | `signingConfigs { create("release") { ... } }` + `buildTypes.release.signingConfig` |
| 版本号 | `pubspec.yaml` 的 `version: 1.2.0+7` |
| 换图标 / 启动图 | `dart run flutter_launcher_icons` / `dart run flutter_native_splash:create` |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| 分层到底为了什么？ | 约束依赖方向（pages → state → services → models），让「找代码」和「改需求」的成本都可预测 |
| 环境为什么不能手改？ | 手改一定会忘、会带上线；编译期注入（dart-define）让「哪个包连哪个环境」由命令决定，而不是由记性决定 |
| 打包的本质是什么？ | 把 Dart 代码 AOT 编译成原生库，再用**你自己的签名**装进一个 Android 应用壳里；出问题几乎都出在「工具链版本、签名、权限」三件事上 |

### 十个高频坑

1. **忘记在 `pubspec.yaml` 声明 assets**：运行时报 `Unable to load asset`。
2. **改表结构没写迁移**（Day 7 的坑在这里放大）：升级安装后老用户直接崩。
3. **`applicationId` 用了 `com.example.*`**：上架前必须换成自己的域名反写，且上架后不能再改。
4. **把 keystore 或 `key.properties` 提交进 Git**：签名泄露等于把 App 的控制权交出去。
5. **`key.properties` 路径用反斜杠**：Java properties 会吃掉转义字符，报「找不到 keystore」。
6. **release 包忘了 `INTERNET` 权限**：debug 正常、release 全网络失败（Day 6 也提过，打包时必须确认）。
7. **生产包还在打 HTTP 日志**：Token、用户信息可能被打进日志，上架合规红线。
8. **`assert` 当业务校验**：release 里被编译器删掉，逻辑直接失效。
9. **首次打包就开混淆**：一旦出错难以定位 → 先用不混淆跑通，再开混淆并回归。
10. **忘记递增构建号**：市场拒绝同一个 `versionCode` 的重复提交。

## 12. 今日自检

完成下面四件事，Day 9 才算通过：

- [ ] 把项目重构到分层目录（`core` / `models` / `services` / `state` / `pages` / `widgets`），`main.dart` 只剩初始化
- [ ] 用 `--dart-define` 或 `--dart-define-from-file` 区分开发 / 生产环境，并能在 App 里看出当前环境
- [ ] 生成 release 签名，跑通 `flutter build apk --release`
- [ ] 把 release 包装到真机/模拟器，完整走一遍启动 → 登录 → 列表 → 详情 → 加购 → 退出

如果你能回答下面三个问题，就可以进入 Day 10（复盘与补漏）：

1. `lib/` 下合理的分层是什么？
2. 开发和生产环境怎么切换？
3. release 打包前要检查哪些？

答案提示：

1. 推荐先用「按层分」：`core/`（基础设施：env、logger、network、storage）、`models/`（纯数据模型 + fromJson/fromMap）、`services/`（接口封装）、`state/`（全局状态与业务编排）、`theme/`（主题）、`pages/`（页面）、`widgets/`（通用组件），`main.dart` 只留初始化和 `runApp`。关键不是目录名字，而是**依赖方向单向**：页面调状态、状态调服务、服务产出模型；页面不直接碰 HTTP/数据库，模型不依赖 UI。等单个功能文件数变多、多人并行开发时，再改成 `features/<功能>/{data,ui}` 的按功能分层。
2. 用编译期注入：命令行 `--dart-define=API_BASE_URL=...`，或更推荐 `--dart-define-from-file=config/dev.json` / `config/prod.json`；代码里统一通过 `String.fromEnvironment`（`Env.apiBaseUrl`）读取，全项目只有这一处环境入口。要同时在一台手机上装 dev 和 prod 两个包，才需要上 Android/iOS 原生的 flavor（配置更繁琐）。注意：这些值是**编译期常量**，改了必须重新编译，热重载不生效；另外客户端包里的值能被反编译看到，**密钥不要放这里**。
3. 至少过这九项：① 版本号已递增（`version: x.y.z+N`）；② release 用的是生产配置（看环境角标 / 检查命令里传的 json）；③ 图标、应用名、启动图已替换；④ 权限最小化且 release 清单里有 `INTERNET`；⑤ 生产不打 HTTP/敏感日志；⑥ 崩溃上报已接；⑦ 混淆与资源裁剪跑通并把符号表归档；⑧ `applicationId` 是正式包名、签名文件已备份；⑨ 真机上按完整链路回归一遍（含杀进程重开验证登录态）。
