Future<int> divide(int a, int b) async {
  await Future.delayed(Duration(milliseconds: 50));
  if (b == 0) {
    return Future.error('除数不能为 0');
  }
  return a ~/ b;
}

void main() async {
  try {
    print(await divide(10, 2)); // 5
    await divide(10, 0);        // 这里抛错
  } catch (e) {
    print('其他错误：$e');
  } finally {
    print('收尾'); // 收尾
  }
}