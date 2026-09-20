# Flutter 学习笔记 06：网络请求

> 适用前提：已经完成 Day 5（状态管理）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 6。
> 本笔记的目标：把本地假数据换成真实 API，用 `dio` 封装请求与拦截器，把 JSON 转成模型，并让界面把「加载中 / 成功 / 失败 / 空」四种状态各就各位。

## 目录

- [1. 从 Vue 到 Flutter：请求怎么对应](#1-从-vue-到-flutter请求怎么对应)
- [2. dio 与 http 怎么选](#2-dio-与-http-怎么选)
- [3. 最小请求：GET 一个商品列表](#3-最小请求get-一个商品列表)
- [4. JSON 转模型：手写 fromJson](#4-json-转模型手写-fromjson)
- [5. 拦截器：统一 Token、日志、错误](#5-拦截器统一-token日志错误)
- [6. 异步 UI 三态：FutureBuilder](#6-异步-ui-三态futurebuilder)
- [7. 配合 Riverpod：AsyncValue](#7-配合-riverpodasyncvalue)
- [8. 今日最小项目：真实 API 商品列表](#8-今日最小项目真实-api-商品列表)
- [9. 速查表](#9-速查表)
- [10. 今日自检](#10-今日自检)

## 1. 从 Vue 到 Flutter：请求怎么对应

你在 Vue / uniapp 里请求接口，套路是固定的：封装一个 `request`，`await` 拿数据，再 `try/catch` 兜错。

```js
const res = await axios.get('/products', { params: { limit: 10 } })
console.log(res.data.products)
```

Flutter 里这套东西几乎一一对应，只是换了库名和 API 名字：

| axios / uni.request | Flutter + dio |
| --- | --- |
| `axios.create({ baseURL })` | `Dio(BaseOptions(baseUrl: ...))` |
| `axios.get(url, { params })` | `dio.get(url, queryParameters: {...})` |
| `res.data` | `response.data` |
| 请求拦截器 | `InterceptorsWrapper` / `Interceptor.onRequest` |
| 响应拦截器 | `Interceptor.onResponse` |
| `catch (e)` | `catch (e)`，错误类型是 `DioException` |
| `JSON.parse(res.data)` | **自动做掉了**，`response.data` 直接是 `Map`/`List` |
| 手写 `loading = true` | `FutureBuilder` / `AsyncValue` 三态 |

最后一行是今天最需要建立的直觉：

> 心智模型：**一次网络请求，本质是一份异步状态**。它不只有「有数据」一种结果，而是「进行中 / 成功 / 失败（还能细分空数据）」四种界面。所以 Day 1 的 `UI = f(state)` 依然成立——只是这里的 state 多了一份「请求状态」。

## 2. dio 与 http 怎么选

Flutter 有两个主流选择：

| | `http` | `dio` |
| --- | --- | --- |
| 定位 | 官方维护的最小 HTTP 客户端 | 社区维护的功能完整客户端 |
| 拦截器 | ❌ 要自己包一层 | ✅ 内置 |
| 超时配置 | 要自己写 `.timeout()` | `BaseOptions` 一行配好 |
| 取消请求 | ❌ | `CancelToken` |
| 表单 / 文件上传 | 手写 MultipartRequest | `FormData` 开箱可用 |
| 自动 JSON 解码 | ❌ 拿到的是字符串 | ✅ 默认解码成 `Map`/`List` |

> 结论：**业务项目直接用 `dio`**。`http` 更适合「只调一个接口、不想引依赖」的极简场景。后面的刷新 Token、统一错误提示、统一 Loading 都靠拦截器实现，这是 `http` 给不了的。

加依赖：

```bash
flutter pub add dio
```

或者在 `pubspec.yaml` 里写（版本以 [pub.dev](https://pub.dev/packages/dio) 最新为准）：

```yaml
dependencies:
  dio: ^5.11.1  # 本笔记撰写时的最新版，以 pub.dev 为准
```

## 3. 最小请求：GET 一个商品列表

```dart
import 'package:dio/dio.dart';

// 1. 创建一个 Dio 实例，baseUrl 只写一次
final dio = Dio(
  BaseOptions(
    baseUrl: 'https://dummyjson.com',
    connectTimeout: const Duration(seconds: 10), // 连上服务器的时间
    receiveTimeout: const Duration(seconds: 10), // 等服务器返回的时间
  ),
);

Future<void> fetchDemo() async {
  // 2. 发请求：/products?limit=10
  final response = await dio.get('/products', queryParameters: {'limit': 10});

  // 3. response.data 已经自动 JSON 解码过了
  final data = response.data as Map<String, dynamic>;
  final list = data['products'] as List;
  print('共 ${data['total']} 条，本次拿到 ${list.length} 条');
  print(list.first); // {id: 1, title: Essence Mascara..., price: 9.99, ...}
}
```

三个必须记住的点：

1. `baseUrl` 里**不要**以 `/` 结尾，请求路径里以 `/` 开头，dio 会正确拼接。
2. `response.data` 的类型跟着返回的 JSON 走：

| 返回的 JSON | `response.data` 实际类型 |
| --- | --- |
| `{ "products": [...] }` | `Map<String, dynamic>` |
| `[1, 2, 3]` | `List<dynamic>` |
| 纯文本 / HTML | `String` |

3. 请求失败**不会**返回一个「错误响应」，而是**抛异常**（`DioException`）。所以要么 `try/catch`，要么交给上层的三态 UI 接住——这也是为什么下一节要先把错误分类说清楚。

```dart
try {
  final response = await dio.get('/products/99999'); // 这个 id 不存在
  print(response.data);
} on DioException catch (e) {
  print(e.type);                    // DioExceptionType.badResponse
  print(e.response?.statusCode);    // 404
  print(e.response?.data);          // {message: Product with id '99999' not found}
}
```

## 4. JSON 转模型：手写 fromJson

### 为什么一定要有模型类

直接用 `Map<String, dynamic>` 也能写界面，但会立刻遇到三个问题：

```dart
// ❌ 全靠字符串 key，写错一个字母要运行时才发现
Text(product['titel'].toString())
// ❌ 类型不确定，全靠 as / toString 硬转
double price = product['price'] as double
// ❌ 字段改名时，全项目搜索字符串
```

换成模型类之后：

```dart
// ✅ 写错编译期就报错，编辑器还能自动补全
Text(product.title)
// ✅ 类型明确，price 就是 double
Text('¥${product.price}')
// ✅ 字段改名只改一处，编译器告诉你哪里要跟着改
```

> 一句话：**模型类是 JSON 和 UI 之间的类型防火墙**。把「不确定的 Map」在边界处一次性转成「确定的 Dart 对象」，之后整个 App 内部都是类型安全的。

### 模型类怎么写

```dart
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.description,
  });

  final int id;
  final String title;
  final double price;
  final String thumbnail;
  final String description;

  // 工厂构造：从 JSON 造一个 Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      // 关键：JSON 里的 549 是 int，549.99 才是 double。
      // 直接写 `as double` 遇到整数价格就会崩，必须先当 num 再转。
      price: (json['price'] as num).toDouble(),
      // 可能缺字段的，用可空转换 + 默认值兜底，别硬断言
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  // 需要往服务器提交时才用得上（今天用不到，但成对写是好习惯）
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'thumbnail': thumbnail,
        'description': description,
      };
}
```

三个高频坑：

| 坑 | 现象 | 正确写法 |
| --- | --- | --- |
| 整数价格 | `type 'int' is not a subtype of type 'double'` | `(json['price'] as num).toDouble()` |
| 字段可能为 null | `type 'Null' is not a subtype of type 'String'` | `json['brand'] as String? ?? '未知'` |
| 嵌套对象 | 手写一长串 `as Map<String, dynamic>` | 嵌套类也写自己的 `fromJson`，逐层转 |

### 列表怎么转

服务器返回的是「一个对象里包着数组」，所以分两步：先取出数组，再逐个转模型。

```dart
final data = response.data as Map<String, dynamic>;   // { products: [...], total: 194, ... }
final products = (data['products'] as List)          // 先拿 List
    .map((e) => Product.fromJson(e as Map<String, dynamic>))  // 逐个转模型
    .toList();                                        // 转成 List<Product>
```

### 手写 vs 代码生成

`fromJson` 全是机械劳动，字段一多就想偷懒。两种做法：

| | 手写 `fromJson` | `json_serializable` + `build_runner` |
| --- | --- | --- |
| 工作量 | 字段多时很烦 | 写个空类 + 注解，跑命令生成 |
| 理解成本 | 完全透明，看得到每一步 | 要懂注解和生成流程 |
| 出错风险 | 手滑写错字段名 | 生成的代码不会错 |
| 适合 | **学习期、字段少的模型** | 字段多、模型多、长期维护的项目 |

> 建议：**先用今天这套手写方式吃透「JSON → 模型」这件事**，等字段多到受不了了再上代码生成。和 Day 5「先 setState 再 Riverpod」是同一个思路——先懂原理，再用工具省事。

## 5. 拦截器：统一 Token、日志、错误

拦截器是 dio 最值钱的部分。它的位置在「请求发出前」和「响应回来后」，所有请求都会经过它：

```
发请求 ──▶ onRequest（加 Token、打印日志）──▶ 服务器
                                              │
界面 ◀── onResponse（统一处理数据）◀──────────┤
       ◀── onError（统一处理错误）◀───────────┘
```

### 三个回调 + 一个铁的规则

```dart
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('→ ${options.method} ${options.uri}');
    handler.next(options); // 放行，交给下一个拦截器
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✗ ${err.response?.statusCode} ${err.requestOptions.uri}');
    handler.next(err);
  }
}

dio.interceptors.add(LoggingInterceptor());
```

> ⚠️ 最容易踩的坑：**忘了调 `handler.next(...)`，这个请求就永远卡住了**。拦截器的回调不会自动往下走，必须自己放行。

三个 handler 方法的分工：

| 方法 | 作用 |
| --- | --- |
| `handler.next(x)` | 放行，继续走后面的流程 |
| `handler.reject(err)` | 中断请求，按错误处理 |
| `handler.resolve(response)` | 中断请求，直接返回一个「成功响应」（常用于缓存 / mock） |

dio 还内置 `LogInterceptor`，一行就能打印完整日志（含请求头、响应体）：

```dart
dio.interceptors.add(LogInterceptor());
```

注意把它注册在**最后一个**，才能把前面拦截器对请求的修改（比如刚加上的 Token 头）也打出来。

### 统一加 Token

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final TokenStore _tokenStore;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenStore.token;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
```

好处：**业务代码里再也不用手写 Token**，登录后拿到 Token 存进 `TokenStore`，之后所有请求自动带上。Day 7 会把 `TokenStore` 换成 `shared_preferences` 持久化版本。

### 统一处理 401

```dart
class AuthInterceptor extends Interceptor {
  // ... onRequest 同上

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token 过期：清掉本地登录态，踢回登录页
      _tokenStore.clear();
      navigatorKey.currentState
          ?.pushNamedAndRemoveUntil('/login', (route) => false);
    }
    handler.next(err); // 处理完还要放行，让界面也能感知到这次失败
  }
}
```

两个细节：

1. **拦截器里没有页面的 `context`**，不能 `Navigator.of(context)`。要用一个全局 `navigatorKey`：

   ```dart
   final navigatorKey = GlobalKey<NavigatorState>();

   // MaterialApp(navigatorKey: navigatorKey, ...)
   ```

2. 401 要和「跳登录」配套。如果只清 Token 不跳转，用户会停在一个永远加载失败的页面上，不知道发生了什么。

> 进阶：如果要在 401 之后「拿 refreshToken 换新 Token，再自动重发原请求」，把 `Interceptor` 换成 `QueuedInterceptor`。它会排队，保证同一时刻只有一个请求在处理，避免一堆并发请求同时去刷新 Token。

### 统一 Loading：要不要在拦截器里做？

第四个横切关注点是全局 Loading。原理是用一个「进行中的请求数」计数器：`onRequest` +1 并弹遮罩，`onResponse` / `onError` -1，归零时收起。因为拦截器里没有 `context`，弹窗同样要走全局 `navigatorKey`：

```dart
int _pending = 0; // 进行中的请求数

void _showLoading() {
  if (_pending++ == 0) {
    // 用 navigatorKey 弹一个不可点穿的遮罩
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }
}

void _hideLoading() {
  if (--_pending <= 0) {
    Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
  }
}
```

但学习期不建议真的做：它和 `FutureBuilder` / `AsyncValue` 的页面级 Loading 会打架（页面转圈 + 全局遮罩一起出）。真实项目通常只对「没有页面级 Loading 的接口」开全局遮罩，或者干脆全部用页面级三态。理解「计数 + navigatorKey」这个原理即可。

### 把异常翻译成人话

`DioException` 的类型对用户没意义，界面要的是能直接显示的文案：

```dart
String friendlyMessage(Object error) {
  if (error is! DioException) return '出了点小问题：$error';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '网络超时，请稍后重试';
    case DioExceptionType.connectionError:
      return '连不上服务器，请检查网络';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 401) return '登录已过期，请重新登录';
      if (code == 404) return '请求的内容不存在';
      return '服务器出错了（$code）';
    case DioExceptionType.cancel:
      return '请求已取消';
    default:
      return '请求失败，请稍后重试';
  }
}
```

先认清 `e.type` 分哪些情况：

| `e.type` | 含义 | 典型原因 |
| --- | --- | --- |
| `connectionTimeout` | 连接超时 | 服务器地址不通、网络慢 |
| `sendTimeout` / `receiveTimeout` | 发送 / 接收超时 | 接口太慢 |
| `badResponse` | 服务器回了错误状态码 | 4xx / 5xx |
| `cancel` | 请求被取消 | 主动调了 `CancelToken` |
| `connectionError` | 网络层错误 | 没网、断网 |
| `unknown` | 其他 | 兜底 |

`badResponse` 再按状态码细分：

| 状态码 | 含义 | 处理 |
| --- | --- | --- |
| 400 | 请求参数错 | 提示参数错误 |
| 401 | 未登录 / 登录过期 | 清 Token，跳登录页 |
| 403 | 无权限 | 提示无权限 |
| 404 | 资源不存在 | 提示不存在 |
| 500 | 服务器内部错 | 提示稍后再试 |

进阶：文案一多，可以把这段翻译包成一个 `ApiException` 类，页面只认「人话 + 状态码」两个字段，错误语义更内聚：

```dart
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  static ApiException from(DioException e) => ApiException(
        friendlyMessage(e),
        statusCode: e.response?.statusCode,
      );
}
```

> 这一层的作用：**把「技术错误」翻译成「用户能懂的提示」，并且只写一次**。所有页面失败时都调它，文案和分类天然统一。

## 6. 异步 UI 三态：FutureBuilder

`FutureBuilder` 是 Flutter 内置的「等一个 `Future` 完成并渲染结果」的组件。它把异步状态抽象成 `snapshot`：

| `snapshot` | 含义 |
| --- | --- |
| `snapshot.connectionState` | `waiting`（进行中）/ `done`（结束） |
| `snapshot.hasError` | 失败了，错误在 `snapshot.error` |
| `snapshot.data` | 成功了，数据在这里（可能为 null） |

```dart
Future<String> loadSlogan() async {
  await Future.delayed(const Duration(seconds: 1));
  throw Exception('服务器开小差了'); // 试着重试时把它注释掉
}

class FutureBuilderDemo extends StatefulWidget {
  const FutureBuilderDemo({super.key});

  @override
  State<FutureBuilderDemo> createState() => _FutureBuilderDemoState();
}

class _FutureBuilderDemoState extends State<FutureBuilderDemo> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = loadSlogan(); // 只在初始化时发起一次
  }

  void _retry() => setState(() => _future = loadSlogan()); // 换一个 Future = 重新请求

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _future,
      builder: (context, snapshot) {
        // ① 加载中
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        // ② 失败
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('出错了：${snapshot.error}'),
                const SizedBox(height: 12),
                FilledButton(onPressed: _retry, child: const Text('重试')),
              ],
            ),
          );
        }
        // ③ 成功（data 可能为 null，仍要判）
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        return Center(child: Text(data));
      },
    );
  }
}
```

必背的坑：

> ❌ `FutureBuilder(future: loadSlogan(), ...)` —— 把请求直接写在 `build` 里。
> `build` 会因为任何原因重建（输入框打字、父组件刷新、切主题），**每重建一次就重新发一次请求**。正确做法是存在 `State` 字段里（如上），或直接用下一节的 `AsyncValue`。

这一点和 Day 1 的结论是同一条：**状态不能被 `build` 创建**，`build` 只负责把状态画出来。

## 7. 配合 Riverpod：AsyncValue

`FutureBuilder` 能用，但缺点是「每个页面都要自己写一遍三态 + 自己管 Future 的生命周期」。Day 5 你已经上了 Riverpod，它把这件事内置了：`FutureProvider` 管请求，`AsyncValue` 管三态。

```dart
// 请求 + 三态，全在这一句里
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(productApiProvider);
  return api.fetchProducts();
});
```

界面里 `ref.watch` 拿到的就是 `AsyncValue`，用 `when` 把三态一次性写完：

```dart
final productsAsync = ref.watch(productsProvider);

