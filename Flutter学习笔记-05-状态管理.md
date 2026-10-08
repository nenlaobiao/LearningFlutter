# Flutter 学习笔记 05：状态管理

> 适用前提：已经完成 Day 4（路由与页面组织）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 5。
> 本笔记的目标：跨页面共享购物车状态，搞懂「什么时候 `setState` 就够、什么时候必须上状态管理」，并用 Riverpod 落地一个全局购物车。
> 第 5 节是 Widget 基础补课：`WidgetRef` 是什么、换成 Consumer 家族时类要怎么改、和普通 `StatelessWidget` / `StatefulWidget` 的区别。

## 目录

- [1. 先建立直觉：setState 为什么不够](#1-先建立直觉setstate-为什么不够)
- [2. 状态的三个层级：局部、提升、全局](#2-状态的三个层级局部提升全局)
- [3. Provider 思想：ChangeNotifier 与订阅重建](#3-provider-思想changenotifier-与订阅重建)
- [4. Riverpod 的数据侧：ProviderScope、Provider、Notifier](#4-riverpod-的数据侧providerscopeprovidernotifier)
- [5. Widget 补课：StatelessWidget、StatefulWidget 与 Consumer 家族](#5-widget-补课statelesswidgetstatefulwidget-与-consumer-家族)
- [6. ref.watch 与 ref.read](#6-refwatch-与-refread)
- [7. 什么时候才需要状态管理](#7-什么时候才需要状态管理)
- [8. 今日最小项目：全局购物车](#8-今日最小项目全局购物车)
- [9. 速查表](#9-速查表)
- [10. 今日自检](#10-今日自检)

## 1. 先建立直觉：setState 为什么不够

回顾 Day 1 的结论：`UI = f(state)`，改状态必须 `setState` 触发重建。`setState` 能完美处理「单个 Widget 内部」的状态，但购物车这种状态有个新问题：**多个互相独立的页面都要读它**。

- 商品详情页「加入购物车」要**改**数量；
- 底部导航的购物车角标要**读**数量；
- 购物车页、结算页也要**读**同一份数量。

如果每个页面各存一份 `Map<int, int>`，它们彼此不知道对方改了没有，就会出现「详情页加了购物车，购物车页还是空的」。这不是 `setState` 不会刷新，而是**状态本身散落在各处，没有唯一来源**。

> 一句话：`setState` 解决「一个组件的重建」，解决不了「多个组件共享同一份可变数据」。

## 2. 状态的三个层级：局部、提升、全局

判断状态该放哪，先问自己一个问题：

> **这份会变的数据，有多少个 Widget 要读？**

### 第一层：局部状态 → setState

只有自己用：收藏按钮的 `isFavorite`、一个折叠开关。放在 `State` 里 + `setState`，最简单。

### 第二层：状态提升（lifting state up）

就近的几个父子组件要用同一份数据：把状态提升到「它们最近的共同父组件」，再通过构造器下发。

比如两个按钮要共享一个计数：

```dart
class _CounterParentState extends State<CounterParent> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CounterButton(
          count: count,
          onPressed: () => setState(() => count++),
        ),
        CounterButton(
          count: count,
          onPressed: () => setState(() => count++),
        ),
      ],
    );
  }
}
```

对应 Vue 的经验：这就像「把 data 放到共同父组件，props 下发」。缺点是层级一深，数据要一层层手传（prop drilling）；两个页面完全无关时，更没法这么传。

### 第三层：全局状态 → 状态管理库

跨页面、跨树共享（购物车、登录态、主题）：理论上可以提升到「最顶层的共同父组件」，但一层层手传不现实。这时用状态管理库，让所有页面直接从**同一个全局容器**里读写。

| 层级 | 状态归属 | 方案 | Vue 对应 |
| --- | --- | --- | --- |
| 局部 | 一个 Widget | `setState` | 组件内 data |
| 提升 | 就近父子组件 | 提到共同父组件下发 | props 下发 |
| 全局 | 跨页面共享 | Riverpod 等 | Pinia |

## 3. Provider 思想：ChangeNotifier 与订阅重建

在讲 Riverpod 之前，先认识它背后的两个零件。

### ChangeNotifier：可变数据 + 通知机制

```dart
class CartModel extends ChangeNotifier {
  final Map<int, int> _items = {};

  void add(int id) {
    _items[id] = (_items[id] ?? 0) + 1;
    notifyListeners(); // 关键：主动广播「我变了」
  }
}
```

它自己不懂 UI，只做两件事：存数据，以及 `notifyListeners()` 通知订阅者。

### Provider 模式：把数据「提供」给整棵树

Provider 模式的核心：一个上层 Widget 持有这个 `ChangeNotifier`，用 Flutter 内置的 `InheritedWidget` 把它传给整棵子树；任何后代 `context.watch<CartModel>()`，`notifyListeners()` 一响就自动重建。这就是 `package:provider` 做的事。

Riverpod 保留了这个思想——「数据放全局容器、谁订阅谁重建」——但去掉了对 `context` 的依赖，改成**编译期安全**的 `ref` 体系。

> 心智模型：状态管理 = **唯一数据源 + 订阅通知**。数据只存一份，谁改了它，所有订阅者自动重建，所以各处天然一致。

## 4. Riverpod 的数据侧：ProviderScope、Provider、Notifier

先加依赖：

```yaml
dependencies:
  flutter_riverpod: ^3.0.0   # 版本以 pub.dev 最新为准
```

入口包一层 `ProviderScope`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ShopApp()));
}
```

`ProviderScope` 就是那个「全局容器」，所有 Provider 都住在里面。

### Provider：只读数据

```dart
final productsProvider = Provider<List<Product>>((ref) => products);
```

适合放常量、派生数据这类「自己不直接变」的值。

### Notifier + NotifierProvider：可变状态 + 修改方法

购物车会变，用 `Notifier`：

```dart
// 全局唯一数据源：商品 id -> 数量
final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {}; // 初始状态：空购物车

  void add(int productId) {
    state = {...state, productId: (state[productId] ?? 0) + 1};
  }
}
```

两个关键点：

1. `build()` 返回初始状态。
2. 改状态必须是**整体替换**：`state = {...state, ...}` 新建一份 Map 再赋值。原地改（`state[id] = 1`）不会触发通知，因为 Riverpod 靠「引用变了」判断状态变了。

### 订阅侧：ConsumerWidget 与那个多出来的 ref

数据准备好了，还差「能读 Provider 的 Widget」把数据画到屏幕上——这就是代码里到处出现的 `ConsumerWidget` 和 `WidgetRef ref`：

```dart
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider); // 订阅：状态变了我重建
    return Text('共 ${cart.length} 种商品');
  }
}
```

和 Day 1 学的写法比，这里多了两样东西：

1. 基类从 `StatelessWidget` 变成了 `ConsumerWidget`；
2. `build` 的签名多了一个 `WidgetRef ref`。

这两件事是**绑定在一起**的，而且换成 `StatefulWidget` 时改法还不一样。因为涉及 Widget 的继承体系，单独放到下一节讲透。

> 只想先跑通代码的，可以跳到第 8 节的完整项目；但「`ref` 是哪来的」「要不要改继承」这两个问题，答案都在第 5 节。

## 5. Widget 补课：StatelessWidget、StatefulWidget 与 Consumer 家族

这一节回答三个一连串的问题，也是初学 Riverpod 最容易卡住的地方：

1. `Widget build(BuildContext context, WidgetRef ref)` 里那个 `ref` 是哪来的？
2. 用了 `ref`，**类要改成什么**？不改行不行？
3. `StatelessWidget` 和 `StatefulWidget` 本来有什么区别？（Day 1 只开了个头，这里补齐）

### 5.1 基础：StatelessWidget 与 StatefulWidget 的区别

> 学过 Day 1 第 6、7 节（[Flutter学习笔记-01-Widget与布局.md](Flutter学习笔记-01-Widget与布局.md)）的，可以只看表格和「三个关键点」。

先记住 Day 1 提过的前提：**Widget 是不可变的配置对象，每次重建都是新的**。所以「需要被记住的数据」放不进 Widget，只能另找地方存——这就是 `State` 存在的唯一理由。

| 对比项 | `StatelessWidget` | `StatefulWidget` |
| --- | --- | --- |
| 类的数量 | 1 个 | 2 个：Widget 外壳 + `State` |
| 会变的数据放哪 | 没有，只有构造器传来的 `final` 字段 | `State` 类的普通字段 |
| `build` 写在哪 | Widget 自己 | `State` 里 |
| 能不能 `setState` | 不能（没有 State，也就没有 `setState`） | 能 |
| 什么时候重建 | 父组件重建、依赖的 InheritedWidget 变化 | `setState`、父组件重建、依赖变化 |
| 生命周期 | 构造函数 → `build` | `initState` → `build` → `didUpdateWidget` → `dispose` |
| 适合什么 | 纯展示、布局、按参数拼 UI | 表单输入、开关、Tab 下标、动画、定时器 |

同一件事的两种写法（一个只负责显示，一个自己记住状态）：

```dart
// 只负责画：收藏状态由外面传入
class FavoriteLabel extends StatelessWidget {
  const FavoriteLabel({super.key, required this.isFavorite});

  final bool isFavorite;

  @override
  Widget build(BuildContext context) => Text(isFavorite ? '已收藏' : '未收藏');
}

// 自己记住「收藏了没」
class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key});

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => setState(() => isFavorite = !isFavorite),
      child: Text(isFavorite ? '取消收藏' : '收藏'),
    );
  }
}
```

三个关键点：

1. **`State` 才是「记忆」**。`StatefulWidget` 外壳每次重建都会换成新对象，但 Flutter 会把同一个 `State` 对象继续挂在它身上（靠 Element 对齐），所以 `isFavorite` 活得比任何一次 `build` 都久。这也是 `build` 要写在 `State` 里的原因——它得读到那些字段。
2. **判断标准只有一句话**：这份数据在组件活着的时候会不会变？会变 → `StatefulWidget`；不会变 → `StatelessWidget`。
3. **常见误用**：把 `TextEditingController`、`AnimationController`、`Timer` 直接塞进 `StatelessWidget` 的字段。它们需要 `dispose`，必须有 `State`（或交给 Riverpod、上层组件管）。

Vue 类比：`StatelessWidget` ≈ 只吃 props 的函数式组件；`StatefulWidget` 的 `State` ≈ 组件的 `data` 加上 `created` / `mounted` / `unmounted` 这一整套生命周期。

### 5.2 WidgetRef 是什么

一句话：**`WidgetRef` 是 Riverpod 发给 Widget 层的门禁卡**。有了它，才能读 Provider、订阅 Provider、调用 Notifier 的方法。

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final cart = ref.watch(cartProvider); // 用 ref 换到 Provider 里的值
  ...
}
```

