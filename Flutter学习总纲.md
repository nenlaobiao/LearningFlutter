# Flutter 学习总纲（10 天冲刺版）

> 前提：Dart 部分已完成，具备 Vue/uniapp 熟练、React 学习中的前端经验。
> 时间预算：10 天，每天 6–8 小时，总计约 65–80 小时。
> 学习方式：每天「概念 → 手写 → 跑通 → 自检」，不追求一次学透，先建立可迁移的 Flutter 心智模型。

## 一、总目标与成功标准

10 天结束时，你要能：

- 独立搭建 Flutter 项目，并用 `Widget` 组织界面；
- 用 `setState` 和一种主流状态管理方案（Riverpod）管理业务状态；
- 完成路由跳转、列表、表单校验、网络请求、本地持久化；
- 独立把一个 demo 项目跑成可安装的 release apk；
- 遇到布局/报错时，知道去 Widget Inspector 和报错堆栈里定位。

贯穿项目：**做一个极简商城 App**（商品列表 → 详情 → 加入购物车 → 结算 → 登录态持久化）。它覆盖了 Flutter 最核心的一整条链路。

## 二、三条主线（比零散知识点更重要）

1. **一切皆 Widget**：UI 是 `Widget` 树，不是 DOM。
2. **UI = f(state)**：界面永远是状态的函数，改变状态必须触发重建。
3. **约束向下、尺寸向上**：布局不是 CSS，是约束在父子间传递。

每天的学习都围绕这三条主线展开。

## 三、10 天路线总表

| 天 | 主题 | 核心内容 | 当日产出 |
| --- | --- | --- | --- |
| 1 | 项目与 Widget 世界观 | 创建项目、`MaterialApp`、`StatelessWidget`、`StatefulWidget`、`setState` | 能跑的首页 + 可点击计数器 |
| 2 | 布局体系 | `Row`/`Column`/`Stack`、`Expanded`、约束模型、`Container`/`Padding` | 商城首页静态布局 |
| 3 | 列表与表单 | `ListView.builder`、`TextField`、`Form` 校验、`RefreshIndicator` | 商品列表 + 登录表单 |
| 4 | 路由与页面组织 | `Navigator`、`go_router`、传参与结果回传 | 商品详情页 + 页面跳转 |
| 5 | 状态管理 | `setState` 局限、Provider 思想、Riverpod | 全局购物车状态 |
| 6 | 网络请求 | `dio` 封装、拦截器、JSON 序列化 | 真实 API 商品数据 |
| 7 | 本地存储 | `shared_preferences`、Token 持久化、`sqflite` 简介 | 登录态保持 |
| 8 | 主题与动画 | `ThemeData`、暗黑模式、隐式动画、`Hero` | 页面过渡与主题切换 |
| 9 | 工程化与打包 | 目录规范、多环境、release 签名打包 | 可安装的 release apk |
| 10 | 复盘与补漏 | 完整跑通项目、自检、补笔记 | 一套可复用项目 + 通过自检 |

## 四、每日详细计划

### Day 1：项目与 Widget 世界观

**目标**：建立“一切皆 Widget”和“UI = f(state)”两条主线。

**概念（约 2 小时）**

- `flutter create` 后目录里各文件是干什么的
- `main.dart` 入口、`runApp`、`MaterialApp`、`Scaffold`
- `StatelessWidget` 与 `StatefulWidget` 怎么选
- `setState` 做了什么：为什么改变量界面不变
- 热重载 `r` 与热重启 `R` 的区别

**动手（约 4 小时）**

1. 用 `flutter create` 建 `shopping_demo` 项目
2. 把默认计数器改成自己的「点击加一」卡片
3. 写一个显示当前时间的 `StatelessWidget`，体会它没有内部状态
4. 用 `StatefulWidget` 做「收藏/取消收藏」按钮，观察 `setState` 重建

**自检**

- `StatelessWidget` 和 `StatefulWidget` 什么时候选？
- 为什么只改 `int` 变量界面不变？
- `r` 和 `R` 分别什么时候用？

### Day 2：布局体系

**目标**：理解 Flutter 没有 CSS，布局靠约束和 Widget 嵌套。

**概念（约 2 小时）**

- 约束模型：约束向下、尺寸向上
- `Row`/`Column` 的主轴、交叉轴
- `Expanded`、`Flexible`、`Spacer`
- `Container`、`SizedBox`、`Padding`、`Center`、`Align`
- `Stack`、`Positioned` 对应 CSS 的 `position: absolute`

**动手（约 4 小时）**

1. 做一个顶部标题栏 + 商品网格的静态首页
2. 用 `Row` 放「标题 + 价格」，标题超长时验证溢出怎么办
3. 用 `Stack` 给商品图加一个角标
4. 把超宽内容放进 `Expanded`，体会它如何分配空间

**自检**

- “约束向下、尺寸向上”是什么意思？
- `Row` 放超宽内容会怎样？怎么解决？
- `Container` 什么时候撑满、什么时候收缩？

