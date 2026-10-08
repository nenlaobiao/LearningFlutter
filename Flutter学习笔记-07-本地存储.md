# Flutter 学习笔记 07：本地存储

> 适用前提：已经完成 Day 6（网络请求）。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 7。
> 本笔记的目标：让「登录态」活过 App 重启。用 `shared_preferences` 存轻量键值（Token、用户信息、偏好），用 `sqflite` 存结构化数据（浏览记录），并把「登录写 → 启动读 → 退出清」这条闭环真正跑通。

## 目录

- [1. 从 Vue 到 Flutter：本地存储怎么对应](#1-从-vue-到-flutter本地存储怎么对应)
- [2. 存储方案怎么选](#2-存储方案怎么选)
- [3. shared_preferences：轻量键值存储](#3-shared_preferences轻量键值存储)
- [4. 登录态：从 TokenStore 到 AuthNotifier](#4-登录态从-tokenstore-到-authnotifier)
- [5. 启动时判断登录态](#5-启动时判断登录态)
- [6. sqflite：结构化数据](#6-sqflite结构化数据)
- [7. 今日最小项目：登录态保持 + 最近浏览](#7-今日最小项目登录态保持--最近浏览)
- [8. 速查表](#8-速查表)
- [9. 今日自检](#9-今日自检)

## 1. 从 Vue 到 Flutter：本地存储怎么对应

你在 Vue / uniapp 里存东西，最长用的是这两个：

```js
// H5
localStorage.setItem('token', token)
const token = localStorage.getItem('token')   // 同步，立刻拿到

// uniapp
uni.setStorageSync('token', token)
const token = uni.getStorageSync('token')     // 也是同步
```

Flutter 里换成 `shared_preferences`，代码不长，但有一个**心态上的差异**：

```dart
final prefs = await SharedPreferences.getInstance();  // 异步，但只 await 一次

await prefs.setString('token', token);               // 写：异步，要 await
final token = prefs.getString('token');              // 读：同步，直接返回
```

对照表：

| Vue / uniapp | Flutter + shared_preferences |
| --- | --- |
| `localStorage.setItem` / `uni.setStorageSync` | `prefs.setString`（异步，要 `await`） |
| `localStorage.getItem` / `uni.getStorageSync` | `prefs.getString`（同步，直接返回） |
| `localStorage.removeItem` | `prefs.remove` |
| `localStorage.clear()` | `prefs.clear()`（慎用，整包清空） |
| 只能存字符串，对象靠 `JSON.stringify` | 多几种类型（`String` / `int` / `double` / `bool` / `List<String>`），对象仍然要 `jsonEncode` |
| 同步、随便调 | **第一步 `getInstance()` 是异步的**，这是最大的差异 |

> 心智模型：`shared_preferences` 本质是「**一份内存 Map + 一个磁盘文件**」。
> **读走内存（同步）；写落磁盘（异步）。**
> 理解这一句，后面「拦截器里怎么同步拿到 Token」「启动时为什么要先 await 一下」全都顺了——这正是 Day 6 留下的那个悬念的答案。

## 2. 存储方案怎么选

Flutter 的本地存储不是只有一个答案，先看清货架上有什么：

| 方案 | 存什么 | 典型用途 | 注意 |
| --- | --- | --- | --- |
| `shared_preferences` | 轻量键值 | Token、用户信息、主题、是否看过引导页 | 不适合大量 / 结构化数据 |
| `sqflite` | SQLite 表 | 浏览记录、离线数据、消息 | 要自己写建表 SQL 和版本迁移 |
| `path_provider` + `dart:io` | 文件 / 二进制 | 导出文件、下载的图片、日志 | 要自己管目录和清理 |
| `flutter_secure_storage` | 加密键值 | 长期 Token、密码、密钥 | 走 Keychain / Keystore，读写更慢 |
| `hive` / `isar` / `drift` | 现代本地库 | 复杂离线缓存 | 多一层学习成本，现在先不用 |

选型就四个问题：

1. **数据多大？** 几条 → `prefs`；几百条以上 → `sqflite`。
2. **要不要查询、排序、分页？** 要 → `sqflite`（`prefs` 做不到）。
3. **敏不敏感？** 敏感 → `flutter_secure_storage`。
4. **是不是二进制？** 是 → 文件。

> 一句话结论：Day 7 手上只要「`prefs` + `sqflite`」两把锤子，其他方案知道什么时候用就行。

### Token 到底该存在哪

这是个会被面试问、也会在上架前被自己问的问题：

| 存法 | 重启后还在？ | 安全性 | 适合 |
| --- | --- | --- | --- |
| 全局变量（只存内存） | ❌ | 高（进程内） | **只能当缓存，不能当登录态** |
| `shared_preferences` | ✅ | 明文（root / 越狱后可读） | 学习期、一般业务 |
| `flutter_secure_storage` | ✅ | 系统级加密（Keychain / Keystore） | 商业项目、长期有效的 Token |
| `sqflite` | ✅ | 明文 | ❌ 别把数据库当保险箱 |

> 商业级 App 的常见做法：**Token 放 `flutter_secure_storage`，用户资料放 `shared_preferences`**。
> 本笔记为了把原理讲透，统一用 `prefs`；等 Day 9 打包上架前，把存 Token 的那几行换成 secure storage 就行（API 几乎一样：`write` / `read` / `delete`）。

顺带记住：本地数据不是「永久」的。用户**清除应用数据**、**卸载重装**、**换设备**，`prefs` 和数据库都会没。所以真正重要的数据必须在服务端有备份，本地只是缓存。

## 3. shared_preferences：轻量键值存储

加依赖：

```bash
flutter pub add shared_preferences
```

或者在 `pubspec.yaml` 里写（版本以 [pub.dev](https://pub.dev/packages/shared_preferences) 最新为准）：

```yaml
dependencies:
  shared_preferences: ^2.5.3  # 本笔记撰写时的大致版本，以 pub.dev 为准
```

### 最小用法

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> demo() async {
  final prefs = await SharedPreferences.getInstance();   // ① 拿句柄（异步，只做一次）

  await prefs.setString('nickname', '小明');              // ② 写：异步，要 await
  await prefs.setInt('launch_count', 3);
  await prefs.setBool('dark_mode', true);
  await prefs.setStringList('history', ['a', 'b']);

  final nick = prefs.getString('nickname');              // ③ 读：同步，直接返回
  final dark = prefs.getBool('dark_mode') ?? false;      // 没存过就是 null，用 ?? 兜底
  final count = prefs.getInt('launch_count') ?? 0;

  await prefs.remove('nickname');                        // ④ 删一个 key
  await prefs.clear();                                   // ⑤ 清空全部（慎用）

  print('$nick $dark $count');
}
```

支持的类型就这五种：

| 类型 | 写 | 读（返回可空） |
| --- | --- | --- |
| 字符串 | `setString` | `getString` |
| 整数 | `setInt` | `getInt` |
| 小数 | `setDouble` | `getDouble` |
| 布尔 | `setBool` | `getBool` |
| 字符串数组 | `setStringList` | `getStringList` |

**没有 `setObject`**。要存对象，只能自己转 JSON 字符串——这正是 Day 6 写 `toJson` / `fromJson` 的回报：

```dart
final user = User(id: 1, name: '小明', avatar: 'https://...');

// 写：对象 -> JSON 字符串
await prefs.setString('auth_user', jsonEncode(user.toJson()));

// 读：JSON 字符串 -> 对象（两层空值都要判）
final raw = prefs.getString('auth_user');
final user = raw == null
    ? null
    : User.fromJson(jsonDecode(raw) as Map<String, dynamic>);
```

`jsonEncode` / `jsonDecode` 就是 Dart 版的 `JSON.stringify` / `JSON.parse`。没有它们，`prefs` 里只能存一堆散装的基本类型。

### 三个必须记住的点

1. **`getInstance()` 只 `await` 一次**：拿到的 `prefs` 是同一个实例，可以注入给全 App 用（本笔记就是用 `prefsProvider` 注入的）。
2. **读是同步的**：`prefs.getString('token')` 不返回 `Future`，因为数据早就在内存里了。所以拦截器、路由判断这些「同步上下文」都能直接用。
3. **写是异步的**：不 `await` 也可能写成功，但**进程被系统杀掉就丢了**。登录、退出这种关键写入，一定 `await`。

### 进阶：新 API（了解即可）

`shared_preferences 2.3+` 增加了 `SharedPreferencesAsync`（纯异步）和 `SharedPreferencesWithCache`（自带缓存）两套新 API，把「内存缓存」和「磁盘」拆得更清楚。学习期用经典的 `SharedPreferences.getInstance()` 完全够，遇到别的项目用新 API 再查也不迟。

## 4. 登录态：从 TokenStore 到 AuthNotifier

Day 6 里 `AuthInterceptor` 依赖一个 `TokenStore`，当时是内存版，我在笔记里留了一句「Day 7 换成 `shared_preferences` 持久化版本」。今天来兑现：

```
              界面（Widget）
                   │ ref.watch(authProvider)
        ┌──────────▼───────────┐
        │  AuthNotifier（内存） │   ← 可订阅、能触发重建
        └──────────┬───────────┘
                   │ await prefs.setString(...)
        ┌──────────▼───────────┐
        │  shared_preferences  │   ← 磁盘，重启后还在
        └──────────────────────┘
```

关键设计：**内存态和磁盘态由同一个 `AuthNotifier` 维护**，不会出现「界面已经退出登录，磁盘里 Token 还在」这种不一致。

### 4.1 状态与 Notifier

```dart
// ① 在 main 里 override 注入真正的实例，其他地方只读
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('请在 main 的 ProviderScope.overrides 里注入'),
);

// ② 认证状态：内存态（可订阅），由 AuthNotifier 负责和磁盘同步
class AuthState {
  const AuthState({this.token, this.user});

  final String? token;
  final User? user;

  bool get isLoggedIn => token != null;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  @override
  AuthState build() {
    final prefs = ref.watch(prefsProvider);
    // 启动时先读一次磁盘：App 一打开，登录态就已经恢复了
    final rawUser = prefs.getString(_kUser);
    return AuthState(
      token: prefs.getString(_kToken),
      user: rawUser == null
          ? null
          : User.fromJson(jsonDecode(rawUser) as Map<String, dynamic>),
    );
  }

  /// 登录成功：先写磁盘，再更新内存
  Future<void> signIn({required String token, required User user}) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    state = AuthState(token: token, user: user); // 界面立刻切到登录态
  }

  /// 退出登录 / Token 过期：内存和磁盘一起清
  Future<void> signOut() async {
    final prefs = ref.read(prefsProvider);
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    state = const AuthState();
  }
}
```

两个顺序上的讲究：

1. **先落盘，再改内存**。如果反过来（先改内存、后写磁盘），磁盘写失败时界面已经显示「登录成功」，重启后又回到登录页——用户会觉得 App 抽风。
2. **`signOut` 两边都清**。只清内存，重启又「复活」；只清磁盘，当前界面还显示着用户信息。

### 4.2 拦截器怎么同步拿到 Token

Day 6 的 `AuthInterceptor` 里那句 `_tokenStore.token` 是**同步**读的（`onRequest` 是同步方法，没法 `await`）。今天用 `prefs` 也能满足这一点——因为 `prefs.getString` 本身就是同步读内存：

```dart
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref; // 拦截器里没有 context，但可以持有 Riverpod 的 ref

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authProvider).token; // 同步读内存态，不用 await
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // Token 过期：清内存 + 清磁盘，并把路由弹回栈底（入口会自动显示登录页）
      _ref.read(authProvider.notifier).signOut();
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    handler.next(err); // 处理完仍然放行，让界面也能感知失败
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor()); // 注册在最后，才能打到刚加上的 Token 头
  return dio;
});
```

> 这就是「**读同步 + 写异步**」的价值：拦截器、路由守卫这类同步上下文可以随手读到 Token，而写入依旧是异步安全的。
>
> 和 Day 6 的一个小改动：401 时不再 `pushNamedAndRemoveUntil('/login')`，而是「清状态 + `popUntil(isFirst)`」。因为接下来第 5 节会把「显示登录页还是首页」交给状态来算——状态一改，界面自己就对了。

### 4.3 界面怎么用

```dart
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider); // 登录 / 登出后自动重建

    if (!auth.isLoggedIn) {
      return const Center(child: Text('未登录'));
    }
    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(auth.user!.avatar)),
          title: Text(auth.user!.name),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('退出登录'),
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) {
              // await 之后 widget 可能已经被销毁，用 context 前先判 mounted
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已退出登录')),
              );
            }
          },
        ),
      ],
    );
  }
}
```

`context.mounted` 这个判断是从 Day 3 就开始强调的规矩：**只要 `await` 过，用 `context` 前就要确认它还有效**。

## 5. 启动时判断登录态

矛盾点：`SharedPreferences.getInstance()` 是异步的，而 `runApp` 是同步的。怎么在「显示第一屏之前」就知道用户登没登录？

### 方案 A：main 里预加载（推荐，最简单）

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();            // ① 用插件前必须先初始化绑定
  final prefs = await SharedPreferences.getInstance();  // ② 先把磁盘读进内存

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)], // ③ 注入给全 App
      child: const ShopApp(),
    ),
  );
}

class ShopApp extends ConsumerWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const AuthGate(), // home 本身不判断，交给 AuthGate
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
    );
  }
}

/// 登录态决定显示哪一屏：冷启动恢复 / 登录成功 / 退出登录 / 401 都会自动切换
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).isLoggedIn
        ? const MainTabsPage()
        : const LoginPage();
  }
}
```

