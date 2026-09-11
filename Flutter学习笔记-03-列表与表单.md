# Flutter 学习笔记 03：列表与表单

> 适用前提：已经完成 Day 2（布局体系）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 3。
> 本笔记的目标：处理真实业务里最常见的两类界面——**长列表**和**输入表单**，并建立 Vue → Flutter 的列表/表单换算直觉。

## 目录

- [1. 从 Vue 到 Flutter：列表渲染怎么对应](#1-从-vue-到-flutter列表渲染怎么对应)
- [2. ListView 与 ListView builder：惰性构建](#2-listview-与-listview-builder惰性构建)
- [3. 下拉刷新：RefreshIndicator](#3-下拉刷新refreshindicator)
- [4. 上拉加载：分页与加载更多](#4-上拉加载分页与加载更多)
- [5. TextField：基础输入](#5-textfield基础输入)
- [6. TextFormField 与 Form：表单校验](#6-textformfield-与-form表单校验)
- [7. TextEditingController：读写输入](#7-texteditingcontroller读写输入)
- [8. 今日最小项目：商品列表与登录页](#8-今日最小项目商品列表与登录页)
- [9. 速查表](#9-速查表)
- [10. 今日自检](#10-今日自检)

## 1. 从 Vue 到 Flutter：列表渲染怎么对应

你在 Vue / uniapp 里渲染列表靠指令：

```html
<view v-for="item in list" :key="item.id">
  <text>{{ item.name }}</text>
</view>
```

Flutter 里没有 `v-for`，列表直接用 Dart 写：要么用 `ListView`，要么用 `ListView.builder`。最常用的是 `builder`：

```dart
ListView.builder(
  itemCount: list.length,
  itemBuilder: (context, index) {
    final item = list[index]; // index 就是当前是第几条
    return Text(item.name);
  },
)
```

对应关系：

| Vue / uniapp | Flutter |
| --- | --- |
| `v-for="item in list"` | `ListView.builder` 的 `itemBuilder` |
| `:key="item.id"` | 每条返回的 Widget 用 `key: ValueKey(item.id)`（多数情况可不写） |
| `v-if` / `v-else` | 三元表达式或 `if` |
| `scroll-view` 滚动容器 | `ListView` / `GridView` / `CustomScrollView` |
| 列表项组件化 | 把 `itemBuilder` 返回的内容抽成一个 `StatelessWidget` |

> 心智模型：`itemBuilder` 本质就是一个“按索引生成 Widget”的函数。`index` 从 0 开始，`list[index]` 取当前那条数据。

## 2. ListView 与 ListView builder：惰性构建

Flutter 有两种写列表的方式，区别在**什么时候构建子项**。

### 方式一：ListView(children: ...)

一次性把列表项都创建出来：

```dart
ListView(
  children: [
    Text('第 1 条'),
    Text('第 2 条'),
    Text('第 3 条'),
  ],
)
```

它适合**数量少、内容固定**的列表（比如底部菜单、几个静态选项）。但如果有 1 万条，它会一次性把 1 万个 Widget 都建出来，内存和性能都会崩。

### 方式二：ListView.builder

**只构建屏幕上看得到的那些项**，滚到哪建到哪，滚出屏幕的项会被回收。这就是“惰性构建（lazy）”。

```dart
ListView.builder(
  itemCount: 10000,
  itemBuilder: (context, index) {
    return Text('第 ${index + 1} 条');
  },
)
```

`itemBuilder` 里的 `(context, index)` 会在需要显示某一条时才被调用一次。你永远不用手动写“我总共有多少条、每条长什么样”，Flutter 只按需问你要。

| | `ListView(children: ...)` | `ListView.builder` |
| --- | --- | --- |
| 构建时机 | 一次性全建 | 按需构建可见项 |
| 适合 | 少量固定内容 | 长列表、动态数据 |
| 性能 | 数量大时变慢 | 数量再大也流畅 |

> 自检第一题就藏在这：**长列表为什么必须用 `builder`？** 因为它惰性构建，只渲染可见部分，省内存、省性能。

如果想给列表加分隔线，可以用 `separated` 变体：

```dart
ListView.separated(
  itemCount: list.length,
  itemBuilder: (context, index) => Text(list[index]),
  separatorBuilder: (context, index) => const Divider(), // 每两条之间一条分隔线
)
```

## 3. 下拉刷新：RefreshIndicator

`RefreshIndicator` 是 Material 自带的下拉刷新组件。你只要把可滚动的 `ListView` 包进去，再给它一个 `onRefresh` 回调：

```dart
Future<void> _refresh() async {
  // 模拟请求 1 秒
  await Future.delayed(const Duration(seconds: 1));
  setState(() {
    // 重新拉取 / 重置数据
  });
}

RefreshIndicator(
  onRefresh: _refresh,
  child: ListView.builder(
    itemCount: list.length,
    itemBuilder: (context, index) => Text(list[index]),
  ),
)
```

三个关键点：

1. `onRefresh` 必须返回一个 `Future`，并且**等这个 Future 完成，转圈才消失**。所以别只写 `onRefresh: () {}`，要返回一个真正异步的任务。
2. `RefreshIndicator` 的 child 必须**可滚动**（通常是 `ListView` / `GridView`）。如果内容不满一屏无法滚动，需要给 `ListView` 加 `physics: AlwaysScrollableScrollPhysics()`，否则拉不动。
3. 下拉刷新的语义是“重置回第一页”，加载更多是另一个方向（下面讲），两者别混在一起。

## 4. 上拉加载：分页与加载更多

下拉刷新是“往下拉”，上拉加载是“滚到底部再继续取下一页”。实现的核心是**监听滚动位置**。

用 `ScrollController` 监听：

```dart
final ScrollController _controller = ScrollController();

@override
void initState() {
  super.initState();
  _controller.addListener(_onScroll);
}

void _onScroll() {
  // 当前位置 >= 最大滚动距离 - 200 时，认为快到底了
  if (_controller.position.pixels >=
      _controller.position.maxScrollExtent - 200) {
    _loadMore();
  }
}

@override
void dispose() {
  _controller.dispose(); // 一定要释放，避免内存泄漏
  super.dispose();
}
```

然后把这个 controller 传给 `ListView.builder(controller: _controller, ...)`。

`_loadMore` 里通常要做三件事：加锁防止重复触发、追加下一页数据、更新列表：

```dart
bool _loading = false;

void _loadMore() {
  if (_loading || _products.length >= _allProducts.length) return;
  setState(() => _loading = true);

  Future.delayed(const Duration(milliseconds: 500), () {
    if (!mounted) return; // 防止页面销毁后还 setState
    setState(() {
      // 追加数据
      _loading = false;
    });
  });
}
```

一个常见的组合套路：

> **下拉刷新 = 清空重置回第一页；上拉加载 = 在现有数据末尾追加下一页。** 用 `_loading` 锁防止“还没加载完又触发下一次”。

## 5. TextField：基础输入

`TextField` 对应 `<input type="text">`。最常用的参数：

```dart
TextField(
  controller: _controller,          // 读写输入内容（下一节讲）
  keyboardType: TextInputType.emailAddress, // 键盘类型
  obscureText: true,                // 密码：输入显示为 ••••
  maxLines: 1,                      // 行数
  onChanged: (text) { ... },        // 每输入一个字符都触发
  onSubmitted: (text) { ... },      // 按回车触发
  decoration: const InputDecoration(
    labelText: '邮箱',               // 浮动标签
    hintText: '请输入邮箱',          // 占位提示
    prefixIcon: Icon(Icons.email),  // 左边图标
    border: OutlineInputBorder(),    // 边框
  ),
)
```

常用 `keyboardType`：

| 取值 | 用途 |
| --- | --- |
| `TextInputType.text` | 普通文本（默认） |
| `TextInputType.number` | 数字键盘 |
| `TextInputType.phone` | 电话号码 |
| `TextInputType.emailAddress` | 邮箱 |
| `TextInputType.multiline` | 多行文本 |

对应 Vue 的 `type="password"` → `obscureText: true`；`type="number"` → `keyboardType: TextInputType.number`。

## 6. TextFormField 与 Form：表单校验

如果只是展示输入框，`TextField` 就够。但要做**校验**（“邮箱不能为空”“密码至少 6 位”），就用 `Form` + `TextFormField`。

`TextFormField` 可以理解成“自带校验能力的 `TextField`”。把它放进 `Form`，再给 `Form` 一个 `key`，就能统一触发校验。

```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        decoration: const InputDecoration(labelText: '邮箱'),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '请输入邮箱';
          }
          if (!value.contains('@')) {
            return '邮箱格式不正确';
          }
          return null; // null = 校验通过
        },
      ),
      ElevatedButton(
        onPressed: _submit,
        child: const Text('登录'),
      ),
    ],
  ),
)
```

`validator` 的返回值决定了校验结果：

| 返回 | 含义 |
| --- | --- |
| `null` | 校验通过 |
| 非空字符串 | 校验失败，该字符串会显示在输入框下方 |

提交时统一触发校验：

```dart
void _submit() {
  if (_formKey.currentState!.validate()) {
    // 所有字段都通过，执行提交
  }
}
```

### key 的作用

`GlobalKey<FormState>` 是一个“句柄”，让你从 `Form` 这个 Widget 外部拿到它内部的 `FormState`，从而调用 `validate()` / `reset()`。这就是为什么 `Form` 需要一个 `key`——没有它，你无法“远程遥控”这整张表单。

如果想让校验在用户**输入时就即时提示**，而不是等点提交才校验，可以给 `Form` 加：

```dart
Form(
  key: _formKey,
  autovalidateMode: AutovalidateMode.onUserInteraction,
  ...
)
```

## 7. TextEditingController：读写输入

`TextField` 自己不存“你输入了什么”，真正存内容的是 `TextEditingController`。它对应 Vue 里的 `v-model`：

| Vue | Flutter |
| --- | --- |
| `v-model="email"` | `TextEditingController` |
| 读 `this.email` | `_controller.text` |
| 设初始值 `email = 'x'` | `_controller.text = 'x'` |
| 清空 `email = ''` | `_controller.clear()` |

```dart
final _controller = TextEditingController();

// 设初始值
_controller.text = 'abc@example.com';

// 读输入值
final value = _controller.text;

// 监听变化
_controller.addListener(() {
  print(_controller.text);
});

// 用完释放（重要）
@override
void dispose() {
  _controller.dispose();
  super.dispose();
}
```

> 两个容易踩的坑：`TextEditingController` 用完后要在 `dispose` 里释放，否则内存泄漏；`TextFormField` 和 `TextField` 都可以传 `controller`，但同一个 controller 不要同时给两个输入框用。

## 8. 今日最小项目：商品列表与登录页

Day 3 有两个产出物，分别贴进 `lib/main.dart` 运行。

### 产出物 1：商品列表（含下拉刷新 + 上拉加载）

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const ListDemoApp());
}

class ListDemoApp extends StatelessWidget {
  const ListDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '商品列表',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}

class Product {
  const Product({required this.id, required this.name, required this.price});

  final int id;
  final String name;
  final int price;
}

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  // 模拟“服务端全量数据”，每次只展示前 10 条
  final List<Product> _allProducts = List.generate(
    50,
    (i) => Product(id: i + 1, name: '商品 ${i + 1}', price: 100 + i * 10),
  );

  List<Product> _products = [];
  bool _loading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _products = _allProducts.take(10).toList();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _products = _allProducts.take(10).toList();
    });
  }

  void _loadMore() {
    if (_loading || _products.length >= _allProducts.length) return;
    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        final next = _products.length + 10;
        _products = _allProducts.take(next).toList();
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('商品列表')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          controller: _scrollController,
          itemCount: _products.length + (_loading ? 1 : 0),
          itemBuilder: (context, index) {
            // 最后一条是“加载中”的占位
            if (index >= _products.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final product = _products[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
              title: Text(product.name),
              subtitle: Text('¥${product.price}'),
              trailing: const Icon(Icons.chevron_right),
            );
          },
        ),
      ),
    );
  }
}
```

运行后验证三件事：

1. 往下滚到底，观察列表自动“追加”更多商品，底部出现转圈。
2. 在顶部下拉，观察刷新圈消失后列表重置回前 10 条。
3. 把 `ListView.builder` 临时改成 `ListView(children: [...])`，体会“一次性全建”和“惰性构建”的区别。

### 产出物 2：登录页（含校验）

```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const LoginDemoApp());
}

