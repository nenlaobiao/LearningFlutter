# Dart 错误与异常学习笔记

> 适合刚接触 Dart / Flutter 的学习者快速查阅。
> 文中的示例可以在 Dart 文件中运行，例如：
>
> ```bash
> dart run 06_errors_exceptions.dart
> ```
>
> 要义：错误有很多种，核心是**分清楚“何时发生”和“谁来处理”**。前者决定它是编译期还是运行时，后者决定它是程序缺陷（`Error`）还是可预期的业务问题（`Exception`）。

## 目录

- [1. 先建立两个维度](#1-先建立两个维度)
- [2. 编译期错误与运行时错误](#2-编译期错误与运行时错误)
- [3. Throwable 下的两大分支 Error 与 Exception](#3-throwable-下的两大分支-error-与-exception)
- [4. 常用异常类型速查（含使用场景）](#4-常用异常类型速查含使用场景)
- [5. 业务异常要用 Exception 而不是 Error](#5-业务异常要用-exception-而不是-error)
- [6. 捕获时机：能精确就不兜底](#6-捕获时机能精确就不兜底)
- [7. 自定义异常类型](#7-自定义异常类型)
- [8. 异步里的错误处理](#8-异步里的错误处理)
- [9. Flutter 层面的特殊错误](#9-flutter-层面的特殊错误)
- [10. 一个常见误区](#10-一个常见误区)
- [11. 速查表](#11-速查表)
- [12. 建议练习](#12-建议练习)

## 1. 先建立两个维度

“错误有很多种”这个直觉是对的，但混乱来自把两个不同的问题混在一起：

1. **何时发生** → 编译期还是运行时。
2. **谁的问题** → 程序写错了（程序员修复），还是运行环境出了状况（调用方处理）。

先记住一句话：

> **编译期错误靠编译器拦；运行时错误靠 `Error` / `Exception` 区分责任，用 `try / catch` 兜住。**

## 2. 编译期错误与运行时错误

### 编译期错误（Compile-time / Static）

写代码或 `dart analyze` 时就报出来，**程序根本没跑起来**，所以不叫“异常”，也没有 `try / catch` 什么事。

常见几类：

| 类型 | 示例 | 为什么会错 |
| --- | --- | --- |
| 语法错误 | `int a = 1`（漏分号） | Dart 语法解析不了 |
| 类型错误 | `String s = 42;` | 47 不是 `String` |
| 变量未定义 | `print(age);` 但没声明 | 找不到名字 |
| 重复赋值 | 对 `final` 二次赋值 | `final` 只能赋值一次 |
| 无法兼容 | `List<num> x = <int>[1];` | 类型不等，Dart 静态检查拦截 |

```dart
// 下面这些注释掉的代码在编译期就报错，不会等到运行时：
// String name = 42;            // error: String 不能接收 int
// final age = 18;
// age = 20;                    // error: final 只能赋值一次
// print(foo);                  // error: foo 未定义
```

编译期错误的价值：**越早发现越好**，IDE 红线就是最好的报错。

### 运行时错误（Runtime）

程序跑起来了才抛。Dart 里所有运行时错误都实现了顶层类型 `Throwable`，我们通常用 `try / catch` 处理。例如：

```dart
void main() {
  try {
    int n = int.parse('abc'); // 运行时抛 FormatException
    print(n);
  } catch (e) {
    print('接住了：$e');
  }
}
```

## 3. Throwable 下的两大分支 Error 与 Exception

Dart 顶层类型是 `Throwable`，下面分成两支，这是“使用场景区别”的关键：

```
Throwable
├── Error      ← 程序本身有 bug，不该 catch，应该修代码
└── Exception  ← 可预期的业务/环境问题，通常要 catch 并处理
```

判断口诀：

> **`Error` 是“代码写错了”；`Exception` 是“情况不对，可以处理”。**

`Error` 类别里常见：`TypeError`、`RangeError`、`UnsupportedError`、`StateError`、`UnimplementedError`、`ConcurrentModificationError`。

`Exception` 类别里常见：`FormatException`、`TimeoutException`、`IOException`（`dart:io`）。

注意：`ArgumentError` 是 `Error` 分支（它本身 `implements Error`），`RangeError` 又继承自 `ArgumentError`。所以别因为 `ArgumentError` 不是 `Exception` 就以为它不该被 `catch`——它代表“**调用方传了坏参数**”，运行时可以接住并给出友好提示；而真正代表“程序员写错”的是 `TypeError`、`NullError` 这些。

## 4. 常用异常类型速查（含使用场景）

| 异常类型 | 继承自 | 使用场景 | 触发示例 |
| --- | --- | --- | --- |
| `FormatException` | `Exception` | 字符串/数据格式不对 | `int.parse('abc')`、`DateTime.parse('not-a-date')` |
| `ArgumentError` | `Error` | 传给函数的参数不合法 | 年龄为负、空字符串做了非法操作 |
| `RangeError` | `Error` | 数组/下标越界、值超范围 | `list[10]`（长度为 3）、`0xff = 256` |
| `StateError` | `Error` | 对象当前状态不允许该操作 | 在空集合上 `single`、对已关闭的 `Stream` 操作 |
| `UnsupportedError` | `Error` | 调用了不支持的 API | 修改 `List.unmodifiable(...)` |
| `UnimplementedError` | `Error` | 某方法还没实现 | `throw UnimplementedError('todo')` |
| `TypeError` | `Error` | 运行时类型不匹配 | `dynamic` 转错误类型后调用 |
| `TimeoutException` | `Exception` | 异步等待超时 | `Future.timeout(...)` 超时 |
| `IOException` | `Exception` | 文件/网络 I/O 出错 | 读不存在的文件、网络断开 |
| `ConcurrentModificationError` | `Error` | 遍历时修改了集合 | `for...in` 循环里删元素 |

这些差异决定你**该不该 catch、该怎么 catch**：

- `FormatException` / `ArgumentError`：可预期，用 `try / catch` 处理，并向用户提示。
- `TypeError` / `UnimplementedError`：程序 bug，修代码，不要用 `catch` 掩盖。

原则：`Error` 家族里的“坏参数、越界”可以 `catch` 后优雅降级；代表代码 bug 的 `TypeError`、`UnimplementedError` 则应让它暴露出来。

## 5. 业务异常要用 Exception 而不是 Error

你自己写业务逻辑时，**主动抛出“可恢复”的异常应该用 `Exception` 家族，或者自定义实现 `Exception`**。不要用 `Error` 表示普通业务失败——那样语义上告诉调用方“这是程序缺陷”，容易误导。

> 一个例外：如果异常只是“参数不合法”，`ArgumentError` 本身就是 `Error` 分支，用它也是合理选择，不必强行走 `Exception`。真正要避免的是用 `Error` 子类表达“业务规则失败”。

```dart
void withdraw(double amount) {
  if (amount <= 0) {
    throw ArgumentError('提现金额必须大于 0');
  }
  // 业务失败也可以抛一个明确类型的异常
  throw InsufficientBalanceException('余额不足');
}

class InsufficientBalanceException implements Exception {
  final String message;
  InsufficientBalanceException(this.message);

  @override
  String toString() => 'InsufficientBalanceException: $message';
}
```

## 6. 捕获时机：能精确就不兜底

接错要**尽可能精确**。`on 具体类型`接第一层，最后才用 `catch (e)` 兜底，避免把内部逻辑错误也一起吞掉。

```dart
void main() {
  try {
    int n = int.parse('abc');
  } on FormatException catch (e) {
    print('格式错误：$e'); // 只接格式问题
  } on ArgumentError catch (e) {
    print('参数错误：$e');
  } catch (e) {
    print('其他异常：$e'); // 最后的兜底
  } finally {
    print('无论是否报错都执行');
  }
}
```

两点注意：
- `finally` 不适合用来“处理错误”，它只做收尾（关文件、释放资源）。
- `catch (e)` 只拿到对象；`catch (e, st)` 还能拿 `StackTrace` 用于调试日志。

## 7. 自定义异常类型

让自定义异常 `implements Exception`（或 `extends Exception`），并覆写 `toString()` 提供友好信息。

```dart
class EmptyCartException implements Exception {
  final String message;
  EmptyCartException([this.message = '购物车为空']);

  @override
  String toString() => 'EmptyCartException: $message';
}

void checkout() {
  throw EmptyCartException();
}

void main() {
  try {
    checkout();
  } on EmptyCartException catch (e) {
    print(e); // EmptyCartException: 购物车为空
  }
}
```

## 8. 异步里的错误处理

异步场景的错误传播和同步不太一样，要注意：

- 在 `async` 函数里 `throw`，相当于让 `Future` 以错误完成。
- 调用方要用 `await + try/catch`，或 `catchError` 接住。
- **忘了处理** → 运行时报 `Unhandled Exception`，且往往不在出错那一行报出来。

```dart
Future<int> divide(int a, int b) async {
  if (b == 0) {
    throw ArgumentError('除数不能为 0');
  }
  return a ~/ b;
}

void main() async {
  try {
    int r = await divide(10, 0);
    print(r);
  } on ArgumentError catch (e) {
    print('参数错误：$e');
  }
}
```

如果发起请求但不等待，又刻意忽略结果，用 `unawaited(...)`：

```dart
import 'dart:async';

unawaited(divide(10, 0).then((r) => print(r)));
```

## 9. Flutter 层面的特殊错误

进入 Flutter 后，还会遇到几类框架级“错误”，它们大多不是 Dart 异常，而是**运行时状态问题**：

| 场景 | 典型表现 | 解决思路 |
| --- | --- | --- |
| 布局溢出 | `RenderFlex overflowed`（黄色条纹） | 给列/行加 `Expanded`、`Flexible` 或 `SingleChildScrollView` |
| 后置引用 | `setState() called after dispose()` | 在 `if (mounted)` 里再 `setState` |
| 异步未处理 | `Unhandled Exception` | 一定要 `await` / `catchError` |
| 空安全错误 | `Null check operator used on a null value` | 检查是否真的值得用 `!`，改成显式处理 null |
| 网络/业务错误 | `SocketException`、HTTP 非 200 | dio 封装里统一处理，映射成可读的异常 |

## 10. 一个常见误区

“`try/catch` 包住更安全” 是错的。**滥用 `catch (e) {}` 会把真正的 bug 也吞掉**——程序看起来没崩，但状态已经不对。正确姿势：

1. 明确知道会有什么错，才 `try`；
2. 只 `catch` 你要处理的 `Exception` 类型；
3. 不认识的错误让它往上抛，不要拦住。

## 11. 速查表

### 分类维度

| 维度 | 分类 | 解决方式 |
| --- | --- | --- |
| 发生时机 | 编译期 / 运行时 | 编译期看 IDE 红线；运行时用 `try/catch` |
| 责任归属 | `Error` / `Exception` | `Error` 修代码，`Exception` 处理 |

### 常用语法

| 写法 | 作用 |
| --- | --- |
| `try { }` | 圈出可能出错的代码 |
| `on 类型 catch (e)` | 只接指定类型异常 |
| `catch (e)` | 接所有异常 |
| `catch (e, st)` | 同时取堆栈 |
| `finally { }` | 无论成败都执行（收尾） |
| `throw ...` | 主动抛出异常 |
| `implements Exception` | 自定义可恢复异常 |
| `unawaited(future)` | 刻意忽略异步错误/结果 |

### 怎么选异常类型

| 想表达 | 用哪个 |
| --- | --- |
| 数据格式无效 | `FormatException` |
| 函数参数不合法 | `ArgumentError` |
| 下标/范围越界 | `RangeError` |
| 状态不允许该操作 | `StateError` |
| 功能未实现 | `UnimplementedError` |
| 异步超时 | `TimeoutException` |
| 业务/接口上的明确错误 | 自定义 `Exception` |

## 12. 建议练习

1. 写一个 `parseScore(String)`，能分别触发 `FormatException` 和 `ArgumentError`，并用 `on` 精确捕获。
2. 定义一个 `AgeOutOfRangeException`，在 `register(age)` 里抛出，调用方接住并打印友好提示。
3. 写一个 `divide(a, b)`，除数为 0 时抛 `ArgumentError`，分别用 `then/catchError` 和 `async/await + try/catch` 两种方式处理。
4. 自己构造一个 `StateError` 场景（例如对空列表调用 `first`），体会它“不该被 catch 掩盖”的语义。
5. 思考：`int.parse('abc')` 抛的是 `FormatException`，为什么它不属于 `Error`？
