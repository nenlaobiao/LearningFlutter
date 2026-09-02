# Dart 异步编程学习笔记

> 适合刚接触 Dart / Flutter 的学习者快速查阅。
> 本笔记是 Dart 系列的第五篇，也是 Dart 阶段的收尾篇。
> 文中的示例可以在 Dart 文件中运行，例如：
>
> ```bash
> dart run 05_async.dart
> ```

## 目录

- [1. 为什么需要异步](#1-为什么需要异步)
- [2. Future 是什么](#2-future-是什么)
- [3. 创建 Future 的几种方式](#3-创建-future-的几种方式)
- [4. 消费 Future 的三种方式](#4-消费-future-的三种方式)
- [5. async 与 await](#5-async-与-await)
- [6. 异步错误处理](#6-异步错误处理)
- [7. Future 的组合](#7-future-的组合)
- [8. 事件循环与执行顺序](#8-事件循环与执行顺序)
- [9. Completer 手动完成 Future](#9-completer-手动完成-future)
- [10. 定时器 Timer](#10-定时器-timer)
- [11. Stream 基础](#11-stream-基础)
- [12. 用 async* 生成 Stream](#12-用-async-生成-stream)
- [13. Stream 的变换与广播](#13-stream-的变换与广播)
- [14. Flutter 中的 FutureBuilder 与 StreamBuilder](#14-flutter-中的-futurebuilder-与-streambuilder)
- [15. 综合演示](#15-综合演示)
- [16. 速查表](#16-速查表)
- [17. 建议练习](#17-建议练习)
- [18. 下一步方向](#18-下一步方向)

## 1. 为什么需要异步

程序里的"慢操作"（网络请求、读文件、定时等待）如果同步执行，后面的代码只能干等。下面用忙等模拟一个阻塞 0.3 秒的请求：

```dart
// 同步版本：这 0.3 秒里什么都做不了
String fetchUserSync() {
  print('开始请求（阻塞中）');
  final start = DateTime.now();
  while (DateTime.now().difference(start).inMilliseconds < 300) {}
  return '小明';
}

void main() {
  final user = fetchUserSync();
  print('拿到 $user'); // 这行要等 0.3 秒才执行
}
```

改成异步后，发起请求的函数**立刻返回一个"承诺"**，不阻塞后续代码：

```dart
Future<String> fetchUser() async {
  print('开始请求');
  await Future.delayed(Duration(milliseconds: 300));
  return '小明';
}

void main() {
  fetchUser();          // 立刻返回一个 Future，不等待
  print('先做别的事');  // 这行立刻执行
}
```

输出顺序是"开始请求 → 先做别的事"，说明 `fetchUser` 内部等待时，`main` 已经继续往下走了。

## 2. Future 是什么

`Future<T>` 可以理解成"未来某个时刻会拿到 `T` 类型结果"的承诺。它有三种状态：

1. **进行中（pending）**：任务还没完成；
2. **完成（completed）**：带着结果 `T`；
3. **失败（error）**：带着一个错误。

拿到结果用 `then`，拿到错误用 `catchError`：

```dart
void main() {
  final future = Future.delayed(Duration(milliseconds: 100), () => 42);

  future.then((value) {
    print('完成，值是 $value'); // 完成，值是 42
  });
}
```

一个 Future 只能完成一次，完成之后回调也不会重复触发。它很像 JS 的 Promise，但语法和错误处理方式更严格。

## 3. 创建 Future 的几种方式

```dart
void main() async {
  // 1. 立即以已知值完成
  print(await Future.value(1)); // 1

  // 2. 延迟一段时间后完成
  print(await Future.delayed(
    Duration(milliseconds: 100),
    () => '延迟结果',
  )); // 延迟结果

  // 3. 放入微任务队列
  print(await Future.microtask(() => '微任务')); // 微任务

  // 4. 立即以错误完成
  try {
    await Future.error('出错了');
  } catch (e) {
    print('捕获：$e'); // 捕获：出错了
  }
}
```

最常见的是第 2 种和第 5 节讲的 `async` 函数：任何标了 `async` 的函数，返回值都会自动包装成 Future。

## 4. 消费 Future 的三种方式

`then` 拿到值、`catchError` 接错误、`whenComplete` 做收尾。`then` 里返回值还能继续传给下一个 `then`：

```dart
void main() {
  Future<int> future = Future.delayed(
    Duration(milliseconds: 100),
    () => 42,
  );

  future
      .then((value) {
        print('拿到 $value'); // 拿到 42
        return value * 2;     // 返回值进入下一个 then
      })
      .then((value) => print('再乘 2：$value')) // 再乘 2：84
      .catchError((error) => print('出错 $error'))
      .whenComplete(() => print('无论成败都执行')); // 无论成败都执行
}
```

链式调用是合法的，但链太长可读性差。下一节的 `async / await` 是更常用的写法。

## 5. async 与 await

`async / await` 是 Future 的"语法糖"：写法像同步，行为是异步。

```dart
Future<String> fetchName() async {
  await Future.delayed(Duration(milliseconds: 100));
  return '小明'; // 自动包装成 Future<String>
}

void main() async {
  print('开始');
  final name = await fetchName(); // await 拆出 Future 里的值
  print('拿到：$name');
  print('结束');
}
// 开始
// 拿到：小明
// 结束
```

三条规则：

1. 标了 `async` 的函数，返回值自动变成 `Future<T>`（原本是 `void` 则变 `Future<void>`）。
2. `await` 只能写在 `async` 函数里（顶层 `main` 可以声明为 `async`）。
3. `await` 只"暂停"当前函数，不会阻塞整个程序；等待期间其它代码照常运行。

`await` 后面也可以接普通值（不是 Future），比如 `await 42` 等价于 `42`，不会报错。

## 6. 异步错误处理

在 `async` 函数里 `throw`，等价于让 Future 以错误完成。调用方用 `try / catch` 接住，写法和同步代码几乎一样：

```dart
Future<int> divide(int a, int b) async {
  await Future.delayed(Duration(milliseconds: 50));
  if (b == 0) {
    throw ArgumentError('除数不能为 0');
  }
  return a ~/ b;
}

void main() async {
  try {
    print(await divide(10, 2)); // 5
    await divide(10, 0);        // 这里抛错
  } on ArgumentError catch (e) {
    print('参数错误：$e'); // 参数错误：Invalid argument(s): 除数不能为 0
  } catch (e) {
    print('其他错误：$e');
  } finally {
    print('收尾'); // 收尾
  }
}
```

两个容易踩的坑：

- **忘了处理错误**：Future 以错误完成却没人 `await` / `catchError`，运行时会出现 Unhandled Exception，而且往往不是在出错那行报出来。
- **发起请求但不等待**：`fetch();` 不写 `await` 时函数照常执行，但错误没人接、结果没人用。如果确实要"发出后不管"，用 `dart:async` 里的 `unawaited(fetch())` 明确表达意图。

## 7. Future 的组合

`Future.wait` 等**全部**完成，结果按传入顺序返回；`Future.any` 取**最先**完成的那一个：

```dart
Future<String> fetch(String name, int ms) async {
  await Future.delayed(Duration(milliseconds: ms));
  return '$name 完成';
}

void main() async {
  final results = await Future.wait([
    fetch('任务A', 200),
    fetch('任务B', 100),
    fetch('任务C', 50),
  ]);
  print(results); // [任务A 完成, 任务B 完成, 任务C 完成]

  final first = await Future.any([
    fetch('任务A', 200),
    fetch('任务B', 100),
    fetch('任务C', 50),
  ]);
  print(first); // 任务C 完成
}
```

要**串行**执行时，用普通 `for` 循环加 `await`：

```dart
void main() async {
  for (final id in [1, 2, 3]) {
    await fetch('任务$id', 100);
    print('任务$id 完成');
  }
  // 任务1 完成
  // 任务2 完成
  // 任务3 完成
}
```

经典错误：`forEach` 里的 `async` 回调**不会被等待**，循环立刻结束：

```dart
void main() async {
  [1, 2, 3].forEach((i) async {
    await Future.delayed(Duration(milliseconds: 100));
    print('处理 $i');
  });
  print('forEach 已返回（任务可能还没完成）');

  await Future.delayed(Duration(milliseconds: 300)); // 等任务跑完
  print('真正结束');
}
// forEach 已返回（任务可能还没完成）
// 处理 1
// 处理 2
// 处理 3
// 真正结束
```

想要"一个接一个"就换成 `for` + `await`，这个坑在 Flutter 里非常常见。

## 8. 事件循环与执行顺序

Dart 是单线程 + 事件循环：**先跑完所有同步代码，再跑微任务队列，最后跑事件队列（定时器等）**。

```dart
void main() {
  print('1 同步开始');

  Future(() => print('4 事件队列任务'));
  Future.microtask(() => print('3 微任务'));
  Future.delayed(Duration.zero, () => print('5 定时器任务'));

  print('2 同步结束');
}
// 1 同步开始
// 2 同步结束
// 3 微任务
// 4 事件队列任务
// 5 定时器任务
```

理解这一点就能解释很多"奇怪"现象：`await` 之后的代码不是立刻执行，而是被重新调度；`Future.delayed(Duration.zero, ...)` 也不会立刻跑，要等当前同步代码和微任务都结束。初学阶段记住"同步 → 微任务 → 事件"这个顺序就够用了。

## 9. Completer 手动完成 Future

某些 API 是回调风格（比如插件、平台通道）。`Completer` 可以把回调包装成 Future，之后就能统一用 `await`：

```dart
import 'dart:async';

Future<String> fetchWithCallback() {
  final completer = Completer<String>();

  // 模拟一个基于回调的 API：1 秒后调用回调
  Timer(Duration(seconds: 1), () {
    completer.complete('回调完成');
  });

  return completer.future;
}

void main() async {
  print(await fetchWithCallback()); // 回调完成
}
```

规则：`complete` 只能调一次；失败用 `completer.completeError(错误)`。

> `Completer`、`Timer`、`StreamController` 都在 `dart:async` 库里，用之前要 `import 'dart:async';`。而 `Future`、`Stream` 这两个类型本身在 `dart:core` 里，不需要导入。

## 10. 定时器 Timer

`Timer` 用于"过一会儿执行一次"，`Timer.periodic` 用于周期执行，来自 `dart:async`：

```dart
import 'dart:async';

void main() {
  // 一次性定时器
  Timer(Duration(seconds: 1), () => print('1 秒后执行'));

  // 周期性定时器：每秒一次，3 次后取消
  var count = 0;
  Timer.periodic(Duration(seconds: 1), (timer) {
    count++;
    print('第 $count 秒');
    if (count == 3) {
      timer.cancel();
      print('计时结束');
    }
  });
}
```

在 Flutter 里，倒计时、轮询都靠它。组件销毁时记得 `cancel`，否则定时器会继续跑、还可能访问已销毁的组件状态。

## 11. Stream 基础

Future 是"一次性的承诺"，Stream 是"一串异步数据流"，适合进度、事件、实时数据。

手动创建并消费一个流：

```dart
import 'dart:async';

void main() async {
  final controller = StreamController<int>();

  controller.stream.listen(
    (data) => print('收到 $data'),
    onDone: () => print('流关闭'),
  );

  controller.sink.add(1);
  controller.sink.add(2);
  controller.sink.add(3);
  await controller.close();
}
// 收到 1
// 收到 2
// 收到 3
// 流关闭
```

消费流还可以用 `await for`，写法就是"异步版的 for-in"：

```dart
void main() async {
  final stream = Stream.fromIterable(['苹果', '香蕉', '橙子']);

  await for (final fruit in stream) {
    print('拿到 $fruit');
  }
  print('遍历结束');
}
// 拿到 苹果
// 拿到 香蕉
// 拿到 橙子
// 遍历结束
```

注意：普通的 Stream 只能被**一个**监听者订阅，第二次 `listen` 会报 "Stream has already been listened to"。

## 12. 用 async* 生成 Stream

`async*` 函数返回 Stream，函数体里用 `yield` 一条一条往外推数据，是生成流最自然的方式：

```dart
Stream<int> countDown(int from) async* {
  for (int i = from; i > 0; i--) {
    await Future.delayed(Duration(milliseconds: 100));
    yield i; // 每 yield 一次，流就推出一条数据
  }
}

void main() async {
  await for (final n in countDown(3)) {
    print(n);
  }
  print('倒计时结束');
}
// 3
// 2
// 1
// 倒计时结束
```

对比记忆：`async` 返回 Future，用 `return`；`async*` 返回 Stream，用 `yield`。

## 13. Stream 的变换与广播

和 List 一样，Stream 可以用 `where` / `map` / `take` 链式变换：

```dart
void main() async {
  final stream = Stream.fromIterable([1, 2, 3, 4, 5, 6])
      .where((n) => n.isEven)   // 过滤
      .map((n) => '偶数 $n');   // 转换

  await for (final item in stream) {
    print(item);
  }
  // 偶数 2
  // 偶数 4
  // 偶数 6
}
```

需要**多个监听者**时，用广播流：

```dart
import 'dart:async';

void main() {
  final controller = StreamController<int>.broadcast();

  controller.stream.listen((d) => print('A 收到 $d'));
  controller.stream.listen((d) => print('B 收到 $d'));

  controller.sink.add(1);
  controller.sink.add(2);
  controller.close();
}
// A 收到 1
// B 收到 1
// A 收到 2
// B 收到 2
```

`sink.addError(错误)` 可以向流里推错误；流用完了记得 `close`。

## 14. Flutter 中的 FutureBuilder 与 StreamBuilder

这两个 Widget 是把异步数据接进界面的桥梁，进入 Flutter 阶段会高频使用，先认识一下：

```dart
// Flutter 示意用法（不能在纯 Dart 里直接运行）
FutureBuilder<String>(
  future: fetchUserName(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator(); // 等待中：转圈
    }
    if (snapshot.hasError) {
      return Text('出错了：${snapshot.error}');
    }
    return Text(snapshot.data ?? '');
  },
);
```

- `FutureBuilder`：请求这类"一次完成"的数据。
- `StreamBuilder`：进度、倒计时、实时消息这类"持续更新"的数据。

它们帮你把 waiting / error / data 三种状态画成对应界面，思路和后面阶段 5 的网络请求直接挂钩。

## 15. 综合演示

模拟"并发下载两个文件，实时打印进度"：并发靠 `Future.wait`，进度靠 `async*` 的 Stream：

```dart
Stream<int> downloadProgress(String fileName, int total) async* {
  for (int i = 1; i <= total; i++) {
    await Future.delayed(Duration(milliseconds: 100));
    yield i;
  }
}

Future<void> downloadFile(String fileName, int total) async {
  await for (final step in downloadProgress(fileName, total)) {
    final percent = (step / total * 100).toStringAsFixed(0);
    print('$fileName 下载中 $percent%');
  }
  print('$fileName 下载完成');
}

void main() async {
  await Future.wait([
    downloadFile('a.zip', 3),
    downloadFile('b.zip', 2),
  ]);
  print('全部完成');
}
// a.zip 下载中 33%
// b.zip 下载中 50%
// a.zip 下载中 67%
// b.zip 下载中 100%
// b.zip 下载完成
// a.zip 下载中 100%
// a.zip 下载完成
// 全部完成
```

## 16. 速查表

### Future

| 写法 | 作用 |
| --- | --- |
| `Future.value(x)` | 立即以已知值完成 |
| `Future.delayed(d, fn)` | 延时后完成 |
| `Future.error(e)` | 以错误完成 |
| `Future.microtask(fn)` | 放入微任务队列 |
| `async` 函数 | 返回值自动包装成 Future |
| `await` | 拆出 Future 的值，暂停当前函数 |
| `then` / `catchError` / `whenComplete` | 拿值 / 接错误 / 收尾 |
| `Future.wait(list)` | 等全部完成，结果按顺序返回 |
| `Future.any(list)` | 取最先完成的 |

### 错误处理

| 写法 | 作用 |
| --- | --- |
| `try / on 类型 / catch / finally` | 异步里和同步写法一致 |
| `async` 函数内 `throw` | Future 以错误完成 |
| `unawaited(future)` | 明确"发起后不等待" |
| `completer.completeError(e)` | 手动让 Future 失败 |

### Stream

| 写法 | 作用 |
| --- | --- |
| `StreamController<T>()` | 手动创建流 |
| `sink.add` / `sink.addError` / `close` | 推数据 / 推错误 / 关闭 |
| `listen` / `await for` | 订阅消费 |
| `Stream.fromIterable` / `Stream.periodic` | 从集合 / 定时生成 |
| `async*` + `yield` | 生成器写法 |
| `where` / `map` / `take` | 流变换 |
| `StreamController.broadcast()` | 广播流，支持多订阅 |
| `Timer` / `Timer.periodic` | 一次性 / 周期定时器 |

## 17. 建议练习

1. 用 `Future.delayed` 模拟一个 0.5 秒后返回的用户名，用 `async / await` 拿到并打印，验证等待期间 `main` 没有阻塞。
2. 写一个 `divide(a, b)`（`b == 0` 时抛 `ArgumentError`），分别用 `then / catchError` 和 `async/await + try/catch` 两种方式处理错误。
3. 用 `Future.wait` 并发"请求"三个延迟不同的接口，再对比 `Future.any` 的结果差异。
4. 找出"`forEach` 里写 `async` 但外层没等待"的问题，改写成 `for` + `await` 的正确版本。
5. 用 `async*` 写一个斐波那契数列 Stream，`take(10)` 后用 `await for` 打印前 10 项。
6. 用 `StreamController` + `Timer.periodic` 做一个 5 秒倒计时流：监听并打印，到 0 时 `cancel` 定时器并 `close` 流。

## 18. 下一步方向

这篇完成后，总纲里的**阶段 0（Dart 语言基础）就全部收尾**。建议顺序：

1. 完成上面 6 道练习（老规矩：跑通才算过）。
2. 对照 [学习总纲.md](D:/Flutter/LearningFlutter/学习总纲.md) 里"阶段 0"的自检清单过一遍。
3. 进入**阶段 1「Widget 世界观」**：`StatelessWidget` / `StatefulWidget`、`setState`、热重载，产出物是一个可交互卡片。

异步是 Flutter 里躲不掉的日常：网络请求、按钮回调、进度条、`FutureBuilder` / `StreamBuilder` 全是它的应用。这篇打牢，后面阶段 5 的网络封装会轻松很多。