return productsAsync.when(
  data: (products) => products.isEmpty
      ? const Center(child: Text('暂无商品'))
      : ListView.builder(...),
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (error, stack) => ErrorView(
    message: friendlyMessage(error),
    onRetry: () => ref.invalidate(productsProvider), // 重试 = 让 Provider 重新执行
  ),
);
```

和 `FutureBuilder` 一一对应：

| FutureBuilder | AsyncValue |
| --- | --- |
| `snapshot.connectionState == waiting` | `loading`（`when` 的第一个分支） |
| `snapshot.hasError` | `error` |
| `snapshot.data` | `data` |
| 空数据要自己在 `data` 里判 `isEmpty` | 一样，在 `data` 分支里判 |
| 手动 `initState` 建 Future、存字段里 | `FutureProvider` 自动管 |
| `setState(() => _future = ...)` 重试 | `ref.invalidate(provider)` 重试 |

> 心智模型：`FutureProvider` **把「一次请求」也变成了一份可订阅的状态**。所以「加载中 / 失败 / 成功」能像购物车数量一样，被任意页面订阅、被统一刷新——这正是 Day 5 那句「唯一数据源 + 订阅通知」的延伸。

再补三个常用写法：

```dart
// 下拉刷新：等新数据真的回来了再收起转圈
RefreshIndicator(
  onRefresh: () => ref.refresh(productsProvider.future),
  child: ...,
)