三个要点：

1. **它不是状态本身**。状态住在 Provider（全局容器）里，`ref` 只是通往容器的遥控器，不保存数据。
2. **它是一本订阅记账簿**。`ref.watch(p)` 等于对 Riverpod 说：「我这个 Widget 订阅了 `p`，它变了就重建我。」既然要记账到「某个具体的 Widget」，`ref` 就必须和 Widget 绑定——这就是它出现在 `build` 参数里的原因。
3. **它只属于 UI 层**。官方注释写得很直接：`WidgetRef` 不应该离开 Widget 层。要传给仓库类、模型类用，得换成 Provider 侧的 `Ref`（Day 6 网络请求里拦截器持有的就是它）。

源码彩蛋，知道后能少一半困惑：`ConsumerStatefulElement implements WidgetRef`，而 `ConsumerState` 里的 `ref` 就是 `context as WidgetRef`。

> 也就是说：**`ref` 背后就是你当前这个 Widget 的 Element**。`context` 让你在 Widget 树里定位自己，`ref` 让你在 Provider 容器里读写数据；两者都只在这个 Widget 活着的时候有效。

用法限制（先记这三条）：

| 想做的事 | 正确写法 | 错误写法 |
| --- | --- | --- |
| 在 `build` 里读值显示 | `ref.watch(p)` | 在 `initState` 或按钮回调里 `watch` |
| 在按钮回调里改状态 | `ref.read(p.notifier).方法()` | 在回调里 `watch` |
| 在 `initState` 里订阅 | `ref.listenManual(...)` | `ref.listen(...)`（只能写在 `build` 顶层） |

