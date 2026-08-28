# 第 1 周：Dart 速成与 Widget 入门（M1 + M2）

> 目标：能读懂任意一段 Flutter 代码，并手写一个可交互的 Widget。
> 时间：约 4 天。
> 前置：已完成 `00-总纲` 里的环境搭建，`flutter run` 能跑起来。

---

## 目录

- [M1 Dart 速成](#m1-dart-速成)
  - [1.1 一分钟总览](#11-一分钟总览dart-vs-js)
  - [1.2 变量与类型](#12-变量与类型)
  - [1.3 空安全（重点）](#13-空安全重点)
  - [1.4 函数与命名参数（重点）](#14-函数与命名参数重点)
  - [1.5 类与构造函数（重点）](#15-类与构造函数重点)
  - [1.6 集合操作](#16-集合操作)
  - [1.7 控制流与运算符糖](#17-控制流与运算符糖)
  - [1.8 异步：Future 与 Stream](#18-异步future-与-stream)
  - [1.9 mixin 与 extension](#19-mixin-与-extension)
- [M2 Widget 入门](#m2-widget-入门)
  - [2.1 一切皆 Widget](#21-一切皆-widget)
  - [2.2 main.dart 逐行拆解](#22-maindart-逐行拆解)
  - [2.3 StatelessWidget](#23-statelesswidget)
  - [2.4 StatefulWidget 与 setState](#24-statefulwidget-与-setstate)
  - [2.5 生命周期](#25-生命周期)
  - [2.6 父子通信](#26-父子通信)
  - [2.7 const 与性能](#27-const-与性能)
  - [2.8 热重载的边界](#28-热重载的边界)
- [本周产出物](#本周产出物)
- [自检与练习](#自检与练习)

---

# M1 Dart 速成

Dart 是 Google 的语言，语法上你可以理解为 **"Java 的骨架 + JS 的手感 + TypeScript 的类型系统"**。你会 JS 和 TS 的话，两三天足够。

## 1.1 一分钟总览：Dart vs JS

| 能力 | JavaScript | Dart |
|---|---|---|
| 变量声明 | `let` / `const` | `var` / `final` / `const` / 具体类型 |
| 类型 | 弱类型 | **强类型 + 空安全** |
| 字符串模板 | `` `hi ${name}` `` | `'hi $name'` / `'${obj.name}'` |
| 数组 | `Array` | `List` |
| 对象/字典 | `Object` / `Map` | `Map` |
| 相等判断 | `===` | `==`（Dart 的 `==` 就是严格相等） |
| 空值合并 | `??` | `??`（一样） |
| 可选链 | `?.` | `?.`（一样） |
| 异步 | `Promise` / `async-await` | `Future` / `async-await`（几乎一样） |
| 流 | `AsyncIterator` / RxJS | `Stream`（内置，很强大） |
| 类 | `class` | `class`（更完整：抽象类、mixin、接口） |
| 展开 | `...arr` | `...list`（一样） |
| 私有 | `#field` / 约定 | **变量名以 `_` 开头即为库内私有** |
| 入口 | 无 | `void main() {}` |
| 分号 | 可省 | **必须写** |

三个最需要注意的差异：
1. **强类型 + 空安全** —— 编译期就拦你，习惯了会真香。
2. **命名参数** —— Flutter 里所有 Widget 都靠它，必须吃透（见 1.4）。
3. **`_` 开头就是私有** —— 没有 `private` 关键字。

## 1.2 变量与类型

```dart
void main() {
  // 类型推断，等价于 String name
  var name = '张三';
  
  // 显式类型
  String city = '北京';
  int age = 25;
  double price = 99.5;
  bool isVip = true;
  
  // 动态类型（相当于 TS 的 any，尽量别用）
  dynamic anything = 'hello';
  anything = 123;   // 合法
  
  // final：运行时赋值一次，之后不可改（≈ JS 的 const）
  final now = DateTime.now();
  
  // const：编译期常量，值必须在编译时就确定
  const pi = 3.14;
  // const bad = DateTime.now();  // ❌ 编译期不知道值
  
  // late：延迟初始化，承诺"用之前一定会赋值"
  late String token;
  token = 'abc';
}
```

### final vs const（Flutter 里非常关键）

```dart
final list1 = [1, 2, 3];
list1.add(4);        // ✅ 允许！final 只锁引用，不锁内容
// list1 = [5];      // ❌ 不能重新赋值

const list2 = [1, 2, 3];
// list2.add(4);     // ❌ const 集合是完全不可变的
```

**Flutter 里的实际意义**：`const` 修饰的 Widget 在重建时会被复用，不会重新创建对象，是免费的性能优化。所以你会看到大量 `const Text('标题')`。**能加 const 就加**，编辑器也会提示你。

### 数字类型的坑

```dart
int a = 10;
double b = 3.0;

print(10 / 3);      // 3.3333...  除法永远返回 double
print(10 ~/ 3);     // 3          整除用 ~/ （JS 里是 Math.floor）
print(10 % 3);      // 1

// int 不会自动转 double（JS 里没这个问题）
double c = 5;       // ✅ 这个特例允许
// int d = 5.0;     // ❌ 不允许
int d = 5.9.toInt();      // 5，截断
int e = 5.9.round();      // 6，四舍五入
```

### 字符串

```dart
String name = '张三';
int count = 3;

print('你好 $name');                    // 简单变量直接 $
print('共 ${count * 2} 件');            // 表达式要 ${}
print("双引号也行");                     // 单双引号等价，团队里统一用单引号

// 多行字符串
String sql = '''
SELECT *
FROM users
''';

// 常用方法（和 JS 高度相似）
'hello'.toUpperCase();          // HELLO
'  a  '.trim();                 // 'a'
'a,b,c'.split(',');             // [a, b, c]
'hello'.contains('ell');        // true
'hello'.substring(1, 3);        // el
'hello'.replaceAll('l', 'L');   // heLLo
'5'.padLeft(3, '0');            // 005
int.parse('123');               // 字符串转数字
123.toString();                 // 数字转字符串
double.tryParse('abc');         // null，转不了不报错（推荐用 tryParse）
```

## 1.3 空安全（重点）

这是 Dart 相对 JS 最大的思维转变，也是你前几天会被反复报错的地方。

**核心规则：默认所有变量都不能为 null。想允许 null，必须在类型后加 `?`。**

```dart
String a = 'hello';
// a = null;          // ❌ 编译报错

String? b = 'hello';  // 加了 ? 才可空
b = null;             // ✅
```

### 四个操作符

```dart
String? name;

// 1. ?. 可选调用：name 为 null 时整个表达式返回 null
print(name?.length);        // null，不会崩

// 2. ?? 空值合并：左边为 null 时用右边
print(name ?? '默认值');     // 默认值

// 3. ??= 空值赋值：只在为 null 时赋值
name ??= '张三';

// 4. ! 非空断言：告诉编译器"我保证它不是 null"
String? maybe = getSomething();
print(maybe!.length);       // ⚠️ 如果真是 null，运行时崩溃
```

> **`!` 是双刃剑**。它不是"把 null 变成非 null"，只是关闭了编译器检查。滥用 `!` 等于放弃空安全的全部好处，Flutter 里最常见的崩溃就是 `Null check operator used on a null value`。能用 `??` 或者提前判空就别用 `!`。

### 实战里的典型场景

```dart
// 后端返回的字段可能缺失
class User {
  final String name;
  final String? avatar;     // 头像可能没有
  User({required this.name, this.avatar});
}

// 使用时
Widget build(BuildContext context) {
  return Column(
    children: [
      Text(user.name),                                    // 非空，直接用
      Image.network(user.avatar ?? 'https://默认头像.png'), // 可空，给兜底
    ],
  );
}
```

### 类型提升（很实用）

```dart
String? name = getName();

if (name != null) {
  // 在这个 if 块里，Dart 自动把 name 当成 String（非空）
  print(name.length);      // ✅ 不用写 name!
}

// 但类的字段不会自动提升（因为可能被其他线程改），要先赋给局部变量
final n = user.avatar;
if (n != null) {
  print(n.length);
}
```

### late 的正确用法

```dart
class MyState extends State<MyWidget> {
  // 声明时还拿不到值，但 initState 里一定会赋，且之后不为空
  late final TextEditingController controller;
  
  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }
}
```

`late` 的含义是"我推迟初始化，但保证使用前已赋值"。如果没赋值就用，运行时报错。

## 1.4 函数与命名参数（重点）

**这一节是理解全部 Flutter 代码的钥匙。**

```dart
// 基础写法
int add(int a, int b) {
  return a + b;
}

// 箭头函数（单表达式）
int add2(int a, int b) => a + b;

// 无返回值
void log(String msg) => print(msg);
```

### 三种参数形式

```dart
// 1. 位置参数（必传，按顺序）
void f1(int a, String b) {}
f1(1, 'x');

// 2. 可选位置参数，用 []
void f2(int a, [String? b, int c = 0]) {}
f2(1);
f2(1, 'x');
f2(1, 'x', 5);

// 3. ★ 命名参数，用 {}  —— Flutter 全靠这个
void f3({required int a, String b = '默认', int? c}) {}
f3(a: 1);
f3(a: 1, b: 'x', c: 3);
f3(c: 3, a: 1);          // 顺序随意！
```

**命名参数的意义**：Flutter 的 Widget 动辄十几二十个可选属性，如果用位置参数根本没法写。所以你看到的所有 Widget 都长这样：

```dart
Container(
  width: 100,              // 命名参数
  height: 50,
  padding: EdgeInsets.all(8),
  color: Colors.blue,
  child: Text('hi'),
)
```

`required` 表示这个命名参数必须传。看到 Widget 报错说"缺少 required 参数"，就是这里。

### 函数是一等公民

```dart
// 函数作为变量
final greet = (String name) => print('hi $name');
greet('张三');

// 函数作为参数（回调，Flutter 里到处都是）
void onTap(void Function() callback) {
  callback();
}

// 类型写法
void Function()            // 无参无返回，等价于 VoidCallback
void Function(String)      // 接收 String
String Function(int, int)  // 接收两个 int 返回 String
```

在 Flutter 里：

```dart
ElevatedButton(
  onPressed: () {           // 传一个匿名函数
    print('点了');
  },
  child: const Text('按钮'),
)

// 不传（禁用按钮）就给 null
ElevatedButton(
  onPressed: null,          // 按钮会自动变灰不可点
  child: Text('禁用'),
)
```

## 1.5 类与构造函数（重点）

```dart
class User {
  // 字段
  String name;
  int age;
  String? email;
  
  // 构造函数（完整写法）
  User(String name, int age) {
    this.name = name;
    this.age = age;
  }
}
```

上面太啰嗦，Dart 提供简写：

```dart
class User {
  String name;
  int age;
  
  // 语法糖：直接把参数赋给同名字段
  User(this.name, this.age);
}

final u = User('张三', 25);
```

### Flutter 里最常见的形式

```dart
class User {
  final String name;          // final：不可变，推荐
  final int age;
  final String? email;
  
  // 命名参数 + required + 默认值
  const User({
    required this.name,
    this.age = 18,
    this.email,
  });
}

final u = User(name: '张三', email: 'a@b.com');
```

**把这个形式背下来**，你写每一个自定义 Widget 都是这个套路。

### 命名构造函数

```dart
class User {
  final String name;
  final int age;
  
  const User({required this.name, required this.age});
  
  // 命名构造：User.guest()
  const User.guest() : name = '游客', age = 0;
  
  // 从 JSON 构造（实战高频）
  User.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int? ?? 0;
  
  Map<String, dynamic> toJson() => {'name': name, 'age': age};
}

final guest = User.guest();
final u = User.fromJson({'name': '李四', 'age': 30});
```

> 冒号后面那部分叫**初始化列表**，在构造函数体执行前给 final 字段赋值。第一次见会懵，记住"给 final 字段赋值的地方"就行。

### 工厂构造函数

```dart
class Config {
  static Config? _instance;
  final String baseUrl;
  
  Config._internal(this.baseUrl);       // 私有构造（名字带 _）
  
  factory Config() {                    // 单例
    return _instance ??= Config._internal('https://api.com');
  }
}
```

`factory` 的特点是**可以不返回新对象**，用来做单例、缓存、根据条件返回子类。

### getter / setter

```dart
class Product {
  final double price;
  final int count;
  
  const Product(this.price, this.count);
  
  // getter，像属性一样访问
  double get total => price * count;
  bool get isFree => price == 0;
}

final p = Product(10, 3);
print(p.total);       // 30，不用加括号
```

### 继承与接口

```dart
// 继承
class Animal {
  void speak() => print('...');
}

class Dog extends Animal {
  @override                    // 标记覆盖父类方法
  void speak() => print('汪');
}

// 抽象类
abstract class Shape {
  double area();               // 抽象方法，子类必须实现
  void describe() => print('面积 ${area()}');   // 也能有实现
}

class Circle extends Shape {
  final double r;
  Circle(this.r);
  @override
  double area() => 3.14 * r * r;
}

// 接口：Dart 没有 interface 关键字，任何类都能被 implements
class Robot implements Animal {
  @override
  void speak() => print('滴滴');   // implements 必须实现所有成员
}
```

区别：`extends` 继承实现，只能一个；`implements` 只借用签名必须全部重写，可以多个。

### 私有

```dart
class User {
  String name;        // 公开
  String _password;   // ★ 下划线开头 = 库内私有（文件外访问不到）
  
  void _log() {}      // 私有方法
}
```

Flutter 里你会看到大量 `_MyPageState`、`_buildHeader()`，就是这个约定。

## 1.6 集合操作

### List（数组）

```dart
List<int> nums = [1, 2, 3];
var names = <String>['a', 'b'];       // 泛型写法
List<String> empty = [];

nums.add(4);
nums.addAll([5, 6]);
nums.remove(1);                        // 删元素
nums.removeAt(0);                      // 删索引
nums.length;
nums.isEmpty; nums.isNotEmpty;
nums.first; nums.last;
nums.contains(3);
nums.indexOf(3);
nums.sublist(1, 3);
```

### 和 JS 数组方法对照

```dart
final list = [1, 2, 3, 4, 5];

// map —— 注意必须 .toList()，因为返回的是 Iterable（惰性）
list.map((e) => e * 2).toList();          // [2,4,6,8,10]

// filter → where
list.where((e) => e > 2).toList();        // [3,4,5]

// find → firstWhere
list.firstWhere((e) => e > 3);            // 4
list.firstWhere((e) => e > 99, orElse: () => -1);  // 找不到会抛异常，要给 orElse

// reduce / fold
list.reduce((a, b) => a + b);             // 15
list.fold(0, (sum, e) => sum + e);        // 15，可指定初始值

// some / every
list.any((e) => e > 4);                   // true
list.every((e) => e > 0);                 // true

// forEach
for (final e in list) { print(e); }       // 推荐用 for-in，比 forEach 好调试

// sort（原地排序）
list.sort((a, b) => b.compareTo(a));      // 降序

// 其他
list.reversed.toList();
list.take(3).toList();                    // 前 3 个
list.skip(2).toList();                    // 跳过 2 个
list.join(',');
[...list, 6];                             // 展开
```

> ⚠️ **忘写 `.toList()` 是新手最高频错误**。`map`/`where` 返回 `Iterable`，而 Flutter 的 `children:` 要 `List<Widget>`，类型对不上就报错。

### Map（对象/字典）

```dart
Map<String, dynamic> user = {
  'name': '张三',
  'age': 25,
};

user['name'];                      // 张三
user['xxx'];                       // null，不会报错
user['city'] = '北京';
user.containsKey('name');
user.keys; user.values;
user.remove('age');

// 遍历
user.forEach((k, v) => print('$k=$v'));
for (final entry in user.entries) {
  print('${entry.key}=${entry.value}');
}
```

### Set

```dart
final s = {1, 2, 3};              // 注意：空的 {} 是 Map，空 Set 要写 <int>{}
s.add(3);                         // 不会重复
list.toSet().toList();            // 数组去重
```

## 1.7 控制流与运算符糖

```dart
// if / else / for / while 和 JS 一样
for (var i = 0; i < 3; i++) {}
for (final item in list) {}

// switch（Dart 3 增强了模式匹配）
switch (status) {
  case 'paid':
    print('已支付');
    break;              // Dart 3 里可以省略
  default:
    print('其他');
}

// 三元
final text = isVip ? 'VIP' : '普通';
```

### 级联操作符 `..`（Flutter 特色）

```dart
// 普通写法
final controller = TextEditingController();
controller.text = 'hello';
controller.selection = ...;

// 级联，连续操作同一对象
final controller = TextEditingController()
  ..text = 'hello'
  ..addListener(() {});

// 常见于 List
final list = <int>[]
  ..add(1)
  ..add(2)
  ..sort();
```

`..` 返回的是**对象本身**而不是方法返回值，所以能链式调用。

### 集合里的 if 和 for（Flutter 里超常用）

这是 Dart 独有的语法糖，用来在**列表字面量内部**做条件和循环，写 UI 时极其方便：

```dart
final showTitle = true;
final items = ['a', 'b', 'c'];

Column(
  children: [
    const Text('固定内容'),
    
    if (showTitle) const Text('条件显示'),          // ★ 相当于 v-if
    
    if (isVip) const Text('VIP') else const Text('普通'),
    
    ...items.map((e) => Text(e)),                  // ★ 相当于 v-for
    
    for (final e in items) Text(e),                // ★ 另一种写法，更直观
  ],
)
```

**和你熟悉的写法对照：**

```html
<!-- uniapp / Vue -->
<view v-if="showTitle">条件显示</view>
<view v-for="e in items" :key="e">{{ e }}</view>
```

```jsx
// React
{showTitle && <Text>条件显示</Text>}
{items.map(e => <Text key={e}>{e}</Text>)}
```

```dart
// Flutter —— 更接近 React，但不用写 key
if (showTitle) Text('条件显示'),
for (final e in items) Text(e),
```

## 1.8 异步：Future 与 Stream

### Future ≈ Promise

```dart
// 定义异步函数
Future<String> fetchUser() async {
  await Future.delayed(const Duration(seconds: 1));   // 相当于 setTimeout
  return '张三';
}

// 调用
void main() async {
  final name = await fetchUser();
  print(name);
}

// then 写法（等价于 Promise.then）
fetchUser().then((name) => print(name));
```

### 错误处理

```dart
Future<void> loadData() async {
  try {
    final res = await api.get('/users');
    print(res);
  } catch (e, stack) {          // Dart 能同时捕获堆栈
    print('出错: $e');
  } finally {
    print('总会执行');
  }
}
```

### 并发

| JS | Dart |
|---|---|
| `Promise.all([a, b])` | `await Future.wait([a, b])` |
| `Promise.race([a, b])` | `await Future.any([a, b])` |
| `Promise.resolve(1)` | `Future.value(1)` |
| `new Promise(...)` | `Completer` |

```dart
final results = await Future.wait([
  fetchUser(),
  fetchOrders(),
]);
```

### Stream ≈ 事件流 / 可订阅的多值 Promise

Future 只能返回**一个**值，Stream 能持续吐出**多个**值。类比 RxJS 的 Observable，或者 WebSocket 的消息流。

```dart
Stream<int> counter() async* {          // async* 表示生成 Stream
  for (var i = 0; i < 5; i++) {
    await Future.delayed(const Duration(seconds: 1));
    yield i;                            // 吐出一个值
  }
}

void main() async {
  await for (final n in counter()) {
    print(n);        // 每秒打印 0 1 2 3 4
  }
  
  // 或者订阅
  final sub = counter().listen(
    (n) => print(n),
    onError: (e) => print(e),
    onDone: () => print('结束'),
  );
  // sub.cancel();   // 记得取消，否则内存泄漏
}
```

Flutter 里 Stream 常见于：输入框防抖、WebSocket、定位监听、Firebase 数据、BLoC 状态管理。配合 `StreamBuilder` 直接驱动 UI。

## 1.9 mixin 与 extension

### mixin —— 复用代码块（≈ Vue 2 的 mixin）

```dart
mixin Logger {
  void log(String msg) => print('[LOG] $msg');
}

mixin Validator {
  bool isEmail(String s) => s.contains('@');
}

class UserService with Logger, Validator {    // 可以混入多个
  void run() {
    log('开始');
    isEmail('a@b.com');
  }
}
```

Flutter 里你会经常用到官方的 mixin，比如动画必需的：

```dart
class _MyState extends State<MyWidget> with SingleTickerProviderStateMixin {
  // 这个 mixin 提供了动画需要的 vsync
}
```

### extension —— 给已有类加方法（很爽的特性）

```dart
extension StringExt on String {
  bool get isEmail => contains('@');
  String get firstChar => isEmpty ? '' : this[0];
}

extension NumExt on num {
  Duration get seconds => Duration(seconds: toInt());
}

void main() {
  'a@b.com'.isEmail;          // true
  print(3.seconds);           // 0:00:03.000000
}
```

Flutter 项目里常用来简化间距写法：

```dart
extension WidgetExt on Widget {
  Widget paddingAll(double v) => Padding(padding: EdgeInsets.all(v), child: this);
}

Text('hi').paddingAll(16);    // 比嵌套 Padding 好读
```

---

# M2 Widget 入门

## 2.1 一切皆 Widget

在 Flutter 里，**所有你看到的和看不到的都是 Widget**：文字是 Widget，按钮是 Widget，内边距是 Widget，居中是 Widget，甚至整个 App 也是 Widget。

**关键理解：Widget 不是 UI 本身，而是"UI 的配置描述"**。它是不可变的（所有字段都是 final），每次状态变化，Flutter 会重新创建一批 Widget 对象，然后对比差异去更新真正的渲染树。

这个模型和 **React 的虚拟 DOM 完全一致**。你正在学 React 的话，这里可以无缝迁移：

| React | Flutter |
|---|---|
| JSX 返回的元素 | Widget |
| 函数组件 | `StatelessWidget` |
| 有 state 的类组件 | `StatefulWidget` + `State` |
| `render()` | `build()` |
| `setState()` | `setState()`（名字都一样） |
| props | 构造函数参数（final 字段） |
| 虚拟 DOM diff | Element 树 diff |

和 Vue 对照：

| Vue | Flutter |
|---|---|
| `<template>` | `build()` 返回值 |
| `data` / `ref` | `State` 里的字段 |
| 自动响应式更新 | **必须手动 `setState`** |
| `props` | 构造函数参数 |
| `emit` | 回调函数参数 |
| `computed` | getter 或直接在 build 里算 |

> Vue 用户最大的落差：**Flutter 没有响应式**。改了变量界面不会自己变，必须告诉框架"我改了，你重建"。

## 2.2 main.dart 逐行拆解

删掉 `flutter create` 生成的默认内容，从头写：

```dart
import 'package:flutter/material.dart';   // 引入 Material 设计组件库

void main() {
  runApp(const MyApp());                  // 入口：把根 Widget 挂到屏幕上
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});               // 固定写法，key 用于 diff

  @override
  Widget build(BuildContext context) {
    return MaterialApp(                   // App 的根，提供主题、路由、本地化
      title: '我的应用',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,  // 去掉右上角 DEBUG 角标
      home: const HomePage(),             // 首页
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(                      // 页面骨架：导航栏 + 内容 + 底部栏
      appBar: AppBar(title: const Text('首页')),
      body: const Center(child: Text('Hello Flutter')),
    );
  }
}
```

### 几个关键概念

**`MaterialApp`** —— 整个 App 只有一个，提供主题、路由表、多语言。相当于 uniapp 的 `App.vue` + `pages.json` 的部分职责。还有个 `CupertinoApp` 是 iOS 风格，国内项目基本都用 Material 再自定义样式。

**`Scaffold`** —— 页面级骨架，一个页面一个。它提供的插槽：

```dart
Scaffold(
  appBar: AppBar(title: Text('标题')),          // 顶部导航栏
  body: Container(),                            // 主体内容
  bottomNavigationBar: BottomNavigationBar(...), // 底部 Tab
  floatingActionButton: FloatingActionButton(...), // 悬浮按钮
  drawer: Drawer(),                             // 侧滑抽屉
  backgroundColor: Colors.white,
)
```

对照 uniapp：`appBar` ≈ `navigationBar` 配置，`bottomNavigationBar` ≈ `tabBar`，但**这些在 Flutter 里是写在代码里的，不是配置文件**。

**`BuildContext context`** —— 当前 Widget 在树中的位置句柄。用来向上查找祖先节点的数据：

```dart
Theme.of(context).primaryColor;         // 拿主题
MediaQuery.of(context).size.width;      // 拿屏幕宽度
Navigator.of(context).push(...);        // 拿路由器
```

`XXX.of(context)` 这个模式你会见到几千次，记住它的含义是"沿着 Widget 树往上找最近的 XXX"。

**`super.key`** —— 用于 diff 时识别节点，类比 React 的 `key`。自定义 Widget 时照着写就行，暂时不用深究。

## 2.3 StatelessWidget

**没有内部状态**，数据全靠外部传入。数据变了，父级重建它。

```dart
class ProductCard extends StatelessWidget {
  // 1. 用 final 声明"props"
  final String title;
  final double price;
  final String? imageUrl;
  final VoidCallback? onTap;     // 回调，相当于 emit

  // 2. 命名参数构造函数（这就是 1.5 节那个套路）
  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    this.imageUrl,
    this.onTap,
  });

  // 3. build 描述 UI
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('¥$price', style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
```

使用：

```dart
ProductCard(
  title: 'iPhone 15',
  price: 5999,
  onTap: () => print('点击了'),
)
```

**对照你熟悉的写法：**

```vue
<!-- Vue -->
<script setup>
defineProps({ title: String, price: Number })
const emit = defineEmits(['tap'])
</script>
<template>
  <div class="card" @click="emit('tap')">
    <div class="title">{{ title }}</div>
    <div class="price">¥{{ price }}</div>
  </div>
</template>
<style scoped>.card { padding: 12px; }</style>
```

三点差异一目了然：
1. Flutter 没有模板和样式段，**全在一个 build 里**
2. props 变成了 final 字段 + 构造函数
3. emit 变成了**传函数进来直接调**（这点和 React 一样）

## 2.4 StatefulWidget 与 setState

**有内部状态**，自己能触发重建。

```dart
class Counter extends StatefulWidget {
  final int initial;
  const Counter({super.key, this.initial = 0});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  late int count;              // 状态放这里

  @override
  void initState() {
    super.initState();
    count = widget.initial;    // ★ 用 widget.xxx 访问外部传入的参数
  }

  void _increment() {
    setState(() {              // ★ 必须包在 setState 里，否则界面不更新
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('$count', style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => setState(() => count--),
              child: const Text('-'),
            ),
            const SizedBox(width: 16),
            ElevatedButton(
              onPressed: _increment,
              child: const Text('+'),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 为什么要拆成两个类

`StatefulWidget` 本身还是不可变的（存 props），可变的东西放在 `State` 对象里。父级重建时 Widget 对象被丢弃重造，但 **State 对象会被保留**，所以计数值不会丢。理解这一点，你就理解 Flutter 为什么这么设计了。

### setState 的三条规则

```dart
// ✅ 正确
setState(() { count++; });

// ❌ 改了但没通知，界面不动
count++;

// ❌ 在 setState 外面改，里面空着（能生效但不规范）
count++;
setState(() {});

// ❌ 组件已销毁还调用 → 报错 setState() called after dispose()
Future.delayed(Duration(seconds: 3), () {
  setState(() {});          // 用户可能已经退出这个页面了
});

// ✅ 异步回调里先判断
Future.delayed(const Duration(seconds: 3), () {
  if (!mounted) return;     // mounted 表示组件还活着
  setState(() {});
});
```

> **`if (!mounted) return;` 这行请记牢**，网络请求回来后 setState 前必须判断，是 Flutter 最常见的运行时报错来源。

### 三种写法的对照

```js
// React
const [count, setCount] = useState(0);
setCount(count + 1);
```

```js
// Vue 3
const count = ref(0);
count.value++;              // 自动更新
```

```dart
// Flutter
int count = 0;
setState(() => count++);    // 必须显式通知
```

## 2.5 生命周期

```dart
class _MyState extends State<MyWidget> {
  
  @override
  void initState() {
    super.initState();
    // 只执行一次，做初始化：请求数据、创建 controller、开启监听
    // ⚠️ 这里不能用 context 做 MediaQuery/Theme 之类的操作
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // initState 之后立即执行一次；依赖的 InheritedWidget 变化时也会执行
    // 需要 context 的初始化放这里
  }

  @override
  void didUpdateWidget(MyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 父级传入的参数变了
    if (widget.id != oldWidget.id) {
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 每次 setState 或父级重建都会调用，可能一秒执行 60 次
    // ⚠️ 千万别在这里发网络请求或做重计算
    return Container();
  }

  @override
  void dispose() {
    // 销毁：释放 controller、取消监听、关闭 Stream
    controller.dispose();
    super.dispose();        // ★ dispose 里 super 放最后
  }
}
```

### 对照表

| Flutter | React 类组件 | Vue 3 | uniapp 页面 |
|---|---|---|---|
| `initState` | `componentDidMount` | `onMounted` | `onLoad` / `onReady` |
| `didChangeDependencies` | — | — | — |
| `build` | `render` | `template` 渲染 | — |
| `didUpdateWidget` | `componentDidUpdate` | `onUpdated` | — |
| `dispose` | `componentWillUnmount` | `onUnmounted` | `onUnload` |

> **注意 Flutter 没有 uniapp 的 `onShow` / `onHide`**。页面从后台返回、或从下一页返回时想刷新数据，需要用 `RouteAware` 或者在 `Navigator.push` 的返回值里处理（第 3 周会讲）。

### 必须 dispose 的东西

忘记 dispose 会内存泄漏，这些一定要处理：

```dart
TextEditingController controller;    // controller.dispose()
AnimationController anim;            // anim.dispose()
ScrollController scroll;             // scroll.dispose()
StreamSubscription sub;              // sub.cancel()
Timer timer;                         // timer.cancel()
FocusNode node;                      // node.dispose()
```

## 2.6 父子通信

### 父传子：构造函数参数

```dart
// 父
ChildWidget(title: '标题', count: 5)

// 子
class ChildWidget extends StatelessWidget {
  final String title;
  final int count;
  const ChildWidget({super.key, required this.title, this.count = 0});
}
```

### 子传父：回调函数

```dart
// 父
class _ParentState extends State<Parent> {
  String value = '';
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('收到：$value'),
        ChildWidget(
          onChanged: (v) {                  // 传一个函数下去
            setState(() => value = v);
          },
        ),
      ],
    );
  }
}

// 子
class ChildWidget extends StatelessWidget {
  final ValueChanged<String>? onChanged;    // = void Function(String)?
  const ChildWidget({super.key, this.onChanged});
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onChanged?.call('新值'),   // 调用回调
      child: const Text('传给父级'),
    );
  }
}
```

**常用回调类型别名：**

```dart
VoidCallback              // void Function()
ValueChanged<T>           // void Function(T value)
ValueGetter<T>            // T Function()
```

对照：Vue 的 `emit('change', v)` ≈ Flutter 的 `onChanged?.call(v)`。写法上 Flutter 和 React 一致。

### 跨层级传递

层级深了一层层传太痛苦（prop drilling）。Flutter 的方案是 `InheritedWidget`，但一般不直接写，而是用 Provider 等库封装 —— 这是第 3 周 M6 的内容。

## 2.7 const 与性能

```dart
// ❌ 每次 build 都创建新对象
Text('固定标题')

// ✅ 编译期常量，复用同一个对象，重建时直接跳过
const Text('固定标题')
```

**规则：只要 Widget 的所有参数都是编译期常量，就加 `const`。**

```dart
const SizedBox(height: 16)
const EdgeInsets.all(12)
const Icon(Icons.home)
const Text('标题', style: TextStyle(fontSize: 16))     // TextStyle 也能 const

// 有变量就不能加
Text(title)                       // title 是变量
Container(color: myColor)
```

VS Code 会给可以加 const 的地方标黄提示，跟着改就行。也可以在 `analysis_options.yaml` 里开启强制检查：

```yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
```

另一个性能要点：**把大 build 拆成小 Widget**，而不是拆成方法。

```dart
// ⚠️ 拆成方法：父级重建时它也一定重建
Widget _buildHeader() => Container(...);

// ✅ 拆成独立 Widget：可以被 const 优化、独立重建
class _Header extends StatelessWidget { ... }
```

## 2.8 热重载的边界

Hot Reload 很爽，但有些改动它处理不了，需要 Hot Restart（`R`）甚至完全重启：

| 改动 | 需要 |
|---|---|
| 改 build 里的 UI | `r` 热重载 ✅ |
| 改样式、文案、颜色 | `r` ✅ |
| 改 `initState` 逻辑 | `R` 热重启（因为 initState 不会重跑） |
| 改全局变量 / 静态字段初始值 | `R` |
| 改 `main()` | `R` |
| 改枚举、类的继承关系 | `R` |
| 加了新依赖 (`pubspec.yaml`) | `flutter pub get` + 完全重启 |
| 改了 android/ios 原生配置 | 完全重启 |

> 遇到"改了没反应"，先按 `R`，还不行就 `q` 退出重跑，再不行 `flutter clean`。

---

# 本周产出物

## 任务：手写一个可交互的商品卡片页

要求覆盖本周全部知识点，不许抄现成模板。

**需求**
1. 定义一个 `Product` 类：`id`（int）、`name`（String）、`price`（double）、`tag`（String?，可空）、`stock`（int，默认 0）。用命名参数构造函数。
2. 写一个 `ProductCard` StatelessWidget，接收一个 `Product` 和一个 `onFavorite` 回调。
3. 卡片显示：名称、价格（带 ¥）、标签（**为 null 时不显示**）、库存（为 0 时显示"缺货"红字）。
4. 写一个 `HomePage` StatefulWidget，维护一个 `List<Product>` 和一个"收藏数量"计数。
5. 用 `Column` + `...list.map()` 渲染出所有卡片。
6. 点击卡片上的收藏按钮，收藏数 +1，AppBar 标题显示当前收藏数。
7. 加一个按钮，点击后往列表里 add 一个新商品，界面自动更新。

**必须用到**：`final` 字段、`required` 命名参数、空安全 `?` 和 `??`、集合 `if`、`...map()`、`setState`、`initState`、`const`、回调函数。

**完成标准**：真机跑起来，点击有反应，代码里没有一个 `dynamic`，`flutter analyze` 无警告。

<details>
<summary>卡住了看提示（尽量先自己写）</summary>

```dart
class Product {
  final int id;
  final String name;
  final double price;
  final String? tag;
  final int stock;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.tag,
    this.stock = 0,
  });
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onFavorite;

  const ProductCard({super.key, required this.product, this.onFavorite});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name),
                  if (product.tag != null) Text(product.tag!),   // 集合 if
                  Text('¥${product.price}'),
                  if (product.stock == 0)
                    const Text('缺货', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
            IconButton(
              onPressed: onFavorite,
              icon: const Icon(Icons.favorite_border),
            ),
          ],
        ),
      ),
    );
  }
}
```

HomePage 部分自己完成，注意 `children: [...products.map((p) => ProductCard(...))]`。
</details>

---

# 自检与练习

## 自检清单

答不上来就回去翻对应小节。

- [ ] `var` / `final` / `const` / `late` 四者区别？（1.2）
- [ ] 为什么 Flutter 里到处都是 `const`？（2.7）
- [ ] `String?` 和 `String` 的区别？`!` 有什么风险？（1.3）
- [ ] `{required this.name}` 这个语法在做什么？（1.4 / 1.5）
- [ ] `list.map((e) => Text(e))` 直接放进 `children` 会报什么错，为什么？（1.6）
- [ ] 集合 `if` 和 `for` 分别对应 Vue 的什么？（1.7）
- [ ] StatelessWidget 和 StatefulWidget 怎么选？（2.3 / 2.4）
- [ ] 为什么 StatefulWidget 要拆成两个类？（2.4）
- [ ] 改了变量界面没变，什么原因？（2.4）
- [ ] `if (!mounted) return;` 是干什么的？（2.4）
- [ ] `initState` 对应 uniapp 的哪个钩子？Flutter 有没有 `onShow`？（2.5）
- [ ] 哪些对象必须在 dispose 里释放？（2.5）
- [ ] 子组件怎么把数据传给父组件？（2.6）

## 补充练习

1. 写一个 `extension` 给 `double` 加一个 `yuan` getter，返回 `'¥12.00'` 这样的字符串（保留两位小数，用 `toStringAsFixed(2)`）。
2. 写一个异步函数模拟接口：延迟 2 秒返回一个 `List<Product>`，在 `initState` 里调用，回来后 `setState` 更新列表（记得判 `mounted`）。
3. 把上面商品页的卡片列表改成用 `for (final p in products)` 写法，对比和 `map` 的差别。
4. 故意写一个会报 `Null check operator used on a null value` 的代码，然后修好它 —— 亲手制造一次这个错误，以后就认得了。

## 下周预告

第 2 周进入**布局**，这是整个 Flutter 学习曲线最陡的部分。你会彻底告别 CSS，学会用"约束 → 尺寸 → 位置"三步来思考界面。提前有个心理准备：**前两天会很难受，第三天会突然通**。
