// 1. 用 `List` 和 `map` 把一组数字全部乘以 3，并过滤出偶数。
void answer1() {
  // 题目1答案
  List nums = [2, 7, 5, 4, 9, 6, 1, 8, 3, 10];
  print(
    nums
      ..map((num) => num *= 3)
      ..removeWhere((num) => num.isEven),
  );
}

bool isEnglish(code) {
  return (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      code == 0x27; // 撇号 ' 算英文单词的一部分;
}

// 2. 用 `Set` 对一篇文章中的单词去重，并统计单词数量。
void answer2() {
  String article =
      "《My Dart Learning Notes》 — Dart is a programming language with concise syntax. Learning Dart helped me understand the concepts of variables, functions, and classes. During my journey of learning Dart, the biggest takeaway I gained is: write more code, modify more code, and read more of other people's code. Functions make code reusable, and classes make code more structured. Every time I run the code, I discover new problems; every time I solve a problem, I learn new knowledge. If you also want to learn Dart, remember: keep writing code, keep reading code, and keep thinking about code. That is my biggest takeaway from learning Dart.";
  List<String> listData = [];
  int coordinate = 0;
  Map<String, int> count = {};
  for (var i = 0; i < article.length; i++) {
    String current = article[i];
    int strCode = current.codeUnits[0];
    if (!isEnglish(strCode)) {
      if (coordinate < i) {
        var str = article.substring(coordinate, i);
        listData.add(str);
        count[str] = (count[str] ?? 0) + 1;
      }
      coordinate = i + 1;
    }
    ;
  }
  if (coordinate < article.length) {
    listData.add(article.substring(coordinate));
  }
  Set<String> setData = {};
  setData.addAll(listData); // 去重
  print(count); //统计出现次数
}

// 3. 用 `Map` 实现一个简单的学生成绩表，支持新增、更新、查询和删除。
void answer3() {
  Map<String, int> gradeReport = {};
  void add(String name, int score) {
    if (gradeReport.containsKey(name)) {
      gradeReport.update(name, (v) => score);
    } else {
      gradeReport.putIfAbsent(name, () => score);
    }
    print('学生$name 添加成功 分数 $score');
  }

  void remove(String name) {
    if (gradeReport.containsKey(name)) {
      gradeReport.remove(name);
      print('学生$name 删除成功');
    } else {
      print('学生$name 不存在');
    }
  }

  void edit(String name, int score) {
    if (gradeReport.containsKey(name)) {
      gradeReport.update(name, (v) => score);
      print('学生$name 分数修改成功 分数 $score');
    } else {
      print('学生$name 不存在');
    }
  }

  void search(String name) {
    if (gradeReport.containsKey(name)) {
      int val = gradeReport[name]!;
      print('学生$name 分数 $val');
    } else {
      print('学生$name 不存在');
    }
  }

  add('张三', 90);
  add('李四', 60);
  add('王二', 80);

  edit('张一', 20);
  edit('张三', 75);

  search('张三');

  search('李五');
  search('李四');

  remove('张二');
  remove('张三');

  search('张三');

  print(gradeReport);
}

// 4. 把 `List<Map<String, Object>>` 转换成一个新的可展示字符串列表。

void answer4() {
  List<Map<String, Object>> users = [
    {'name': 'Alice', 'age': 18, 'score': 88.5, 'vip': true},
    {'name': 'Bob', 'age': 20, 'score': 95.0, 'vip': false},
    {'name': 'Carol', 'age': 22, 'score': 76.0, 'vip': true},
  ];
  users.forEach((user) {
    var {'name': name, 'age': age, 'score': score, 'vip': vip} = user;
    print('姓名：$name, 年龄：$age, 积分：$score, 是否是vip:' + (vip == true ? '是' : '否'));
  });
}

// 5. 练习 `int.tryParse`、`String?`、`??` 等空安全写法，处理用户输入。
void answer5() {
  Map<String, Map<String, num>> userProfile = {};
  num count = 0;
  /** name：用户名 ,score：分数 , age: 年龄 */
  void setuser({String? name, String? score, String? age}) {
    if (name == null && score == null && age == null) {
      print('非法输入');
    } else {
      String userName = name ?? '未知用户$count';
      if (name == null) ++count;
      Map<String, num> userData = {
        'score': score == null ? 0 : int.tryParse(score) ?? 0,
        'age': age == null ? 0 : int.tryParse(age) ?? 0,
      };
      if (userProfile.containsKey(userName)) {
        userProfile.update(userName, (u) => userData);
      } else {
        userProfile.putIfAbsent(userName, () => userData);
      }
    }
  };

  setuser(name: '小明', age: '11', score: '100');
  setuser(name: '小方');
  setuser(name: '小刚', score: '100');
  setuser( score: '80');
  setuser( score: '12');
  print(userProfile);
}

void main() {
  answer1();
  print('-----------------------------------------------------');
  answer2();
  print('-----------------------------------------------------');
  answer3();
  print('-----------------------------------------------------');
  answer4();
  print('-----------------------------------------------------');
  answer5();
}