还有一条：`await` 之后再碰 `ref` 要先 `if (!mounted) return;`，否则 Widget 可能已经销毁，会抛 `Using "ref" when a widget is about to or has been unmounted is unsafe.`

#### `ref` 不止 `watch` 一个方法

初学时满屏都是 `ref.watch`，很容易以为 `ref` 就等于 `watch`。其实常用的是这一组（flutter_riverpod 3.x 的 `WidgetRef`）：

| 方法 | 作用 | 必须在 `build` 里吗 |
| --- | --- | --- |
| `ref.watch(p)` | 订阅：值变了就重建当前 Widget | 是（`build` 顶层） |
| `ref.read(p)` | 读一次，不订阅，也不重建 | 否（回调、`initState` 都能用） |
| `ref.listen(p, (prev, next) {...})` | 订阅并执行副作用：弹 SnackBar、跳转、写日志 | 是（`build` 顶层） |
| `ref.listenManual(p, (prev, next) {...})` | 手动订阅，返回 `ProviderSubscription`（可手动关闭） | 否（专门给 `initState` 等生命周期用） |
| `ref.refresh(p)` | 立刻让 Provider 重算，并把新值返回 | 否 |
| `ref.invalidate(p)` | 让 Provider 失效，下一帧 / 下次读取时再重算 | 否 |
| `ref.exists(p)` | 判断这个 Provider 有没有被初始化过 | 否 |
| `ref.context` | 拿到当前 Widget 的 `BuildContext`（属性，不是方法） | —— |

