// 1. 写一个 BMI 计算器：输入身高和体重，用 `/` 和条件表达式输出"偏瘦 / 正常 / 偏胖"。
void answer1() {
  /**
   * BMI计算器
   * height：身高（cm）  
   * weight：体重（kg）  
   */
  void BMIcalculator({required num height, required num weight}) {
    if (height <= 0 || weight <= 0) return print('非法输入');
    var mheight = height / 100;
    double bmi =
        double.tryParse((weight / (mheight * mheight)).toStringAsFixed(1)) ??
        0.0;
    String evaluate = switch (bmi) {
      < 18.5 => '偏瘦',
      >= 18.5 && <= 23.9 => '正常',
      >= 24 && <= 27.9 => '超重',
      >= 28 => '肥胖',
      _ => '计算错误',
    };
    print("""
您的身高为: $height CM
体重为: $weight KG
BMI值为: $bmi
您的体型: $evaluate
    """);
  }

  BMIcalculator(height: 175, weight: 83);
}

// 2. 用 `%` 运算符判断一个年份是否为闰年（能被 4 整除但不能被 100 整除，或者能被 400 整除）。
void answer2() {
  void leapYear(int year) {
    if (year <= 0) return print('非法输入');
    String type = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
        ? '闰年'
        : '平年';
    print('$year 年为$type');
  }

  leapYear(1999);
  leapYear(2024);
  leapYear(2026);
}

// 3. 用 `??` 和 `??=` 处理一个可能为 null 的用户昵称，为空时显示"匿名用户"。
void answer3() {
  userNameCheck(String? name) {
    String display = name ?? '匿名用户';
    print(display);
    name ??= '默认昵称';
    print('欢迎，${display}');
  }

  userNameCheck('明明');
  userNameCheck(null);
}

// 4. 用位运算实现权限系统：读 = 1、写 = 2、执行 = 4，判断某个权限组合是否包含写权限。
void answer4() {
  const read = 1;
  const write = 2;
  const delete = 4;
  const admin = 8;
  void permission(int p) {
    print('-----');
    if ((p & read) != 0) print('写入权限');
    if ((p & write) != 0) print('读取权限');
    if ((p & delete) != 0) print('删除权限');
    if ((p & admin) != 0) print('管理员权限');
  }

  permission(1 | 8);
}

// 5. 用级联运算符初始化一个列表并排序，再对比普通写法的可读性差异。
// 创建这个列表
// 添加一个 'Mango'
// 删除 'Orange'
// 排序
// 最后打印列表
void answer5() {
  final fruits = ['Banana', 'Apple', 'Orange', 'Watermelon', 'Grape'];
  List<String> newList = fruits
    ..add('Mango')
    ..remove('Orange')
    ..sort();
  print(newList);

  final fruits1 = ['Banana', 'Apple', 'Orange', 'Watermelon', 'Grape'];
  List<String> newList2 = [...fruits1,'Mango'];
  newList2.remove('Orange');
  newList2.sort();
  print(newList2);

}

void main() {
  answer1();
  answer2();
  answer3();
  answer4();
  answer5();
}