// 只想拿数据、不需要三态 UI（数据还没来就用旧值/默认值）
final products = ref.watch(productsProvider).valueOrNull ?? const [];

// 只关心「是否在加载」（比如按钮转圈）
final isLoading = ref.watch(productsProvider).isLoading;
```

## 8. 今日最小项目：真实 API 商品列表

把 Day 5 的本地假数据换成 DummyJSON 的真接口，并复用 Day 5 的购物车。这一段覆盖总纲里的四个动手任务：`dio` 请求商品接口、JSON 转 `Product` 模型、加载中/成功/失败三态、拦截器打印日志与统一处理 401。

`pubspec.yaml`：

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^3.0.0
  dio: ^5.11.1
```

`lib/main.dart` 完整代码：

```dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ShopApp()));
}

// ---------- 全局导航 key：给拦截器跳登录页用（拦截器里没有 context） ----------
final navigatorKey = GlobalKey<NavigatorState>();

// ---------- 日志拦截器：打印每个请求和响应 ----------
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    handler.next(options); // 别忘了放行，否则请求会一直卡住
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final code = err.response?.statusCode;
    debugPrint('✗ $code ${err.requestOptions.uri}');
    if (code == 401) {
      // 统一处理登录过期：真实项目里这里会清 Token + 跳登录页
      debugPrint('登录已过期，需要重新登录');
    }
    handler.next(err); // 处理完照样放行，让界面感知失败
  }
}

// ---------- 网络层：一个 Dio 实例 + 拦截器 ----------
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(LoggingInterceptor());
  return dio;
});

// ---------- 模型：JSON -> Product ----------
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
    required this.description,
  });

  final int id;
  final String title;
  final double price;
  final String thumbnail;
  final String description;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      title: json['title'] as String,
      // 整数价格在 JSON 里是 int，必须先按 num 转，否则 `as double` 会崩
      price: (json['price'] as num).toDouble(),
      thumbnail: json['thumbnail'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }
}

// ---------- API：业务代码只面对模型，不碰 Map ----------
class ProductApi {
  ProductApi(this._dio);

  final Dio _dio;

  /// GET /products?limit=20&skip=0
  Future<List<Product>> fetchProducts({int limit = 20, int skip = 0}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products',
      queryParameters: {'limit': limit, 'skip': skip},
    );
    return (response.data!['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /products/search?q=xxx
  Future<List<Product>> search(String keyword) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/products/search',
      queryParameters: {'q': keyword},
    );
    return (response.data!['products'] as List)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productApiProvider = Provider<ProductApi>(
  (ref) => ProductApi(ref.watch(dioProvider)),
);

// ---------- 异步状态：请求本身就是一份可订阅的状态 ----------
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final api = ref.watch(productApiProvider);
  return api.fetchProducts();
});

// ---------- 错误文案：技术错误 -> 人话 ----------
String friendlyMessage(Object error) {
  if (error is! DioException) return '出了点小问题：$error';

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return '网络超时，请稍后重试';
    case DioExceptionType.connectionError:
      return '连不上服务器，请检查网络';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      if (code == 401) return '登录已过期，请重新登录';
      if (code == 404) return '请求的内容不存在';
      return '服务器出错了（$code）';
    default:
      return '请求失败，请稍后重试';
  }
}

// ---------- 购物车（沿用 Day 5，注意这里存的是商品快照） ----------
class CartItem {
  const CartItem({required this.product, required this.count});

  final Product product;
  final int count;
}

final cartProvider =
    NotifierProvider<CartNotifier, Map<int, CartItem>>(CartNotifier.new);

class CartNotifier extends Notifier<Map<int, CartItem>> {
  @override
  Map<int, CartItem> build() => {};

  void add(Product product) {
    final current = state[product.id];
    state = {
      ...state,
      product.id: CartItem(product: product, count: (current?.count ?? 0) + 1),
    };
  }

  void remove(int productId) {
    final current = state[productId];
    if (current == null) return;
    final next = {...state};
    if (current.count <= 1) {
      next.remove(productId);
    } else {
      next[productId] = CartItem(product: current.product, count: current.count - 1);
    }
    state = next;
  }

  void clear() => state = {};
}

// ---------- App 骨架 ----------
class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
    final totalCount = cart.values.fold(0, (sum, item) => sum + item.count);

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

// ---------- 商品列表：三态 + 下拉刷新 ----------
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('商品列表（真实接口）'),
        actions: [
          IconButton(
            tooltip: '用一个错误 Token 触发 401，观察拦截器日志',
            icon: const Icon(Icons.key_off),
            onPressed: () async {
              try {
                await ref.read(dioProvider).get(
                      '/auth/me',
                      options: Options(
                        headers: {'Authorization': 'Bearer bad-token'},
                      ),
                    );
              } on DioException {
                // 拦截器已打印 401 日志，这里让错误自然结束
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        // 等新数据真的回来了再收起转圈
        onRefresh: () => ref.refresh(productsProvider.future),
        child: productsAsync.when(
          // ① 加载中
          loading: () => const Center(child: CircularProgressIndicator()),
          // ② 失败：给文案 + 重试按钮
          error: (error, stack) => ListView(
            // 失败态也要能下拉刷新，所以用可滚动组件包一层
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.cloud_off, size: 56, color: Colors.grey),
              const SizedBox(height: 16),
              Center(child: Text(friendlyMessage(error))),
              const SizedBox(height: 16),
              Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(productsProvider),
                  child: const Text('重试'),
                ),
              ),
            ],
          ),
          // ③ 成功：先判空，再渲染列表
          data: (products) {
            if (products.isEmpty) {
              // 空态同样用可滚动组件包一层，否则下拉刷新会失效
              return ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('暂无商品')),
                ],
              );
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ListTile(
                  leading: ProductThumb(url: product.thumbnail),
                  title: Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('¥${product.price.toStringAsFixed(2)}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailPage(product: product),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// 网络图片：加载中和失败都要有交代
class ProductThumb extends StatelessWidget {
  const ProductThumb({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const SizedBox(
                width: 56,
                height: 56,
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
        errorBuilder: (context, error, stack) => const SizedBox(
          width: 56,
          height: 56,
          child: Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }
}

// ---------- 详情页 ----------
class DetailPage extends ConsumerWidget {
  const DetailPage({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text(product.title, maxLines: 1)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              product.thumbnail,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.image_not_supported,
                size: 64,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            product.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${product.price.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.red, fontSize: 22),
          ),
          const SizedBox(height: 16),
          Text(product.description),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref.read(cartProvider.notifier).add(product);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('已加入购物车'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('加入购物车'),
          ),
        ],
      ),
    );
  }
}

// ---------- 购物车 ----------
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final items = cart.values.toList();
    final totalCount = items.fold(0, (sum, item) => sum + item.count);
    final totalPrice =
        items.fold<double>(0, (sum, item) => sum + item.product.price * item.count);

    return Scaffold(
      appBar: AppBar(title: const Text('购物车')),
      body: items.isEmpty
          ? const Center(child: Text('购物车是空的'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        leading: ProductThumb(url: item.product.thumbnail),
                        title: Text(
                          item.product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '¥${item.product.price.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .remove(item.product.id),
                            ),
                            Text('${item.count}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () =>
                                  ref.read(cartProvider.notifier).add(item.product),
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
                        Expanded(
                          child: Text('共 $totalCount 件，合计 ¥${totalPrice.toStringAsFixed(2)}'),
                        ),
                        FilledButton(
                          onPressed: () {
                            ref.read(cartProvider.notifier).clear();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已清空购物车')),
                            );
                          },
                          child: const Text('清空'),
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
```