怎么记：

- **要展示、要跟着变** → `watch`（`build` 里）；
- **点了按钮要改状态** → `read`（回调里）；
- **值变了要「做点事」而不是重画** → `listen` / `listenManual`；
- **想强制重新拉一次数据**（下拉刷新、重试按钮）→ `refresh` / `invalidate`。

`refresh` 和 `invalidate` 的区别：`refresh` 立即重算并返回新值；`invalidate` 只是标脏，等下一帧或下次读取时才重算（连续调多次也只算一次）。异步 Provider 重算时，`AsyncValue` 默认会**保留上一次的值**，所以界面不会闪空；想连旧值一起清掉、走「硬刷新」，用 `invalidate(p, asReload: true)`。

### 5.3 要改继承吗：要，而且 build 签名跟着一起改

`ref` 不是全局变量，它由 **Consumer 家族**的类提供。所以想用 `ref`，就必须换基类：

| 原来的写法 | 要订阅 Provider 就改成 | `build` 签名 | `ref` 从哪来 |
| --- | --- | --- | --- |
| `extends StatelessWidget` | `extends ConsumerWidget` | `build(context, ref)` | 第二个参数 |
| `extends StatefulWidget` | `extends ConsumerStatefulWidget` | —— | —— |
| `State<X>` | `ConsumerState<X>` | `build(context)` | State 上的 `ref` 属性 |
| 一行都不想改 | 原类 + 里面包一层 `Consumer` | 不变 | `builder` 的第二个参数 |

不改会怎样？在普通 `StatelessWidget` 里写 `ref.watch(...)` 直接编译不过（`Undefined name 'ref'`）——**`ref` 是按 Widget 发下来的，不是天上掉的。**

#### 写法 A：原来的 StatelessWidget

```dart
// 改之前：数据靠构造器层层传进来
class CartBadge extends StatelessWidget {
  const CartBadge({super.key, required this.totalCount});

  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Badge(label: Text('$totalCount'), child: const Icon(Icons.shopping_cart));
  }
}

// 改之后：自己订阅，构造器不用再传数量
class CartBadge extends ConsumerWidget {
  const CartBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalCount = cart.values.fold(0, (sum, count) => sum + count);
    return Badge(label: Text('$totalCount'), child: const Icon(Icons.shopping_cart));
  }
}
```

