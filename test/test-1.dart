sealed class Result {}

final class IntResult extends Result {
  final int value;
  IntResult(this.value);
}

final class DoubleResult extends Result {
  final double value;
  DoubleResult(this.value);
}

final class ErrorResult extends Result {
  final String message;
  ErrorResult(this.message);
}

String describe(Result r) => switch (r) {
  IntResult(value: final v)  => '整数：$v',
  DoubleResult(value: final v) => '小数：$v',
  ErrorResult(message: final m) => '出错：$m',
};

void main() {
  final results = <Result>[
    IntResult(10),
    DoubleResult(3.14),
    ErrorResult('网络异常'),
  ];

  for (final r in results) {
    print(describe(r));
  }
}