运行后验证五件事：

1. 启动时先看到转圈，随即列表出现真实商品（图 + 标题 + 价格）——三态里的「加载中 → 成功」。
2. 打开终端，能看到每一条 `→ GET https://dummyjson.com/products?...` 和 `← 200 ...`，这就是拦截器的日志。
3. 把 `baseUrl` 改成 `https://dummyjson.com-wrong`，热重载：列表变成「连不上服务器，请检查网络」+ 重试按钮——三态里的「失败」。
4. 下拉刷新有转圈；点进详情、加入购物车，回列表看角标 +1，进购物车看数量和合计——网络层换了，购物车状态依然跨页共享。
5. 点右上角钥匙图标：向 `/auth/me` 发一个错误 Token，控制台出现 `✗ 401 https://dummyjson.com/auth/me` 和「登录已过期」——这就是拦截器统一处理 401 的效果。

## 9. 速查表

### 今天出现的 API / 类

| 名称 | 作用 |
| --- | --- |
| `Dio(BaseOptions(...))` | 创建客户端，集中配 `baseUrl`、超时 |
| `dio.get / post / put / delete` | 各类请求，`queryParameters` 传查询参数 |
| `response.data` | 已自动 JSON 解码的数据 |
| `DioException` | 请求失败的异常类型 |
| `Interceptor` / `InterceptorsWrapper` | 拦截器，`onRequest` / `onResponse` / `onError` |
| `handler.next()` | 放行（不调就卡住） |
| `CancelToken` | 取消请求（搜索框防抖常用） |
| `FormData` | 表单 / 文件上传 |
| `Product.fromJson` | JSON → 模型 |
| `FutureBuilder` | 内置的异步三态 UI |
| `FutureProvider` | Riverpod 版异步状态 |
| `AsyncValue.when(data/loading/error)` | 一次性写三态 |
| `ref.invalidate` / `ref.refresh(...future)` | 重试 / 刷新 |
| `Image.network` + `loadingBuilder` / `errorBuilder` | 网络图片的加载中与失败兜底 |
| `LogInterceptor` | dio 内置日志拦截器，注册在最后 |
| `DioExceptionType` | 错误分类：超时 / `badResponse` / `cancel` 等 |
| `ApiException` | 把 `DioException` 翻译成人话的自定义异常 |

