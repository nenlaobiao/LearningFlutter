class A {
  factory A() => A._internal();
  A._internal();
}

// B 没有声明任何构造函数，看看默认构造能不能用父类的工厂
class B extends A {}

class C {
  factory C.fromJson(Map<String, dynamic> json) => C();
}

class D extends C {
  D();
}

class G {
  factory G.named() => G._();
  G._();
}

class H extends G {
  // 生成式构造的初始化列表里能否调用父类的工厂构造？
  H() : super.named();
}

void main() {
  var b = B();
  // 命名工厂构造是否被继承？
  var d = D.fromJson({});
}
