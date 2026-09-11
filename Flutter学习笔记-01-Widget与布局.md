# Flutter 学习笔记 01：项目、Widget 与 setState

> 适用前提：已经学完 Dart 基础，准备正式开始 Flutter。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 1。
> 本笔记的目标：把「一切皆 Widget」和「UI = f(state)」这两条主线写透。

## 目录

- [1. 从 Vue 到 Flutter：先建立正确的直觉](#1-从-vue-到-flutter先建立正确的直觉)
- [2. 创建一个 Flutter 项目](#2-创建一个-flutter-项目)
- [3. 项目目录里每个文件是干什么的](#3-项目目录里每个文件是干什么的)
- [4. main.dart 的最小结构](#4-maindart-的最小结构)
- [5. Widget：所有界面元素都是对象](#5-widget所有界面元素都是对象)
- [6. StatelessWidget：没有内部状态的 Widget](#6-statelesswidget没有内部状态的-widget)
- [7. StatefulWidget：有内部状态的 Widget](#7-statefulwidget有内部状态的-widget)
- [8. setState：为什么改变量界面不变](#8-setstate为什么改变量界面不变)
- [9. 热重载 r 与热重启 R](#9-热重载-r-与热重启-r)
- [10. 今日最小项目：一个收藏卡片](#10-今日最小项目一个收藏卡片)
- [11. 速查表](#11-速查表)
- [12. 今日自检](#12-今日自检)

## 1. 从 Vue 到 Flutter：先建立正确的直觉

你之前写 uniapp/Vue，心智模型是：

> 写模板 → 绑定数据 → 框架监听数据变化 → 自动更新 DOM。

Flutter 里没有模板、没有 DOM、没有 CSS。界面直接用 Dart 代码写成一棵 Widget 树：

```dart
Text('Hello')       // 一个文本
Container(...)       // 一个盒子
Column(children: [...]) // 一列
```

你写的是一个又一个 `Widget` 对象，Flutter 负责把这些对象画成像素。所以 Vue 里的“组件”在 Flutter 里就是“Widget”，但它的构建方式不是模板，而是重写 `build` 方法返回一个 Widget 树。

Flutter 最重要的心智模型是一句话：

> **UI = f(state)，界面永远是状态的函数。**

Vue 是“改数据，框架自动更新视图”；Flutter 是“改数据，然后**显式触发重建**”。Day 1 要理解的就是这条链路。

## 2. 创建一个 Flutter 项目

先进入你的工作目录，然后执行：

```bash
flutter create shopping_demo
cd shopping_demo
flutter run
```

参数说明：

| 命令 | 作用 |
| --- | --- |
| `flutter create shopping_demo` | 生成一个标准 Flutter 项目 |
| `cd shopping_demo` | 进入项目 |
| `flutter run` | 编译并在已连接的设备上运行 |
| `flutter run -d chrome` | 指定在 Chrome 运行（桌面端快速预览） |
| `flutter run -d <device-id>` | 指定真机或模拟器 |

`flutter create` 默认会生成 Android、iOS、Web、Windows、macOS、Linux 等多平台目录。如果只想生成 Android/iOS，可以用：

```bash
flutter create --platforms android,ios shopping_demo
```

但作为学习阶段，用默认全平台更方便，能随时在 Chrome 里快速预览。

## 3. 项目目录里每个文件是干什么的

创建后主要关注这些：

| 路径 | 作用 |
| --- | --- |
| `lib/main.dart` | App 入口，所有业务代码从这开始 |
| `pubspec.yaml` | 依赖清单、资源声明、版本信息 |
| `android/` | Android 原生工程，打包和权限在这 |
| `ios/` | iOS 原生工程 |
| `web/` | Web 平台入口 |
| `test/` | 测试文件 |
| `analysis_options.yaml` | Dart 静态检查规则 |

初学阶段 90% 的时间只在 `lib/` 和 `pubspec.yaml` 里活动，其余目录先不用管。

## 4. main.dart 的最小结构

Flutter 默认生成的 `main.dart` 里，最重要的是下面这段骨架：

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('我的第一个 App')),
        body: const Center(child: Text('Hello Flutter')),
      ),
    );
  }
}
```

几个关键点：

- `runApp` 是真正的入口，把根 Widget 挂到屏幕。
- `MaterialApp` 提供路由、主题、导航等全局能力。
- `Scaffold` 是 Material 页面骨架，提供 `appBar`、`body` 等区域。
- `Center` 是居中容器，`Text` 是文本 Widget。

你的所有页面，最终都从 `runApp` 挂载的这一棵树开始。

## 5. Widget：所有界面元素都是对象

Flutter 的 Widget 和 Vue 组件最大的不同：**Widget 是不可变的配置**。

```dart
const Text('Hello')
```

这个 `Text` 对象一旦创建，内容就不会变。当你需要更新界面时，Flutter 不是“改这个 Text 的内容”，而是**重新构建一棵新的 Widget 树**，然后和旧树做 diff，只重绘变化的部分。

这就是为什么 `build` 方法会被反复调用。也正因如此，`build` 方法要尽量写纯函数：同样的输入，产出同样的 UI。

## 6. StatelessWidget：没有内部状态的 Widget

如果一个 Widget 只展示数据、自己不需要“记住”任何会变的东西，就用 `StatelessWidget`：

```dart
class Greeting extends StatelessWidget {
  const Greeting({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text('Hello, $name');
  }
}

// 使用
const Greeting(name: 'Flutter')
```

它的特点：

- 数据从外部通过构造函数传入
- 数据不变，Widget 通常也不需要重建
- 适合纯展示型组件

对应你的前端经验：`StatelessWidget` 就像一个没有内部 `state` 的 Vue 函数式组件。

## 7. StatefulWidget：有内部状态的 Widget

如果一个 Widget 需要记住用户交互产生的变化，比如「点击次数」「是否收藏」，就要用 `StatefulWidget`：

```dart
class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  void _increment() {
    setState(() {
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('当前次数：$count'),
        ElevatedButton(
          onPressed: _increment,
          child: const Text('点我 +1'),
        ),
      ],
    );
  }
}
```

`StatefulWidget` 由两部分组成：

- `Counter`：不可变的外壳，负责创建 State。
- `_CounterState`：可变的状态，保存 `count` 并负责重建 UI。

你以后看到“Widget 和 State 分离”的结构，都是这个模式。

## 8. setState：为什么改变量界面不变

这是从 Vue 转 Flutter 时最容易踩的第一个坑：

```dart
void _increment() {
  count++; // 只改变量
}
```

上面代码**不会**让界面更新。原因是 Flutter 不会自动监听变量变化，它只会在你调用 `setState` 后，重新执行 `build`，用新的状态画出一棵新树。

正确写法是：

```dart
void _increment() {
  setState(() {
    count++;
  });
}
```

`setState` 做三件事：

1. 标记这个 State 需要重建。
2. 重新调用 `build` 方法。
3. Flutter 用新的 Widget 树更新界面。

所以“改了变量界面不变”的答案就是：**状态变了，但没有调用 `setState` 触发重建。**

## 9. 热重载 r 与热重启 R

在 `flutter run` 的终端里，可以：

| 快捷键 | 名称 | 作用 | 会丢失什么 |
| --- | --- | --- | --- |
| `r` | Hot reload | 快速刷新代码和 UI | 不重置 State |
| `R` | Hot restart | 重新启动 App | 重置 State |
| `q` | Quit | 退出运行 | — |

记忆方法：

- 改了 UI 或方法逻辑，用 `r`。
- 改了 `main`、`initState` 或怀疑状态异常，用 `R`。
- 界面更新后想保留当前页面状态，用 `r`；想回到干净状态，用 `R`。

热重载不会重新执行 `main`，所以有些全局初始化改动必须热重启才能生效。

## 10. 今日最小项目：一个收藏卡片

把下面的完整代码放进 `lib/main.dart`，运行后你会得到一个「可收藏 / 取消收藏」的卡片。它同时覆盖 `StatelessWidget`、`StatefulWidget` 和 `setState`。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Day 1',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isFavorite = false;

  void _toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day 1 收藏卡片')),
      body: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 48,
                  color: isFavorite ? Colors.red : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(isFavorite ? '已收藏' : '未收藏'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _toggleFavorite,
                  child: Text(isFavorite ? '取消收藏' : '收藏'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

你要做的三件事：

1. 把代码贴进 `lib/main.dart`，用 `flutter run` 运行。
2. 点击按钮，观察图标、文字、按钮文案是否一起变化。
3. 在终端按 `r` 和 `R`，感受热重载和热重启的区别。

## 11. 速查表

### 今天出现的 Widget

| Widget | 作用 |
| --- | --- |
| `MaterialApp` | App 根节点，提供主题、路由等 |
| `Scaffold` | 页面骨架：`appBar`、`body` 等 |
| `AppBar` | 顶部导航栏 |
| `Text` | 文本 |
| `Column` | 垂直排列 |
| `Row` | 水平排列 |
| `Center` | 居中 |
| `Padding` | 内边距 |
| `SizedBox` | 固定间距或尺寸 |
| `Icon` | 图标 |
| `Card` | Material 卡片 |
| `ElevatedButton` / `FilledButton` | 按钮 |

### 核心语法

| 写法 | 作用 |
| --- | --- |
| `runApp(Widget)` | 启动 App |
| `class X extends StatelessWidget` | 无状态组件 |
| `class X extends StatefulWidget` | 有状态组件 |
| `createState()` | 创建状态对象 |
| `setState(() { ... })` | 修改状态并触发重建 |
| `Widget build(BuildContext context)` | 构建界面 |

### 今天的两个心智模型

| 问题 | 答案 |
| --- | --- |
| 为什么界面不更新？ | 没有调用 `setState` |
| 为什么 `build` 会反复执行？ | Widget 是不可变配置，更新靠重建整棵树再 diff |

## 12. 今日自检

完成下面三件事，Day 1 才算通过：

- [x] 能新建项目并用 `flutter run` 跑起来
- [x] 能解释 `StatelessWidget` 和 `StatefulWidget` 的选择依据
- [x] 能写出「点按钮 → `setState` → 界面变化」的最小 demo

如果你能回答下面三个问题，就可以进入 Day 2：

1. `setState` 里不写任何代码，界面会重建吗？
2. `StatelessWidget` 真的完全不能改变内容吗？
3. 热重载和热重启各自会保留或丢失什么？

答案提示：`setState` 即使空调用也会重建；`StatelessWidget` 的内容只能靠父级传新的参数来变；热重载保留 State，热重启会重置 State。