- 好处：**没有 loading 三态**，一个三元表达式就决定了去哪；登录 / 退出后界面自动切换，业务代码里几乎看不到「跳转」。
  - 小技巧：`home` 保持 `const AuthGate()` 不变，让 `AuthGate` 内部去 `ref.watch`。这样「谁根据状态变化」这件事是显式的，比直接把三元写在 `home:` 里更稳。
- 代价：启动时多等一次磁盘 IO（通常几毫秒，首次可能几十毫秒），这期间用户看到的是原生启动图 / 白屏。
- `WidgetsFlutterBinding.ensureInitialized()` 不能省：**在 `runApp` 之前调用插件（`shared_preferences` 就是插件）必须先初始化绑定**，否则报 `Binding has not yet been initialized`。

### 方案 B：不预加载，用三态启动页

如果以后要初始化的事情变多（prefs + 数据库 + 远程配置），`main` 里全 `await` 会让启动变慢，这时改成「先给用户看 Logo，数据好了再进主界面」：

```dart
final bootstrapProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  await AppDatabase.instance(); // 顺便预热数据库（sqflite 第一次打开较慢）
  return prefs;
});

class BootstrapGate extends ConsumerWidget {
  const BootstrapGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(bootstrapProvider).when(
      loading: () => const SplashScreen(),                      // 转圈 / Logo
      error: (error, stack) => StartupErrorView(error: error),   // 启动失败也要有交代
      data: (prefs) => const AuthGate(),                        // 就绪后再进真正的入口
    );
  }
}
```

