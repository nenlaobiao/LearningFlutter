# Flutter 学习笔记 05：状态管理

> 适用前提：已经完成 Day 4（路由与页面组织）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 5。
> 本笔记的目标：跨页面共享购物车状态，搞懂「什么时候 `setState` 就够、什么时候必须上状态管理」，并用 Riverpod 落地一个全局购物车。

## 目录

- [1. 先建立直觉：setState 为什么不够](#1-先建立直觉setstate-为什么不够)
- [2. 状态的三个层级：局部、提升、全局](#2-状态的三个层级局部提升全局)
- [3. Provider 思想：ChangeNotifier 与订阅重建](#3-provider-思想changenotifier-与订阅重建)
- [4. Riverpod 三件套：Provider、Notifier、ConsumerWidget](#4-riverpod-三件套providernotifierconsumerwidget)
- [5. ref.watch 与 ref.read](#5-refwatch-与-refread)
- [6. 什么时候才需要状态管理](#6-什么时候才需要状态管理)
- [7. 今日最小项目：全局购物车](#7-今日最小项目全局购物车)
- [8. 速查表](#8-速查表)
- [9. 今日自检](#9-今日自检)

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

## 4. Riverpod 三件套：Provider、Notifier、ConsumerWidget

先加依赖：

```yaml
dependencies:
  flutter_riverpod: ^3.0.0   # 版本以 pub.dev 最新为准
```

入口包一层 `ProviderScope`：

```dart
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

### ConsumerWidget：能订阅 Provider 的组件

普通 `StatelessWidget` 没有 `ref`，换成 `ConsumerWidget`，`build` 多一个 `ref` 参数：

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

对应关系：`ConsumerWidget` ≈ 能订阅状态的 `StatelessWidget`；`ConsumerStatefulWidget` ≈ 能订阅状态的 `StatefulWidget`（组件内部还有自己的 `setState` 时用）。

## 5. ref.watch 与 ref.read

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

## 6. 什么时候才需要状态管理

不是每个变量都往全局塞。判断标准还是那句话：

> **这份会变的数据，有多少个互相独立的 Widget 要读？**

| 情况 | 方案 |
| --- | --- |
| 只有当前 Widget 读 | `setState` |
| 就近的几个父子组件读 | 状态提升，构造器下发 |
| 跨页面 / 很多组件读 | Riverpod（或 Provider） |

典型该上状态管理的：购物车、登录态、主题、用户信息。典型的反面教材：一个弹窗的开合、一个 Tab 的当前 index——这些 `setState` 就够，硬塞全局只会让代码更难读。

> 总纲里的建议：先把 `setState` 写透再上 Riverpod。今天你已经过了 `setState` 的关，现在学的是「同一份状态跨页面共享」的正确姿势。

## 7. 今日最小项目：全局购物车

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

## 8. 速查表

### 今天出现的 API / Widget

| 名称 | 作用 |
| --- | --- |
| `ProviderScope` | 全局容器，所有 Provider 的家 |
| `Provider` | 只读数据 |
| `Notifier` + `NotifierProvider` | 可变状态 + 修改方法 |
| `ConsumerWidget` / `ConsumerStatefulWidget` | 能订阅状态的组件 |
| `ref.watch` | 订阅，状态变则重建 |
| `ref.read` | 读一次，不订阅 |
| `ref.watch(...select(...))` | 只订阅部分状态 |
| `provider.notifier` | 拿到 Notifier 实例调方法 |

### 三个心智模型

| 问题 | 答案 |
| --- | --- |
| 状态放哪？ | 看有多少独立 Widget 要读：一个 → `setState`，就近几个 → 提升，跨页面 → 全局 |
| 全局状态怎么建？ | `Notifier` 的 `build` 给初始值，方法里**整体替换** `state` |
| 组件怎么订阅？ | `ConsumerWidget` + `ref.watch`；改状态用 `ref.read(...notifier).方法()` |

## 9. 今日自检

完成下面三件事，Day 5 才算通过：

- [ ] 用 Riverpod 建全局 `CartNotifier`，详情页加入购物车能改全局数量
- [ ] 购物车 tab 和底部角标能实时显示数量
- [ ] 结算页读同一份状态，验证跨页共享

如果你能回答下面三个问题，就可以进入 Day 6（网络请求）：

1. 什么时候 `setState` 就够？什么时候必须上状态管理？
2. 全局状态放在哪里？组件怎么订阅？
3. 购物车数量在多个页面如何保持一致？

答案提示：

1. 状态只被一个 Widget 的 UI 用时，`setState` 就够；当多个互相独立的页面/组件要读同一份会变的数据（购物车、登录态、主题），必须上状态管理。
2. 全局状态放在 Riverpod 的 Provider 里，由最外层 `ProviderScope` 统一托管；组件用 `ConsumerWidget` 的 `ref.watch` 订阅，状态一变自动重建。
3. 所有页面都 `watch` 同一个 `cartProvider`；任何一处修改 `state`（整体替换成新 Map），Riverpod 通知所有 watcher 重建，所以各处数量天然一致——前提是只存一份数据源，不各自复制。
