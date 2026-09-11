// Dart 学习笔记 06 配套练习：错误与异常
// 运行：dart run test/test-6.dart

class AgeOutOfRangeException implements Exception {
  final String message;
  AgeOutOfRangeException([this.message = '年龄超出范围']);

  @override
  String toString() => 'AgeOutOfRangeException: $message';
}

// 练习 1：分别触发 FormatException 与 ArgumentError，用 on 精确捕获
int parseScore(String text) {
  // 空字符串 → ArgumentError
  if (text.isEmpty) {
    throw ArgumentError('分数不能为空');
  }
  // 非数字 → FormatException
  return int.parse(text);
}

// 练习 2：在 register(age) 里抛出显式业务异常
void register(int age) {
  if (age < 0 || age > 120) {
    throw AgeOutOfRangeException('年龄必须在 0~120 之间');
  }
  print('注册成功，age=$age');
}

// 练习 3：除数为 0 抛 ArgumentError（供 then/catchError 与 async/await 两用）
Future<int> divide(int a, int b) async {
  if (b == 0) {
    throw ArgumentError('除数不能为 0');
  }
  return a ~/ b;
}

void main() async {
  // 练习 1：精确捕获
  try {
    parseScore('abc');
  } on FormatException catch (e) {
    print('格式错误：$e');
  } on ArgumentError catch (e) {
    print('参数错误：$e');
  }

  try {
    parseScore('');
  } on FormatException catch (e) {
    print('格式错误：$e');
  } on ArgumentError catch (e) {
    print('参数错误：$e');
  }

  // 练习 2：自定义业务异常
  try {
    register(130);
  } on AgeOutOfRangeException catch (e) {
    print(e);
  }

  // 练习 3a：async/await + try/catch
  try {
    await divide(10, 0);
  } on ArgumentError catch (e) {
    print('async/await -> $e');
  }

  // 练习 3b：then / catchError
  divide(10, 0).then((r) {
    print('结果：$r');
  }).catchError((e) {
    print('catchError -> $e');
  });

  // 练习 4：构造 StateError 场景（空列表取第一个）
  final empty = <int>[];
  try {
    print(empty.first); // 抛 StateError
  } catch (e) {
    print('StateError 示例 -> ${e.runtimeType}');
  }
}