思路还是 Day 6 那套三态 UI（loading / error / data），只是数据源从「网络请求」换成了「本地初始化」。

要提醒一点：方案 B 里 `prefs` 是 `data` 分支才拿到的，`AuthNotifier.build()` 就不能再靠 `ref.watch(prefsProvider)` 同步拿了——要么把它显式往下传，要么把 provider 换成 `AsyncNotifier`。这就是「方案 A 简单」的代价反转：**A 用一点启动时间换全项目代码简单，B 用一点架构复杂度换首屏更快**。

> 学习期选 A。Day 9 做启动优化时再考虑 B，那时你已经有能力判断值不值。

### 登录态的三个判断层次

| 层次 | 判断依据 | 处理 |
| --- | --- | --- |
| 冷启动 | 本地有没有 Token | 有 → 首页；没有 → 登录页（就是 `AuthGate`） |
| 带 Token 冷启动 | 服务端认不认（`/auth/me` 返回 200？） | 200 → 照常使用；401 → 拦截器清 Token + 回登录页 |
| 使用中过期 | 任意接口返回 401 | Day 6 的 `AuthInterceptor` 统一处理 |

关键认知：**本地 Token 只是一份缓存，登录态最终以服务端为准。** 本地判断只解决「敢不敢直接把用户带进首页」，不解决「这个 Token 还有没有效」。

