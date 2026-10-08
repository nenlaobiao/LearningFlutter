# Flutter 学习笔记 08：主题与动画

> 适用前提：已经完成 Day 7（本地存储）。本机 Flutter 3.47.5 / Dart 3.13.4，笔记里的 API 都按这个版本核对过。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 8。
> 本笔记的目标：让 App 有一套**统一视觉**和**合理动效**——主题只配一次、全站生效；亮色 / 深色 / 跟随系统能切换还能记住；数字变化、图片转场这些「小动效」用最少的代码做出来，并且知道什么时候该收手。

## 目录

- [1. 从 Vue 到 Flutter：主题与动画怎么对应](#1-从-vue-到-flutter主题与动画怎么对应)
- [2. ThemeData：把设计规范写进代码](#2-themedata把设计规范写进代码)
- [3. ColorScheme：M3 的颜色语义](#3-colorscheme-m3-的颜色语义)
- [4. 深色模式：亮 / 暗 / 跟随系统](#4-深色模式亮--暗--跟随系统)
- [5. 隐式动画：改属性就自动过渡](#5-隐式动画改属性就自动过渡)
- [6. 显式动画：AnimationController 自己开车](#6-显式动画animationcontroller-自己开车)
- [7. Hero：列表图到详情图的共享元素转场](#7-hero列表图到详情图的共享元素转场)
- [8. 今日最小项目：主题切换 + 加购动效 + Hero 转场](#8-今日最小项目主题切换--加购动效--hero-转场)
- [9. 速查表](#9-速查表)
- [10. 今日自检](#10-今日自检)

## 1. 从 Vue 到 Flutter：主题与动画怎么对应

你在 Vue 里做主题，通常是这样：CSS 变量 + `var(--brand)`，再配一个 `.dark` 类切深色；做动效，通常是 `transition: all .3s ease` 或者 `<transition>` 组件。

Flutter 里的事是一样的，但换了一套「零件」：

| Vue / CSS | Flutter | 一句话说明 |
| --- | --- | --- |
| SCSS 变量 / CSS 变量 | `ThemeData` + `ColorScheme` | 一处定义，全站取用 |
| `--brand: #6750A4` + `var(--brand)` | `ColorScheme.fromSeed(seedColor: ...)` + `colorScheme.primary` | 给一颗种子色，自动生成一整套协调配色 |
| `@media (prefers-color-scheme: dark)` | `MaterialApp(themeMode: ThemeMode.system, darkTheme: ...)` | 跟随系统 |
| `document.body.classList.add('dark')` | 改 `themeMode` 状态（Riverpod） | 状态驱动，不是操作 DOM |
| Element / antd 的「全局组件样式」 | 组件主题：`CardThemeData`、`FilledButtonThemeData`… | 一次配置，全站同类组件统一 |
| `transition: all .3s ease` | `AnimatedContainer(duration:, curve:)` | 属性变了自动补间 |
| `@keyframes` + `animation` | `AnimationController` + `Tween` + `CurvedAnimation` | 需要「控制播放」时用 |
| `<transition>` 切组件 | `AnimatedSwitcher` | 一个组件换成另一个时的过渡 |
| 路由过渡 / FLIP 共享元素 | `Hero`、`PageRouteBuilder` | 列表图飞到详情图 |

> 心智模型：**Flutter 里没有「CSS 过渡」，也没有浏览器帮你插值。** 所有动画的本质都是同一件事：
> **一个 `Animation` 对象每帧给出一个新值 → 你（或框架）用它算样式 → 相关 Widget 重建。**
> 「隐式动画」只是框架把这套脚手架替你写好了；「显式动画」是你自己开车。理解了这一句，Day 8 剩下所有 API 都只是它的不同包装。

## 2. ThemeData：把设计规范写进代码

### 2.1 ThemeData 是什么

一句话：**ThemeData 是「一整套设计决策」的集合**——用什么颜色、文字多大、按钮多高、卡片圆角多少。它通过 `InheritedWidget` 机制沿着 Widget 树往下传，任何后代都能用 `Theme.of(context)` 拿到。

所以它解决的问题是：

> 不要让「主色是什么」「按钮多高」散落在 50 个页面里，而是**集中在一处定义、全站自动生效**。以后产品说「主色换成橙色」，你只改一行。

最小可用配置（其实就这一行）：

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
  ),
  home: const HomePage(),
);
```

> 版本提醒：Material 3 现在是**默认开启**的，写 `useMaterial3: true` 属于多余（写了也不报错，只是没意义）。你以前看到的老教程里还有它，是因为那时默认还是 Material 2。

### 2.2 主要配置哪些东西

| 配置项 | 管什么 | 常见值 |
| --- | --- | --- |
| `colorScheme` | **颜色**（最重要，见第 3 节） | `ColorScheme.fromSeed(...)` |
| `textTheme` | 文字层级（大标题 / 正文 / 按钮字） | 覆盖个别层级即可 |
| `scaffoldBackgroundColor` | 页面底色 | `scheme.surface` |
| `appBarTheme` | 顶栏：标题居中、阴影、底色 | `AppBarThemeData(...)` |
| `cardTheme` | 卡片：圆角、阴影、边距 | `CardThemeData(...)` |
| `filledButtonTheme` | 主按钮的高度、圆角、字重 | `FilledButtonThemeData(...)` |
| `inputDecorationTheme` | 输入框：圆角、填充色、边框 | `InputDecorationThemeData(...)` |
| `navigationBarTheme` | 底部导航栏 | `NavigationBarThemeData(...)` |
| `dividerTheme` | 分割线粗细、颜色 | `DividerThemeData(...)` |
| `visualDensity` | 整体「松紧度」 | `VisualDensity.standard` |

> 版本提醒（重要）：Flutter 3.29 之后，组件主题类统一改名为 `XxxThemeData`。所以你看老文章里的 `CardTheme(...)`、`AppBarTheme(...)`、`InputDecorationTheme(...)` 现在应该写成 **`CardThemeData(...)`、`AppBarThemeData(...)`、`InputDecorationThemeData(...)`**。名字变了，参数没变。

### 2.3 一份可以直接抄的主题文件

约定：**所有颜色和样式只在这个文件里定义**，页面里再也不出现 `Color(0xFF...)`。

```dart
// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  /// 种子色：改这一颗颜色，整套配色（按钮 / 选中态 / 卡片 / 分割线）跟着变
  static const Color seed = Color(0xFF6750A4);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);

    return ThemeData(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // 文字：只写要改的层级，其余自动继承默认
      textTheme: TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyMedium: TextStyle(height: 1.5, color: scheme.onSurface),
      ),

      appBarTheme: AppBarThemeData(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,          // 内容滚到顶栏下面时才浮起一点，细节更精致
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent, // 关掉 M3 默认的「抬升染色」
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,  // 用容器底色区分层次，比阴影更现代
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48), // 所有主按钮一样高
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),

      dividerTheme: DividerThemeData(
        space: 1,
        thickness: 1,
        color: scheme.outlineVariant,        // 分割线不需要很显眼
      ),
    );
  }
}
```

配好之后，页面里就只剩「语义」了：

```dart
// 页面代码：不写颜色，不写圆角，全部来自主题
Scaffold(
  appBar: AppBar(title: const Text('商品详情')),
  body: Padding(
    padding: const EdgeInsets.all(16),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('这个卡片是全站统一样式', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('圆角、底色、内边距都由主题决定',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: () {}, child: const Text('加入购物车')),
          ],
        ),
      ),
    ),
  ),
);
```

### 2.4 文字层级：TextTheme 的 15 个名字

Material 3 把文字分成 5 组、每组 3 档，共 15 个「语义名字」：

| 组 | 名字 | 典型用途 |
| --- | --- | --- |
| Display | `displayLarge` / `displayMedium` / `displaySmall` | 超大数字、开屏标语 |
| Headline | `headlineLarge` / `headlineMedium` / `headlineSmall` | 页面大标题 |
| Title | `titleLarge` / `titleMedium` / `titleSmall` | 顶栏标题、卡片标题 |
| Body | `bodyLarge` / `bodyMedium` / `bodySmall` | 正文、次要说明 |
| Label | `labelLarge` / `labelMedium` / `labelSmall` | 按钮文字、标签、角标 |

老教程里的 `headline6`、`bodyText1`、`caption` 是 2018 年的旧名字，对照关系：

| 旧名（2018） | 新名（M3） |
| --- | --- |
| `headline1` → `headline4` | `displayLarge` → `headlineMedium` |
| `headline5` | `headlineSmall` |
| `headline6` | `titleLarge` |
| `subtitle1` / `subtitle2` | `titleMedium` / `titleSmall` |
| `bodyText1` / `bodyText2` | `bodyLarge` / `bodyMedium` |
| `caption` / `overline` / `button` | `bodySmall` / `labelSmall` / `labelLarge` |

用法：**永远从 `Theme.of(context)` 取，不要手写 `TextStyle(fontSize: 17)`**。

```dart
final textTheme = Theme.of(context).textTheme;

