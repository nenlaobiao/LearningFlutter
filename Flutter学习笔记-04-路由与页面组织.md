# Flutter 学习笔记 04：路由与页面组织

> 适用前提：已经完成 Day 3（列表与表单）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 4。
> 本笔记的目标：在多页面之间正确跳转、传参、拿结果，并搭出「首页 / 购物车 / 我的」的底部 Tab 骨架。

## 目录

- [1. 从 Vue 到 Flutter：路由怎么对应](#1-从-vue-到-flutter路由怎么对应)
- [2. Navigator：push 与 pop](#2-navigatorpush-与-pop)
- [3. 页面传参：构造器传值](#3-页面传参构造器传值)
- [4. 结果回传：pop 带值回去](#4-结果回传pop-带值回去)
- [5. 替换与清空路由栈：pushReplacement 与 pushAndRemoveUntil](#5-替换与清空路由栈pushreplacement-与-pushandremoveuntil)
- [6. 命名路由与 go_router](#6-命名路由与-go_router)
- [7. 底部 Tab：BottomNavigationBar 与 IndexedStack](#7-底部-tabbottomnavigationbar-与-indexedstack)
- [8. 今日最小项目：商品列表与详情页](#8-今日最小项目商品列表与详情页)
- [9. 速查表](#9-速查表)
- [10. 今日自检](#10-今日自检)

## 1. 从 Vue 到 Flutter：路由怎么对应

你在 uniapp / Vue 里跳页面，用的是全局 API 或 `pages.json`：

```js
uni.navigateTo({ url: '/pages/detail/detail?id=1' })
uni.redirectTo({ url: '/pages/home/home' })
uni.navigateBack()
```

Flutter 没有 `pages.json`，页面跳转直接写在代码里，核心就一个东西：`Navigator`。它维护着一个「路由栈」，你往里压页面、往外弹页面。

| uniapp / Vue | Flutter |
| --- | --- |
| `uni.navigateTo` | `Navigator.push` |
| `uni.navigateBack` | `Navigator.pop` |
| `uni.redirectTo` | `Navigator.pushReplacement` |
| URL 带参 `?id=1` | 目标页面构造函数传参 |
| 页面回传数据 | `Navigator.pop(result)` + `await push` |
| `pages.json` 集中配置 | 命名路由 / `go_router` |
| `tabBar` 页面 | `BottomNavigationBar` / `TabBar` |

> 心智模型：**push 是把新页面压到栈顶，pop 是从栈顶弹出返回。** 栈顶永远是你当前看到的页面。

## 2. Navigator：push 与 pop

跳转用 `push`，返回用 `pop`：

```dart
// 跳转：把 DetailPage 压到路由栈顶
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DetailPage()),
);

// 返回：把当前页面从栈顶弹出
Navigator.pop(context);
```

几个关键点：

- `context` 用来定位到当前页面所属的 `Navigator`，所以它必须是「当前页面里的 context」，不能随便从别的函数里拿。
- `MaterialPageRoute` 提供 Material 风格的转场动画。在 iOS 上，`MaterialPageRoute` 也支持边缘右滑返回手势，初学者用它就够了。
- `builder` 里的 `context` 是新页面的 context，`(context) => const DetailPage()` 这种写法要分清内外两个 context。

对比你的经验：`Navigator.push` ≈ `uni.navigateTo`（新页面可以返回），返回键 / `Navigator.pop` ≈ `uni.navigateBack`。

## 3. 页面传参：构造器传值

Flutter 里没有「路由字符串带 query」这一说，传参就是**给目标页面构造函数传字段**。

目标页面先声明它需要什么：

```dart
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.productId});

  final int productId; // 需要外部传入

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('商品 ID：$productId')),
      body: const Center(child: Text('详情内容')),
    );
  }
}
```

跳转时把值传进去：

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailPage(productId: product.id),
  ),
);
```

对比 Vue 的 `?id=1` 和 `query.id`：

| Vue | Flutter |
| --- | --- |
| `/detail?id=1` | `DetailPage(productId: 1)` |
| `onLoad(query)` 里 `query.id` | 直接读 `widget.productId` / `productId` 字段 |

好处是**类型安全**：`productId` 声明成 `int`，传错类型编译期就报错，不用在运行时拿字符串去解析。

## 4. 结果回传：pop 带值回去

真实业务里最常见的是「列表 → 详情 → 操作完 → 把结果带回列表」。对应 Flutter 的写法是：

**发起方：`await` 接收结果。**

```dart
final result = await Navigator.push<String>(
  context,
  MaterialPageRoute(builder: (context) => DetailPage(product: product)),
);

if (result != null && context.mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('${product.name} $result')),
  );
}
```

**详情页：`pop` 时把值带回去。**

```dart
FilledButton(
  onPressed: () {
    Navigator.pop(context, '已加入购物车');
  },
  child: const Text('加入购物车'),
)
```

三个容易踩的点：

1. `Navigator.push<String>` 的泛型 `<String>` 声明了「返回值的类型」。不写也可以，但写了更安全、更清晰。
2. `result` 的类型是 `String?`——因为用户可能直接点返回键退出，这时候 `pop` 没带值，`result` 就是 `null`。所以用之前要判空。
3. `await` 之后再用 `context`，要先检查 `context.mounted`。页面可能在等待期间被销毁，直接 `ScaffoldMessenger.of(context)` 会报错。这是 Flutter 新版本里的高频报错，养成「await 后用 context 前先 mounted」的习惯。

对应你的前端经验：这就像 Vue 里从子页面 `$emit('xxx', data)` 回传，或者 uniapp 的 `uni.$emit` / 事件总线——只是 Flutter 用「返回值」这条更直接的通道。

## 5. 替换与清空路由栈：pushReplacement 与 pushAndRemoveUntil

### pushReplacement：替换当前页

「登录成功 → 进首页，而且按返回键不能再回到登录页」就是它的典型场景：

```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => const HomePage()),
);
```

它把当前页从栈里**替换**掉，而不是压一个新页面。所以栈里不再有登录页，返回键直接退出 App 而不是回到登录页。

### pushAndRemoveUntil：清空整条栈

如果想把「登录 → 首页」中间所有历史都清掉（比如退出登录后重新登录），用：

```dart
Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => const HomePage()),
  (route) => false, // false = 把所有旧页面都移除
);
```

三者的区别：

| 方法 | 栈变化 | 返回键去哪 |
| --- | --- | --- |
| `push` | 压入新页 | 回到上一页 |
| `pushReplacement` | 替换当前页 | 回到上上一页 |
| `pushAndRemoveUntil` | 清空旧栈再压新页 | 无处可回（直接退出） |

## 6. 命名路由与 go_router

### 命名路由：给路径起名字

不想每次都手写 `MaterialPageRoute`，可以给路由起名字：

```dart
MaterialApp(
  home: const HomePage(),
  routes: {
    '/detail': (context) => const DetailPage(),
  },
)

// 跳转
Navigator.pushNamed(context, '/detail');
```

传参配合 `arguments`：

```dart
Navigator.pushNamed(context, '/detail', arguments: 1);
```

### go_router：现代路由方案

官方现在主推 `go_router`（声明式路由，路径支持参数），Day 4 只需要**认识它、知道什么时候用它**，先不用迁移过去。加依赖后大致长这样：

```yaml
dependencies:
  go_router: ^14.0.0
```

```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/detail/:id',
      builder: (context, state) => DetailPage(id: state.pathParameters['id']!),
    ),
  ],
);