### 核心写法

| 场景 | 写法 |
| --- | --- |
| 配 baseUrl 和超时 | `Dio(BaseOptions(baseUrl:..., connectTimeout:..., receiveTimeout:...))` |
| GET 带参数 | `dio.get('/products', queryParameters: {'limit': 20})` |
| 整数价格转 double | `(json['price'] as num).toDouble()` |
| 可能缺的字段 | `json['brand'] as String? ?? '未知'` |
| 列表转模型 | `(data['products'] as List).map((e) => Product.fromJson(e)).toList()` |
| 统一加 Token | `onRequest` 里 `options.headers['Authorization'] = 'Bearer $token'` |
| 统一处理 401 | `onError` 里判 `err.response?.statusCode == 401`，清 Token + `navigatorKey` 跳登录 |
| 三态 UI（内置） | `FutureBuilder` + `connectionState` / `hasError` / `data` |
| 三态 UI（Riverpod） | `ref.watch(p)..when(data:, loading:, error:)` |
| 失败重试 | `ref.invalidate(productsProvider)` |
| 下拉刷新 | `onRefresh: () => ref.refresh(productsProvider.future)` |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| 一次请求在 UI 上是什么？ | 一份异步状态：加载中 / 成功 / 失败 / 空，四态都要有画面 |
| 错误处理写在哪？ | 拦截器统一处理共性（Token、401、日志），`friendlyMessage` 统一翻译文案，页面只管展示 |
| 网络数据和 UI 怎么衔接？ | 边界处 `fromJson` 转成模型，之后全项目类型安全；请求交给 `FutureProvider` 管理生命周期 |