## 6. sqflite：结构化数据

`prefs` 是一个「大 Map」，一旦你想要「按时间倒序取最近 20 条」，就开始别扭了。结构化数据上 `sqflite`。

加依赖：

```bash
flutter pub add sqflite path
```

### 6.1 建库与建表

```dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static Database? _db;

  /// 全 App 共用一个连接：别每次操作都 openDatabase
  static Future<Database> instance() async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'shop.db'); // 应用私有目录
    return openDatabase(
      path,
      version: 1, // 表结构版本号（不是 App 版本号）
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recent_viewed(
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            price REAL NOT NULL,
            thumbnail TEXT,
            viewed_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 以后改表结构：version +1，在这里按 oldVersion 逐级补迁移
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE recent_viewed ADD COLUMN brand TEXT');
        }
      },
    );
  }
}
```

三个要点：

1. `version` 是**表结构版本**。改了表结构必须 +1，并在 `onUpgrade` 里写迁移。
2. `onCreate` 只在新装时跑一次；老用户走的是 `onUpgrade`。
3. 改了表结构却没写迁移 → 老用户一升级就报 `no such column`，这是最经典的线上事故之一。

### 6.2 增删改查

```dart
final db = await AppDatabase.instance();

// 增 / 覆盖：ConflictAlgorithm.replace 让「重复插入」变成「更新」
await db.insert(
  'recent_viewed',
  {
    'id': product.id,
    'title': product.title,
    'price': product.price,
    'thumbnail': product.thumbnail,
    'viewed_at': DateTime.now().millisecondsSinceEpoch,
  },
  conflictAlgorithm: ConflictAlgorithm.replace,
);

// 查：按时间倒序取 20 条
final rows = await db.query(
  'recent_viewed',
  orderBy: 'viewed_at DESC',
  limit: 20,
);
final items = rows.map(RecentViewed.fromMap).toList();

// 改
await db.update(
  'recent_viewed',
  {'title': '新标题'},
  where: 'id = ?',
  whereArgs: [product.id],
);

// 删
await db.delete('recent_viewed', where: 'id = ?', whereArgs: [product.id]);

// 复杂 SQL
final cheap = await db.rawQuery('SELECT * FROM recent_viewed WHERE price < ?', [50]);
```

`where` 里的 `?` 是占位符，值放 `whereArgs`。**永远不要用字符串拼 SQL**（`where: 'id = ${id}'`）：既有注入风险，也容易类型出错。

