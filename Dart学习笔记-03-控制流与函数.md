# Dart 控制流与函数学习笔记

> 适合刚接触 Dart / Flutter 的学习者快速查阅。
> 文中的示例可以在 Dart 文件中运行，例如：
>
> ```bash
> dart run 03_control_flow_functions.dart
> ```

## 目录

- [1. 程序执行顺序](#1-程序执行顺序)
- [2. 条件判断 if else](#2-条件判断-if-else)
- [3. 条件判断 switch 语句](#3-条件判断-switch-语句)
- [4. switch 表达式](#4-switch-表达式)
- [5. for 循环](#5-for-循环)
- [6. while 与 do-while 循环](#6-while-与-do-while-循环)
- [7. break continue 与标签](#7-break-continue-与标签)
- [8. 异常处理 try catch finally](#8-异常处理-try-catch-finally)
- [9. 函数的定义与调用](#9-函数的定义与调用)
- [10. 函数的参数](#10-函数的参数)
- [11. 返回值与箭头函数](#11-返回值与箭头函数)
- [12. 匿名函数与闭包](#12-匿名函数与闭包)
- [13. 高阶函数](#13-高阶函数)
- [14. 综合演示](#14-综合演示)
- [15. 速查表](#15-速查表)
- [16. 建议练习](#16-建议练习)

## 1. 程序执行顺序

程序默认从 `main()` 开始，一行接一行往下执行。控制流就是用来"改变执行顺序"的：条件判断决定"走哪条路"，循环决定"重复走几次"，异常处理决定"出错时往哪跳"。

```dart
void main() {
  print('第一步');
  print('第二步');
  print('第三步');
}
```

## 2. 条件判断 if else

`if` 括号里的条件必须是 `bool` 类型。多个条件用 `else if` 连接，最后用 `else` 兜底。

```dart
void main() {
  int score = 85;

  if (score >= 90) {
    print('优秀');
  } else if (score >= 60) {
    print('及格');
  } else {
    print('不及格');
  }
  // 输出：及格
}
```

两个细节：

- 只有一条语句时，花括号可以省略，但建议始终保留，避免后续加代码时出错。
- Dart 的条件只认 `bool`：`if (name)` 这种写法会编译报错，必须写成 `if (name != null)`（在运算符笔记里也提过）。

## 3. 条件判断 switch 语句

当某个变量要和多个固定值比较时，`switch` 比一长串 `else if` 更清晰。Dart 3 起，每个 `case` 不再需要写 `break`，分支执行完会自动结束，不会"穿透"。

```dart
void main() {
  String fruit = 'apple';

  switch (fruit) {
    case 'apple':
      print('苹果');
    case 'banana':
      print('香蕉');
    default:
      print('其他水果');
  }
  // 输出：苹果
}
```

多个值对应同一段逻辑时，可以写"空 case"让它们落到一起：

```dart
void main() {
  int day = 6; // 1 是周一，6 是周六

  switch (day) {
    case 6:
    case 7:
      print('周末');
    default:
      print('工作日');
  }
  // 输出：周末
}
```

## 4. switch 表达式

Dart 3 引入了 switch 表达式：`switch` 可以像表达式一样直接算出结果，用 `=>` 写每个分支，`_` 相当于 `default`。它非常适合"把一个值映射成另一个值"的场景。

```dart
void main() {
  int score = 85;

  String grade = switch (score) {
    >= 90 => 'A',
    >= 60 => 'B',
    _ => 'C',
  };
  print(grade); // B
}
```

它还能配合模式匹配做更灵活的判断（进阶用法，先了解即可）：

```dart
String describe(Object value) {
  return switch (value) {
    0 => '零',
    final int n when n > 0 => '正整数 $n',
    final String s => '字符串：$s',
    _ => '其他',
  };
}

void main() {
  print(describe(0));       // 零
  print(describe(5));       // 正整数 5
  print(describe('hello')); // 字符串：hello
}
```

## 5. for 循环

`for` 循环适合"知道次数"的重复，分两部分：

- **传统写法**：初始化、条件、步进三件套。
- **for-in**：直接遍历集合里的每个元素，代码更简洁。

```dart
void main() {
  // 传统写法：i 从 0 到 2
  for (int i = 0; i < 3; i++) {
    print(i); // 0 1 2
  }

  // for-in：遍历列表
  List<String> fruits = ['apple', 'banana', 'orange'];
  for (final fruit in fruits) {
    print(fruit);
  }
}
```

列表的 `forEach` 也能达到类似效果，但 `for-in` 里可以用 `break` / `continue`，而 `forEach` 的闭包里不行，所以简单遍历用 `for-in` 更灵活。

## 6. while 与 do-while 循环

`while` 适合"不知道次数、只知道继续条件"的重复：先判断，再执行。

```dart
void main() {
  int i = 0;
  while (i < 3) {
    print(i); // 0 1 2
    i++;
  }
}
```

`do-while` 是先执行一次，再判断是否继续，所以**至少执行一次**：

```dart
void main() {
  int i = 0;
  do {
    print(i); // 0 1 2
    i++;
  } while (i < 3);
}
```

注意：`while` 一定要保证循环条件最终会变假，否则会死循环。上面的 `i++` 就是干这个的。

## 7. break continue 与标签

`break` 立即结束整个循环，`continue` 跳过本次迭代进入下一次。它们只能影响最内层循环，想跳出外层循环可以加"标签"。

```dart
void main() {
  for (int i = 0; i < 5; i++) {
    if (i == 2) continue; // 跳过 2
    if (i == 4) break;    // 到 4 直接结束
    print(i);             // 0 1 3
  }

  // 标签：从内层循环直接跳出外层循环
  outer:
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      if (i == 1 && j == 1) break outer;
      print('$i-$j');
    }
  }
  // 输出到 1-0 就停止
}
```

Dart 没有 `goto`，标签只能和 `break` / `continue` 搭配使用。

## 8. 异常处理 try catch finally

程序出错时会"抛出异常"，如果没人接住，程序就崩了。用 `try` 包住可能出错的代码，用 `catch` 接住并处理，用 `finally` 写"无论成败都要执行"的收尾代码。

```dart
void main() {
  try {
    int result = int.parse('abc'); // 这里会抛 FormatException
    print(result);
  } on FormatException catch (e) {
    print('格式错误：$e'); // 只接住这一种异常
  } catch (e) {
    print('其他错误：$e'); // 兜底接住所有异常
  } finally {
    print('无论是否报错，finally 都会执行');
  }
}
```

也可以主动抛出异常：

```dart
void checkAge(int age) {
  if (age < 0) {
    throw ArgumentError('年龄不能是负数');
  }
}

void main() {
  try {
    checkAge(-1);
  } catch (e) {
    print(e); // Invalid argument(s): 年龄不能是负数
  }
}
```

## 9. 函数的定义与调用

函数 = 返回值类型 + 函数名 + 参数 + 函数体。把重复逻辑装进函数，是让代码可维护的第一步。

```dart
int add(int a, int b) {
  return a + b;
}

void sayHello(String name) {
  print('你好，$name！');
}

void main() {
  int sum = add(1, 2);
  print(sum);        // 3
  sayHello('小明'); // 你好，小明！
}
```

约定：

- 有返回值时写具体类型，并用 `return` 返回。
- 没有返回值时返回类型写 `void`。
- 函数名用"动词开头"的小驼峰，例如 `getUserInfo`、`checkAge`。

## 10. 函数的参数

Dart 的参数分三种：必填位置参数、可选位置参数、命名参数。

| 类型 | 写法 | 调用示例 |
| --- | --- | --- |
| 必填位置参数 | `int add(int a, int b)` | `add(1, 2)` |
| 可选位置参数 | `[String title = '同学']` | `greet('小明')` |
| 命名必填参数 | `{required int age}` | `describe('小明', age: 18)` |
| 命名可选参数 | `{String city = '上海'}` | `describe('小明', age: 18, city: '北京')` |

```dart
// 可选位置参数，用 = 给默认值
String greet(String name, [String title = '同学']) {
  return '$title，$name 你好！';
}

// 命名参数：required 表示必填，其余给默认值
String describe(String name, {required int age, String city = '上海'}) {
  return '$name，$age 岁，来自 $city';
}

void main() {
  print(greet('小明'));                     // 同学，小明 你好！
  print(greet('小明', '老师'));             // 老师，小明 你好！
  print(describe('小明', age: 18));         // 小明，18 岁，来自 上海
  print(describe('小红', age: 20, city: '北京')); // 小红，20 岁，来自 北京
}
```

两个容易犯的错：

- 可选位置参数不能写在必填参数前面，`greet([String title], String name)` 是不合法的。
- 命名参数调用时**必须写参数名**（`age: 18`），这样参数多了也不会传错位置。

## 11. 返回值与箭头函数

函数体只有一个表达式时，可以用 `=>` 简写成"箭头函数"，它等价于 `{ return ...; }`。

```dart
int add(int a, int b) => a + b;

bool isAdult(int age) => age >= 18;

String greet(String name) => '你好，$name！';

void main() {
  print(add(1, 2));     // 3
  print(isAdult(20));   // true
  print(greet('小明')); // 你好，小明！
}
```

注意：箭头函数只能放一条表达式，不能放多条语句；逻辑复杂时还是用普通函数体。

## 12. 匿名函数与闭包

**匿名函数**就是没有名字的函数，常用于回调场景，比如传给 `forEach`、`map`：

```dart
void main() {
  List<int> nums = [1, 2, 3];

  nums.forEach((n) {
    print(n * 2); // 2 4 6
  });

  // 也可以存进变量
  int Function(int, int) add = (a, b) => a + b;
  print(add(3, 4)); // 7
}
```

**闭包** = 函数 + 它定义时能访问的变量。哪怕外层函数已经执行完，闭包仍然"记得"那些变量：

```dart
Function makeCounter() {
  int count = 0;
  return () => ++count;
}

void main() {
  var counter = makeCounter();
  print(counter()); // 1
  print(counter()); // 2
  print(counter()); // 3
}
```

`count` 本来应该随着 `makeCounter` 结束而消失，但闭包把它"留"了下来，这是函数式编程里非常核心的思想。

## 13. 高阶函数

把函数当作参数或返回值的函数，就叫高阶函数。前面笔记里的 `map`、`where`、`forEach` 都是高阶函数，你也可以自己写：

```dart
// 第一个参数是次数，第二个参数是"要做的事"
void repeat(int times, void Function(int index) action) {
  for (int i = 0; i < times; i++) {
    action(i);
  }
}

void main() {
  repeat(3, (i) => print('第 $i 次'));
  // 第 0 次
  // 第 1 次
  // 第 2 次
}
```

高阶函数的好处是：把"怎么循环"和"循环时做什么"分开，同一个 `repeat` 可以复用于完全不同的任务。

## 14. 综合演示

把条件、循环、函数、高阶函数组合起来，做一个学生成绩分析的小工具。

```dart
String gradeOf(int score) {
  return switch (score) {
    >= 90 => 'A',
    >= 60 => 'B',
    _ => 'C',
  };
}

void main() {
  List<int> scores = [92, 78, 65, 88, 59];

  // 用高阶函数统计及格人数
  int passed = scores.where((s) => s >= 60).length;
  print('及格人数：$passed'); // 及格人数：4

  // 循环给每个人评级
  for (final score in scores) {
    print('$score 分：${gradeOf(score)}');
  }

  // 计算平均分
  double average = scores.reduce((a, b) => a + b) / scores.length;
  print('平均分：${average.toStringAsFixed(1)}'); // 平均分：76.4
}
```

## 15. 速查表

### 条件判断

| 写法 | 作用 |
| --- | --- |
| `if / else if / else` | 按条件选择分支 |
| `switch (x) { case ... }` | 多值匹配，Dart 3 无需 break |
| `switch (x) { ... => ... }` | switch 表达式，直接产出结果 |
| `condition ? a : b` | 三目条件表达式 |

### 循环

| 写法 | 作用 |
| --- | --- |
| `for (;;)` | 传统计数循环 |
| `for (x in list)` | 遍历集合 |
| `while (cond)` | 先判断再执行 |
| `do { } while (cond)` | 先执行一次再判断 |
| `break` / `continue` | 跳出循环 / 跳过本次迭代 |
| `outer: for (...)` | 标签，配合 break / continue 跳出外层 |

### 异常处理

| 写法 | 作用 |
| --- | --- |
| `try { }` | 圈出可能出错的代码 |
| `on 类型 catch (e)` | 捕获指定类型异常 |
| `catch (e)` | 捕获所有异常 |
| `finally { }` | 无论成败都执行 |
| `throw ...` | 主动抛出异常 |

### 函数

| 写法 | 作用 |
| --- | --- |
| `返回值 函数名(参数) { }` | 定义函数 |
| `[可选位置参数 = 默认值]` | 可选位置参数 |
| `{required 参数}` / `{参数 = 默认值}` | 命名参数 |
| `=> 表达式` | 箭头函数（单表达式简写） |
| `(参数) { }` | 匿名函数 |
| 函数作为参数 / 返回值 | 高阶函数与闭包 |

## 16. 建议练习

1. 写 FizzBuzz：打印 1 到 100，3 的倍数打印 Fizz，5 的倍数打印 Buzz，既是 3 又是 5 的倍数打印 FizzBuzz，其余打印数字本身。
2. 写一个 `isPrime(int n)` 函数判断素数，再用循环找出 1 到 50 里的所有素数。
3. 用 switch 表达式写一个 `gradeOf`，把 0 到 100 的分数映射成 A / B / C / D 等级。
4. 用闭包实现一个"累加器"：每次调用返回当前总和，再新建一个独立的累加器验证它们互不影响。
5. 写一个高阶函数 `applyTwice(int value, int Function(int) fn)`，把传入函数连续应用两次，例如 `applyTwice(3, (n) => n * n)` 的结果是 81。