### 八个高频坑

1. **在 `build` 里发请求**：任何重建都会重新请求 → 存 `State` 字段或交给 `FutureProvider`。
2. **拦截器忘了 `handler.next()`**：请求永远卡住，不报错但没结果。
3. **`as double` 转整数价格的 JSON**：`type 'int' is not a subtype of type 'double'` → 用 `(x as num).toDouble()`。
4. **硬断言可能为 null 的字段**：`json['brand'] as String` 遇到 null 直接崩 → 可空转换 + `??` 兜底。
5. **Android release 包请求失败**：`android/app/src/main/AndroidManifest.xml` 里补上 `<uses-permission android:name="android.permission.INTERNET"/>`（debug 默认有，release 不补就白屏）。
6. **401 处理不闭环**：只清 Token 不跳登录，用户会卡在一个一直失败的页面 → 清 Token + 踢回登录页。
7. **Android 模拟器访问 `localhost` 失败**：模拟器里宿主机是 `10.0.2.2`，真机调试要用电脑的局域网 IP。
8. **真机访问 `http://` 明文接口被拦**：Android 9+ 默认禁明文流量 → 接口上 HTTPS；开发期临时在 `AndroidManifest.xml` 的 `<application>` 上加 `android:usesCleartextTraffic="true"`。