Text('标题', style: textTheme.titleLarge)
Text('需要强调的正文', style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary))
```

> 为什么强调这一点：字号写死在页面里，改设计的时候就要全项目搜 `fontSize`。走 `textTheme` 的话，将来接设计系统、做无障碍字号缩放、换字体，都只改主题一处。

### 2.5 进阶：ThemeExtension（品牌自定义颜色）

`ColorScheme` 只提供「语义化」的颜色（primary / surface / error…）。真实项目常需要 `success`（成功绿）、`warning`（警告黄）这种**它没有的颜色**。硬写 `Color(0xFF4CAF50)` 的话，深色模式就会翻车。

正确做法是 `ThemeExtension`——把自定义颜色也变成主题的一部分，**同时支持深浅两套和插值动画**：

```dart
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({required this.success, required this.warning});

  final Color success;
  final Color warning;

  @override
  AppColors copyWith({Color? success, Color? warning}) =>
      AppColors(success: success ?? this.success, warning: warning ?? this.warning);

  /// 主题切换时框架会调它做平滑过渡，不能省
  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
    );
  }
}

// 注册（light / dark 各给一套）
ThemeData(extensions: const [
  AppColors(success: Color(0xFF2E7D32), warning: Color(0xFFF9A825)),
])

// 取用
final appColors = Theme.of(context).extension<AppColors>()!;
Icon(Icons.check_circle, color: appColors.success)
```

学习期可以先不写，但要知道**「主题里没有的颜色，不要硬写，而是扩进主题」**，这是商业项目里很常见的一层。

## 3. ColorScheme：M3 的颜色语义

### 3.1 fromSeed 在做什么

```dart
final scheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF6750A4), // 给一颗种子色
  brightness: Brightness.light,       // 亮色版（dark 就是深色版）
);
```

Material 3 会拿这颗种子色，按色调（tonal palette）算法生成**一整套互相协调的颜色**：主色、容器色、表面色、分割线色、错误色……每个颜色还配了一个「放在它上面的文字色」（`on*`）。

好处很直接：

1. **不会配出难看的组合**——对比度由算法保证；
2. **深色模式免费**——同一个种子色换 `brightness: Brightness.dark` 就是一整套深色方案；
3. **换品牌色成本极低**——改一颗种子色，全站跟着变。

想要更「有个性」的配色，还能给个变体（了解即可）：

```dart
ColorScheme.fromSeed(
  seedColor: seed,
  brightness: Brightness.light,
  dynamicSchemeVariant: DynamicSchemeVariant.vibrant, // 更鲜艳；还有 expressive / fidelity / neutral 等
  contrastLevel: 0.0,                                 // 0 正常，1 最高对比（无障碍场景用得上）
);
```

### 3.2 常用颜色角色速查

| 角色 | 用在哪 |
| --- | --- |
| `primary` / `onPrimary` | 主按钮、强调色块（`on*` = 放在它上面的文字/图标色） |
| `primaryContainer` / `onPrimaryContainer` | 选中态背景、次级强调块、标签 |
| `secondary` / `tertiary` | 辅助点缀（算法保证和主色协调） |
| `surface` | 页面底色（**取代旧的 `background`**） |
| `surfaceContainerLowest` → `surfaceContainerHighest` | 卡片、面板、分组的层次（越大越「浮起来」） |
| `onSurface` / `onSurfaceVariant` | 正文 / 次要文字（**取代旧的 `Colors.black54`**） |
| `outline` / `outlineVariant` | 边框 / 分割线 |
| `error` / `onError` | 错误态 |
| `inverseSurface` / `onInverseSurface` | SnackBar 这类「反色」表面 |

### 3.3 写颜色的两条铁律

**铁律一：颜色一律从 `colorScheme` 取，不写十六进制。**

```dart
// ❌ 深色模式下必然翻车：白底白字 / 黑底黑字
Container(color: Colors.white, child: Text('价格', style: TextStyle(color: Colors.black)))