// 跳转
context.go('/detail/1');
context.push('/detail/1');
```

> 建议：初学阶段先用 `Navigator` + 构造器传参把「栈」这个概念写透，等 App 页面多起来、需要深层链接或统一路由管理时再上 `go_router`。顺序别反，否则容易「会用工具但不懂原理」。

## 7. 底部 Tab：BottomNavigationBar 与 IndexedStack

底部三个 tab（首页 / 购物车 / 我的）的标准搭法：

```dart
int _currentIndex = 0;

Scaffold(
  body: IndexedStack(
    index: _currentIndex,
    children: const [HomePage(), CartPage(), ProfilePage()],
  ),
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    onTap: (index) => setState(() => _currentIndex = index),
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
      BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '购物车'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
    ],
  ),
)
```

为什么用 `IndexedStack`？这是今天自检的考点：

> 普通写法「切 tab 就换 body 里的 Widget」会让旧页面被销毁重建，输入框内容、滚动位置全丢。`IndexedStack` 把三个页面**同时挂在树上**，只是只显示 `index` 那一个——切 tab 不销毁、状态保留。

补充两个保持状态的手段：

| 手段 | 作用 |
| --- | --- |
| `IndexedStack` | 所有子页面同时存活，按 index 显示（最常用） |
| `AutomaticKeepAliveClientMixin` | 在 `ListView` 等可回收页面里保持状态 |
| `PageStorageKey` | 记住滚动位置等局部状态 |

### TabBar 与 TabBarView：顶部选项卡

顶部滑动 tab 用 `TabBar`：

```dart
DefaultTabController(
  length: 3,
  child: Scaffold(
    appBar: AppBar(
      bottom: const TabBar(
        tabs: [Tab(text: '推荐'), Tab(text: '新品'), Tab(text: '热门')],
      ),
    ),
    body: const TabBarView(
      children: [RecommendPage(), NewPage(), HotPage()],
    ),
  ),
)
```

> 区分：`BottomNavigationBar` 是「底部导航」，`TabBar` 是「顶部选项卡」。两者都是「切换页面区域」的骨架，但交互位置和滑动行为不同。

## 8. 今日最小项目：商品列表与详情页

把下面的完整代码放进 `lib/main.dart` 运行。它一次覆盖了 `push` / `pop`、构造器传参、`pop` 回传结果、`BottomNavigationBar` + `IndexedStack`。

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const ShopApp());
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

class Product {
  const Product({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final int price;
}

// 主框架：底部三个 tab，用 IndexedStack 保持各页状态
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    ProductListPage(),
    CartPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: '购物车'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
      ),
    );
  }
}

// 首页：商品列表，点击进详情
class ProductListPage extends StatelessWidget {
  const ProductListPage({super.key});

  static const List<Product> products = [
    Product(id: 1, name: '无线蓝牙耳机', price: 199),
    Product(id: 2, name: '机械键盘', price: 459),
    Product(id: 3, name: '智能手表', price: 899),
    Product(id: 4, name: '便携充电宝', price: 129),
  ];

  @override
  Widget build(BuildContext context) {
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
            onTap: () async {
              // 跳转并等待详情页带回的结果
              final result = await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailPage(product: product),
                ),
              );
              if (result != null && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${product.name} $result')),
                );
              }
            },
          );
        },
      ),
    );
  }
}

// 详情页：接收 Product，点按钮 pop 带回结果
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
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
            FilledButton(
              onPressed: () {
                Navigator.pop(context, '已加入购物车');
              },
              child: const Text('加入购物车'),
            ),
          ],
        ),
      ),
    );
  }
}

// 购物车 tab：Day 5 会接入全局状态，今天先占位
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('购物车（Day 5 接入状态管理）')),
    );
  }
}

// 我的 tab：占位
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('我的')),
    );
  }
}
```

