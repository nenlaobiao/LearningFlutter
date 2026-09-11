# Flutter 学习笔记 02：布局体系

> 适用前提：已经完成 Day 1（项目、Widget 与 setState）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 2。
> 本笔记的目标：把「Flutter 没有 CSS，布局靠约束和 Widget 嵌套」写透，并建立一套 **CSS → Flutter 的换算直觉**。

## 目录

- [1. 先建立直觉：Flutter 布局不是 CSS](#1-先建立直觉flutter-布局不是-css)
- [2. 核心心智模型：约束向下、尺寸向上](#2-核心心智模型约束向下尺寸向上)
- [3. Row 与 Column：主轴与交叉轴](#3-row-与-column主轴与交叉轴)
- [4. 处理溢出：Expanded、Flexible、Spacer](#4-处理溢出expandedflexiblespacer)
- [5. 盒模型：Container、SizedBox、Padding、Center、Align](#5-盒模型containersizedboxpaddingcenteralign)
- [6. Stack 与 Positioned：层叠与定位](#6-stack-与-positioned层叠与定位)
- [7. CSS 与 Flutter 的布局换算表](#7-css-与-flutter-的布局换算表)
- [8. 常见坑：谁撑满、谁收缩](#8-常见坑谁撑满谁收缩)
- [9. 今日最小项目：商城首页静态布局](#9-今日最小项目商城首页静态布局)
- [10. 速查表](#10-速查表)
- [11. 今日自检](#11-今日自检)

## 1. 先建立直觉：Flutter 布局不是 CSS

你写 Vue / uniapp 时，布局靠 CSS：

```css
.card {
  display: flex;
  justify-content: space-between;
  padding: 16px;
  position: relative;
}
.badge {
  position: absolute;
  top: 8px;
  right: 8px;
}
```

Flutter 里**没有 CSS、没有 class、没有 `display: flex`**。布局是「用 Widget 嵌套 Widget」拼出来的。同一个卡片在 Flutter 里长这样：

```dart
Container(
  padding: const EdgeInsets.all(16),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text('标题'), Text('价格')],
  ),
)
```

区别不是「语法变了」，而是**布局的思考方式变了**：

| 维度 | CSS | Flutter |
| --- | --- | --- |
| 样式从哪来 | class + 样式表 | Widget 构造函数的参数 |
| 怎么控制排列 | `display: flex` + 方向 | 选 `Row` 还是 `Column` |
| 怎么控制对齐 | `justify-content` / `align-items` | `MainAxisAlignment` / `CrossAxisAlignment` |
| 怎么设内边距 | `padding` 属性 | `Padding` Widget 或 `Container` 的 `padding` |
| 怎么设外边距 | `margin` 属性 | `Container` 的 `margin` |
| 怎么绝对定位 | `position: absolute` | `Stack` + `Positioned` |
| 怎么居中 | `margin: auto` / flex | `Center` / `Align` |
| 文本怎么截断 | `text-overflow: ellipsis` | `Text(overflow: TextOverflow.ellipsis, maxLines: 1)` |

> 一句话记住：**在 Flutter 里，布局不是「给元素写样式」，而是「选对容器，把它们套起来」。**

## 2. 核心心智模型：约束向下、尺寸向上

Flutter 布局最重要的心法，就八个字：

> **约束向下传，尺寸向上报。**

一个 Widget 是怎么确定自己大小的？整个过程是一次「父与子的对话」：

1. **父组件给子组件下约束**：告诉它「你最大能到多大、最小不能小于多少」（即 `min` / `max` 的宽高范围）。
2. **子组件在自己「认为合适」的范围里选一个尺寸**：比如文本按内容宽度，`SizedBox` 按给定尺寸。
3. **子组件把实际尺寸汇报给父组件**。
4. **父组件再据此安排自己在屏幕上的位置**。

用一个直观的比喻：

> 家长（父 Widget）对孩子（子 Widget）说：「这间房你最小 100、最大 300 宽。」孩子量了量自己（content），报回「我要 200 宽」。家长再决定把它放房间的哪个位置。

### 约束里最常出现的两种“无界限”

| 情况 | 含义 | 典型场景 |
| --- | --- | --- |
| **宽度无界** | `maxWidth` 是无限 | 一个 `Row` 竖着放进不限制宽度的父级，或列表横着滚 |
| **高度无界** | `maxHeight` 是无限 | 一个 `Column` 放进 `SingleChildScrollView`，高度随内容撑开 |

判断“会不会溢出”和“谁撑满谁收缩”，答案几乎都在约束里：

- **主轴无界 + 子内容超宽** → 溢出报错。
- **交叉轴无界** → 子组件无法靠 `Expanded` 占满，因为压根没有“剩余空间”可分配。
- **父级给的是紧约束（min == max）** → 子组件**必须**填满这个尺寸，自己给的大小可能被忽略。

> 排查口诀：**报错先看约束**。看到 “RenderFlex overflowed” 时，马上想“谁在主轴方向给了一个放不下的内容”。

## 3. Row 与 Column：主轴与交叉轴

`Row` 水平排列子组件，`Column` 垂直排列子组件。它们共同点：都有一条**主轴**（排列方向）和一条**交叉轴**（垂直于主轴）。

| Widget | 主轴方向 | 交叉轴方向 |
| --- | --- | --- |
| `Row` | 水平（→） | 垂直（↓） |
| `Column` | 垂直（↓） | 水平（→） |

### 主轴排列：MainAxisAlignment

`mainAxisAlignment` 控制子组件在**主轴**上怎么排：

| 取值 | 效果 |
| --- | --- |
| `MainAxisAlignment.start` | 靠主轴起点（默认） |
| `MainAxisAlignment.end` | 靠主轴终点 |
| `MainAxisAlignment.center` | 居中 |
| `MainAxisAlignment.spaceBetween` | 两端贴边，中间等距 |
| `MainAxisAlignment.spaceAround` | 每个间隔等距，两端留一半间隔 |
| `MainAxisAlignment.spaceEvenly` | 所有间隔（含两端）完全等距 |

对应 CSS：

| CSS | Flutter |
| --- | --- |
| `justify-content: flex-start` | `start` |
| `justify-content: flex-end` | `end` |
| `justify-content: center` | `center` |
| `justify-content: space-between` | `spaceBetween` |
| `justify-content: space-around` | `spaceAround` |
| `justify-content: space-evenly` | `spaceEvenly` |

### 交叉轴对齐：CrossAxisAlignment

`crossAxisAlignment` 控制子组件在**交叉轴**上怎么站：

| 取值 | 效果 |
| --- | --- |
| `CrossAxisAlignment.center` | 居中（默认） |
| `CrossAxisAlignment.start` | 靠交叉轴起点 |
| `CrossAxisAlignment.end` | 靠交叉轴终点 |
| `CrossAxisAlignment.stretch` | 拉伸，占满整条交叉轴 |
| `CrossAxisAlignment.baseline` | 按文字基线对齐（需配合 `textBaseline`） |

对应 CSS：

| CSS | Flutter |
| --- | --- |
| `align-items: center` | `center` |
| `align-items: flex-start` | `start` |
| `align-items: flex-end` | `end` |
| `align-items: stretch` | `stretch` |

### mainAxisSize：主轴是撑满还是收缩

`mainAxisSize` 决定 Row / Column **自身**在主轴方向的大小：

| 取值 | 效果 |
| --- | --- |
| `MainAxisSize.max` | 主轴方向占满父级允许的最大空间（默认） |
| `MainAxisSize.min` | 主轴方向收缩，只占子组件所需 |

举一个常见用法：一个只包含少量内容的 `Column`，默认会占满父容器高度。如果你只想让它“包裹内容”并居中，就设 `mainAxisSize: MainAxisSize.min`：

```dart
Center(
  child: Column(
    mainAxisSize: MainAxisSize.min, // 不再占满整屏高度
    children: const [Text('标题'), Text('副标题')],
  ),
)
```

> 对应你的前端经验：`mainAxisSize: min` 就像 flex 容器里的 `width: fit-content` / `align-self: center` 那层“我不撑满，只包内容”的直觉。

## 4. 处理溢出：Expanded、Flexible、Spacer

这是 Day 2 最容易踩的坑：`Row` / `Column` 里放了超宽内容 → 黄黑条纹溢出。

```dart
// 会溢出：标题文本太长时，Row 放不下
Row(
  children: const [Text('这是一个非常长的商品标题'), Text('¥199')],
)
```

办法有三层，从“刚性分配”到“弹性让步”。

### 方案 1：Expanded —— 按比例拿走剩余空间

`Expanded` 会把它在**主轴**上的剩余空间按 `flex` 比例分给子组件，子组件必须**吃掉**这部分空间。

```dart
Row(
  children: const [
    Expanded(child: Text('这是一个非常长的商品标题')),
    SizedBox(width: 8),
    Text('¥199'),
  ],
)
```

这里 `Expanded` 分到了“除价格外”的全部剩余宽度，标题无论多长都不会把价格挤出去。配合 `maxLines` 和 `overflow` 就能优雅截断：

```dart
Expanded(
  child: Text(
    '这是一个非常长的商品标题',
    maxLines: 1,
    overflow: TextOverflow.ellipsis, // 超出部分显示 …
  ),
)
```

多个 `Expanded` 会按 `flex` 分配剩余空间：

```dart
Row(
  children: const [
    Expanded(flex: 2, child: BoxA()), // 占 2 份
    Expanded(flex: 1, child: BoxB()), // 占 1 份
  ],
)
```

> `flex` 对应的就是 CSS 里的 `flex: <n>`（按比例伸缩）。`Expanded` 的 `flex` 默认是 1。

### 方案 2：Flexible —— 允许子组件“不占满，按需缩放”

`Flexible` 和 `Expanded` 很像，区别在于 `Expanded` 是**强制占满**，`Flexible` 是**尽力而为**。当子组件自身不需要那么多空间时，`Flexible` 会让它保持原始大小。

```dart
Row(
  children: const [
    Flexible(child: Text('既不会撑爆，也不会被硬撑大')),
    SizedBox(width: 8),
    Text('¥199'),
  ],
)
```

两者还有一个 `fit` 参数：

| 参数 | 效果 |
| --- | --- |
| `FlexFit.tight` | 强制占满（即 `Expanded` 的行为） |
| `FlexFit.loose` | 允许子组件保留自身尺寸（`Flexible` 默认） |

一句话区分：

> **`Expanded` = `Flexible(fit: FlexFit.tight)`。** 需要“它必须吃下这块空间”用 `Expanded`；需要“它挤一点也行，但别硬撑”用 `Flexible`。

### 方案 3：Spacer —— 一个没有内容的占位

`Spacer` 本质就是 `Expanded(child: SizedBox())`，专门用来在 `Row` / `Column` 里“顶开两边的元素”。

```dart
Row(
  children: [
    Text('左'),
    const Spacer(), // 把左右两边的元素推向两端
    Text('右'),
  ],
)
```

它等价于 `Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)`，适合做“左右贴边”的布局。

## 5. 盒模型：Container、SizedBox、Padding、Center、Align

CSS 里一个 `<div>` 同时管尺寸、内边距、外边距、背景、边框。Flutter 把这些**拆成一个套一个的 Widget**，各管一件事：

| Widget | 对应 CSS | 管什么 |
| --- | --- | --- |
| `Container` | `<div>` + `background` + `border` | 背景、边框、圆角、阴影、padding、margin、尺寸 |
| `SizedBox` | `width` / `height` / `gap` | 固定尺寸，或做间隔 |
| `Padding` | `padding` | 内边距 |
| `Center` | flex 居中 | 让子组件居中，并尽量撑满父级 |
| `Align` | `align-items` / `position` | 按 9 宫格方向对齐子组件 |
| `ConstrainedBox` | `max-width` | 限制约束范围 |

### Container

`Container` 是最“像 div”的 Widget，但千万别把它当成万能 div。它的尺寸规则是**有顺序的**：

1. 给了 `width` / `height` → 用这个尺寸。
2. 有 `child` 且没给尺寸 → 尺寸 = 子组件 + `padding` + `margin`。
3. 没有 `child` 也没给尺寸 → 在约束允许下**尽量撑满**。
4. 设了 `alignment` → 会根据对齐方式决定布局。

```dart
Container(
  padding: const EdgeInsets.all(16),
  margin: const EdgeInsets.symmetric(vertical: 8),
  width: 200,
  decoration: BoxDecoration(
    color: Colors.orange,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Colors.black26, blurRadius: 8),
    ],
  ),
  child: const Text('商品卡片'),
)
```

> `decoration` 对应 CSS 的 `background` 和 `border-radius`；`color` 是 `decoration` 里的一个快捷写法。`Container` 同时写了 `color` 和 `decoration` 会报错，因为 `color` 本质就是 `decoration` 的简写。

### SizedBox

如果你只是想要一个**固定尺寸或间距**，用 `SizedBox`，别用 `Container`。

```dart
const SizedBox(width: 16)        // 水平间隔
const SizedBox(height: 16)       // 垂直间隔
SizedBox(width: 100, height: 100) // 固定盒子
SizedBox.expand()                 // 撑满父级，等价于宽高都取约束上限
```

`SizedBox(width: double.infinity)` 也是让子组件“撑满宽度”的常用写法。

### Padding

只负责加内边距：

```dart
// 三种常见写法，任选其一
Padding(
  padding: const EdgeInsets.all(16),
  child: const Text('四边等距'),
)

Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: const Text('横向 16，纵向 8'),
)

Padding(
  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
  child: const Text('上右下左'),
)
```

> CSS 的 `padding: 16px` → `EdgeInsets.all(16)`；
> `padding: 16px 8px` → `EdgeInsets.symmetric(horizontal: 16, vertical: 8)`；
> `padding: 16px 8px 16px 8px` → `EdgeInsets.fromLTRB(16, 8, 16, 8)`。

### Center 与 Align

`Center` 就是 `Align(alignment: Alignment.center)` 的简写。

```dart
Center(child: Text('水平 + 垂直居中'))
Align(
  alignment: Alignment.topRight, // 右上角
  child: Text('右上角'),
)
Align(
  alignment: Alignment(0.5, 0.2), // 精确坐标：x、y 取值 -1 ~ 1
  child: Text('自定义位置'),
)
```

`Center` / `Align` 通常会在父级允许的情况下**撑满父级**（因为默认 `widthFactor` / `heightFactor` 为 null，会取约束最大值），然后把子组件放到指定位置。

> 对应 CSS：`Center` ≈ flex 容器的 `justify-content: center; align-items: center`；`Align` ≈ `position` + `translate`。

## 6. Stack 与 Positioned：层叠与定位

`Stack` 对应 CSS 的 `position: relative` 容器，`Positioned` 对应 `position: absolute`。子组件默认按叠加顺序从下往上铺开。

```dart
Stack(
  children: [
    Container(width: 200, height: 200, color: Colors.blue), // 底层
    Positioned(
      top: 8,
      right: 8,       // 相对 Stack 右上方
      child: Container( // 顶层：商品角标
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text('热卖', style: TextStyle(color: Colors.white)),
      ),
    ),
  ],
)
```

关键点：

| 东西 | 作用 |
| --- | --- |
| `Stack` | 层叠容器，后写的子组件在更上层 |
| `Positioned` | 定位子组件：`top` / `bottom` / `left` / `right` / `width` / `height` |
| `StackFit.expand` | 让非 `Positioned` 的子组件撑满整个 `Stack` |
| `Alignment` | `Stack(alignment: Alignment.center)` 控制默认对齐 |

> 对应 CSS：`Stack` = `position: relative`，`Positioned` = `position: absolute`，`z-index` 由 `Stack` 里子组件的书写顺序决定（越靠后越在上层）。

## 7. CSS 与 Flutter 的布局换算表

这是 Day 2 最值得反复对照的一张表。以后从 Vue / uniapp 切过来，遇到想不起来的布局就查它。

| CSS / uniapp 习惯 | Flutter 写法 |
| --- | --- |
| `display: flex; flex-direction: row` | `Row` |
| `display: flex; flex-direction: column` | `Column` |
| `justify-content` | `mainAxisAlignment` |
| `align-items` | `crossAxisAlignment` |
| `flex: 1` / `flex-grow` | `Expanded(flex: 1)` |
| `flex-shrink` / 弹性 | `Flexible` |
| `flex: n` 按比例 | `Expanded(flex: n)` |
| `margin` | `Container(margin: EdgeInsets...)` |
| `padding` | `Padding` 或 `Container(padding: ...)` |
| `width` / `height` | `SizedBox(width: …, height: …)` |
| `width: 100%` | `SizedBox(width: double.infinity)` |
| `max-width` | `ConstrainedBox(constraints: BoxConstraints(maxWidth: …))` |
| 盒子边距 + 间隙 | `SizedBox(width: 16)` / `SizedBox(height: 16)` |
| 水平 + 垂直居中 | `Center` |
| 指定方向对齐 | `Align(alignment: Alignment…)` |
| `position: absolute` | `Stack` + `Positioned` |
| `z-index` | `Stack` 里子组件书写顺序（越靠后越上） |
| `border-radius` / `box-shadow` | `BoxDecoration` |
| `text-overflow: ellipsis` | `Text(maxLines: 1, overflow: TextOverflow.ellipsis)` |
| `<br>` 换行 | `Column` + `const SizedBox(height: 8)` 不用 `\n` |

> 隐藏优势：你有 Vue 的组件拆分直觉 + React 的“用代码描述 UI”直觉，这两点会让你对 `build` 方法里的 Widget 树非常亲切。Day 2 只需要把“样式”从 CSS 语法迁移到“参数 + 嵌套”即可。

## 8. 常见坑：谁撑满、谁收缩

这是自检里一定会考的两类问题。

### 问题 A：为什么这个 Container 撑满了，那个却收缩了？

| Container 写法 | 尺寸行为 |
| --- | --- |
| `Container(color: ...)`（无 child、无尺寸、父级约束有界） | **撑满**父级 |
| `Container(color: ..., child: Text(...))` | **收缩**，包裹文本 |
| `Container(width: 100, child: ...)` | 固定宽 100 |
| `Container(color: ..., alignment: Alignment.center)` | 撑满父级（配合 align） |
| `SizedBox(width: 100, height: 100)` | 固定尺寸 |
| `SizedBox.expand()` | 撑满父级 |

一句话记忆：

> **有 child → 收缩包内容；没 child 也没尺寸 → 撑满；给了 width/height → 固定；在 Expanded 里 → 必须填满。**

### 问题 B：Row 里放超宽内容会怎样？怎么解决？

会**溢出**，屏幕出现黄黑条纹（debug 模式下），并伴随 `RenderFlex overflowed` 报错。

解决顺序：

1. 给放不下的那头包一层 `Expanded`（或 `Flexible`），让它在主轴剩余空间里分配。
2. 配合 `Text(maxLines: 1, overflow: TextOverflow.ellipsis)` 截断文本。
3. 如果整行实在太多元素，考虑换成 `Wrap`（自动换行）而不是 `Row`。
4. 检查是不是父级把宽度设成了无限（比如放进一个横向滚动的容器里）。

### 问题 C：为什么会报 “unbounded constraints” / 无限高度？

通常是你把 `Expanded` / `Flexible` 用在了主轴无界的地方。比如：

```dart
// 错：SingleChildScrollView 让高度无界，Column 里再放 Expanded 不知道“剩余空间”是多少
SingleChildScrollView(
  child: Column(
    children: [Expanded(child: ...)], // 报错
  ),
)
```

> 直觉：**“剩余空间”要有“总量”才有意义。** 一旦父级在某个方向是无限（滚动容器），那个方向就不能再用 `Expanded` 去“分剩余空间”了。

## 9. 今日最小项目：商城首页静态布局

把下面的完整代码放进 `lib/main.dart`，运行后你会得到一个「顶部标题栏 + 分类导航 + 商品网格」的静态首页。它一次性用上了 `Row` / `Column` / `Stack` / `Expanded` / `Container` / `Padding` / `Align` / `GridView`。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const ShoppingApp());
}

class ShoppingApp extends StatelessWidget {
  const ShoppingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '商城首页',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商城首页'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 顶部分类导航：Row + spaceAround
          const CategoryBar(),
          // 商品网格：Expanded 撑满剩余高度，GridView 自身可滚动
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: EdgeInsets.all(12),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: const [
                ProductCard(title: '无线蓝牙耳机', price: 199, color: Colors.blue),
                ProductCard(title: '机械键盘', price: 459, color: Colors.green),
                ProductCard(title: '智能手表', price: 899, color: Colors.orange),
                ProductCard(title: '便携充电宝', price: 129, color: Colors.purple),
                ProductCard(title: '降噪头戴耳机', price: 1299, color: Colors.teal),
                ProductCard(title: '4K 显示器', price: 1999, color: Colors.indigo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryBar extends StatelessWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: Colors.white,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('推荐'),
          Text('手机'),
          Text('电脑'),
          Text('家电'),
          Text('更多'),
        ],
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.color,
  });

  final String title;
  final int price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 商品图区域：Expanded 撑满卡片上方剩余空间 + Stack 叠角标
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: color),
                const Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        '热卖',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 标题 + 价格：Row + Expanded + ellipsis 处理超长标题
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '¥$price',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
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

运行后你要做的四件事（对应 Day 2 的动手清单）：

1. 把「分类导航」改成一个类目的 `Row`，试着用 `mainAxisAlignment: spaceBetween` / `spaceAround` / `spaceEvenly`，观察三种排列的差异。
2. 把一个商品标题改成超长文本（比如 50 个字），确认它被 `Expanded + ellipsis` 优雅截断，**价格不会被挤出去**。再把 `Expanded` 去掉，观察黄黑条纹溢出。
3. 把「热卖」角标从 `Positioned` 挪到 `Stack` 的普通子组件里，观察它变成“参与布局”而不是“绝对定位”。
4. 把 `Grid` 改成 `Row` + 两个 `Expanded` 的简易双列，体会 `Expanded` 如何分配剩余空间。

## 10. 速查表

### 今天出现的 Widget

| Widget | 作用 |
| --- | --- |
| `Row` / `Column` | 水平 / 垂直排列 |
| `Expanded` | 主轴按 `flex` 分配剩余空间（强制占满） |
| `Flexible` | 主轴按 `flex` 分配剩余空间（允许收缩） |
| `Spacer` | 空白的 `Expanded`，用于撑开间距 |
| `Container` | 尺寸 + padding + margin + 背景 + 边框 + 阴影 |
| `SizedBox` | 固定尺寸 / 间距 / `SizedBox.expand()` 撑满 |
| `Padding` | 内边距 |
| `Center` | 居中（`Align` 的简写） |
| `Align` | 按方向 / 精确坐标对齐 |
| `Stack` + `Positioned` | 层叠 + 绝对定位 |
| `ConstrainedBox` | 限制约束范围（类似 max-width） |
| `GridView` | 网格布局（今天顺带认识） |

### 核心属性

| 属性 | 用在 | 作用 |
| --- | --- | --- |
| `mainAxisAlignment` | Row / Column | 主轴排列 |
| `crossAxisAlignment` | Row / Column | 交叉轴对齐 |
| `mainAxisSize` | Row / Column | 主轴撑满（max）还是收缩（min） |
| `flex` | Expanded / Flexible | 剩余空间分配比例 |
| `EdgeInsets` | Padding / Container | 内/外边距，`all` / `symmetric` / `fromLTRB` |
| `StackFit.expand` | Stack | 让子组件撑满 Stack |
| `TextOverflow.ellipsis` | Text | 超出部分用 … 截断 |

### 今天的两个心智模型

| 问题 | 答案 |
| --- | --- |
| Flutter 怎么决定布局？ | 约束向下传、尺寸向上报 |
| 为什么 Box 会撑满或收缩？ | 有 child 收缩、没 child 也没尺寸就撑满、Expanded 里必须填满 |

## 11. 今日自检

完成下面三件事，Day 2 才算通过：

- [ ] 能用 `Row` / `Column` / `Stack` / `Expanded` / `Container` 拼出商城首页静态布局
- [ ] 能把一段常用 CSS 手写成对应的 Flutter Widget 组
- [ ] 能解释“约束向下、尺寸向上”并预判一个容器是撑满还是收缩

如果你能回答下面三个问题，就可以进入 Day 3（列表与表单）：

1. “约束向下、尺寸向上”是什么意思？为什么它会影响我判断溢出？
2. `Row` 放超宽内容会怎样？你打算怎么解决？
3. `Container` 什么时候撑满、什么时候收缩？`Expanded` 和 `Flexible` 有什么区别？

答案提示：

1. 父组件给出 min/max 约束，子组件在范围内选尺寸并汇报；知道“主轴是否无界”就能判断会不会溢出。
2. 会 `RenderFlex overflowed` 出现黄黑条纹；用 `Expanded` / `Flexible` + `TextOverflow.ellipsis`，必要时换 `Wrap`。
3. 有 `child` 收缩包内容、没 `child` 也没尺寸且父级有界则撑满、给了宽高则固定；`Expanded` 强制占满（＝`Flexible(fit: tight)`），`Flexible` 允许收缩（`loose`）。