// ✅ 跟着主题走，深浅模式都正常
final scheme = Theme.of(context).colorScheme;
Container(color: scheme.surfaceContainerLow, child: Text('价格', style: TextStyle(color: scheme.onSurface)))
```

**铁律二：需要「淡一点的品牌色」，用 `withValues(alpha:)`，不要用 `withOpacity`。**

```dart
// ⚠️ withOpacity 在新版已经废弃（精度问题）
scheme.primary.withOpacity(0.12)

// ✅ 新写法
scheme.primary.withValues(alpha: 0.12)
```

> 加一层 12% 透明度的主色，是做「浅色标签底」「选中态背景」最常用的手法，比硬写一个浅紫色靠谱得多。

## 4. 深色模式：亮 / 暗 / 跟随系统

### 4.1 三件套：theme、darkTheme、themeMode

```dart
MaterialApp(
  theme: AppTheme.light(),        // 亮色
  darkTheme: AppTheme.dark(),     // 深色
  themeMode: ThemeMode.system,    // 什么时候用哪套（见下表）
  home: const HomePage(),
);
```

| `ThemeMode` | 效果 | 什么时候用 |
| --- | --- | --- |
| `ThemeMode.system` | 跟随系统（默认值） | 推荐默认：用户系统开了深色就深色 |
| `ThemeMode.light` | 永远亮色 | 用户手动选「浅色」 |
| `ThemeMode.dark` | 永远深色 | 用户手动选「深色」 |

> 常见误区：以为要自己监听系统亮暗。**不需要**——`ThemeMode.system` 下，MaterialApp 会自动跟着系统切换并重建整棵树。

### 4.2 让用户能选、并且记住（接上 Day 7 的 prefs）

主题偏好属于「App 级状态」，放 Riverpod 最合适；持久化用 Day 7 已经接好的 `shared_preferences`：

```dart
// lib/state/theme_mode.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    // 启动时读磁盘：Day 7 已经保证 prefs 在 main 里初始化好了
    final raw = ref.watch(prefsProvider).getString(_key);
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system, // 没存过 / 'system' 都走这里
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
    state = mode; // 先落盘再改内存，和 Day 7 的登录态一个规矩
  }
}
```

入口处接上：

```dart
class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider), // 状态一变，整站换肤
      home: const HomePage(),
    );
  }
}
```

设置页里给一个三选一（`SegmentedButton` 就是为这种「少量互斥选项」准备的）：

```dart
class AppearanceSetting extends ConsumerWidget {
  const AppearanceSetting({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('浅色')),
        ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('深色')),
        ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('跟随系统')),
      ],
      selected: {mode},
      onSelectionChanged: (selection) =>
          ref.read(themeModeProvider.notifier).setMode(selection.first),
    );
  }
}
```

### 4.3 主题切换时其实有过渡动画

很多人以为切主题是「啪」一下跳变——其实 MaterialApp 默认会做一个 **200ms 的颜色插值过渡**（`kThemeAnimationDuration`），新旧两套 `ThemeData` 之间由框架调用 `lerp` 平滑过渡，所以你自定义的 `ThemeExtension` 也必须实现 `lerp`（第 2.5 节讲过）。

```dart
MaterialApp(
  themeAnimationDuration: const Duration(milliseconds: 300), // 想更慢一点可调
  themeAnimationCurve: Curves.easeOut,
  // ...
);
```

### 4.4 深色模式最容易翻车的四件事

| 问题 | 现象 | 正确做法 |
| --- | --- | --- |
| 页面里写死颜色 | 深色下「白底白字」直接看不见 | 颜色全部走 `colorScheme` |
| `brightness` 和 `colorScheme` 不一致 | 以为自己配了深色，控件还是亮色 | 只用 `ColorScheme.fromSeed(brightness:)`，别单独设 `ThemeData(brightness:)` |
| 靠阴影区分层次 | 深色下阴影几乎看不见，卡片糊成一片 | 用 `surfaceContainerLow/High` 这类**容器底色**区分层次 |
| 图片、图标没做适配 | 深色下图标太暗 / 透明 PNG 消失 | 图标色用 `onSurface` / `onSurfaceVariant`；图片给一层浅色或容器色占位底 |

加分细节：状态栏图标颜色可以用 `AppBarThemeData(systemOverlayStyle: ...)` 统一；系统若开了「减弱动效」，用 `MediaQuery.disableAnimationsOf(context)` 判断，把动画时长设为 `Duration.zero`，这是无障碍里很基本的一条。

**深色模式自查清单**：页面里所有颜色都来自 `colorScheme`；层次靠容器底色而不是阴影；分割线用 `outlineVariant`；图片有占位底色；切主题有 200ms 过渡不跳变。

## 5. 隐式动画：改属性就自动过渡

### 5.1 它到底替我们做了什么

普通 `Container` 改成 `AnimatedContainer` 之后，**你只改属性，过渡交给框架**。框架在背后做了三件事：

1. 帮你创建并维护一个 `AnimationController`；
2. 发现属性（高度、颜色…）变了，自动从「旧值」补间到「新值」；
3. Widget 销毁时自动释放资源（不用你写 `dispose`）。

所以隐式动画的适用场景可以一句话概括：

> **凡是「同一个东西，从 A 状态变成 B 状态」的动效，优先用隐式动画。** 代码最少、最不容易漏资源释放。

### 5.2 例子一：会「长大」的卡片

```dart
class ExpandCard extends StatefulWidget {
  const ExpandCard({super.key});

  @override
  State<ExpandCard> createState() => _ExpandCardState();
}