改动只有三处：`extends`、`build` 参数、数据来源（构造器 → `ref.watch`）。**所以你会觉得「好像只是多了一个参数」——因为页面结构真的没变，变的只是数据从哪来。**

#### 写法 B：原来的 StatefulWidget

组件自己还有本地状态（页面里的 Tab 下标、展开收起、各种控制器）时才走这条路：

```dart
class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  bool _expanded = false; // 本地状态：只有这个页面用，setState 就够

  @override
  void initState() {
    super.initState();
    // initState 里不能 watch；只想读一次用 read（它不建立订阅）
    final product = ref.read(productsProvider).firstWhere((p) => p.id == widget.productId);
    debugPrint('打开详情页：${product.name}');
  }

  @override
  Widget build(BuildContext context) {
    // 注意：ConsumerState 的 build 只有 context 一个参数，ref 直接用
    final cart = ref.watch(cartProvider);
    return Column(
      children: [
        Text('购物车里 ${cart.length} 种商品'),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? '收起' : '展开'),
        ),
      ],
    );
  }
}
```

和普通 `StatefulWidget` 相比只有三处不同，也是最爱写错的地方：

1. 基类换成 `ConsumerStatefulWidget`；
2. `createState()` 的返回类型是 `ConsumerState<DetailPage>`，不是 `State<DetailPage>`；
3. `ConsumerState` 的 `build` 只有 `BuildContext context` 一个参数——`ref` 是继承来的属性，**不要**照抄写法 A 再加一个参数。

#### 为什么 ConsumerWidget 不用写 State

因为 Riverpod 已经替你写好了。flutter_riverpod 3.x 的源码：

```dart
abstract class ConsumerWidget extends ConsumerStatefulWidget {
  const ConsumerWidget({super.key});

  Widget build(BuildContext context, WidgetRef ref);

  @override
  ConsumerState<ConsumerWidget> createState() => _ConsumerState();
}

class _ConsumerState extends ConsumerState<ConsumerWidget> {
  @override
  Widget build(BuildContext context) => widget.build(context, ref);
}
```

看明白了：**`ConsumerWidget` 就是一个「框架替你写好了 State 的 StatefulWidget」**，那个内部 State 只干一件事——把 `ref` 递给你写的 `build(context, ref)`。

两个推论：

- 你写 `ConsumerWidget` 时确实不用管 State，概念上它就是「能订阅 Provider 的无状态组件」，和 Day 1 的 `StatelessWidget` 心智一致；
- 但它没有地方写 `initState` / `dispose`。真要生命周期钩子，就换成写法 B。

### 5.4 不改继承的办法：用 Consumer 局部订阅

页面大部分是静态的，只有一小块要跟着 Provider 变时，不必把整个页面改成 `ConsumerWidget`，用 `Consumer` 把那一小块包起来即可：

```dart
class ProductPage extends StatelessWidget { // 类保持原样
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品')),
      body: Column(
        children: [
          const Text('这段是静态内容'),
          Consumer( // 只有这里面会订阅、会重建
            builder: (context, ref, child) {
              final cart = ref.watch(cartProvider);
              return Text('购物车：${cart.length} 种商品');
            },
          ),
        ],
      ),
    );
  }
}
```

为什么要这样绕一下？因为 **`ref.watch` 一触发，整个 `build` 都会重跑**。把订阅放到尽量小的组件里，重建范围就尽量小。

- 官方推荐：优先把这块**抽成独立的 `ConsumerWidget`**（重建范围小，职责清楚）；
- `Consumer` 更适合「不想动现有结构，只想局部改造」的场景，两者目的相同。

`Consumer` 的 `builder` 还有第三个参数 `child`，用来放和 Provider 无关的静态子树，避免它跟着重建：

```dart
Consumer(
  builder: (context, ref, child) {
    final cart = ref.watch(cartProvider);
    return Row(children: [child!, Text('${cart.length} 种商品')]);
  },
  child: const Icon(Icons.shopping_cart), // 只构建一次
)
```

### 5.5 决策表：这个 Widget 该继承谁