## 10. 今日自检

完成下面三件事，Day 6 才算通过：

- [ ] 用 `dio` 请求 DummyJSON 商品接口，把响应 JSON 转成 `Product` 模型
- [ ] 用三态 UI（`FutureBuilder` 或 `AsyncValue`）分别展示加载中 / 成功 / 失败，失败能重试
- [ ] 写一个拦截器打印请求日志，并在 `onError` 里统一处理 401

如果你能回答下面三个问题，就可以进入 Day 7（本地存储）：

1. JSON 转模型为什么要写 `fromJson`？
2. 拦截器里怎么统一加 Token？
3. 加载中、失败、空数据分别怎么展示？

答案提示：

1. `Map<String, dynamic>` 是「不确定的数据」：字段名靠字符串、类型靠硬转，写错了编译期不报错、运行时才崩。`fromJson` 把它在边界处一次性转成类型明确的 `Product`，之后编辑器有补全、写错字段编译期就报错、字段改名只改一处——相当于 JSON 和 UI 之间的类型防火墙。
2. 在拦截器的 `onRequest` 里读本地 Token，写进 `options.headers['Authorization'] = 'Bearer $token'`，然后 `handler.next(options)` 放行。这样每个请求自动带上 Token，业务代码里一次都不用写；登录成功后只要把 Token 存进统一的地方（Day 7 用 `shared_preferences`）。
3. 三态（其实是四态）：加载中用 `CircularProgressIndicator`（或骨架屏）；失败用「友好文案 + 重试按钮」，文案由 `friendlyMessage` 从 `DioException` 统一翻译；成功但列表为空时显示「暂无商品」的空状态插画/文案，而不是留一片空白。用 `AsyncValue.when` 时，加载/失败在 `loading`、`error` 分支，空数据在 `data` 分支里判 `isEmpty`。
