# Dart 数据类型与内置方法学习笔记

> 适合刚接触 Dart / Flutter 的学习者快速查阅。
> 文中的示例可以在 Dart 文件中运行，例如：
>
> ```bash
> dart run 01_dart_basics.dart
> ```

## 目录

- [1. 前置概念](#1-前置概念)
- [2. 数据类型总览](#2-数据类型总览)
- [3. 数值类型：num / int / double](#3-数值类型num--int--double)
- [4. 字符串：String](#4-字符串string)
- [5. 布尔类型：bool](#5-布尔类型bool)
- [6. 列表：List](#6-列表list)
- [7. 集合：Set](#7-集合set)
- [8. 映射：Map](#8-映射map)
- [9. 其他类型：Rune / Symbol / Null](#9-其他类型rune--symbol--null)
- [10. 可空类型与空安全](#10-可空类型与空安全)
- [11. dynamic / Object / var / final / const](#11-dynamic--object--var--final--const)
- [12. Record 记录类型](#12-record-记录类型)
- [13. Enum 枚举类型](#13-enum-枚举类型)
- [14. 常用类型转换](#14-常用类型转换)
- [15. 综合演示](#15-综合演示)
- [16. 内置方法速查表](#16-内置方法速查表)

## 1. 前置概念

1. **一切皆对象**：`int`、`String`、`bool`、`null` 在 Dart 中都是对象。
2. **类型安全**：Dart 会在编译期尽量检查类型，但仍可使用 `dynamic` 关闭部分检查。
3. **程序入口**：普通 Dart 程序从 `main()` 开始执行。
4. **空安全**：默认情况下变量不能为 `null`，除非明确声明为可空类型。
5. **变量可以类型推断**：使用 `var` 时，类型由第一次赋值决定。

```dart
void main() {
  var name = 'Dart'; // name 被推断为 String
  int year = 2024;   // 明确指定类型
  print('Hello, $name $year');
}
```

## 2. 数据类型总览

| 类型 | 示例 | 说明 | 常用场景 |
| --- | --- | --- | --- |
| `num` | `1`, `2.5` | 数值类型的公共父类型 | 不确定整数还是小数时 |
| `int` | `1`, `-10` | 整数 | 数量、索引、计数 |
| `double` | `1.0`, `3.14` | 浮点数 | 价格、比例、小数 |
| `String` | `'Dart'` | 字符串 | 文本、输入输出 |
| `bool` | `true`, `false` | 布尔值 | 条件判断 |
| `List` | `[1, 2, 3]` | 有序集合，可重复 | 数组、列表 |
| `Set` | `{1, 2, 3}` | 无序集合，不重复 | 去重、集合运算 |
| `Map` | `{'a': 1}` | 键值对 | 字典、配置 |
| `Rune` | `Runes('你好')` | Unicode 码点 | 处理特殊字符 |
| `Symbol` | `#foo` | 符号标识 | 反射、库标识 |
| `Null` | `null` | 表示空值 | 没有值 |
| `Object` | 任意非空对象 | 所有非空类型的基类 | 通用参数 |
| `dynamic` | 任意类型 | 关闭静态类型检查 | 动态数据 |
| `Record` | `(1, 'a')` | 记录/元组 | 返回多个值 |

## 3. 数值类型：num / int / double

### 3.1 声明方式

```dart
void main() {
  int age = 18;
  double price = 12.5;
  num number = 3; // 可以是 int，也可以改为 double

  var a = 1;      // int
  var b = 1.0;    // double

  print(age);
  print(price);
  print(number);
  print(a.runtimeType);
  print(b.runtimeType);
}
```

### 3.2 常用属性

| 属性 | 说明 |
| --- | --- |
| `isFinite` | 是否为有限数 |
| `isInfinite` | 是否为正负无穷 |
| `isNaN` | 是否不是数字 |
| `isNegative` | 是否为负数 |
| `sign` | 符号：`-1`、`0`、`1` |
| `hashCode` | 哈希码 |

```dart
void main() {
  double x = 3.14;
  print(x.isFinite);   // true
  print(x.isNegative); // false
  print(x.sign);       // 1

  double bad = 0 / 0;
  print(bad.isNaN);    // true
}
```

### 3.3 常用内置方法

| 方法 | 说明 |
| --- | --- |
| `abs()` | 返回绝对值 |
| `ceil()` | 向上取整 |
| `floor()` | 向下取整 |
| `round()` | 四舍五入取整 |
| `truncate()` | 去掉小数部分 |
| `toInt()` | 转为 `int` |
| `toDouble()` | 转为 `double` |
| `toString()` | 转为字符串 |
| `toStringAsFixed(n)` | 保留 n 位小数的字符串 |
| `toStringAsPrecision(n)` | 保留 n 位有效数字 |
| `clamp(min, max)` | 限制在 `[min, max]` 范围内 |
| `remainder(other)` | 取余数 |
| `compareTo(other)` | 比较大小，返回 -1/0/1 |

```dart
void main() {
  double price = 12.567;

  print(price.abs());                 // 12.567
  print(price.ceil());                // 13
  print(price.floor());               // 12
  print(price.round());               // 13
  print(price.truncate());            // 12
  print(price.toStringAsFixed(2));    // 12.57

  int a = -5;
  int b = 3;
  print(a.abs());                     // 5
  print(a.remainder(b));              // -2
  print(a.clamp(0, 10));              // 0
  print(a.compareTo(b));              // -1
}
```

### 3.4 静态方法

`parse` 可以把字符串转为数字；解析失败时，`tryParse` 返回 `null`。

```dart
void main() {
  int n1 = int.parse('123');
  double n2 = double.parse('3.14');
  num n3 = num.parse('8');

  int? maybeInt = int.tryParse('abc');
  double? maybeDouble = double.tryParse('2.5');

  print(n1);          // 123
  print(n2);          // 3.14
  print(n3);          // 8
  print(maybeInt);    // null
  print(maybeDouble); // 2.5
}
```

## 4. 字符串：String

### 4.1 声明与拼接

Dart 支持单引号、双引号、三引号多行字符串，以及原始字符串。

```dart
 void main() {
  String s1 = 'Hello';
  String s2 = "Dart";

  String multi = '''
第一行
第二行
''';

  String raw = r'换行符不会生效：\n';

  print(s1 + ' ' + s2);              // Hello Dart
  print('$s1 $s2');                  // 字符串插值
  print('${s1.toUpperCase()}');      // 插值中写表达式
  print(multi);
  print(raw);
}
```

### 4.2 常用属性

| 属性 | 说明 |
| --- | --- |
| `length` | 字符串长度 |
| `isEmpty` | 是否为空字符串 |
| `isNotEmpty` | 是否非空 |
| `codeUnits` | UTF-16 编码单元列表 |
| `runes` | Unicode 码点 |
| `hashCode` | 哈希码 |

```dart
void main() {
  String s = 'Flutter';
  print(s.length);      // 7
  print(s.isEmpty);     // false
  print(s.isNotEmpty);  // true
  print(s.codeUnits);   // [70, 108, 117, 116, 116, 101, 114]
  print(s.runes);   // (70, 108, 117, 116, 116, 101, 114)
  print(s.hashCode);   // [70, 108, 117, 116, 116, 101, 114]
}
```

### 4.3 常用内置方法

| 方法 | 说明 |
| --- | --- |
| `toUpperCase()` | 转大写 |
| `toLowerCase()` | 转小写 |
| `trim()` | 去掉首尾空白 |
| `trimLeft()` / `trimRight()` | 去掉左侧/右侧空白 |
| `split(pattern)` | 按分隔符拆分 |
| `join(list)` | 把列表拼成字符串 |
| `substring(start, [end])` | 截取子串 |
| `contains(other)` | 是否包含子串 |
| `startsWith(prefix)` | 是否以某串开头 |
| `endsWith(suffix)` | 是否以某串结尾 |
| `indexOf(pattern)` | 查找首个位置，找不到返回 -1 |
| `lastIndexOf(pattern)` | 查找最后一个位置 |
| `replaceAll(from, replace)` | 替换所有匹配 |
| `replaceFirst(from, replace)` | 替换第一个匹配 |
| `padLeft(width, [padding])` | 左侧补全 |
| `padRight(width, [padding])` | 右侧补全 |
| `compareTo(other)` | 比较两个字符串 |

```dart
void main() {
  String text = '  Dart and Flutter  ';

  print(text.toUpperCase());               // '  DART AND FLUTTER  '
  print(text.toLowerCase());               // '  dart and flutter  '
  print(text.trim());                      // 'Dart and Flutter'

  String words = 'apple,banana,orange';
  List<String> parts = words.split(',');
  print(parts);                            // [apple, banana, orange]
  print(parts.join(' | '));                // apple | banana | orange

  print(words.substring(6, 12));           // banana
  print(words.contains('apple'));          // true
  print(words.startsWith('app'));          // true
  print(words.endsWith('ge'));             // true
  print(words.indexOf('banana'));          // 6
  print(words.lastIndexOf('a'));           // 17

  print(words.replaceAll('a', '@'));       // @pple,b@n@n@,or@nge
  print(words.replaceFirst('a', '@'));     // @pple,banana,orange

  print('7'.padLeft(3, '0'));              // 007
  print('7'.padRight(3, '0'));             // 700
}
```

## 5. 布尔类型：bool

`bool` 只有两个值：`true` 和 `false`。

```dart
void main() {
  bool isLogin = true;
  bool isAdult = false;

  print(isLogin);
  print(isAdult);
  print(!isLogin);                 // false
  print(isLogin && isAdult);       // false
  print(isLogin || isAdult);       // true
  print(isLogin.toString());       // 'true'

  int age = 20;
  bool canVote = age >= 18;
  print(canVote);                  // true
}
```

## 6. 列表：List

### 6.1 声明方式

```dart
void main() {
  List<int> nums = [1, 2, 3];
  List<String> names = ['Alice', 'Bob', 'Carol'];
  var mixed = [1, 'two', 3.0]; // List<Object>

  List<int> generated = List<int>.generate(5, (index) => index * 2);
  List<int> filled = List<int>.filled(3, 0);

  print(nums);
  print(names);
  print(mixed);
  print(generated); // [0, 2, 4, 6, 8]
  print(filled);    // [0, 0, 0]
}
```

### 6.2 常用属性

| 属性 | 说明 |
| --- | --- |
| `length` | 列表长度 |
| `first` | 第一个元素 |
| `last` | 最后一个元素 |
| `isEmpty` | 是否为空 |
| `isNotEmpty` | 是否非空 |
| `reversed` | 反向视图 |

```dart
void main() {
  List<int> nums = [10, 20, 30];
  print(nums.length);        // 3
  print(nums.first);         // 10
  print(nums.last);          // 30
  print(nums.isEmpty);       // false
  print(nums.reversed);      // (30, 20, 10)
  print(nums.reversed.toList()); // [30, 20, 10]
}
```

### 6.3 增删改方法

| 方法 | 说明 |
| --- | --- |
| `add(item)` | 在末尾添加一个元素 |
| `addAll(items)` | 添加多个元素 |
| `insert(index, item)` | 在指定位置插入 |
| `insertAll(index, items)` | 在指定位置插入多个 |
| `remove(item)` | 删除第一个匹配元素 |
| `removeAt(index)` | 删除指定位置元素 |
| `removeLast()` | 删除最后一个元素 |
| `removeWhere(test)` | 删除满足条件的元素 |
| `clear()` | 清空列表 |
| `sort([compare])` | 排序 |
| `shuffle([random])` | 随机打乱 |

```dart
void main() {
  List<int> nums = [3, 1, 2];

  nums.add(4);
  print(nums);          // [3, 1, 2, 4]

  nums.addAll([5, 6]);
  print(nums);          // [3, 1, 2, 4, 5, 6]

  nums.insert(0, 100);
  print(nums);          // [100, 3, 1, 2, 4, 5, 6]

  nums.remove(3);
  print(nums);          // [100, 1, 2, 4, 5, 6]

  nums.removeAt(0);
  print(nums);          // [1, 2, 4, 5, 6]

  nums.removeWhere((item) => item > 4);
  print(nums);          // [1, 2, 4]

  nums.sort();
  print(nums);          // [1, 2, 4]

  nums.clear();
  print(nums);          // []
}
```

### 6.4 查找与判断方法

```dart
void main() {
  List<String> fruits = ['apple', 'banana', 'orange'];

  print(fruits.contains('banana'));   // true
  print(fruits.indexOf('orange'));    // 2
  print(fruits.lastIndexOf('apple')); // 0
  print(fruits.where((f) => f.length > 5).toList()); // [banana, orange]

  String? found = fruits.firstWhere(
    (f) => f.startsWith('o'),
    orElse: () => '',
  );
  print(found); // orange
}
```

### 6.5 高阶方法

`forEach`、`map`、`where`、`any`、`every`、`reduce`、`fold`、`expand` 是处理列表时最常用的内置方法。

```dart
void main() {
  List<int> nums = [1, 2, 3, 4, 5];

  // 遍历
  nums.forEach((n) => print(n * 2));

  // 映射，生成新列表
  List<int> doubled = nums.map((n) => n * 2).toList();
  print(doubled); // [2, 4, 6, 8, 10]

  // 过滤
  List<int> even = nums.where((n) => n.isEven).toList();
  print(even); // [2, 4]

  // 是否至少一个满足
  print(nums.any((n) => n > 3)); // true

  // 是否全部满足
  print(nums.every((n) => n > 0)); // true

  // 累加
  int sum = nums.reduce((a, b) => a + b);
  print(sum); // 15

  // 带初始值的折叠
  int total = nums.fold(0, (a, b) => a + b);
  print(total); // 15

  // 展开嵌套列表
  List<List<int>> nested = [
    [1, 2],
    [3, 4],
  ];
  List<int> flat = nested.expand((list) => list).toList();
  print(flat); // [1, 2, 3, 4]
}
```

## 7. 集合：Set

`Set` 中的元素不能重复，默认是 `LinkedHashSet`，会保留插入顺序。

### 7.1 声明方式

```dart
void main() {
  Set<int> numbers = {1, 2, 3, 3, 4};
  print(numbers); // {1, 2, 3, 4}

  Set<String> names = <String>{};
  names.add('Alice');
  names.add('Bob');
  names.add('Alice'); // 不会重复添加
  print(names);       // {Alice, Bob}

  List<int> withDuplicates = [1, 2, 2, 3, 3, 3];
  Set<int> unique = withDuplicates.toSet();
  print(unique); // {1, 2, 3}
}
```

### 7.2 常用内置方法

| 方法 | 说明 |
| --- | --- |
| `add(item)` | 添加元素 |
| `addAll(items)` | 添加多个元素 |
| `remove(item)` | 删除元素 |
| `contains(item)` | 是否包含 |
| `containsAll(items)` | 是否包含全部 |
| `union(other)` | 并集 |
| `intersection(other)` | 交集 |
| `difference(other)` | 差集 |
| `lookup(item)` | 返回集合中相等的元素 |
| `clear()` | 清空 |

```dart
void main() {
  Set<int> a = {1, 2, 3};
  Set<int> b = {3, 4, 5};

  print(a.union(b));        // {1, 2, 3, 4, 5}
  print(a.intersection(b)); // {3}
  print(a.difference(b));   // {1, 2}

  a.add(9);
  print(a.contains(9));     // true

  a.remove(9);
  print(a);                 // {1, 2, 3}

  print(a.containsAll({1, 2})); // true

  List<int> result = a.where((n) => n > 1).toList();
  print(result); // [2, 3]
}
```

## 8. 映射：Map

`Map` 用于存储键值对，键不能重复。

### 8.1 声明方式

```dart
void main() {
  Map<String, int> scores = {
    'Alice': 90,
    'Bob': 85,
  };

  Map<String, String> info = Map<String, String>();
  info['name'] = 'Dart';

  Map<String, int> fromList = Map.from({
    'x': 1,
    'y': 2,
  });

  print(scores);
  print(info);
  print(fromList);
}
```

### 8.2 常用属性

```dart
void main() {
  Map<String, int> scores = {
    'Alice': 90,
    'Bob': 85,
  };

  print(scores.length);   // 2
  print(scores.isEmpty);  // false
  print(scores.keys);     // (Alice, Bob)
  print(scores.values);   // (90, 85)
  print(scores.entries);  // (MapEntry(Alice: 90), MapEntry(Bob: 85))
}
```

### 8.3 常用内置方法

| 方法 | 说明 |
| --- | --- |
| `containsKey(key)` | 是否包含键 |
| `containsValue(value)` | 是否包含值 |
| `putIfAbsent(key, ifAbsent)` | 键不存在时插入并返回新值 |
| `remove(key)` | 删除键并返回值 |
| `update(key, update)` | 更新已有键的值 |
| `updateAll(update)` | 更新所有值 |
| `clear()` | 清空 |
| `forEach(action)` | 遍历键值对 |
| `map(transform)` | 转换后生成新 Map |

```dart
void main() {
  Map<String, int> scores = {
    'Alice': 90,
    'Bob': 85,
  };

  print(scores.containsKey('Alice'));   // true
  print(scores.containsValue(85));      // true

  scores['Carol'] = 88;
  print(scores);                        // {Alice: 90, Bob: 85, Carol: 88}

  int oldValue = scores.putIfAbsent('Alice', () => 100);
  print(oldValue);                      // 90，因为 Alice 已存在

  scores.update('Alice', (value) => value + 5);
  print(scores['Alice']);               // 95

  scores.remove('Bob');
  print(scores);                        // {Alice: 95, Carol: 88}

  scores.forEach((key, value) {
    print('$key 的分数是 $value');
  });

  Map<String, String> labels = scores.map((key, value) {
    return MapEntry(key, '分数：$value');
  });
  print(labels);                        // {Alice: 分数：95, Carol: 分数：88}
}
```

## 9. 其他类型：Rune / Symbol / Null

### 9.1 Rune

`Rune` 表示 Unicode 码点，适合处理 emoji 或某些需要按字符而不是按 UTF-16 单元处理的文本。

```dart
void main() {
  String text = 'A😀';
  print(text.length);    // 3，因为 emoji 占两个 UTF-16 单元
  print(text.runes);     // (65, 128512)

  String fromRune = String.fromCharCode(128512);
  print(fromRune);       // 😀

  Runes runes = Runes('你好');
  for (final rune in runes) {
    print(rune);
  }
}
```

### 9.2 Symbol

`Symbol` 主要用于反射、库标识和命名参数，日常业务中较少使用。

```dart
void main() {
  Symbol symbol = #exampleSymbol;
  print(symbol); // Symbol("exampleSymbol")
}
```

### 9.3 Null

`null` 表示“没有值”。它本身是 `Null` 类型的唯一实例。

```dart
void main() {
  String? value;
  print(value);          // null
  print(value == null);  // true
}
```

## 10. 可空类型与空安全

### 10.1 可空类型

```dart
void main() {
  int? maybeInt = null;   // 可以存储 null
  String? name;           // 默认也是 null

  if (name != null) {
    print(name.length);
  }

  // 安全调用：name 为 null 时整个表达式返回 null
  print(name?.length);
}
```

### 10.2 常用空安全运算符

| 运算符 | 说明 |
| --- | --- |
| `?.` | 安全调用 |
| `??` | 如果左侧为 null，则使用右侧 |
| `??=` | 如果变量为 null，则赋值 |
| `!` | 断言非空 |

```dart
void main() {
  String? name;

  String display = name ?? '匿名用户';
  print(display); // 匿名用户

  name ??= 'Dart';
  print(name); // Dart

  print(name!.length); // 4，这里 name 一定非空
}
```

### 10.3 `late` 关键字

`late` 表示变量稍后再初始化，但首次使用前必须完成赋值。

```dart
late String description;

void main() {
  description = '学习 Dart';
  print(description);
}
```

## 11. dynamic / Object / var / final / const

### 11.1 dynamic

`dynamic` 会关闭静态类型检查，适合处理结构不确定的数据，但要小心运行时错误。

```dart
void main() {
  dynamic value = 'Hello';
  print(value.length); // 5

  value = 123;
  print(value + 1); // 124
}
```

### 11.2 Object

`Object` 是所有非空类型的基类。声明为 `Object` 的变量可以保存任意非空对象，但不能直接调用任意类型特有的方法。

```dart
void main() {
  Object value = 'Hello';
  print(value); // Hello

  // 需要先判断或转换类型
  if (value is String) {
    print(value.length);
  }
}
```

### 11.3 var / final / const

| 关键字 | 说明 |
| --- | --- |
| `var` | 类型推断，声明后可重新赋值 |
| `final` | 只能赋值一次，运行时可确定值 |
| `const` | 编译期常量，值在编译时确定 |

```dart
void main() {
  var a = 1;
  a = 2; // 可以

  final b = DateTime.now(); // 运行时确定
  // b = DateTime.now(); // 错误，final 只能赋值一次

  const c = 100; // 编译期常量
  // const d = DateTime.now(); // 错误，DateTime.now() 不是常量

  print('$a, $b, $c');
}
```

## 12. Record 记录类型

Dart 3 引入的 `Record` 可以像“元组”一样一次返回多个值。

```dart
void main() {
  (String, int) user = ('Alice', 18);
  print(user.$1); // Alice
  print(user.$2); // 18

  ({String name, int age}) person = (name: 'Bob', age: 20);
  print(person.name); // Bob
  print(person.age);  // 20

  var result = getInfo();
  print('${result.$1}，${result.$2} 岁');

  var mixed = (1, 'two', true);
  print(mixed);
}

(String, int) getInfo() {
  return ('Carol', 25);
}
```

## 13. Enum 枚举类型

### 13.1 简单枚举

```dart
enum Color {
  red,
  green,
  blue,
}

void main() {
  Color favorite = Color.blue;
  print(favorite);        // Color.blue
  print(favorite.index);  // 2

  for (final color in Color.values) {
    print(color);
  }
}
```

### 13.2 带字段和方法的增强枚举

```dart
enum Status {
  success(200, '成功'),
  notFound(404, '未找到'),
  serverError(500, '服务器错误');

  const Status(this.code, this.message);

  final int code;
  final String message;

  bool get isError => code >= 400;
}

void main() {
  Status status = Status.notFound;
  print(status.code);     // 404
  print(status.message);  // 未找到
  print(status.isError);  // true
}
```

## 14. 常用类型转换

### 14.1 字符串与数字互转

```dart
void main() {
  String numberText = '42';
  int number = int.parse(numberText);
  print(number + 1); // 43

  String doubleText = '3.14';
  double pi = double.parse(doubleText);
  print(pi);

  int? safeNumber = int.tryParse('not a number');
  print(safeNumber); // null

  print(123.toString());          // '123'
  print(3.14159.toStringAsFixed(2)); // '3.14'
}
```

### 14.2 集合互转

```dart
void main() {
  List<int> nums = [1, 2, 3, 3];

  Set<int> unique = nums.toSet();
  print(unique); // {1, 2, 3}

  List<int> backToList = unique.toList();
  print(backToList); // [1, 2, 3]

  List<String> words = ['a', 'bb', 'ccc'];
  Map<String, int> lengthMap = {
    for (final word in words) word: word.length,
  };
  print(lengthMap); // {a: 1, bb: 2, ccc: 3}
}
```

### 14.3 类型判断与转换

```dart
void main() {
  Object value = 123;

  print(value is int);       // true
  print(value is String);    // false
  print(value is! String);   // true

  if (value is int) {
    int intValue = value as int; // as 强制转换
    print(intValue + 1);         // 124
  }
}
```

## 15. 综合演示

下面的示例把多个数据类型和内置方法组合起来，适合整体复习。

```dart
void main() {
  // 数字处理
  List<double> prices = [12.3, 8.88, 100, 56.789];
  double total = prices.fold(0, (sum, price) => sum + price);
  print('总价：${total.toStringAsFixed(2)}');

  // 字符串处理
  String title = '  dart language  ';
  print(title.trim().toUpperCase());

  // 列表去重与排序
  List<int> scores = [88, 92, 75, 88, 100, 92];
  List<int> sortedUniqueScores = scores.toSet().toList()..sort();
  print(sortedUniqueScores);

  // 过滤及格分数
  List<int> passed = scores.where((score) => score >= 90).toList();
  print('90 分以上：$passed');

  // Map 统计
  Map<String, int> userAges = {
    'Alice': 18,
    'Bob': 20,
    'Carol': 22,
  };

  userAges['Dave'] = 19;
  userAges.update('Alice', (age) => age + 1);

  bool hasBob = userAges.containsKey('Bob');
  int totalAge = userAges.values.fold(0, (sum, age) => sum + age);
  print('有 Bob 吗？$hasBob，总年龄：$totalAge');

  // 可空类型与默认值
  String? nickname;
  print(nickname ?? '还没有昵称');

  // Record 一次返回多个结果
  var result = analyzeScores(scores);
  print('最高分：${result.$1}，最低分：${result.$2}，平均分：${result.$3.toStringAsFixed(2)}');
}

(int, int, double) analyzeScores(List<int> scores) {
  int maxScore = scores.reduce((a, b) => a > b ? a : b);
  int minScore = scores.reduce((a, b) => a < b ? a : b);
  double average = scores.fold(0, (sum, score) => sum + score) / scores.length;
  return (maxScore, minScore, average);
}
```

## 16. 内置方法速查表

### 数字

| 方法 | 作用 |
| --- | --- |
| `abs()` | 绝对值 |
| `round()` | 四舍五入 |
| `ceil()` / `floor()` | 向上 / 向下取整 |
| `toStringAsFixed(n)` | 保留 n 位小数 |
| `clamp(min, max)` | 限制范围 |
| `int.parse()` / `double.parse()` | 字符串转数字 |
| `int.tryParse()` / `double.tryParse()` | 安全解析，失败返回 null |

### 字符串

| 方法 | 作用 |
| --- | --- |
| `trim()` | 去首尾空白 |
| `split()` | 拆分 |
| `join()` | 拼接列表 |
| `substring()` | 截取 |
| `contains()` | 包含判断 |
| `startsWith()` / `endsWith()` | 前缀 / 后缀判断 |
| `replaceAll()` | 全部替换 |
| `padLeft()` / `padRight()` | 补全字符 |

### List

| 方法 | 作用 |
| --- | --- |
| `add()` / `addAll()` | 添加元素 |
| `remove()` / `removeAt()` | 删除元素 |
| `contains()` / `indexOf()` | 查找 |
| `sort()` | 排序 |
| `map()` | 映射转换 |
| `where()` | 过滤 |
| `any()` / `every()` | 条件判断 |
| `reduce()` / `fold()` | 累加 |
| `expand()` | 展开嵌套列表 |

### Set

| 方法 | 作用 |
| --- | --- |
| `add()` / `remove()` | 添加 / 删除 |
| `contains()` | 包含判断 |
| `union()` | 并集 |
| `intersection()` | 交集 |
| `difference()` | 差集 |

### Map

| 方法 | 作用 |
| --- | --- |
| `containsKey()` | 键是否存在 |
| `containsValue()` | 值是否存在 |
| `putIfAbsent()` | 不存在时插入 |
| `update()` | 更新值 |
| `remove()` | 删除键 |
| `forEach()` | 遍历 |
| `keys` / `values` / `entries` | 访问键、值、键值对 |

## 建议练习

1. 用 `List` 和 `map` 把一组数字全部乘以 2，并过滤出偶数。
2. 用 `Set` 对一篇文章中的单词去重，并统计单词数量。
3. 用 `Map` 实现一个简单的学生成绩表，支持新增、更新、查询和删除。
4. 把 `List<Map<String, Object>>` 转换成一个新的可展示字符串列表。
5. 练习 `int.tryParse`、`String?`、`??` 等空安全写法，处理用户输入。