class _ExpandCardState extends State<ExpandCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // 必填：过渡时长
        curve: Curves.easeOutCubic,                  // 必填？不写默认 linear，手感生硬
        height: _expanded ? 160 : 72,                // 高度变化 -> 自动补间
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: _expanded ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(_expanded ? 24 : 12), // 圆角也跟着动
        ),
        child: Center(
          child: Text(
            _expanded ? '点击收起' : '点击展开',
            style: TextStyle(color: _expanded ? scheme.onPrimaryContainer : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}
```

**一行只改属性，就能带动画**——这就是隐式动画的价值。`AnimatedContainer` 能「动」的属性包括：`height/width`、`padding`、`margin`、`decoration`（颜色、圆角、边框、渐变）、`transform`、`alignment`。

### 5.3 例子二：购物车数字变化（`AnimatedSwitcher`）

场景：加入购物车时，角标数字从 2 变 3，直接跳变很廉价，加个缩放淡入就舒服很多。

```dart
AnimatedSwitcher(
  duration: const Duration(milliseconds: 250),
  transitionBuilder: (child, animation) => ScaleTransition(
    scale: animation,
    child: FadeTransition(opacity: animation, child: child),
  ),
  child: Text(
    '$count',
    key: ValueKey(count), // ⚠️ 关键：让框架知道「这是另一个孩子」
    style: const TextStyle(fontWeight: FontWeight.bold),
  ),
)
```

> ⚠️ 最经典的坑：**`AnimatedSwitcher` 靠「key 或类型不同」判断孩子换了**。
> 不加 `key`，框架认为「还是同一个 Text，只是文字变了」，于是**没有动画**。
> 反过来，如果每次都塞 `UniqueKey()`，那每次重建都会触发一次切换动画，也会出现奇怪的闪烁。正确姿势是 `ValueKey(真正会变的值)`。

### 5.4 例子三：一次性数值动画（`TweenAnimationBuilder`）

场景：合计金额从 0 涨到 199.5、进度条从 0 到 0.7。这类「进入页面时从 A 动到 B，之后不反复」的，用 `TweenAnimationBuilder` 最少代码：

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0, end: totalPrice),
  duration: const Duration(milliseconds: 600),
  curve: Curves.easeOutCubic,
  builder: (context, value, child) => Text(
    '合计 ¥${value.toStringAsFixed(2)}',
    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
  ),
)
```

注意 `builder` 的第三个参数 `child`：**不需要跟着动画重建的内容，放进构建函数的 `child` 参数**（或者在 `TweenAnimationBuilder` 的 `child:` 参数里传），框架会只构建一次，性能更好。

### 5.5 常用隐式动画速查

| Widget | 动什么 | 典型场景 |
| --- | --- | --- |
| `AnimatedContainer` | 尺寸、内外边距、装饰（颜色/圆角/边框） | 展开收起、选中态、按钮形变 |
| `AnimatedOpacity` | 透明度 | 淡入淡出、加载完再显示 |
| `AnimatedPadding` | 内边距 | 键盘弹出时内容上移 |
| `AnimatedAlign` | 对齐位置 | 小圆点在容器内移动 |
| `AnimatedPositioned` | 位置（配合 `Stack`） | 悬浮按钮位置变化 |
| `AnimatedDefaultTextStyle` | 文字样式 | 选中时文字变粗变大 |
| `AnimatedCrossFade` | **两个固定孩子之间的切换** | 「加载中 / 内容」互换、展开详情 |
| `AnimatedSwitcher` | **任意单个孩子替换** | 数字变化、图标切换、状态图标 |
| `TweenAnimationBuilder` | 任意数值 → 自定义界面 | 金额滚动、进度、评分条 |

### 5.6 三条必须记住的规则

1. **`duration` 必填，`curve` 决定手感。** 不写 `curve` 就是匀速直线运动（`Curves.linear`），看起来像机器。常用曲线：

   | 曲线 | 手感 | 用在哪 |
   | --- | --- | --- |
   | `Curves.easeOutCubic` | 快速启动、缓慢停下 | **最常用**：元素进入、数字变化 |
   | `Curves.easeInOut` | 两头慢、中间快 | 往返移动、对称变化 |
   | `Curves.easeIn` | 慢慢启动、快速结束 | 元素退出 |
   | `Curves.easeOutBack` | 冲过头再回弹一点 | 弹跳感、加购成功 |
   | `Curves.elasticOut` | 明显弹性震荡 | 强调型动效，别滥用 |
   | `Curves.fastOutSlowIn` | Material 标准曲线 | 页面级过渡 |

2. **只有「同一个位置上的属性变化」才会补间。** 如果你用 `if/else` 换成了另一个类型的 Widget，框架看到的是「旧孩子被扔掉、新孩子被插入」，不会帮你过渡——这时要用 `AnimatedSwitcher` / `AnimatedCrossFade`。

3. **隐式动画不能「控制播放」。** 你不能让它暂停、反向、循环，也不能在动画结束时精确回调。需要这些能力时，进入下一节的显式动画。

### 5.7 动效设计与性能

| 时长 | 感受 | 建议用途 |
| --- | --- | --- |
| 100–150ms | 几乎察觉不到 | 颜色/图标这类小变化 |
| 200–300ms | 舒服、standard | **页面内绝大多数动效都落在这里** |
| 300–500ms | 明显但可接受 | 卡片展开、页面转场 |
| > 500ms | 用户开始等 | 只在开屏、庆祝类场景用 |

性能小原则：

- 动画期间**每帧都会重建**被动画的 Widget，所以它的子树尽量轻，静态部分抽成 `const` 子 Widget 或放到 `child:` 参数里；
- 动画如果只改「绘制」相关的属性（透明度、`Transform`），比改「布局」相关的属性（宽高、边距）便宜；
- 大量元素同时动画时，用 `RepaintBoundary` 把动画区域和其余区域隔开。

## 6. 显式动画：AnimationController 自己开车

### 6.1 什么时候必须用它

隐式动画是「自动挡」，显式动画是「手动挡」。出现下面任一需求，就该换手动挡：

- 需要**控制播放**：暂停、反向、循环、中途改变方向；
- 需要**一个动画值驱动多个属性/多个 Widget**（比如进度同时改变高度、颜色、文字）；
- 需要**动画结束后做事**（播完再跳转、播完再弹提示）；
- 需要**序列动画**（先放大再缩小、A 完了 B 才开始）；
- 需要**物理/弹性效果**（弹球、拖拽回弹）。

### 6.2 骨架：一个会「心跳」的收藏按钮

```dart
class FavButton extends StatefulWidget {
  const FavButton({super.key});

  @override
  State<FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<FavButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _liked = false;

  @override
  void initState() {
    super.initState();

    // ① 控制器：一个「按时长从 0 跑到 1」的时间轴
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );

    // ② Tween 把 0~1 映射成 1~1.35；③ CurvedAnimation 给它加缓动
    _scale = Tween<double>(begin: 1, end: 1.35)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose(); // ⚠️ 必须释放，否则会报内存/资源泄漏
    super.dispose();
  }

  Future<void> _toggle() async {
    setState(() => _liked = !_liked);
    if (_liked) {
      await _controller.forward();  // 放大
      await _controller.reverse();  // 回弹到原位
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: _toggle,
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          _liked ? Icons.favorite : Icons.favorite_border,
          color: _liked ? scheme.error : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

### 6.3 三件套各自负责什么

| 零件 | 作用 | 类比 |
| --- | --- | --- |
| `AnimationController` | 时间轴，按 `duration` 从 0 走到 1（`value` 可读可写） | 秒表 |
| `Tween` | 把 0~1 映射成你要的值域（1→1.35、宽→高、颜色 A→B） | 单位换算表 |
| `CurvedAnimation` / `CurveTween` | 给线性时间加「速度曲线」 | 给秒表加个油门曲线 |

它们的关系是「串起来用」：

```
AnimationController（0 → 1，线性时间）
        ↓ Tween 映射
值域（1 → 1.35）
        ↓ Curve 塑形
最终的 Animation<double>（拿去用）
```

> `vsync: this` 是什么：告诉框架「这个动画跟我这个 State 绑定」。框架会用一个 `Ticker` 每帧回调，页面销毁时自动停；`SingleTickerProviderStateMixin` 表示「这个 State 只服务一个控制器」，如果一个页面要跑多个控制器，就用 `TickerProviderStateMixin`。

### 6.4 常用控制 API

| 调用 | 效果 |
| --- | --- |
| `controller.forward()` | 正向播到 1 |
| `controller.reverse()` | 反向播到 0 |
| `controller.repeat()` | 循环播放（loading 类动效常用） |
| `controller.reset()` | 立即回到 0 |
| `controller.stop()` | 停在当前位置 |
| `await controller.forward()` | 播放结束的 `Future`，可以直接 `await` 后做事 |
| `controller.value = 0.5` | 手动跳到一半（拖拽进度时有用） |
| `controller.status` | `dismissed` / `forward` / `reverse` / `completed` |
| `controller.addStatusListener(...)` | 状态变化回调（播放完 → 干点什么） |

### 6.5 用 `AnimatedBuilder` 让「任意 UI」跟着动画变

如果动画值要驱动的不只是缩放，而是颜色、偏移、文字、进度……就用 `AnimatedBuilder`：

```dart
AnimatedBuilder(
  animation: _controller,
  // child：不随动画变化的部分，只构建一次（性能关键）
  child: const Text('正在提交'),
  builder: (context, child) {
    return Column(
      children: [
        Opacity(opacity: 1 - _controller.value * 0.5, child: child),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: _controller.value),
        Transform.translate(
          offset: Offset(0, -12 * _controller.value), // 上浮 12
          child: const Icon(Icons.check_circle),
        ),
      ],
    );
  },
)
```

**一个 `_controller.value` 同时喂给了透明度、进度条、位移**——这就是显式动画不可替代的地方。

### 6.6 现成的「过渡组件」：不用自己写 Transform

框架给了一批 `AnimatedWidget`，直接把 `Animation` 塞进去就行：

| 组件 | 效果 |
| --- | --- |
| `FadeTransition` | 透明度 |
| `ScaleTransition` | 缩放 |
| `SlideTransition` | 平移（参数是「自身尺寸的比例」，`Offset(0, 0.2)` = 下移 20%） |
| `RotationTransition` | 旋转 |
| `SizeTransition` | 尺寸（常用于展开/收起一块区域） |
| `AlignTransition` | 对齐位置 |
| `PositionedTransition` | 位置（配合 `Stack`） |

序列动画（先放大、再缩小）用 `TweenSequence`，两段之间按权重分配时间：

```dart
_anim = TweenSequence<double>([
  TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
  TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 60),
]).animate(_controller);
```

想让多个动画「错开开始」，用 `Interval` 把时间轴切段：

```dart
final fadeIn = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.0, 0.5, curve: Curves.easeOut), // 前 50% 时间做淡入
);
final slideIn = CurvedAnimation(
  parent: _controller,
  curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic), // 从 30% 开始做位移
);
```

### 6.7 隐式还是显式？一张表决定

| 你的需求 | 选谁 |
| --- | --- |
| 只是「A 状态 → B 状态」的属性变化 | **隐式**（`AnimatedContainer` 等） |
| 一个 Widget 换成另一个 | **隐式**（`AnimatedSwitcher` / `AnimatedCrossFade`） |
| 数字 / 进度从 A 到 B | **隐式**（`TweenAnimationBuilder`） |
| 要暂停、反向、循环、拖拽控制 | 显式 |
| 一个动画驱动多个属性 / 多个 Widget | 显式 |
| 播完要回调做事、要串行动画 | 显式 |

> 经验：**能用隐式就别写显式**。显式动画代码量大约是隐式的 3 倍，还多一个「忘记 `dispose`」的风险。真正需要手动挡的场景没那么多。

## 7. Hero：列表图到详情图的共享元素转场

### 7.1 原理：两个页面里的「同一个东西」

```
   列表页                          详情页