### Day 3：列表与表单

**目标**：处理真实业务里最常见的两类界面。

**概念（约 2 小时）**

- `ListView` 和 `ListView.builder` 的区别与惰性构建
- `RefreshIndicator` 下拉刷新
- `TextField`、`TextFormField`、`Form`、`TextEditingController`
- `validator` 表单校验、`key` 的作用

**动手（约 4 小时）**

1. 用 `ListView.builder` 渲染一份本地商品数据
2. 给列表加下拉刷新和加载更多
3. 做一个登录页：邮箱、密码、提交按钮，含校验
4. 提交时把表单数据打印出来，验证校验逻辑

**自检**

- 长列表为什么用 `builder` 而不是 `children: [...]`？
- 表单校验失败时，错误提示放在哪里？
- 下拉刷新和上拉加载怎么组合？

### Day 4：路由与页面组织

**目标**：在多页面之间正确跳转、传参、拿结果。

**概念（约 2 小时）**

- `Navigator.push` / `pop` 的基本用法
- 命名路由与 `go_router`
- 页面传参与结果回传
- `BottomNavigationBar`、`TabBar` 的页面骨架

**动手（约 4 小时）**

1. 商品列表 → 商品详情页，传入商品 id
2. 详情页「加入购物车」后 `pop` 回列表，带回结果
3. 用 `BottomNavigationBar` 做「首页 / 购物车 / 我的」三个 tab
4. 登录成功后跳转首页，避免返回键回到登录页

**自检**

- `push` 和 `pushReplacement` 区别？
- 路由参数怎么传、结果怎么回？
- 底部 tab 怎么保持各页状态？

### Day 5：状态管理

**目标**：跨页面共享购物车状态，理解为什么需要状态管理。

**概念（约 2 小时）**

- `setState` 只适合局部状态
- 状态提升、Provider 思想、`ChangeNotifier`
- Riverpod 的 `Provider`、`Notifier`、`ConsumerWidget`
- 什么时候才需要状态管理（不是每个变量都上）

**动手（约 4 小时）**

1. 用 Riverpod 建一个全局 `CartNotifier`
2. 商品详情「加入购物车」改变全局数量
3. 购物车 tab 实时显示数量
4. 结算页读同一份状态，验证跨页共享

**自检**

- 什么时候 `setState` 就够？什么时候必须上状态管理？
- 全局状态放在哪里？组件怎么订阅？
- 购物车数量在多个页面如何保持一致？

### Day 6：网络请求

**目标**：把本地假数据换成真实 API，并统一错误处理。

**概念（约 2 小时）**

- `dio` 与 `http` 怎么选，为什么推荐 `dio`
- 拦截器：统一带 Token、日志、Loading、错误
- JSON 转模型：手写 `fromJson` / `toJson`
- `FutureBuilder` 与异步 UI 状态

**动手（约 4 小时）**

