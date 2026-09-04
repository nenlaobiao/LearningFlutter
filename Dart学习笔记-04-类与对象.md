# Dart 类与对象学习笔记

> 适合刚接触 Dart / Flutter 的学习者快速查阅。
> 本笔记是 Dart 系列的第四篇，接在「控制流与函数」之后。
> 文中的示例可以在 Dart 文件中运行，例如：
>
> ```bash
> dart run 04_classes_oop.dart
> ```

## 目录

- [1. 为什么需要类](#1-为什么需要类)
- [2. 定义类：字段与方法](#2-定义类字段与方法)
- [3. 构造函数基础](#3-构造函数基础)
- [4. 命名构造函数与工厂构造函数](#4-命名构造函数与工厂构造函数)
- [5. getter 与 setter](#5-getter-与-setter)
- [6. 继承 extends 与 super](#6-继承-extends-与-super)
- [7. 抽象类 abstract](#7-抽象类-abstract)
- [8. 接口 implements](#8-接口-implements)
- [9. 混入 mixin](#9-混入-mixin)
- [10. 静态成员 static 与 const](#10-静态成员-static-与-const)
- [11. 运算符重载](#11-运算符重载)
- [12. 扩展方法 extension](#12-扩展方法-extension)
- [13. 泛型 generic](#13-泛型-generic)
- [14. 私有成员与封装](#14-私有成员与封装)
- [15. 综合演示](#15-综合演示)
- [16. 速查表](#16-速查表)
- [17. 建议练习](#17-建议练习)
- [18. 下一步方向](#18-下一步方向)

## 1. 为什么需要类

前面三篇笔记里，我们一直用 `Map` 之类的"散装数据"表示一个概念，比如一个用户：

```dart
void main() {
  // 用 Map 描述一个用户
  final user = {'name': '小明', 'age': 18};

  print(user['nmae']); // null：字段名打错也不会报错
  print('${user['name']}，${user['age']} 岁');
}
```

这种写法有三个问题：

1. **字段名没有约束**：`nmae` 打错了，编译器不吭声，运行时才拿到 `null`。
2. **取出来的值类型是 `Object?`**：要用还得先 `as String` 转换，麻烦又危险。
3. **数据和行为是分开的**："介绍自己"这种逻辑只能写成外面的函数，和数据粘不到一起。

类（class）把"数据 + 行为"打包成一个整体，还能让编译器帮我们检查字段名和类型：

```dart
class User {
  String name;
  int age;

  User(this.name, this.age);

  void introduce() {
    print('我是 $name，今年 $age 岁');
  }
}

void main() {
  final user1 = User('小明', 18);
  final user2 = User('小红', 20);

  user1.introduce(); // 我是 小明，今年 18 岁
  user2.introduce(); // 我是 小红，今年 20 岁

  print(user1.name); // 小明
  // user1.nmae 会直接编译报错，问题在开发阶段就暴露
}
```

> **和 Flutter 的关系**：屏幕上每一个组件都是一个类（`Text`、`Button`、`StatelessWidget`……），写类是把界面"组件化"的基本功。这一篇学完，读 Flutter 源码的门槛会低很多。

## 2. 定义类：字段与方法

类的最基本组成是**字段**（保存数据）和**方法**（执行动作）。方法用函数的知识即可，字段可以像 `width` 这样在声明时给默认值：

```dart
class Rectangle {
  double width = 0;
  double height = 0;

  double area() {
    return width * height;
  }

  double perimeter() => 2 * (width + height);
}

void main() {
  final rect = Rectangle()
    ..width = 3
    ..height = 4;

  print(rect.area());      // 12.0
  print(rect.perimeter()); // 14.0
}
```

两个细节：

- 非空字段（`double`，不是 `double?`）必须在声明时或构造函数里完成初始化，否则编译报错。
- `..` 是笔记 02 讲过的级联运算符，`rect` 配合 `final` 声明后依然可以修改它内部的字段。

### this 关键字

方法里用 `this` 表示"当前对象"。大多数时候可以省略，只有当**参数名和字段名撞车**时才必须写：

```dart
class Person {
  String name;

  Person(this.name);

  void rename(String name) {
    this.name = name; // 左边的 name 是字段，右边的 name 是参数
  }
}

void main() {
  final person = Person('小明');
  person.rename('大明');
  print(person.name); // 大明
}
```

## 3. 构造函数基础

构造函数负责在创建对象时初始化字段。它和类同名，`this.字段` 是一种简写：参数直接赋给同名字段。

```dart
class Point {
  final double x;
  final double y;

  // 位置参数构造函数
  Point(this.x, this.y);

  // 命名构造函数：用初始化列表给 final 字段赋值
  Point.origin()
      : x = 0,
        y = 0;
}

void main() {
  final p1 = Point(3, 4);
  final origin = Point.origin();

  print('${p1.x}, ${p1.y}');       // 3.0, 4.0
  print('${origin.x}, ${origin.y}'); // 0.0, 0.0
}
```

### 命名参数构造函数

Flutter 的组件几乎都用这种写法：参数多的时候，调用处写上参数名就不怕传错位置。

```dart
class User {
  final String name;
  final int age;
  final String? city;

  User({required this.name, required this.age, this.city});
}

void main() {
  final user = User(name: '小明', age: 18, city: '上海');
  print('${user.name}，${user.age} 岁，${user.city ?? '未知城市'}');
  // 小明，18 岁，上海
}
```

### 初始化列表与 assert

初始化列表写在 `:` 后面，在构造函数体执行**之前**运行。它只能访问参数和静态成员，常用于给 `final` 字段算初始值，或配合 `assert` 做参数校验：

```dart
class Temperature {
  final double celsius;
  final double fahrenheit;

  Temperature.fromFahrenheit(double f)
      : assert(f >= -459.67, '温度不能低于绝对零度'),
        celsius = (f - 32) * 5 / 9,
        fahrenheit = f;
}

void main() {
  final temp = Temperature.fromFahrenheit(212);
  print(temp.celsius); // 100.0
  // Temperature.fromFahrenheit(-1000); // 触发 assert，抛异常
}
```

## 4. 命名构造函数与工厂构造函数

### 命名构造函数

一个类可以有多个构造函数，写法是 `类名.名字(...)`。它让"从不同来源创建对象"的意图一目了然：

```dart
class User {
  final String name;
  final int age;

  User(this.name, this.age);

  // 从 JSON Map 创建对象
  User.fromJson(Map<String, dynamic> json)
      : name = json['name'] as String,
        age = json['age'] as int;

  @override
  String toString() => 'User($name, $age)';
}

void main() {
  final user = User.fromJson({'name': '小明', 'age': 18});
  print(user); // User(小明, 18)
}
```

> `@override` 表示"重写父类的方法"。`toString` 是 `Object` 自带的，重写后 `print(user)` 会调用我们的版本。

### 工厂构造函数 factory

普通构造函数**一定会创建一个新实例**，而 `factory` 构造函数可以控制返回值：

- 返回缓存好的同一个实例（单例）；
- 根据参数返回不同的子类实例；
- 复用已有的计算结果，避免重复创建。

单例的经典写法：

```dart
class Config {
  static Config? _instance;

  // 私有构造，外部无法直接 new
  Config._internal();

  factory Config() => _instance ??= Config._internal();
}

void main() {
  final a = Config();
  final b = Config();
  print(identical(a, b)); // true：两次拿到的都是同一个实例
}
```

根据参数返回不同子类：

```dart
abstract class Animal {
  String get sound;

  factory Animal.create(String type) {
    return switch (type) {
      'dog' => Dog(),
      'cat' => Cat(),
      _ => throw ArgumentError('不支持的动物：$type'),
    };
  }
}

class Dog implements Animal {
  @override
  String get sound => '汪汪';
}

class Cat implements Animal {
  @override
  String get sound => '喵喵';
}

void main() {
  final animal = Animal.create('dog');
  print(animal.sound); // 汪汪
}
```

## 5. getter 与 setter

getter 是一个"调用时不写括号"的方法，setter 给它配对。它们很适合把**计算出来的值**伪装成字段：

```dart
class Circle {
  double radius;

  Circle(this.radius);

  // 只读的计算属性
  double get diameter => radius * 2;
  double get area => 3.14159 * radius * radius;

  // setter：给 diameter 赋值时，自动换算回 radius
  set diameter(double value) {
    radius = value / 2;
  }
}

void main() {
  final circle = Circle(2);

  print(circle.diameter);                // 4.0
  print(circle.area.toStringAsFixed(2)); // 12.57

  circle.diameter = 10;
  print(circle.radius);                  // 5.0
}
```

getter 的另一个高频用途是"包装私有字段，对外只读"（见第 14 节）。

## 6. 继承 extends 与 super

继承表达"is-a"关系：狗是动物。子类自动获得父类的字段和方法，还可以重写它们：

```dart
class Animal {
  final String name;

  Animal(this.name);

  void eat() {
    print('$name 在吃东西');
  }
}

class Dog extends Animal {
  Dog(super.name); // super 参数：直接把参数传给父类构造函数

  void bark() {
    print('$name 汪汪叫');
  }

  @override
  void eat() {
    super.eat(); // 先执行父类的实现
    print('$name 吃完骨头，摇摇尾巴');
  }
}

void main() {
  final dog = Dog('旺财');
  dog.eat();
  // 旺财 在吃东西
  // 旺财 吃完骨头，摇摇尾巴
  dog.bark();
  // 旺财 汪汪叫
}
```

Dart **只支持单继承**：一个类只能 `extends` 一个父类。想复用多份能力，后面会用 `mixin`。

把子类对象当作父类使用时，父类类型看不到子类独有方法，`is` 判断后会自动"类型提升"：

```dart
void main() {
  Animal animal = Dog('旺财');
  print(animal.name); // 旺财：父类成员可以直接用
  // animal.bark();   // 错误：animal 的静态类型是 Animal

  if (animal is Dog) {
    animal.bark(); // is 判断成功后自动提升为 Dog
  }
}
```

## 7. 抽象类 abstract

抽象类不能直接实例化，它用来规定"子类必须实现什么"。抽象方法只有签名、没有函数体：

```dart
abstract class Shape {
  double area();

  String get name;
}

class Circle extends Shape {
  final double radius;

  Circle(this.radius);

  @override
  double area() => 3.14159 * radius * radius;

  @override
  String get name => '圆';
}

class Square extends Shape {
  final double side;

  Square(this.side);

  @override
  double area() => side * side;

  @override
  String get name => '正方形';
}

void main() {
  final shapes = <Shape>[Circle(2), Square(3)];
  for (final shape in shapes) {
    print('${shape.name}的面积是 ${shape.area().toStringAsFixed(2)}');
  }
  // 圆的面积是 12.57
  // 正方形的面积是 9.00
}
```

注意：抽象类里**也可以有**普通字段和已实现的方法，不必全部抽象。上面的循环能写出 `shape.area()`，正是因为 `Shape` 这个抽象类型统一了接口——这就是多态。

## 8. 接口 implements

`implements` 和 `extends` 不同：它**只继承方法签名（契约），不继承任何实现**，所有成员都必须自己重写。好处是一个类可以同时实现多个接口：

```dart
abstract class Flyer {
  void fly();
}

abstract class Swimmer {
  void swim();
}

class Duck implements Flyer, Swimmer {
  @override
  void fly() {
    print('鸭子在飞');
  }

  @override
  void swim() {
    print('鸭子在游泳');
  }
}

void main() {
  final duck = Duck();
  duck.fly();  // 鸭子在飞
  duck.swim(); // 鸭子在游泳
}
```

两者对比：

| | extends | implements |
| --- | --- | --- |
| 数量 | 只能一个 | 可以多个 |
| 是否复用实现 | 直接继承父类实现 | 不继承，全部自己重写 |
| 表达的语义 | is-a，复用默认行为 | 遵守同一套"契约" |

> Dart 里任何类都隐含地定义了一个接口，所以 `implements` 后面不一定非得是 `abstract class`。

## 9. 混入 mixin

`mixin` 解决的是"把同一段能力塞进多个不相关的类"，比多继承更克制，用 `with` 引入：

```dart
mixin Logger {
  void log(String message) {
    print('[LOG] $message');
  }
}

class Service with Logger {
  void start() {
    log('服务启动');
  }
}

class UserService with Logger {
  void login(String name) {
    log('$name 登录了');
  }
}

void main() {
  Service().start();           // [LOG] 服务启动
  UserService().login('小明'); // [LOG] 小明 登录了
}
```

用 `on` 可以限制 mixin 只能混进某个父类的子类，这样 mixin 里就能放心使用父类的成员：

```dart
class Animal {
  final String name;

  Animal(this.name);
}

// 这个 mixin 只能被 Animal 的子类使用
mixin Swimmer on Animal {
  void swim() {
    print('$name 在水中游');
  }
}

class Fish extends Animal with Swimmer {
  Fish(super.name);
}

void main() {
  Fish('小黄鱼').swim(); // 小黄鱼 在水中游
}
```

选择建议：有明确的"是"关系用 `extends`；只想复用一段逻辑、类之间没有父子关系，用 `mixin`。

## 10. 静态成员 static 与 const

`static` 成员属于**类本身**而不是某个实例，通过 `类名.成员` 访问，常用于工具函数和共享常量：

```dart
class MathUtils {
  static const double pi = 3.14159;

  static int version = 1;

  static double square(double x) => x * x;
}

void main() {
  print(MathUtils.pi);        // 3.14159
  print(MathUtils.version);   // 1
  print(MathUtils.square(9)); // 81.0
}
```

`const` 构造函数能创建**编译期常量**，满足三个条件才能用：

1. 所有字段都是 `final`；
2. 构造函数体为空；
3. 传入的参数本身是编译期常量。

```dart
class ThemeColor {
  final String name;
  final int value;

  const ThemeColor(this.name, this.value);
}

void main() {
  const primary = ThemeColor('主色', 0xFF42A5F5);
  const same = ThemeColor('主色', 0xFF42A5F5);

  print(identical(primary, same)); // true：相同参数复用同一个实例
}
```

> **Flutter 高频考点**：给不随状态变化的 Widget 加 `const`，Flutter 就能在重建时直接复用它们、跳过不必要的渲染，这是性能优化的基本功，也是第 1 周自检清单里的一条。

## 11. 运算符重载

可以让自定义类型支持 `+`、`-`、`*`、`==` 等运算符。最常重载的是 `==` 和 `hashCode`：

```dart
class Vector {
  final double x;
  final double y;

  const Vector(this.x, this.y);

  Vector operator +(Vector other) {
    return Vector(x + other.x, y + other.y);
  }

  Vector operator -(Vector other) {
    return Vector(x - other.x, y - other.y);
  }

  Vector operator *(double scalar) {
    return Vector(x * scalar, y * scalar);
  }

  @override
  bool operator ==(Object other) {
    return other is Vector && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Vector($x, $y)';
}

void main() {
  const a = Vector(1, 2);
  const b = Vector(3, 4);

  print(a + b);                    // Vector(4.0, 6.0)
  print(b - a);                    // Vector(2.0, 2.0)
  print(a * 3);                    // Vector(3.0, 6.0)
  print(a == const Vector(1, 2));  // true
}
```

### 可以重载的运算符

Dart 能重载的运算符是**固定的一份名单**，一共 20 个，不能自己发明新符号：

| 分类 | 运算符 | 说明 |
| --- | --- | --- |
| 比较 | `<` `>` `<=` `>=` `==` | 排序、相等判断 |
| 算术 | `+` `-` `*` `/` `~/` `%` | `-` 既可以是一元负号，也可以是二元减法 |
| 位运算 | `&` `\|` `^` `~` `<<` `>>` `>>>` | `~` 是一元按位取反 |
| 索引 | `[]` `[]=` | 让对象像列表一样读写元素 |

重载时运算符的**参数个数不能改**：`+`、`-`、`*` 等二元运算符必须恰好 1 个参数；`~` 和一元 `-` 不能有参数；`[]` 恰好 1 个参数；`[]=` 恰好 2 个参数（下标 + 新值）。另外，运算符重载只能是**实例方法**，不能声明成 `static`。

`Vector` 例子没展示的三种写法，这里补上：

```dart
class Team {
  final List<String> _members;

  Team(this._members);

  // 只读下标：team[0]
  String operator [](int index) => _members[index];

  // 可写下标：team[0] = '新成员'
  void operator []=(int index, String name) {
    _members[index] = name;
  }

  // 一元负号：成员顺序反过来
  Team operator -() => Team(_members.reversed.toList());
}

void main() {
  final team = Team(['小明', '小红']);

  print(team[0]);    // 小明
  team[0] = '大明';
  print(team[0]);    // 大明
  print((-team)[0]); // 小红
}
```

### 不能重载的运算符

下面这些**不能**重载，记住名单即可，不用深究原因：

- 赋值类：`=`、`+=`、`-=`、`*=` 等复合赋值；
- 逻辑类：`&&`、`||`、`!`；
- 条件与空安全：`?:`、`??`、`??=`、`?.`、`...?`；
- 其他：`.`、`..`、`...`、`?[]`、`is`、`as`、`await`。

两个容易踩的坑：

- `!=` 不需要单独重载，它自动取 `==` 的相反结果；重写 `==` 后 `!=` 会跟着变。
- `+=` 虽然不能直接重载，但会自动复用 `+` 的重载：`a += b` 等价于 `a = a + b`。

铁律：**重写 `==` 就必须同时重写 `hashCode`**，规则是"相等的对象必须有相同的 hashCode"，否则放进 `Set` / `Map` 会出诡异 bug。

## 12. 扩展方法 extension

extension 可以给**已有类型**追加方法，而且不用修改原类型。适合封装常用的字符串、日期、列表处理：

```dart
extension StringExtension on String {
  String get firstUpper {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  bool get isPhoneNumber {
    return RegExp(r'^1\d{10}$').hasMatch(this);
  }
}

void main() {
  print('dart'.firstUpper);          // Dart
  print('13800138000'.isPhoneNumber); // true
  print('123'.isPhoneNumber);         // false
}
```

```dart
extension IntListExtension on List<int> {
  int sum() => fold(0, (total, n) => total + n);

  double average() => isEmpty ? 0 : sum() / length;
}

void main() {
  final scores = [88, 92, 79, 95];
  print(scores.sum());                   // 354
  print(scores.average().toStringAsFixed(1)); // 88.5
}
```

注意：extension 不会真的改类型，只是在使用处 `import` 了该扩展后才"看得见"这些方法。

## 13. 泛型 generic

泛型让同一个类/函数能处理多种类型，同时保留类型安全。`List<int>`、`Map<String, int>` 其实早就在用了：

```dart
class Box<T> {
  T value;

  Box(this.value);

  T open() => value;
}

void main() {
  final intBox = Box<int>(42);
  final strBox = Box('dart'); // 类型推断为 Box<String>

  print(intBox.open() + 1);           // 43
  print(strBox.open().toUpperCase()); // DART
}
```

用 `extends` 给类型参数加**约束**，限制只能用某类及其子类：

```dart
class NumberBox<T extends num> {
  final T value;

  NumberBox(this.value);

  double half() => value / 2;
}

void main() {
  print(NumberBox(10).half());    // 5.0
  print(NumberBox(10.5).half());  // 5.25
  // NumberBox('10'); // 编译报错：String 不是 num
}
```

函数和方法同样可以声明泛型：

```dart
T firstOr<T>(List<T> items, T fallback) {
  return items.isEmpty ? fallback : items.first;
}

void main() {
  print(firstOr<int>([1, 2, 3], 0));      // 1
  print(firstOr<String>([], '空列表'));   // 空列表
}
```

## 14. 私有成员与封装

以 `_` 开头的成员是**私有**的。封装的目标是：外部只能通过我们提供的公开方法来操作数据，数据不会被人随便改成非法状态：

```dart
class BankAccount {
  final String _owner;
  double _balance;

  BankAccount(this._owner, this._balance);

  // 通过 getter 对外只读
  String get owner => _owner;
  double get balance => _balance;

  void deposit(double amount) {
    if (amount <= 0) {
      throw ArgumentError('存款金额必须大于 0');
    }
    _balance += amount;
  }

  bool withdraw(double amount) {
    if (amount <= 0 || amount > _balance) {
      return false;
    }
    _balance -= amount;
    return true;
  }
}

void main() {
  final account = BankAccount('小明', 100);

  account.deposit(50);
  print(account.balance); // 150.0

  print(account.withdraw(1000)); // false：余额不足
  print(account.withdraw(30));   // true
  print(account.balance);        // 120.0
}
```

一个容易误解的点：Dart 的私有是**库级**（文件级）的，同一个文件里仍然能访问 `_balance`；跨文件才会被挡在外面。这和 Java/C# 的"类级私有"不一样。

## 15. 综合演示

把抽象类、继承、mixin、泛型组合起来，做一个迷你动物园：

```dart
abstract class Animal {
  final String name;

  Animal(this.name);

  String speak();

  @override
  String toString() => '$runtimeType($name)';
}

mixin Runnable on Animal {
  void run() {
    print('$name 在奔跑');
  }
}

class Dog extends Animal with Runnable {
  Dog(super.name);

  @override
  String speak() => '汪汪';
}

class Cat extends Animal with Runnable {
  Cat(super.name);

  @override
  String speak() => '喵喵';
}

class Zoo<T extends Animal> {
  final List<T> _animals = [];

  void add(T animal) => _animals.add(animal);

  void showAll() {
    for (final animal in _animals) {
      print('${animal.name}说：${animal.speak()}');
    }
  }
}

void main() {
  final dog = Dog('旺财');
  final cat = Cat('咪咪');

  final zoo = Zoo<Animal>();
  zoo.add(dog);
  zoo.add(cat);
  zoo.showAll();
  // 旺财说：汪汪
  // 咪咪说：喵喵

  dog.run();
  cat.run();
  // 旺财 在奔跑
  // 咪咪 在奔跑
}
```

## 16. 速查表

### 类与构造函数

| 写法 | 作用 |
| --- | --- |
| `class 类名 { }` | 定义类 |
| `类名(this.字段)` | 构造函数，参数直接赋给字段 |
| `类名.名字(...)` | 命名构造函数 |
| `factory 类名(...)` | 工厂构造函数，可返回缓存/子类实例 |
| `const 类名(...)` | 常量构造函数，需全 final 字段 + 空构造体 |
| `:` 初始化列表 | 构造体执行前给 final 字段赋值、写 assert |
| `static` | 静态成员，用 `类名.成员` 访问 |

### 继承与复用

| 写法 | 作用 |
| --- | --- |
| `extends` | 单继承，复用父类实现 |
| `super` | 调用父类构造函数 / 方法 |
| `@override` | 重写父类成员 |
| `abstract class` | 抽象类，含无实现的抽象方法 |
| `implements` | 实现接口，可多个，全部自己重写 |
| `mixin ... with` | 混入复用逻辑 |
| `mixin X on Y` | 限制 mixin 只能用于 Y 的子类 |

### 其他常用

| 写法 | 作用 |
| --- | --- |
| `_名字` | 库级私有成员 |
| `get` / `set` | 计算属性 |
| `operator +` 等 | 运算符重载 |
| `==` + `hashCode` | 重写相等判断，二者必须成对 |
| `extension 名字 on 类型` | 扩展方法 |
| `<T>` / `<T extends 类型>` | 泛型与类型约束 |
| `toString()` | 重写后影响 `print` 的显示 |

## 17. 建议练习

1. 写一个 `Student` 类：字段 `name`、`scores`（`List<int>`），方法 `averageScore()`，getter `passedCount`（及格数）和 `bestScore`，重写 `toString` 打印学生信息。
2. 用抽象类 `Shape`（`area()`）派生 `Circle` 和 `Rectangle`，写一个 `totalArea(List<Shape> shapes)` 函数计算总面积，体会多态。
3. 写 `BankAccount`：私有 `_balance`，`deposit` 校验金额必须为正，`withdraw` 校验不能透支，练习封装。
4. 用泛型写 `Stack<T>`：`push`、`pop`、`peek`、`isEmpty`、`length`，分别用 `Stack<int>` 和 `Stack<String>` 测试。
5. 写一个 `mixin JsonLogger`（记录每次读写的字段名），让 `User` 类 `with` 它；再给 `String` 写一个 `toTitleCase` 扩展方法。
6. 给 `Vector` 类补上 `-` 运算符重载，并解释为什么重写 `==` 时必须重写 `hashCode`。

## 18. 下一步方向

按你的路线图（第 1 周 M1），Dart 速成还差最后一块：**异步编程**。

**建议顺序：**

1. **完成本篇练习**（老规矩：有产出物才算过，不要只"看会"）。
2. **写「Dart学习笔记-05-异步编程」**：`Future`、`async / await`、`Stream`、错误处理。这是必学项——Flutter 里的网络请求、按钮回调、页面跳转、定时器几乎全在异步场景里。
3. **进入 Flutter M2「一切皆 Widget」**：`StatelessWidget` / `StatefulWidget`、`setState`、热重载，对应你 `01-第一周` 文档里的内容，产出物是"一个可交互卡片"。

别跳过第 2 步直接抄 UI——路线图里也专门提醒过：很多人第三周被空安全、构造函数和异步反复打脸，根子都在 M1 没打牢。

学完本篇，先对照自检一遍：

- [ ] 能说清 `extends` 和 `implements` 的区别
- [ ] 知道什么时候用继承、什么时候用 mixin
- [ ] `factory` 构造函数和普通构造函数差在哪
- [ ] 为什么重写 `==` 必须重写 `hashCode`
- [ ] `const` 构造函数需要满足哪些条件

这些正是第 1 周自检清单里"读 Flutter 源码不卡壳"的底气来源。