┌───────────────┐              ┌───────────────────┐
│  Hero(tag:X)  │              │   Hero(tag:X)     │
│   商品小图     │  ─ push ─▶   │     商品大图       │
└───────────────┘              └───────────────────┘

飞行过程：框架把两个「同名 Hero」配对，
在 Overlay 上放一个飞行中的图片，从起点的矩形飞到终点的矩形，
两边的原始位置在飞行期间「留空」。
```

所以 Hero 不是「让页面切换好看一点」，而是**让用户明确知道「我点的这个东西，就是打开的那个东西」**——这是最有效的一类动效，因为它降低认知成本，而不只是好看。

### 7.2 最小实现：列表图 → 详情图

列表页（把缩略图包进 `Hero`）：

```dart
ListTile(
  leading: Hero(
    tag: 'product-${product.id}', // ⚠️ tag 必须唯一：用 id，不要用商品名
    child: Image.network(
      product.thumbnail,
      width: 56,
      height: 56,
      fit: BoxFit.cover,
    ),
  ),
  title: Text(product.title),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
  ),
)
```

详情页（用**同样的 tag**，尺寸更大）：

```dart
Hero(
  tag: 'product-${product.id}', // 和列表页一字不差
  child: Image.network(
    product.thumbnail,
    height: 260,
    width: double.infinity,
    fit: BoxFit.cover,
  ),
)
```

就这两处，中间那一路「飞行」是框架做的：位置、大小、圆角都会自动插值。

### 7.3 生效条件（自检必答）

| 条件 | 说明 |
| --- | --- |
| 两个页面**各有**一个 Hero | 只有一边有，不会有任何动画 |
| 两边 `tag` **相同** | 这是配对依据 |
| 同一个页面内 tag **唯一** | 重复会直接抛异常（见 7.4 坑 1） |
| 通过 `Navigator.push/pop` 触发 | 同 `MaterialApp` 下的同一个 Navigator |
| 两边的孩子**结构尽量一致** | 都用 `Image` / 都用 `ClipRRect`，中途不会「换脸」 |

### 7.4 五个高频坑

1. **tag 重复 → 直接崩**：`There are multiple heroes that share the same tag within a subtree`。
   最容易发生在「底部 Tab 的两页里都有列表、且都用了相同 tag」的场景。修法：tag 带上页面前缀（`'home-product-1'` / `'cart-product-1'`），或列表项用 `id` 而不是 `index`。
2. **飞行中文字出现下划线（黄/红双线）**：飞行的 subtree 脱离了原本的 `Material` 祖先，`Text` 拿不到 `DefaultTextStyle`。修法：给 Hero 的孩子包一层 `Material(color: Colors.transparent, child: ...)`。
3. **图片在飞行中「空白一下」**：飞行用的是新构建的 widget，如果图片还没解码就会闪。
   修法：两页用**同一个 URL**（命中同一份图片缓存），必要时给两页同一个 `cacheWidth`/`BoxFit`；也可以给图片容器一个占位底色。
4. **形状突变很生硬**：起点是 56×56 正方形、终点是 260 宽的全宽图，默认按矩形插值，看起来会「抻」。
   修法：`fit` 保持一致、圆角一致；确实需要精细控制时用 `flightShuttleBuilder` 自定义飞行中的样子。
5. **返回时 Hero 找不到目标**：返回前列表被刷新/重建（比如 item 被滚出屏幕、数据被替换），配对失败会报错。
   修法：返回前别重建列表；用稳定的 key（`ValueKey(product.id)`）让 item 可被复用。

### 7.5 几个有用的参数（了解即可）

```dart
Hero(
  tag: 'product-$id',
  // 控制「飞行中长什么样」：默认是终点页的 widget
  flightShuttleBuilder: (flightContext, animation, direction, fromContext, toContext) {
    return fromContext.widget;
  },
  // Hero 不在屏幕上时的占位（例如列表里 item 还没滚出来）
  placeholderBuilder: (context, size, child) => Container(color: Colors.black12),
  // 是否允许 iOS 侧滑手势触发 Hero 转场
  transitionOnUserGestures: true,
  child: ...,
)
```

还有一个实用小件：`HeroMode(enabled: false, child: ...)` 可以**局部关掉** Hero。场景：同一个列表在同一页面出现两次（比如底部 Tab 的 `IndexedStack` 同时挂了首页和购物车页），可以给不在前台的页面套 `HeroMode(enabled: false)`，避免 tag 冲突。

## 8. 今日最小项目：主题切换 + 加购动效 + Hero 转场

目标：在 Day 7 的商城 Demo 上做四件事——

1. 抽出 `AppTheme`（亮 / 暗两套），让按钮、卡片、输入框、分隔线全站统一；
2. 加「浅色 / 深色 / 跟随系统」切换，并用 `prefs` 记住选择；
3. 加购角标数字用 `AnimatedSwitcher` 做变化动画，收藏按钮用显式动画做「心跳」；
4. 商品图从列表 Hero 飞到详情。

### 8.1 目录结构

```
lib/
├── main.dart                  # 入口：预加载 prefs、装配 MaterialApp
├── theme/
│   └── app_theme.dart         # 第 2.3 节那份主题文件，直接用
├── models/
│   └── product.dart           # Product 模型（Day 6 / Day 7 沿用）
├── state/
│   ├── app_state.dart         # cart / products provider（Day 6 沿用）
│   └── theme_mode.dart        # 主题模式状态 + prefs 持久化
├── pages/
│   ├── product_list_page.dart
│   ├── product_detail_page.dart
│   └── profile_page.dart
└── widgets/
    ├── cart_badge.dart        # AnimatedSwitcher 数字角标
    └── fav_button.dart        # AnimationController 心跳收藏