1. 用 `dio` 请求 [DummyJSON](https://dummyjson.com) 的商品接口
2. 把响应 JSON 转成 `Product` 模型
3. 用 `FutureBuilder` 显示加载中 / 成功 / 失败三态
4. 写拦截器打印请求日志、统一处理 401

**自检**

- JSON 转模型为什么要写 `fromJson`？
- 拦截器里怎么统一加 Token？
- 加载中、失败、空数据分别怎么展示？

### Day 7：本地存储

**目标**：登录后重启 App 仍保持登录态。

**概念（约 2 小时）**

- `shared_preferences` 适合存轻量键值
- `sqflite` 适合结构化数据，什么时候用
- Token 持久化：登录写、启动读、退出清
- 异步初始化与空安全

**动手（约 4 小时）**

1. 登录成功后把 Token 写入 `shared_preferences`
2. 启动时读 Token，决定进登录页还是首页
3. 退出登录时清除 Token
4. 可选：把最近浏览商品用 `sqflite` 存起来

**自检**

- Token 存哪里？为什么不用全局变量？
- 启动时怎么判断是否已登录？
- `shared_preferences` 和 `sqflite` 怎么选？

### Day 8：主题与动画

**目标**：让 App 有统一视觉，并加入合理动效。

**概念（约 2 小时）**

- `ThemeData`：主色、文字、按钮样式
- 暗黑模式：`ThemeMode` 与系统跟随
- 隐式动画：`AnimatedContainer`、`AnimatedOpacity`、`AnimatedSwitcher`
- `Hero` 转场：列表图到详情图

**动手（约 4 小时）**

1. 抽一套 `ThemeData`，统一按钮和卡片样式
2. 做「浅色 / 深色 / 跟随系统」切换
3. 加入购物车时用 `AnimatedSwitcher` 做数字变化
4. 商品图列表→详情加 `Hero` 动画

**自检**

- `ThemeData` 主要配置哪些？
- 隐式动画和显式动画怎么选？
- `Hero` 需要满足什么条件才有效？

### Day 9：工程化与打包

**目标**：把 demo 变成可安装的 release apk。

**概念（约 2 小时）**

- 目录规范：`lib/` 下怎么分层
- 多环境配置：开发 / 生产的 baseURL、App 名称
- `flutter build apk --release` 与签名
- 常见打包报错：SDK、签名、混淆

**动手（约 4 小时）**

1. 重构项目目录：`pages`、`models`、`services`、`state`
2. 用 `--dart-define` 区分开发/生产环境
3. 生成 release 签名，跑通 `flutter build apk --release`
4. 安装到模拟器或真机，检查启动、登录、购物车完整流程

**自检**

- `lib/` 下合理的分层是什么？
- 开发和生产环境怎么切换？
- release 打包前要检查哪些？

### Day 10：复盘与补漏

**目标**：完整跑通项目，补齐笔记和薄弱环节。

**动手（约 5 小时）**

1. 从「启动 → 登录 → 商品列表 → 详情 → 加入购物车 → 结算 → 退出」完整走一遍
2. 把 10 天的笔记整理成「Flutter 笔记索引」
3. 针对自检没通过的知识点，补最小 demo
4. 清理死代码，确认项目结构清晰

**收尾（约 1 小时）**

- 整理一份「我学到的 Flutter 核心概念」清单
- 记录 3 个最容易踩的坑，写进笔记
- 决定下一步：继续深挖状态管理，还是直接复刻一个 uniapp 老项目

## 五、阶段自检清单（Day 10 逐项确认）

- [ ] 能解释 `StatelessWidget` 和 `StatefulWidget` 的区别
- [ ] 能解释 `setState` 为什么能刷新界面
- [ ] 能解释约束向下、尺寸向上
- [ ] 能处理 `Row`/`Column` 溢出
- [ ] 能用 `ListView.builder` 渲染长列表
- [ ] 能用 `Form` 做输入校验
- [ ] 能完成路由跳转、传参、结果回传
- [ ] 能用 Riverpod 共享全局状态
- [ ] 能用 `dio` 封装请求、拦截器、错误处理
- [ ] 能用 `shared_preferences` 持久化 Token
- [ ] 能配置主题与暗黑模式
- [ ] 能加入 `Hero` / 隐式动画
- [ ] 能跑通 `flutter build apk --release`

## 六、学习建议（针对你的背景）

1. **不要再用 DOM 思维找“class”**：Flutter 没有 CSS，样式是 Widget 参数。
2. **`setState` 先写透，再上 Riverpod**：顺序很重要，否则会用工具但不懂原理。
3. **布局卡住就开 Widget Inspector**：它能显示约束和尺寸，比猜快十倍。
4. **报错先读堆栈最后一行**：Flutter 的报错往往直接告诉你哪个 Widget、哪一行。
5. **每天留 30 分钟整理笔记**：把当天概念和踩坑写进 `Flutter学习笔记` 系列。
6. **卡住 30 分钟就拆小任务**：先跑通最小版，再加功能。

## 七、Flutter 笔记索引（持续更新）

| 编号 | 计划文件 | 主题 | 状态 |
| --- | --- | --- | --- |
| — | Flutter学习总纲.md | 10 天冲刺路线与自检 | ✅ 本文 |
| Flutter 01 | Flutter学习笔记-01-Widget与布局.md | 项目、Widget、setState | ✅ 已生成 |
| Flutter 02 | Flutter学习笔记-02-布局体系.md | 约束模型、Row/Column/Stack、Container、Expanded | ✅ 已生成 |
| Flutter 03 | Flutter学习笔记-03-列表与表单.md | ListView、Form、校验 | ✅ 已生成 |
| Flutter 04 | Flutter学习笔记-04-路由与页面组织.md | Navigator、go_router、传参、Tab | ✅ 已生成 |
| Flutter 05 | Flutter学习笔记-05-状态管理.md | setState 局限、Provider、Riverpod | ✅ 已生成 |
| Flutter 06 | Flutter学习笔记-06-网络请求.md | dio、拦截器、JSON 序列化 | ✅ 已生成 |
| Flutter 07 | Flutter学习笔记-07-本地存储.md | shared_preferences、sqflite、Token | 📅 计划 |
| Flutter 08 | Flutter学习笔记-08-主题与动画.md | ThemeData、隐式动画、Hero | 📅 计划 |
| Flutter 09 | Flutter学习笔记-09-工程化与打包.md | 目录、多环境、release | 📅 计划 |
| Flutter 10 | Flutter学习笔记-10-复盘与补漏.md | 完整跑通、自检、补笔记 | 📅 计划 |

## 八、资源

- 官方文档 [docs.flutter.dev](https://docs.flutter.dev)
- 中文文档 [flutter.cn](https://flutter.cn)
- Widget 官方目录 [Widget catalog](https://docs.flutter.dev/ui/widgets)
- Riverpod 文档 [riverpod.dev](https://riverpod.dev)
- dio 文档 [pub.dev/packages/dio](https://pub.dev/packages/dio)
- 练习 API [DummyJSON](https://dummyjson.com)