再加两个工程习惯：

```dart
// 批量：一次事务写多行，比循环 insert 快得多
final batch = db.batch();
batch.insert('recent_viewed', {...});
batch.delete('recent_viewed', where: 'id = ?', whereArgs: [1]);
await batch.commit();

// 事务：要么全成功，要么全回滚
await db.transaction((txn) async {
  await txn.delete('cart_items');
  for (final item in cart.values) {
    await txn.insert('cart_items', {...});
  }
});
```

### 6.3 行数据 ↔ 模型

数据库里的一行就是 `Map<String, Object?>`，和 Day 6 的 JSON 一模一样的套路：**边界处一次性转成模型**。

```dart
class RecentViewed {
  const RecentViewed({required this.id, required this.title, required this.price});

  final int id;
  final String title;
  final double price;

  factory RecentViewed.fromMap(Map<String, Object?> map) => RecentViewed(
        id: map['id'] as int,
        title: map['title'] as String,
        price: (map['price'] as num).toDouble(), // 和 Day 6 同一个坑
      );

  Map<String, Object?> toMap() => {'id': id, 'title': title, 'price': price};
}
```

> 对照记忆：**JSON 用 `fromJson`，数据库行用 `fromMap`，套路完全一样。** 进去的是「不确定的 Map」，出来的是「确定的 Dart 对象」。

### 6.4 什么时候用 sqflite，而不是 prefs

| 症状 | 该用什么 |
| --- | --- |
| 一个 Token、一个开关、一个主题 | `shared_preferences` |
| 20 条浏览记录，要按时间倒序取 | `sqflite`（存 JSON 数组也能凑合，但很快会难受） |
| 1000 条商品要按关键字查询、分页 | `sqflite` |
| 要跨表关联（订单 + 订单明细） | `sqflite` |
| 一张图片 / 一个二进制文件 | 文件（`path_provider` + `dart:io`） |

平台说明：`sqflite` 官方支持 Android / iOS / macOS；要在 Windows / Linux 桌面或 Web 上跑，需要额外接 `sqflite_common_ffi`（或改用 `drift`）。学习期在 Android 模拟器上验证就够了。

## 7. 今日最小项目：登录态保持 + 最近浏览

目标：在 Day 6 的商城 Demo 上补三件事——**登录页**、**退出登录**、**最近浏览**。

```bash
flutter pub add shared_preferences sqflite path
```

下面按「文件里的段落顺序」贴完整代码，可以先都放在 `main.dart` 里跑通，Day 9 再做目录拆分。

### 0. 全局工具

```dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// 全局导航 key：拦截器、退出登录这些「没有 context」的地方靠它操作路由
final navigatorKey = GlobalKey<NavigatorState>();
```

### 1. 模型（含 fromMap / toMap）

```dart
class User {
  const User({required this.id, required this.name, required this.avatar});

  final int id;
  final String name;
  final String avatar;

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as int,
        name: (json['firstName'] as String?) ??
            (json['username'] as String?) ??
            '用户',
        avatar: json['image'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'avatar': avatar};
}

class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.thumbnail,
  });

  final int id;
  final String title;
  final double price;
  final String thumbnail;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as int,
        title: json['title'] as String,
        price: (json['price'] as num).toDouble(),
        thumbnail: json['thumbnail'] as String? ?? '',
      );

  /// 数据库行 -> 模型（和 fromJson 一个思路）
  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int,
        title: map['title'] as String,
        price: (map['price'] as num).toDouble(),
        thumbnail: map['thumbnail'] as String? ?? '',
      );

  /// 模型 -> 数据库行
  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'price': price,
        'thumbnail': thumbnail,
      };
}
```

### 2. 本地存储基建

```dart
/// 在 main 里 override 注入真正的实例
final prefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('请在 main 里 override'),
);

/// 最近浏览：全 App 共用一个数据库连接
class AppDatabase {
  static Database? _db;

  static Future<Database> instance() async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  static Future<Database> _open() async {
    final path = join(await getDatabasesPath(), 'shop.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recent_viewed(
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            price REAL NOT NULL,
            thumbnail TEXT,
            viewed_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // 以后加字段、加表，都在这里按 oldVersion 逐级迁移
      },
    );
  }

  /// 记一次浏览：同一商品重复浏览 -> 覆盖，只更新时间
  static Future<void> saveViewed(Product product) async {
    final db = await instance();
    await db.insert(
      'recent_viewed',
      {...product.toMap(), 'viewed_at': DateTime.now().millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 最近浏览：按时间倒序
  static Future<List<Product>> recentViewed({int limit = 20}) async {
    final db = await instance();
    final rows = await db.query(
      'recent_viewed',
      orderBy: 'viewed_at DESC',
      limit: limit,
    );
    return rows.map(Product.fromMap).toList();
  }

  static Future<void> clearViewed() async {
    final db = await instance();
    await db.delete('recent_viewed');
  }
}

/// 读数据库 = 一次异步请求，交给 FutureProvider 管生命周期
final recentViewedProvider =
    FutureProvider<List<Product>>((ref) => AppDatabase.recentViewed());
```

