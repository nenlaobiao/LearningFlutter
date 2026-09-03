// 1. 写一个 `Student` 类：字段 `name`、`scores`（`List<int>`），方法 `averageScore()`，getter `passedCount`（及格数）和 `bestScore`，重写 `toString` 打印学生信息。
import 'dart:math';

class Student {
  static const int _passedScores = 60;
  final String name;
  final List<int> scores;
  Student(this.name, this.scores);

  num averageScore() {
    return (scores.fold(0, (a, b) => a + b)) / scores.length;
  }

  int get passedCount => scores.where((s) => s >= _passedScores).length;
  int get bestScore => scores.reduce((a, b) => a > b ? a : b);
  @override
  String toString() =>
      '''
学生姓名: $name
成绩: $scores
最高分: $bestScore
平均分: ${averageScore().toStringAsFixed(1)}
及格数: $passedCount
''';
}

void answer1() {
  var xm = Student('小明', [100, 90, 44, 29]);
  print(xm.averageScore());
  print(xm.passedCount);
  print(xm.bestScore);
  print(xm);
}

// 2. 用抽象类 `Shape`（`area()`）派生 `Circle` 和 `Rectangle`，写一个 `totalArea(List<Shape> shapes)` 函数计算总面积，体会多态。
abstract class Shape {
  double area();
  String get name;
}

class Circle extends Shape {
  final double radius;
  Circle(this.radius);
  @override
  double area() => radius * radius * pi;
  @override
  String get name => '圆形';
  @override
  String toString() => '$name , 半径：$radius , 面积：${area().toStringAsFixed(2)}';
}

class Rectangle extends Shape {
  final double length;
  final double width;
  Rectangle(this.length, this.width);
  @override
  double area() => length * width;
  @override
  String get name => '长方形';
  @override
  String toString() => '$name , 长：$length , 宽: $width , 面积：${area()}';
}

double totalArea(List<Shape> shapes) =>
    shapes.fold<double>(0.0, (n, s) => n + s.area());

void answer2() {
  var circle = Circle(2);
  var rectangle = Rectangle(2, 3);
  print(circle);
  print(rectangle);

  print(totalArea([circle, rectangle]));
}

// 3. 写 `BankAccount`：私有 `_balance`，`deposit` 校验金额必须为正，`withdraw` 校验不能透支，练习封装。
class BankAccount {
  double _balance;
  double get balance => _balance;

  BankAccount([this._balance = 0.0]);
  String deposit(double money) {
    if (money <= 0) return '存款失败！金额必须大于零';
    _balance += money;
    return '存款成功! 余额：$_balance';
  }

  String withdraw(double money) {
    if (money <= 0) return '提现失败！金额必须大于零';
    if (money > _balance) return '提现失败！余额不足 当前余额:$_balance';
    _balance -= money;
    return '提现成功! 余额：$_balance';
  }
}

void answer3() {
  var myBank = BankAccount(100);
  print(myBank.balance);
  print(myBank.deposit(10));
  print(myBank.deposit(-1));
  print(myBank.withdraw(5));
  print(myBank.withdraw(200));
  print(myBank.balance);
}

// 4. 用泛型写 `Stack<T>`：`push`、`pop`、`peek`、`isEmpty`、`length`，分别用 `Stack<int>` 和 `Stack<String>` 测试。
class Stack<T> {
  final List<T> _value;
  Stack([List<T>? items]) : _value = items ?? [];
  List<T> get value => List.unmodifiable(_value);

  List<T> push(T val) {
    _value..add(val);
    return value;
  }

  T pop() {
    var val = _value.removeLast();
    return val;

  }

  T get peek => _value.last;
  bool get isEmpty => _value.isEmpty;
  int get length => _value.length;
  @override
  String toString() => _value.toString();
}

void answer4() {
  var strStack = Stack(['1111']);
  var numStack = Stack<int>();

  print(strStack.push('2222'));
  print(strStack.peek);
  print(strStack.push('333'));
  print(strStack.peek);
  print(strStack.pop());
  print(strStack.value[0]='000');
  print(strStack.value);
  print(strStack.isEmpty);
  print(strStack.length);
  print(numStack.isEmpty);
}

// 5. 写一个 `mixin JsonLogger`（记录每次读写的字段名），让 `User` 类 `with` 它；再给 `String` 写一个 `toTitleCase` 扩展方法。
void answer5() {}

// 6. 给 `Vector` 类补上 `-` 运算符重载，并解释为什么重写 `==` 时必须重写 `hashCode`。
void answer6() {}

void main() {
  // answer1();
  // answer2();
  // answer3();
  answer4();
  answer5();
  answer6();
}