| 这个 Widget 的情况 | 继承谁 |
| --- | --- |
| 不碰 Provider，数据全部从构造器来 | `StatelessWidget` |
| 不碰 Provider，但自己有待 `dispose` 的东西（控制器、定时器） | `StatefulWidget` |
| 要读 Provider，不需要生命周期钩子 | `ConsumerWidget`（最常用） |
| 要读 Provider，还要 `initState` / `dispose` / 本地 `setState` | `ConsumerStatefulWidget` + `ConsumerState` |
| 只有页面里一小块要读 Provider | 原类不动，包一层 `Consumer` |

⚠️ 别走极端：**不是「上了 Riverpod，所有页面都要换成 ConsumerXxx」**。只有真正读写 Provider 的那个 Widget 才需要改，能下沉到小组件就下沉，重建范围和代码可读性都会更好。

### 5.6 两条「触发重建」的路线

`setState` 和 `ref.watch` 解决的是同一件事——「数据变了，界面要重画」，但方向相反：

| 对比项 | `setState` | `ref.watch` |
| --- | --- | --- |
| 数据放在哪 | 当前 `State` 里 | Provider（全局容器） |
| 谁发起重建 | Widget 自己主动喊 | Provider 变化后通知订阅者 |
| 影响范围 | 当前 State 对应的 Widget | 所有订阅了这个 Provider 的 Widget |
| 适合 | 组件私有的状态 | 跨组件 / 跨页面共享的状态 |

> 心智模型：`setState` 是「我变了，重建我」；`ref.watch` 是「它变了，通知我」。两条路线最后都落到同一件事——某个 Element 需要重建。

### 5.7 常见报错对照

| 现象 | 原因 | 修法 |
| --- | --- | --- |
| `Undefined name 'ref'` | 类还是 `StatelessWidget` / `StatefulWidget` | 换基类，或包一层 `Consumer` |
| `build` 参数不匹配（`invalid_override`） | 已改成 `ConsumerWidget`，`build` 却只写了 `context` | 补上 `WidgetRef ref` |
| `createState` 返回类型报错 | `ConsumerStatefulWidget` 配了普通 `State` | `State<X>` 改成 `ConsumerState<X>` |
| 在 `initState` 里用 `ref` 报错 | `watch` / `listen` 只能写在 `build` 顶层 | 改用 `ref.read`（要订阅用 `listenManual`） |
| 异步回调里报 unmounted / 已销毁 | `await` 之后 Widget 已经没了 | 先 `if (!mounted) return;` |
| 改了基类后热重载报奇怪的错 | 换基类属于结构性改动，热重载换不掉旧的 Element | 按 `R` 热重启（Day 1 第 9 节） |

## 6. ref.watch 与 ref.read

这是 Riverpod 最容易混的两个方法：

| 方法 | 行为 | 什么时候用 |
| --- | --- | --- |
| `ref.watch(provider)` | 订阅，状态一变当前组件重建 | `build` 里读状态显示 |
| `ref.read(provider)` | 只读一次，不订阅、不重建 | 事件回调里执行操作 |

记忆法：**build 里用 `watch`（要跟着变），onPressed 里用 `read`（一次性读出来执行）。**

```dart
Widget build(BuildContext context, WidgetRef ref) {
  final cart = ref.watch(cartProvider); // 显示：订阅
  return FilledButton(
    onPressed: () {
      ref.read(cartProvider.notifier).add(1); // 操作：一次性读 notifier 改状态
    },
    child: Text('购物车(${cart.length})'),
  );
}
```

另外两个常用后缀：

- `provider.notifier`：拿到 `CartNotifier` 实例，调用它的方法。
- `ref.watch(cartProvider.select((cart) => cart.length))`：只订阅其中一部分，`cart.length` 没变就不重建（性能优化用）。

## 7. 什么时候才需要状态管理

不是每个变量都往全局塞。判断标准还是那句话：

> **这份会变的数据，有多少个互相独立的 Widget 要读？**

| 情况 | 方案 |
| --- | --- |
| 只有当前 Widget 读 | `setState` |
| 就近的几个父子组件读 | 状态提升，构造器下发 |
| 跨页面 / 很多组件读 | Riverpod（或 Provider） |