```

### 8.2 入口：把主题三件套接上

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pages/product_list_page.dart';
import 'state/theme_mode.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance(); // Day 7 的启动预加载

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const ShopApp(),
    ),
  );
}

class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '商城 Demo',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider), // 状态一变，整站换肤
      home: const MainTabsPage(),
    );
  }
}

class MainTabsPage extends ConsumerStatefulWidget {
  const MainTabsPage({super.key});

  @override
  ConsumerState<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends ConsumerState<MainTabsPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ProductListPage(), ProfilePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(
            icon: CartBadge(child: const Icon(Icons.shopping_cart_outlined)),
            label: '购物车',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
```

> 注意：这里为了聚焦主题和动画，把「购物车」做成了只有角标没有独立页面的简化版。真正要用的时候，把 Day 6 的 `CartPage` 填回第二个 Tab 即可。

### 8.3 购物车状态与角标动画

```dart
// lib/state/app_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 商品 id -> 数量
final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  void add(int productId) {
    state = {...state, productId: (state[productId] ?? 0) + 1};
  }

  void removeOne(int productId) {
    final current = state[productId] ?? 0;
    final next = {...state};
    if (current <= 1) {
      next.remove(productId);
    } else {
      next[productId] = current - 1;
    }
    state = next;
  }
}

/// 派生状态：总件数（状态变了自动重算，不用手写监听）
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).values.fold(0, (sum, count) => sum + count),
);
```