### 3. 认证状态：内存 + 磁盘

```dart
class AuthState {
  const AuthState({this.token, this.user});

  final String? token;
  final User? user;

  bool get isLoggedIn => token != null;
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends Notifier<AuthState> {
  static const _kToken = 'auth_token';
  static const _kUser = 'auth_user';

  @override
  AuthState build() {
    // 启动时的「读磁盘」：prefs 在 main 里已初始化，这里可以同步读
    final prefs = ref.watch(prefsProvider);
    final rawUser = prefs.getString(_kUser);
    return AuthState(
      token: prefs.getString(_kToken),
      user: rawUser == null
          ? null
          : User.fromJson(jsonDecode(rawUser) as Map<String, dynamic>),
    );
  }

  /// 登录成功：先落盘，再改内存
  Future<void> signIn({required String token, required User user}) async {
    final prefs = ref.read(prefsProvider);
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user.toJson()));
    state = AuthState(token: token, user: user);
  }

  /// 退出登录 / Token 过期：内存和磁盘一起清
  Future<void> signOut() async {
    final prefs = ref.read(prefsProvider);
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    state = const AuthState();
  }
}
```

### 4. dio + 拦截器

```dart
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://dummyjson.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(LogInterceptor()); // 放最后，才能打到刚加上的 Token 头
  return dio;
});

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref);

  final Ref _ref;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _ref.read(authProvider).token; // 同步读内存态
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _ref.read(authProvider.notifier).signOut();
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    handler.next(err);
  }
}

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final response = await ref
      .read(dioProvider)
      .get<Map<String, dynamic>>('/products', queryParameters: {'limit': 20});
  return (response.data!['products'] as List)
      .map((e) => Product.fromJson(e as Map<String, dynamic>))
      .toList();
});
```

### 5. 入口：预加载 prefs

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();            // 用插件前先初始化绑定
  final prefs = await SharedPreferences.getInstance();  // 先把磁盘读进内存

  runApp(
    ProviderScope(
      overrides: [prefsProvider.overrideWithValue(prefs)],
      child: const ShopApp(),
    ),
  );
}

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
      home: const AuthGate(),
    );
  }
}