典型该上状态管理的：购物车、登录态、主题、用户信息。典型的反面教材：一个弹窗的开合、一个 Tab 的当前 index——这些 `setState` 就够，硬塞全局只会让代码更难读。

> 总纲里的建议：先把 `setState` 写透再上 Riverpod。今天你已经过了 `setState` 的关，现在学的是「同一份状态跨页面共享」的正确姿势。

## 8. 今日最小项目：全局购物车

在 `pubspec.yaml` 加上 `flutter_riverpod` 依赖，然后把下面的完整代码放进 `lib/main.dart`。它一次覆盖四个动手任务：全局 `CartNotifier`、详情页加入购物车、购物车 tab 实时数量、结算页读同一份状态。

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ShopApp()));
}

// ---------- 商品模型 ----------
class Product {
  const Product({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final int price;
}

const products = [
  Product(id: 1, name: '无线蓝牙耳机', price: 199),
  Product(id: 2, name: '机械键盘', price: 459),
  Product(id: 3, name: '智能手表', price: 899),
  Product(id: 4, name: '便携充电宝', price: 129),
];

// ---------- 全局购物车状态：商品 id -> 数量 ----------
final cartProvider = NotifierProvider<CartNotifier, Map<int, int>>(CartNotifier.new);

class CartNotifier extends Notifier<Map<int, int>> {
  @override
  Map<int, int> build() => {};

  void add(int productId) {
    state = {...state, productId: (state[productId] ?? 0) + 1};
  }

  void remove(int productId) {
    final next = {...state};
    final count = (next[productId] ?? 1) - 1;
    if (count <= 0) {
      next.remove(productId);
    } else {
      next[productId] = count;
    }
    state = next;
  }

  void clear() {
    state = {};
  }
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '商城 Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const MainTabsPage(),
    );
  }
}

// 主框架：底部两个 tab，购物车角标实时读全局状态
class MainTabsPage extends ConsumerStatefulWidget {
  const MainTabsPage({super.key});

  @override
  ConsumerState<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends ConsumerState<MainTabsPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final totalCount = cart.values.fold(0, (sum, count) => sum + count);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [ProductListPage(), CartPage()],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('$totalCount'),
              child: const Icon(Icons.shopping_cart),
            ),
            label: '购物车',
          ),
        ],
      ),
    );
  }
}