```dart
// lib/widgets/cart_badge.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';

/// 数字变化时带一点缩放淡入，而不是硬跳
class CartBadge extends ConsumerWidget {
  const CartBadge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    if (count == 0) return child;

    return Badge(
      label: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOutBack,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text('$count', key: ValueKey(count)), // key 是触发动画的关键
      ),
      child: child,
    );
  }
}
```

### 8.4 收藏按钮：显式动画

```dart
// lib/widgets/fav_button.dart
import 'package:flutter/material.dart';

class FavButton extends StatefulWidget {
  const FavButton({super.key});

  @override
  State<FavButton> createState() => _FavButtonState();
}

class _FavButtonState extends State<FavButton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(begin: 1, end: 1.35)
        .chain(CurveTween(curve: Curves.easeOutBack))
        .animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    setState(() => _liked = !_liked);
    if (_liked) {
      await _controller.forward();
      await _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      tooltip: '收藏',
      onPressed: _toggle,
      icon: ScaleTransition(
        scale: _scale,
        child: Icon(
          _liked ? Icons.favorite : Icons.favorite_border,
          color: _liked ? scheme.error : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
```

### 8.5 列表页：Hero + 缩略图

```dart
// lib/pages/product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import 'product_detail_page.dart';

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('商品列表')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败：$error')),
        data: (products) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Hero(
                  // tag 的唯一性靠「页面前缀 + 商品 id」，避免多页面撞车
                  tag: 'list-product-${product.id}',
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      product.thumbnail,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  '¥${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(product: product),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

### 8.6 详情页：Hero 大图 + 数字动画 + 收藏动画

```dart
// lib/pages/product_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../state/app_state.dart';
import '../widgets/fav_button.dart';