运行后验证四件事：

1. 点列表任意一条，进详情页，确认详情页显示的是对应商品的 `id / 名称 / 价格`——这是构造器传参。
2. 点「加入购物车」，页面 `pop` 回列表，同时列表底部弹出「xx 已加入购物车」的 SnackBar——这是结果回传。
3. 在底部切「首页 / 购物车 / 我的」三个 tab，观察切换流畅、没有整页闪烁——这是 `IndexedStack`。
4. 手动给代码加一个「登录页」，把登录按钮写成 `pushReplacement` 跳首页，确认返回键不会回到登录页。

## 9. 速查表

### 今天出现的 API / Widget

| 名称 | 作用 |
| --- | --- |
| `Navigator.push` | 压入新页面（可返回） |
| `Navigator.pop` | 弹出当前页，可带返回值 |
| `Navigator.pushReplacement` | 替换当前页（常用于登录后跳首页） |
| `Navigator.pushAndRemoveUntil` | 清空路由栈后进新页 |
| `Navigator.pushNamed` | 命名路由跳转 |
| `MaterialPageRoute` | Material 转场 + iOS 边缘返回手势 |
| `BottomNavigationBar` | 底部导航栏 |
| `IndexedStack` | 同时挂载子页面、只显示 index 那个 |
| `TabBar` + `TabBarView` | 顶部选项卡 + 对应页面 |
| `DefaultTabController` | 管理 TabBar 的控制器 |

### 核心写法

| 场景 | 写法 |
| --- | --- |
| 传参 | 目标页构造函数加 `final int id`，`DetailPage(id: 1)` |
| 回传 | `Navigator.pop(context, result)`，发起方 `await Navigator.push<T>(...)` |
| 登录后去首页 | `Navigator.pushReplacement` |
| 清空历史栈 | `Navigator.pushAndRemoveUntil(..., (route) => false)` |
| 三个底部 tab | `BottomNavigationBar` + `IndexedStack` |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| 页面跳转的本质是什么？ | 路由栈：push 压栈、pop 弹栈 |
| 参数和结果怎么走？ | 参数走构造器，结果走 `pop` 的返回值 |
| tab 怎么保持状态？ | `IndexedStack` 让页面常驻不销毁 |

## 10. 今日自检

完成下面三件事，Day 4 才算通过：

- [ ] 商品列表 → 详情页，能传商品 id，点「加入购物车」能带回结果
- [ ] 用 `BottomNavigationBar` 搭出「首页 / 购物车 / 我的」三 tab 骨架
- [ ] 登录成功后用 `pushReplacement` 跳首页，返回键回不到登录页

如果你能回答下面三个问题，就可以进入 Day 5（状态管理）：

1. `push` 和 `pushReplacement` 区别是什么？
2. 路由参数怎么传、结果怎么回？
3. 底部 tab 怎么保持各页状态？

答案提示：

1. `push` 压栈可返回上一页；`pushReplacement` 把当前页替换掉，栈里不再有它，常用于「登录 → 首页」防止返回键回登录页。
2. 参数通过目标页构造函数传入（类型安全）；结果通过 `Navigator.pop(context, result)` 带回，发起方 `await Navigator.push<T>` 接收，且用前判空、用 `context.mounted` 防销毁后访问。
3. 用 `IndexedStack` 把各 tab 页面同时挂载、只切换 `index`，页面不被销毁，滚动位置和输入状态自然保留；也可以按需用 `AutomaticKeepAliveClientMixin` 或 `PageStorageKey`。