class LoginDemoApp extends StatelessWidget {
  const LoginDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '登录',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  void _submit() {
    if (_formKey.currentState!.validate()) {
      debugPrint('邮箱: ${_emailController.text}');
      debugPrint('密码: ${_passwordController.text}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('校验通过，提交成功')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: '邮箱',
                  hintText: '请输入邮箱',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入邮箱';
                  }
                  if (!value.contains('@')) {
                    return '邮箱格式不正确';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入密码',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscure = !_obscure);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  if (value.length < 6) {
                    return '密码至少 6 位';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submit,
                child: const Text('登录'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

运行后验证：

1. 邮箱、密码都不填直接点登录，观察两个输入框下方出现错误提示。
2. 邮箱填 `abc`（不带 @），密码填 5 位，分别触发对应校验。
3. 全部填对后点登录，看控制台 `debugPrint` 是否打印出你输入的内容，并弹出 SnackBar。

## 9. 速查表

### 今天出现的 Widget / 类

| Widget / 类 | 作用 |
| --- | --- |
| `ListView` / `ListView.builder` | 普通列表 / 惰性构建长列表 |
| `ListView.separated` | 带分隔线的列表 |
| `RefreshIndicator` | 下拉刷新 |
| `ScrollController` | 监听滚动位置，实现上拉加载 |
| `TextField` | 基础输入框 |
| `TextFormField` | 带校验的输入框 |
| `Form` | 表单容器，统一触发校验 |
| `GlobalKey<FormState>` | 从外部访问表单状态 |
| `TextEditingController` | 读写输入内容 |
| `SnackBar` | 底部轻提示（顺带认识） |

### 核心属性

| 属性 | 用在 | 作用 |
| --- | --- | --- |
| `itemCount` | ListView.builder | 列表总条数 |
| `itemBuilder` | ListView.builder | 按索引生成每条 Widget |
| `onRefresh` | RefreshIndicator | 下拉刷新回调，返回 Future |
| `onChanged` | TextField | 输入时触发 |
| `validator` | TextFormField | 校验，返回 null 通过 / 字符串报错 |
| `obscureText` | TextField | 密码显示为 •••• |
| `keyboardType` | TextField | 键盘类型 |
| `autovalidateMode` | Form | 何时自动校验 |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| 长列表为什么用 builder？ | 惰性构建，只渲染可见项，省内存 |
| 校验失败提示放哪？ | `validator` 返回的字符串显示在输入框下方 |
| 下拉刷新和上拉加载怎么组合？ | 下拉重置回第一页，上拉追加下一页，用锁防止重复 |

## 10. 今日自检

完成下面三件事，Day 3 才算通过：

- [ ] 能用 `ListView.builder` 渲染一份本地数据，并加下拉刷新 + 上拉加载
- [ ] 能写出一个含邮箱、密码校验的登录表单
- [ ] 提交时能把表单数据打印出来，验证校验逻辑

如果你能回答下面三个问题，就可以进入 Day 4（路由与页面组织）：

1. 长列表为什么用 `ListView.builder` 而不是 `ListView(children: [...])`？
2. 表单校验失败时，错误提示放在哪里？
3. 下拉刷新和上拉加载怎么组合才不打架？

答案提示：

1. `builder` 惰性构建，只构建屏幕上可见的项，滚动时按需创建并回收，数据量再大也流畅；`children` 会一次性全部构建。
2. `validator` 返回的非空字符串会显示在对应输入框下方（由 `InputDecoration` 的 `errorText` 呈现），返回 `null` 表示通过。
3. 下拉刷新重置回第一页、上拉加载在末尾追加下一页；用 `_loading` 锁防重复触发，并监听 `ScrollController` 判断是否接近底部。
