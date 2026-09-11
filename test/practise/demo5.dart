import 'dart:async';

// 1. 用 `Future.delayed` 模拟一个 0.5 秒后返回的用户名，用 `async / await` 拿到并打印，验证等待期间 `main` 没有阻塞。
Future<String> getUserInfo() async {
  await Future.delayed(Duration(milliseconds: 600));
  return '小明';
}

answer1() {
  print('answer1开始');
  getUserInfo().then((name) => print(name));
  print('answer1结束');
}

// 2. 写一个 `divide(a, b)`（`b == 0` 时抛 `ArgumentError`），分别用 `then / catchError` 和 `async/await + try/catch` 两种方式处理错误。
Future<double> divide(a, b) async {
  await Future.delayed(Duration(milliseconds: 500));
  if (b == 0) {
    throw ArgumentError('分母不能为0');
  }
  return a / b;
}

answer2() async {
  divide(2, 0).then((value) => print('value:$value')).catchError(print);
  try {
    var val = await divide(2, 0);
    print('value1:$val');
  } catch (e) {
    print('value1:$e');
  }
}

// 3. 用 `Future.wait` 并发"请求"三个延迟不同的接口，再对比 `Future.any` 的结果差异。
Future<String> ybFn(String name, int time) {
  return Future.delayed(Duration(milliseconds: time), () => '$name: $time');
}

answer3() {
  Future.wait([ybFn('你好1', 100), ybFn('你好2', 200), ybFn('你好3', 300)])
      .then(print);

  Future.any([ybFn('hello1', 1000), ybFn('hello2', 200), ybFn('hello3', 100)])
      .then(print);

  // Future.wait 会等待所有函数完成之后返回
  // Future.any 会返回第一个完成的函数
}

// 4. 找出"`forEach` 里写 `async` 但外层没等待"的问题，改写成 `for` + `await` 的正确版本。
Future<void> fetchData(String name) async {
  await Future.delayed(const Duration(seconds: 1));
  print('$name 完成');
}

Future<void> fn1() async {
  final names = ['任务1', '任务2', '任务3'];

  names.forEach((name) async {
    await fetchData(name);
  });

  print('全部任务完成123');
}

Future<void> fn2() async {
  final names = ['任务A', '任务B', '任务C'];

  for (final item in names) {
    await fetchData(item);
  }
  print('全部任务完成abc');
}

answer4() {
  fn1();
  fn2();
}

// 5. 用 `async*` 写一个斐波那契数列 Stream，`take(10)` 后用 `await for` 打印前 10 项。
Stream<int> fibonacci([int max = 1000]) async* {
  int a = 0;
  int b = 1;
  while (a <= max) {
    yield a;
    var next = a + b;
    a = b;
    b = next;
    await Future.delayed(Duration(milliseconds: 10));
  }
}

answer5() async {
  await for (final n in fibonacci()) {
    print(n);
  }
}
// 6. 用 `StreamController` + `Timer.periodic` 做一个 5 秒倒计时流：监听并打印，到 0 时 `cancel` 定时器并 `close` 流。
answer6() {
  final controller = StreamController<int>();
  controller.stream.listen((d) => print('倒计时 $d'));
  var num = 5;
  Timer.periodic(Duration(seconds: 1),(timer){
    controller.sink.add(num--);
    if(num <= 0){
      timer.cancel();
      controller.close();
    }
  });
}


// 选择排序
List<int> choose(List<int> nums) {
  for (var i = nums.length - 1; i >= 0; i--) {
    for (var j = 0; j < i; j++) {
      var index = i;
      if (nums[j] > nums[i]) {
        index = j;
      }
      if (index != i) {
        var val = nums[index];
        nums[index] = nums[i];
        nums[i] = val;
      }
    }
  }
  return nums;
}

// 冒泡排序
List<int> bubble(List<int> nums) {
  for (var i = nums.length - 1; i >= 0; i--) {
    for (var j = 0; j < i; j++) {
      if (nums[j] > nums[j + 1]) {
        var val = nums[j];
        nums[j] = nums[j + 1];
        nums[j + 1] = val;
      }
    }
  }
  return nums;
}

answer7() {
  List<int> nums = [23, 13, 88, 2, 10, 3, 5];
  print('选择排序${choose(nums)}');
  print('冒泡排序${bubble(nums)}');
}

void main() {
  // answer1();
  // answer2();
  // answer3();
  // answer4();
  // answer5();
  answer6();
  answer7();
}