class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品列表')),
      body: ListView.builder(
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
            title: Text(product.name),
            subtitle: Text('¥${product.price}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('商品 ID：${product.id}'),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${product.price}',
              style: const TextStyle(color: Colors.red, fontSize: 20),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ref.read(cartProvider.notifier).add(product.id);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('加入购物车'),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final entries = cart.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final totalPrice = entries.fold<int>(0, (sum, entry) {
      final product = products.firstWhere((p) => p.id == entry.key);
      return sum + product.price * entry.value;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: cart.isEmpty
          ? const Center(child: Text('购物车是空的'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      final product = products.firstWhere((p) => p.id == entry.key);
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                        title: Text(product.name),
                        subtitle: Text('单价 ¥${product.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).remove(product.id),
                            ),
                            Text('${entry.value}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).add(product.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: Text('合计：¥$totalPrice')),
                        FilledButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CheckoutPage(),
                              ),
                            );
                          },
                          child: const Text('去结算'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// 结算页：读同一份 cartProvider，验证跨页共享
class CheckoutPage extends ConsumerWidget {
  const CheckoutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final totalCount = cart.values.fold(0, (sum, count) => sum + count);
    final totalPrice = cart.entries.fold<int>(0, (sum, entry) {
      final product = products.firstWhere((p) => p.id == entry.key);
      return sum + product.price * entry.value;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('结算')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 64),
            const SizedBox(height: 16),
            Text('共 $totalCount 件商品'),
            const SizedBox(height: 8),
            Text(
              '应付 ¥$totalPrice',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
                Navigator.pop(context);
              },
              child: const Text('确认支付'),
            ),
          ],
        ),
      ),
    );
  }
}
```

运行后验证四件事：

1. 详情页连点几次「加入购物车」，回到底部导航看购物车角标实时 +N。
2. 切到购物车 tab，数量和列表与角标一致——三个页面读的是同一份状态。
3. 购物车页点 + / - 改数量，观察底部角标同步变化。
4. 点「去结算」，结算页的件数 / 总价来自同一份 `cartProvider`；点「确认支付」清空后回购物车页，看它变成空。

## 9. 速查表

### 今天出现的 API / Widget

| 名称 | 作用 |
| --- | --- |
| `ProviderScope` | 全局容器，所有 Provider 的家 |
| `Provider` | 只读数据 |
| `Notifier` + `NotifierProvider` | 可变状态 + 修改方法 |
| `WidgetRef` | `build` 里拿到的「Provider 遥控器」，只在 Widget 层有效 |
| `ConsumerWidget` | `StatelessWidget` 的订阅版：`build(context, ref)` |
| `ConsumerStatefulWidget` + `ConsumerState` | `StatefulWidget` 的订阅版：`ref` 是 State 的属性 |
| `Consumer` | 不改继承，局部订阅（`builder` 里拿 `ref`） |
| `ref.watch` | 订阅，状态变则重建 |
| `ref.read` | 读一次，不订阅 |
| `ref.listen` / `ref.listenManual` | 订阅并做副作用（弹提示、跳转）；`listen` 写在 `build` 顶层 |
| `ref.refresh` / `ref.invalidate` | 强制 Provider 重算：前者立即返回新值，后者标脏、下次读取时再算 |
| `ref.watch(...select(...))` | 只订阅部分状态 |
| `provider.notifier` | 拿到 Notifier 实例调方法 |

### 四个心智模型

| 问题 | 答案 |
| --- | --- |
| 状态放哪？ | 看有多少独立 Widget 要读：一个 → `setState`，就近几个 → 提升，跨页面 → 全局 |
| 全局状态怎么建？ | `Notifier` 的 `build` 给初始值，方法里**整体替换** `state` |
| 组件怎么订阅？ | `ConsumerWidget` + `ref.watch`；改状态用 `ref.read(...notifier).方法()` |
| Widget 继承谁？ | 纯展示 → `StatelessWidget`；有本地可变状态 → `StatefulWidget`；要读 Provider → `ConsumerWidget` / `ConsumerStatefulWidget`（或包一层 `Consumer`） |

## 10. 今日自检

完成下面四件事，Day 5 才算通过：

- [ ] 用 Riverpod 建全局 `CartNotifier`，详情页加入购物车能改全局数量
- [ ] 购物车 tab 和底部角标能实时显示数量
- [ ] 结算页读同一份状态，验证跨页共享
- [ ] 把一个 `ConsumerWidget` 临时改回 `StatelessWidget`，看 `ref` 报什么错，再改回来

如果你能回答下面四个问题，就可以进入 Day 6（网络请求）：

1. 什么时候 `setState` 就够？什么时候必须上状态管理？
2. 全局状态放在哪里？组件怎么订阅？
3. 购物车数量在多个页面如何保持一致？
4. `build` 里那个 `WidgetRef ref` 是哪来的？不换成 `ConsumerWidget` 行不行？

答案提示：

1. 状态只被一个 Widget 的 UI 用时，`setState` 就够；当多个互相独立的页面/组件要读同一份会变的数据（购物车、登录态、主题），必须上状态管理。
2. 全局状态放在 Riverpod 的 Provider 里，由最外层 `ProviderScope` 统一托管；组件用 `ConsumerWidget` 的 `ref.watch` 订阅，状态一变自动重建。
3. 所有页面都 `watch` 同一个 `cartProvider`；任何一处修改 `state`（整体替换成新 Map），Riverpod 通知所有 watcher 重建，所以各处数量天然一致——前提是只存一份数据源，不各自复制。
4. `ref` 由 Consumer 家族提供：`ConsumerWidget` 把它作为 `build` 的第二个参数递进来，`ConsumerState` 则把它做成 State 的属性（源码里 `ref` 本质就是当前 Widget 的 Element）。普通 `StatelessWidget` / `StatefulWidget` 拿不到 `ref`，所以要么换基类，要么不改继承、在外面包一层 `Consumer`（第 5 节）。