/// 登录态决定第一屏：冷启动恢复 / 登录成功 / 退出登录 / 401 都会自动切换
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(authProvider).isLoggedIn
        ? const MainTabsPage()
        : const LoginPage();
  }
}
```

### 6. 登录页（DummyJSON 测试账号）

```dart
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _username = TextEditingController(text: 'emilys'); // DummyJSON 自带测试账号
  final _password = TextEditingController(text: 'emilyspass');
  bool _loading = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final response = await ref.read(dioProvider).post<Map<String, dynamic>>(
        '/auth/login',
        data: {
          'username': _username.text.trim(),
          'password': _password.text,
          'expiresInMins': 60,
        },
      );
      final data = response.data!;
      // 写磁盘 + 更新内存态；AuthGate 会自动切到首页，不用手写跳转
      await ref.read(authProvider.notifier).signIn(
            token: data['accessToken'] as String,
            user: User.fromJson(data),
          );
    } on DioException catch (e) {
      if (!mounted) return;
      final badCredentials = e.response?.statusCode == 400;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(badCredentials ? '用户名或密码不对' : '登录失败，请稍后重试')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('登录')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          TextField(
            controller: _username,
            decoration: const InputDecoration(labelText: '用户名'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: '密码'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _submit,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登录'),
          ),
        ],
      ),
    );
  }
}
```

### 7. 三 Tab 骨架

```dart
class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack：切 tab 不丢滚动位置和状态
      body: IndexedStack(
        index: _index,
        children: const [HomePage(), RecentPage(), ProfilePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: '首页'),
          NavigationDestination(icon: Icon(Icons.history), label: '最近浏览'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }
}
```

### 8. 首页 + 详情（进详情写入浏览记录）

```dart
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('商品列表')),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('加载失败：$error')),
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ListTile(
              leading: Image.network(
                product.thumbnail,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported),
              ),
              title: Text(
                product.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text('¥${product.price.toStringAsFixed(2)}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => DetailPage(product: product)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class DetailPage extends ConsumerStatefulWidget {
  const DetailPage({super.key, required this.product});

  final Product product;

  @override
  ConsumerState<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends ConsumerState<DetailPage> {
  @override
  void initState() {
    super.initState();
    _recordView();
  }

  /// 进详情页 = 一次浏览：写进 sqflite，并让「最近浏览」列表重新取数
  Future<void> _recordView() async {
    await AppDatabase.saveViewed(widget.product);
    if (!mounted) return;
    ref.invalidate(recentViewedProvider);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.image_not_supported, size: 64),
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
        ],
      ),
    );
  }
}
```

### 9. 最近浏览（读数据库）

```dart
class RecentPage extends ConsumerWidget {
  const RecentPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentAsync = ref.watch(recentViewedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('最近浏览'),
        actions: [
          IconButton(
            tooltip: '清空浏览记录',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () async {
              await AppDatabase.clearViewed();
              ref.invalidate(recentViewedProvider);
            },
          ),
        ],
      ),
      body: recentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('读取失败：$error')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('还没有浏览记录，去首页点几个商品'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final product = items[index];
              return ListTile(
                leading: Image.network(
                  product.thumbnail,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.image_not_supported),
                ),
                title: Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('¥${product.price.toStringAsFixed(2)}'),
              );
            },
          );
        },
      ),
    );
  }
}
```

### 10. 我的：登录态 + 模拟过期 + 退出登录

```dart
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundImage: (user != null && user.avatar.isNotEmpty)
                  ? NetworkImage(user.avatar)
                  : null,
              child: (user == null || user.avatar.isEmpty)
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(user?.name ?? '未登录'),
            subtitle: Text(
              auth.isLoggedIn ? 'Token 已持久化，重启 App 免登录' : '未登录',
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.key_off_outlined),
            title: const Text('模拟 Token 过期'),
            subtitle: const Text('用坏 Token 请求 /auth/me，触发 401 统一处理'),
            onTap: () async {
              try {
                await ref.read(dioProvider).get(
                      '/auth/me',
                      options: Options(
                        headers: {'Authorization': 'Bearer bad-token'},
                      ),
                    );
              } on DioException {
                // 拦截器已经清掉登录态并把路由弹回栈底，这里什么都不用做
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authProvider.notifier).signOut();
              navigatorKey.currentState?.popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
```

运行后验证六件事：

1. 用 `emilys` / `emilyspass` 登录 → 自动进首页，「我的」显示名字和头像。**注意：没有写一行「跳转到首页」的代码**，是 `AuthGate` 看状态自己切的。
2. **彻底杀掉 App 再打开** → 直接进首页，不用重新登录。这就是今天最核心的产出：登录态持久化。
3. 点几个商品进详情 → 切到「最近浏览」，刚才的商品按时间倒序出现；**重启 App 依然在**，因为它在 sqflite 里。
4. 点退出登录 → 回到登录页；再杀掉 App 重开 → 仍是登录页（磁盘里已经清干净了）。
5. 点「模拟 Token 过期」→ 控制台出现 `✗ 401 .../auth/me`，App 自动清登录态并弹回登录页。
6. 看终端日志：登录后的每个请求都带着 `Authorization: Bearer ...`——Day 6 的拦截器 + 今天的 `prefs`，两天的内容在这里合流。

## 8. 速查表

### 今天出现的 API / 类

| 名称 | 作用 |
| --- | --- |
| `SharedPreferences.getInstance()` | 拿 prefs 句柄（异步，只做一次） |
| `prefs.setString / setInt / setBool / setDouble / setStringList` | 写（异步，要 `await`） |
| `prefs.getString / getInt / getBool / ...` | 读（同步，返回可空） |
| `prefs.remove` / `prefs.clear` | 删一个 key / 清空全部 |
| `jsonEncode` / `jsonDecode` | 对象 ↔ JSON 字符串（存对象必须用） |
| `WidgetsFlutterBinding.ensureInitialized()` | `runApp` 之前用插件必须先调 |
| `prefsProvider` + `overrideWithValue` | 把 prefs 注入全 App（在 main 里 override） |
| `AuthNotifier`（`NotifierProvider`） | 内存态 + 磁盘同步的登录态 |
| `flutter_secure_storage` | 加密存 Token（商业项目推荐，API 类似） |
| `openDatabase` / `onCreate` / `onUpgrade` | 建库、建表、表结构迁移 |
| `db.insert / query / update / delete / rawQuery` | 增删改查（全异步） |
| `ConflictAlgorithm.replace` | 主键冲突时覆盖（= upsert） |
| `db.batch().commit()` / `db.transaction()` | 批量 / 事务 |
| `getDatabasesPath()` + `join(...)` | 数据库文件路径 |
| `Product.fromMap` / `toMap` | 数据库行 ↔ 模型 |

### 核心写法

| 场景 | 写法 |
| --- | --- |
| 启动预加载 | `WidgetsFlutterBinding.ensureInitialized(); final prefs = await SharedPreferences.getInstance();` |
| 注入 prefs | `ProviderScope(overrides: [prefsProvider.overrideWithValue(prefs)])` |
| 存 Token | `await prefs.setString('auth_token', token)` |
| 读 Token（同步） | `prefs.getString('auth_token')` |
| 存对象 | `await prefs.setString('user', jsonEncode(user.toJson()))` |
| 读对象 | `final raw = prefs.getString('user'); raw == null ? null : User.fromJson(jsonDecode(raw))` |
| 退出登录 | `await prefs.remove('auth_token'); await prefs.remove('auth_user');` |
| 判断登录态 | `ref.watch(authProvider).isLoggedIn`（放在 `AuthGate` 里） |
| 建表 | `openDatabase(path, version: 1, onCreate: (db, v) => db.execute('CREATE TABLE ...'))` |
| 写入一行 | `db.insert('recent_viewed', {...}, conflictAlgorithm: ConflictAlgorithm.replace)` |
| 查最近 20 条 | `db.query('recent_viewed', orderBy: 'viewed_at DESC', limit: 20)` |
| 清空表 | `db.delete('recent_viewed')` |
| 数据变化后刷新界面 | `ref.invalidate(recentViewedProvider)` |

### 今天的三个心智模型

| 问题 | 答案 |
| --- | --- |
| `prefs` 为什么能同步读？ | 它是「内存 Map + 磁盘文件」：读走内存所以同步，写落磁盘所以异步 |
| 登录态为什么不能只放内存？ | 进程一死就没了；内存态只负责「当前这次运行能立刻读到」，磁盘态负责「下次打开还在」 |
| 什么时候上 sqflite？ | 当你要查询、排序、分页、跨表时；`prefs` 只适合少量键值 |

### 八个高频坑

1. **忘了 `WidgetsFlutterBinding.ensureInitialized()`**：`runApp` 之前用插件会报 `Binding has not yet been initialized`。
2. **想在 `build` 里 `await` prefs**：`build` 是同步的，写不出 `await` → 用「main 预加载」或三态启动页。
3. **拿 `localStorage` 的同步思维用 prefs**：`getItem` 是同步的，但 `getInstance()` 是异步的，这一步必须安排在启动阶段。
4. **往 prefs 里塞对象或列表**：没有 `setObject`，`setStringList` 也只接受 `List<String>` → 用 `jsonEncode` 转字符串。
5. **写 Token 不 `await`**：刚写完就被系统杀进程，Token 丢了，用户下次打开又要登录。
6. **改表结构不写 `onUpgrade`**：老用户升级后 `no such column` 直接崩 → `version` +1 并补迁移。
7. **用字符串拼 SQL**：`where: 'id = ${id}'` 有注入风险、还容易类型出错 → 用 `whereArgs`。
8. **每次操作都 `openDatabase`**：连接被重复创建 → 用 `AppDatabase.instance()` 单例复用。

## 9. 今日自检

完成下面四件事，Day 7 才算通过：

- [ ] 登录成功后把 Token 写入 `shared_preferences`
- [ ] 启动时读 Token，决定进登录页还是首页
- [ ] 退出登录时清除 Token
- [ ] 把最近浏览商品用 `sqflite` 存起来，重启后还能看到

如果你能回答下面三个问题，就可以进入 Day 8（主题与动画）：

1. Token 存哪里？为什么不用全局变量？
2. 启动时怎么判断是否已登录？
3. `shared_preferences` 和 `sqflite` 怎么选？

答案提示：

1. 存 `shared_preferences`（学习期）或 `flutter_secure_storage`（商业项目）这类**磁盘**存储里。全局变量只在内存里活着：进程一被杀（用户划掉、系统回收、崩溃重启）就全没了，用户下次打开又得重新登录，体验直接掉一档。正确姿势是「内存态 + 磁盘态」两份：内存态给界面订阅、给拦截器同步读；磁盘态负责重启后恢复，并且两边由同一个 `AuthNotifier` 保持一致（今天的写法就是这个角色）。
2. 启动时在 `main` 里 `await SharedPreferences.getInstance()`，然后由 `AuthNotifier.build()` 从磁盘读一次 Token：有 Token 就让 `AuthGate` 直接渲染首页，没有就渲染登录页。注意这只解决「第一屏去哪」，Token 还有效没效要以服务端为准——带 Token 的请求一旦返回 401，拦截器会清掉本地登录态并把用户送回登录页。
3. 看三个问题：**数据量大不大、要不要查询排序分页、敏不敏感**。少量键值（Token、主题、开关、是否看过引导页）用 `shared_preferences`；要按条件查询、排序、分页、跨表关联的（浏览记录、离线列表、订单明细）用 `sqflite`；敏感信息（长期 Token、密码）优先 `flutter_secure_storage`；二进制文件用文件系统。判断标准不是「哪个更高级」，而是「谁更贴合这份数据的形态」。

