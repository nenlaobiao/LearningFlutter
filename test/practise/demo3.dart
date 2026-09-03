// 1. 写 FizzBuzz：打印 1 到 100，3 的倍数打印 Fizz，5 的倍数打印 Buzz，既是 3 又是 5 的倍数打印 FizzBuzz，其余打印数字本身。
void answer1() {
  // 方法1
  void fizzBuzz1(int n) {
    print(switch (n) {
      int i when (i % 3 == 0 && i % 5 == 0) => 'FizzBuzz',
      int i when i % 3 == 0 => 'Fizz',
      int i when i % 5 == 0 => 'Buzz',
      _ => n,
    });
  }

  // 方法2
  void fizzBuzz2(int n) {
    String str = '';
    if (n % 3 == 0) str += 'Fizz';
    if (n % 5 == 0) str += 'Buzz';
    print(str.isEmpty ? n : str);
  }

  // 方法3
  void fizzBuzz3(int n) {
    final list = [
      if (n % 3 == 0) 'Fizz',
      if (n % 5 == 0) 'Buzz'
    ].join();
    print(list.isEmpty ? n : list);
  }

  for (var i = 1; i <= 100; i++) {
    // fizzBuzz1(i);
    // fizzBuzz2(i);
    // fizzBuzz3(i);
  }
}

// 2. 写一个 `isPrime(int n)` 函数判断素数，再用循环找出 1 到 50 里的所有素数。
void answer2() {
  void isPrime(int n) {
    if(n<2)return;
    bool prime = true;
    for(var i=2 ;i<n ; i++){
      if(n%i == 0){
        prime = false;
        break;
      }
    }
    if(prime)print(n);
  }

  for (var i = 1; i <= 50; i++) {
    isPrime(i);
  }
}

// 3. 用 switch 表达式写一个 `gradeOf`，把 0 到 100 的分数映射成 A / B / C / D 等级。
void answer3() {
  gradeOf(int s){
    print(switch(s){
      <25 =>'D',
      <50 =>'C',
      <75 =>'B',
      _ =>'A'
    });
  }
  for (var i = 0; i <= 100; i++) {
    // gradeOf(i);
  }
}

// 4. 用闭包实现一个"累加器"：每次调用返回当前总和，再新建一个独立的累加器验证它们互不影响。
void answer4() {
  int Function() count(){
    int num = 0;
    return ()=>num++;
  }
  var aaa= count();
  var bbb= count();
  print(aaa());
  print(aaa());
  print('-------------');
  print(bbb());
  print(bbb());
  print(bbb());
  print(bbb());
  print(bbb());
}

// 5. 写一个高阶函数 `applyTwice(int value, int Function(int) fn)`，把传入函数连续应用两次，例如 `applyTwice(3, (n) => n * n)` 的结果是 81。
void answer5() {
  applyTwice(int value, int Function(int) fn){
    print(fn(fn(value))); 
  }
  applyTwice(3, (n) => n * n);
}

void main() {
  answer1();
  answer2();
  answer3();
  answer4();
  answer5();
}