class ProductDetailPage extends ConsumerWidget {
  const ProductDetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final count = ref.watch(cartProvider)[product.id] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: const [FavButton(), SizedBox(width: 8)],
      ),
      body: ListView(
        children: [
          // 和列表页同一个 tag -> 图片从小图飞到这里
          Hero(
            tag: 'list-product-${product.id}',
            child: Material(
              // ⚠️ 包一层 Material：避免飞行中的文字出现下划线等样式问题
              color: scheme.surfaceContainerLow,
              child: Image.network(
                product.thumbnail,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 260,
                  child: Icon(Icons.image_not_supported, size: 64),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title, style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '¥${product.price.toStringAsFixed(2)}',
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '这是 Day 8 的示例商品说明：主题负责统一视觉，动画负责让状态变化被看见。',
                  style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => ref.read(cartProvider.notifier).add(product.id),
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('加入购物车'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 数量变化时平滑过渡，而不是硬跳
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0, 0.4), end: Offset.zero)
                          .animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    count == 0 ? '还没有加入购物车' : '已加入 $count 件',
                    key: ValueKey(count),
                    style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

### 8.7 我的页：外观设置

```dart
// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/theme_mode.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const ListTile(title: Text('外观'), subtitle: Text('选择主题后会自动记住，重启依然生效')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('浅色'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('深色'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('跟随系统'),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  ref.read(themeModeProvider.notifier).setMode(selection.first),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            title: const Text('当前主题'),
            trailing: Text(switch (mode) {
              ThemeMode.light => '浅色',
              ThemeMode.dark => '深色',
              ThemeMode.system => '跟随系统',
            }),
          ),
        ],
      ),
    );
  }
}
```

运行后验证六件事：

1. 在「我的」里切浅色 / 深色 / 跟随系统 → **整站立刻换肤**：顶栏、卡片、按钮、文字、分割线一起变，没有哪一块「没跟上」。
2. **杀掉 App 重开** → 主题选择还在（`prefs` 生效，和 Day 7 的登录态用的是同一套机制）。
3. 点商品进详情 → 图片从小缩略图**飞**到大图，返回时飞回原位。
4. 点「加入购物车」→ 底部购物车角标数字带缩放动画变化，详情页的「已加入 N 件」也是滑入淡入，而不是瞬间跳变。
5. 点右上角收藏 → 爱心放大再回弹（显式动画），颜色跟随主题（深色下用 `error` 色也够醒目）。
6. 切到深色模式逐页翻一遍：没有白底白字、没有看不见的分割线；把系统「减弱动效」打开后，动画应该缩短或消失（用 `MediaQuery.disableAnimationsOf(context)` 判断即可）。

## 9. 速查表

### 今天出现的 API / 类

| 名称 | 作用 |
| --- | --- |
| `ThemeData` | 一整套设计决策，传给 `MaterialApp.theme` / `darkTheme` |
| `ColorScheme.fromSeed` | 用一颗种子色生成整套配色（含亮 / 暗） |
| `Theme.of(context)` | 取当前主题（颜色、文字、组件样式） |
| `ThemeExtension` | 把 `ColorScheme` 没有的颜色（success / warning）扩进主题 |
| `AppBarThemeData` / `CardThemeData` / `FilledButtonThemeData` / `InputDecorationThemeData` / `DividerThemeData` | 组件主题（**新版统一叫 `XxxThemeData`**） |
| `TextTheme` | 15 个文字层级：display / headline / title / body / label |
| `ThemeMode` | `system` / `light` / `dark` |
| `MaterialApp(theme, darkTheme, themeMode)` | 深色模式三件套 |
| `themeAnimationDuration` | 主题切换的过渡时长（默认 200ms） |
| `withValues(alpha:)` | 半透明颜色（`withOpacity` 已废弃） |
| `AnimatedContainer` / `AnimatedOpacity` / `AnimatedPadding` / `AnimatedAlign` / `AnimatedPositioned` / `AnimatedDefaultTextStyle` | 隐式动画：属性变化自动补间 |
| `AnimatedSwitcher` / `AnimatedCrossFade` | 「换一个孩子」的过渡 |
| `TweenAnimationBuilder` | 数值从 A 到 B 的自定义动画 |
| `AnimationController` | 显式动画的时间轴（0→1） |
| `Tween` / `CurveTween` / `CurvedAnimation` / `TweenSequence` / `Interval` | 值映射、缓动、序列、错开 |
| `AnimatedBuilder` | 用动画值驱动任意 UI（`child:` 做性能优化） |
| `FadeTransition` / `ScaleTransition` / `SlideTransition` / `RotationTransition` / `SizeTransition` | 现成的过渡组件 |
| `Hero` | 两个页面同名元素的共享转场 |
| `HeroMode` | 局部关闭 Hero（多列表同屏时防 tag 冲突） |
| `MediaQuery.disableAnimationsOf(context)` | 系统「减弱动效」设置 |

### 核心写法

| 场景 | 写法 |
| --- | --- |
| 亮 / 暗两套主题 | `AppTheme.light()` / `AppTheme.dark()`，都基于 `ColorScheme.fromSeed(brightness:)` |
| 接上主题 | `MaterialApp(theme:, darkTheme:, themeMode: ref.watch(themeModeProvider))` |
| 记住用户选择 | prefs 存 `'light' / 'dark' / 'system'`，`Notifier.build()` 里读回来 |
| 取颜色 | `Theme.of(context).colorScheme.primary`（**不写 hex**） |
| 取文字样式 | `Theme.of(context).textTheme.titleLarge` |
| 半透明品牌色 | `scheme.primary.withValues(alpha: 0.12)` |
| 属性过渡 | `AnimatedContainer(duration: 300ms, curve: Curves.easeOutCubic, ...)` |
| 数字变化 | `AnimatedSwitcher(child: Text('$n', key: ValueKey(n)))` |
| 数值滚动 | `TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: total), ...)` |
| 显式动画骨架 | `AnimationController(vsync: this, duration:)` + `Tween(...).animate(controller)` + `ScaleTransition` |
| 用动画驱动任意 UI | `AnimatedBuilder(animation: _c, child: const X(), builder: (c, child) => ...)` |
| 收藏心跳 | `await controller.forward(); await controller.reverse();` |
| Hero 转场 | 两页都写 `Hero(tag: 'list-product-$id', child: ...)` |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| 主题解决什么？ | 把「设计决策」从 50 个页面里收敛到一个地方；改一处、全站生效，深色模式还能白送 |
| 动画的本质是什么？ | 一个 `Animation` 每帧给出新值 → 用它算样式 → Widget 重建；隐式动画只是框架替你写好了脚手架 |
| 什么时候用 Hero？ | 两个页面存在「同一个东西」（列表图 → 详情图、头像 → 大图）时，让用户知道「点的是它、打开的还是它」 |

### 十个高频坑

1. **页面里写死颜色**（`Colors.white` / `Color(0xFF...)`）：深色模式必然翻车 → 一律走 `colorScheme`。
2. **组件主题用了旧类名**：`CardTheme(...)` 现在已经不是数据类了 → 改成 `CardThemeData(...)`（AppBar 同理）。
3. **`AnimatedSwitcher` 忘了给 child 加 key**：数字变了却没有动画 → `key: ValueKey(count)`。
4. **每次都塞 `UniqueKey()`**：每次重建都触发切换动画，出现莫名闪烁 → 用「真正会变的值」当 key。
5. **显式动画忘了 `dispose()`**：页面退出后控制器还在跑，报资源泄漏 → `_controller.dispose()` 写在 `dispose` 第一行。
6. **动画里 `setState` 整个页面**：每帧重建巨大子树，掉帧 → 用 `AnimatedBuilder` 缩小重建范围，`child:` 装静态部分。
7. **Hero tag 重复**：同屏出现两个相同 tag 直接抛异常 → tag 加页面前缀、用 `id`；必要时用 `HeroMode(enabled: false)`。
8. **Hero 飞行中文字出现下划线**：脱离了 `Material` 祖先 → 给 Hero 的孩子包一层透明 `Material`。
9. **过渡时长太长**：>500ms 的页面内动效会让 App 显得「迟钝」 → 常用 200–300ms。
10. **`withOpacity` 已废弃**：新版里用 `color.withValues(alpha: 0.12)`。

## 10. 今日自检

完成下面四件事，Day 8 才算通过：

- [ ] 抽出 `AppTheme`（亮 / 暗各一套），让按钮、卡片、输入框、分割线全站统一
- [ ] 做「浅色 / 深色 / 跟随系统」切换，并且重启 App 后选择还在
- [ ] 加购数字用 `AnimatedSwitcher` 做变化动画（角标 + 详情页各一处）
- [ ] 商品图列表 → 详情加 `Hero` 转场，返回时也能飞回去

如果你能回答下面三个问题，就可以进入 Day 9（工程化与打包）：

1. `ThemeData` 主要配置哪些东西？
2. 隐式动画和显式动画怎么选？
3. `Hero` 需要满足什么条件才有效？

答案提示：

1. 按重要性排：① `colorScheme`——所有颜色的来源（用 `ColorScheme.fromSeed` 生成，亮暗两套各一份）；② `textTheme`——文字层级（字号、字重、行高），页面里只取用不写死；③ 组件主题——`appBarTheme` / `cardTheme` / `filledButtonTheme` / `inputDecorationTheme` / `dividerTheme` 等，把「同类组件长什么样」一次配好；④ 零散但常改的：`scaffoldBackgroundColor`、`visualDensity`、`pageTransitionsTheme`。判断标准很简单：**凡是「产品改一次、全站都要跟着改」的东西，就属于 ThemeData**。
2. 先问自己两个问题：**我要控制的只是「A 到 B 两个状态」吗？我需要暂停 / 反向 / 循环 / 播完回调吗？** 只要前者成立、后者不成立，就用隐式动画（`AnimatedContainer`、`AnimatedSwitcher`、`TweenAnimationBuilder`），代码最少、自动管资源；如果需要控制播放过程、要一个动画值驱动多处、要做序列或物理动画，才上 `AnimationController` 那套显式动画。经验值是：项目里 80% 的动效都该是隐式的。
3. 三个必要条件：① 两个页面（push 前和 push 后）**各有**一个 `Hero`；② 两边的 `tag` **完全相同**，而且同一个页面内的 tag **必须唯一**（重复会直接抛异常）；③ 转场是通过**同一个 Navigator 的 push / pop** 触发的。除此之外还有两条「体验条件」：两边孩子的结构尽量一致（都是 Image + 相同 `fit` / 圆角），否则飞行中会「换脸」或形状突变；飞行中若出现文字下划线，给它包一层透明 `Material` 即可。
