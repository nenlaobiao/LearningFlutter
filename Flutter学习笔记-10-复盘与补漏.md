# Flutter 学习笔记 10：复盘与补漏

> 适用前提：Day 1 ~ Day 9 都走过一遍（哪怕某些地方还半懂）。本机 Flutter 3.47.5 / Dart 3.13.4。
> 配套计划：[Flutter学习总纲.md](Flutter学习总纲.md) 的 Day 10。
> 本笔记的目标：把散在九篇里的东西**串成一张网**，把「半懂」的地方补成「能用」，把项目收拾到可以交给别人看，最后决定下一步往哪走。这一天不学新概念——**只做体检、补漏、归档**。

## 目录

- [1. 复盘怎么做才有用](#1-复盘怎么做才有用)
- [2. 十天知识地图：三条主线串起所有内容](#2-十天知识地图三条主线串起所有内容)
- [3. 全链路走查：从启动到退出](#3-全链路走查从启动到退出)
- [4. 毕业自检 13 条（附标准答案）](#4-毕业自检-13-条附标准答案)
- [5. 快问快答 12 题](#5-快问快答-12-题)
- [6. 高频坑总榜（九篇汇总）](#6-高频坑总榜九篇汇总)
- [7. 项目收尾：清死代码、写 README、整理提交](#7-项目收尾清死代码写-readme整理提交)
- [8. 调试工具箱总览](#8-调试工具箱总览)
- [9. 下一步往哪走](#9-下一步往哪走)
- [10. 笔记索引与产出物总表](#10-笔记索引与产出物总表)
- [11. 今日自检（收尾清单）](#11-今日自检收尾清单)

## 1. 复盘怎么做才有用

### 1.1 复盘 ≠ 再看一遍笔记

重看笔记会给你「我好像都会了」的错觉，但一上手就卡。真正有效的复盘只有三件事：

1. **自测**：找出「其实不会」的地方（而不是「看过」的地方）；
2. **补最小 demo**：每个漏洞写一个 20 行以内的小例子跑通，跑通即算补上；
3. **归档**：把已经会的东西写成清单 / 文档，让它变成可查的资产，而不是记忆。

### 1.2 一张复盘表（把感觉变成证据）

对着第 4 节的 13 条自检，逐条填这张表：

| 知识点 | 状态 | 证据（我能跑出什么） | 补漏动作 |
| --- | --- | --- | --- |
| 例：`setState` 为什么能刷新界面 | ⚠️ 半懂 | 能改数字，但说不清 Element 重建过程 | 写 20 行计数器 + 打印 build 次数 |
| 例：`ListView.builder` | ✅ 会 | 能渲染 1000 条列表并滚动流畅 | 无 |
| 例：Dio 拦截器 | ❌ 不会 | 只抄过代码，没自己加过 header | 写一个拦截器给每个请求加时间戳 |

三种状态的含义要抠清楚：

| 状态 | 判断标准 | 处理 |
| --- | --- | --- |
| ✅ 会 | **能不看笔记写出来**，还能给别人讲明白 | 归档进「已掌握」清单 |
| ⚠️ 半懂 | 能看懂、能改，但**从零写会卡** | 这一档最危险，**优先补** |
| ❌ 不会 | 看到就发懵 | 先补前置知识，再补这一条 |

> 关键提醒：**「半懂」比「不会」更危险**。不会你知道要查，半懂会让你在项目里写出「能跑但不对」的代码（比如该用 `ref.watch` 却写了 `ref.read`，表面看没报错，界面就是不刷新）。

### 1.3 补漏的正确姿势：写「最小 demo」

不要重看整篇笔记，而是把问题切到最小：

```
最小 demo 的三条规矩：
① 一个文件（或者一个空项目里的一页）；
② 不超过 30 行；
③ 只验证一个疑问，跑出来就删掉（或留成 snippets）。
```

举例：

| 疑问 | 最小 demo 怎么写 |
| --- | --- |
| `ref.watch` 和 `ref.read` 到底差在哪？ | 两个按钮，一个用 read 一个用 watch，看哪个按钮点了界面会变 |
| `Expanded` 和 `Flexible` 区别？ | 一行里放三个色块，两种写法各跑一次，看谁会被压缩 |
| `Hero` 为什么不飞？ | 两页只放一张 `Image.asset`，tag 故意写不一样 → 不飞；改成一样 → 飞了 |
| Dio 拦截器为什么卡住？ | 故意不写 `handler.next()`，观察请求永远 pending |

### 1.4 今天的时间怎么分（约 6 小时）

| 时段 | 做什么 | 产出 |
| --- | --- | --- |
| 第 1 小时 | 填复盘表 + 走一遍全链路（第 3 节） | 一张「漏洞清单」 |
| 第 2-4 小时 | 按清单写最小 demo 补漏 | 每个漏洞一个跑通的小例子 |
| 第 5 小时 | 项目收尾：清死代码、写 README、整理提交（第 7 节） | 一个干净的项目 |
| 第 6 小时 | 归档：整理笔记索引 + 记录 3 个坑 + 定下一步（第 10 节） | 一份可复查的文档 |

## 2. 十天知识地图：三条主线串起所有内容

### 2.1 依赖关系：后面全靠前面

```
Dart 基础（空安全 / 类 / 异步）
        │
        ▼
Widget 与状态（Stateless / Stateful / setState）        ┐
        │                                              │
        ▼                                              │
布局体系（约束向下、尺寸向上）                            │  三条主线
        │                                              │  贯穿全部
        ▼                                              │
列表与表单（builder / Form 校验）                        │
        │                                              │
        ▼                                              │
路由与状态管理（Navigator / Riverpod）                   │
        │                                              │
        ▼                                              │
网络与存储（dio / prefs / sqflite）                     │
        │                                              │
        ▼                                              │
主题与动画（ThemeData / 隐式与显式动画 / Hero）           │
        │                                              │
        ▼                                              ┘
工程化与打包（分层 / 多环境 / release 签名）
```

> 这张图有个实际用法：**卡住的时候往上找**。比如「列表滚不动」可能是布局约束的问题；「请求回来界面不更新」可能是状态管理的问题；「编译过不去的空安全」是 Dart 基础的问题。

### 2.2 三条主线（每篇都在重复它）

| 主线 | 一句话 | 怎么自查 |
| --- | --- | --- |
| 一切皆 Widget | UI 是一棵 Widget 树，不是 DOM，没有 CSS | 看到任何界面，能说出它大概由哪几层 Widget 组成 |
| UI = f(state) | 界面是状态的函数；改状态必须触发重建 | 界面不更新时，先问「状态变了吗？谁负责重建？」 |
| 约束向下、尺寸向上 | 父给约束、子报尺寸；布局问题是约束问题 | 布局诡异时，先问「这个 Widget 收到的约束是什么？」 |

### 2.3 六张能力地图

**① 组件与状态（Day 1）**

| 概念 | 一句话 |
| --- | --- |
| `StatelessWidget` | 没有内部状态，界面全靠入参；`build` 应该是纯函数 |
| `StatefulWidget` | 需要自己维护会变的数据；`State` 在重建之间保留 |
| `setState` | 标记「状态脏了」→ 框架重新调用 `build` |
| 生命周期 | `initState` 建、`dispose` 拆，别在 `build` 里搞副作用 |
| `const` Widget | 不随重建而变化的部分加 `const`，减少重建与内存开销 |

**② 布局（Day 2）**

| 概念 | 一句话 |
| --- | --- |
| 约束模型 | 父传约束、子报尺寸，父再定位子 |
| `Row` / `Column` | 主轴 + 交叉轴；用 `MainAxisAlignment` / `CrossAxisAlignment` 调对齐 |
| `Expanded` / `Flexible` | 剩余空间分配；`Flexible` 可以不撑满，`Expanded` 一定占满 |
| `Stack` / `Positioned` | 对应 CSS 的绝对定位与叠放 |
| `Container` / `SizedBox` / `Padding` | `Container` 是「多功能工具箱」，只想要空白就用 `SizedBox` |
| 溢出 | 文字省略、`Expanded` 包一层、或换成可滚动布局 |

**③ 列表与表单（Day 3）**

| 概念 | 一句话 |
| --- | --- |
| `ListView.builder` | 只构建可见项，长列表必须用它 |
| `RefreshIndicator` | 下拉刷新：`onRefresh` 返回的 `Future` 决定转圈何时收起 |
| `Form` + `TextFormField` | `validator` 负责校验，`GlobalKey<FormState>` 负责触发 `validate()` |
| 控制器 | `TextEditingController` 读写输入内容，用完要 `dispose` |

**④ 导航与状态管理（Day 4、Day 5）**

| 概念 | 一句话 |
| --- | --- |
| `Navigator.push` | 压入新页面；`pop` 返回时能带回结果 |
| 传参与回传 | 构造参数传进去，`pop(result)` 传回来，`await push` 接住 |
| 底部 Tab | `IndexedStack` 保状态，`NavigationBar` 管切换 |
| `setState` 的边界 | 只适合单个页面内部的状态 |
| Riverpod | 跨页共享 + 可测试：`NotifierProvider` 存状态，`ref.watch` 订阅，`ref.read` 触发动作 |

**⑤ 数据层（Day 6、Day 7）**

| 概念 | 一句话 |
| --- | --- |
| 模型类 | 「JSON ↔ Dart 对象」的类型防火墙，入口处一次性转换 |
| Dio 拦截器 | 请求/响应/错误的统一处理点，**别忘了 `handler.next()`** |
| 三态 UI | 加载中 / 成功 /（失败 + 空）——每种都要有画面 |
| `shared_preferences` | 轻量键值：**读同步、写异步** |
| `sqflite` | 结构化数据：建表 + 版本迁移 + 增删改查 |
| 登录态 | 内存态（可订阅）+ 磁盘态（重启还在），两边由一个 Notifier 维护 |

**⑥ 体验与交付（Day 8、Day 9）**

| 概念 | 一句话 |
| --- | --- |
| `ThemeData` + `ColorScheme` | 一处定义、全站生效；颜色不写死 |
| 深色模式 | `theme` / `darkTheme` / `themeMode` 三件套，用户选择要持久化 |
| 隐式动画 | 属性从 A 到 B，框架自动补间 |
| 显式动画 | 需要控制播放、一值驱动多处时才用 `AnimationController` |
| `Hero` | 两页同名 tag 的共享元素转场 |
| 分级目录 | `core` / `models` / `services` / `state` / `pages` / `widgets`，依赖单向 |
| 多环境 | `--dart-define-from-file` 编译期注入，代码里只读 `Env` |
| release 打包 | 签名 → `flutter build apk/appbundle` → 装机回归 |

## 3. 全链路走查：从启动到退出

复盘的第一步不是看笔记，而是**用用户的眼睛把这个 App 完整走一遍**，边看边记「哪里别扭、哪里不对」。下面这张表就是走查清单——每一步都写清了该看到什么、出问题先去翻哪一篇。

| # | 步骤 | 该看到什么 | 出问题先查 |
| --- | --- | --- | --- |
| 1 | 冷启动 | 启动图（不是白屏）→ 首屏；已登录直接进首页，未登录进登录页 | Day 7（启动预加载、登录态判断）、Day 9（启动图） |
| 2 | 登录 | 输入为空/格式错时有校验提示；密码错误有友好文案；成功后自动进首页 | Day 3（Form 校验）、Day 6（错误翻译）、Day 7（Token 落盘） |
| 3 | 商品列表 | 先转圈再出数据；下拉能刷新；图片加载失败有兜底图标 | Day 6（三态 UI） |
| 4 | 长列表滚动 | 滚动流畅、不卡顿、不一次性卡住 | Day 3（`ListView.builder` 惰性构建） |
| 5 | 进入详情 | 图片有 Hero 飞行；标题/价格正确；返回后列表位置还在 | Day 4（路由传参）、Day 8（Hero） |
| 6 | 加入购物车 | 底部角标数字带一点动画变化；详情页数量同步变化 | Day 5（跨页共享状态）、Day 8（`AnimatedSwitcher`） |
| 7 | 购物车 / 结算 | 数量、合计金额与详情页一致；加减数量正确；删除后归零 | Day 5（派生状态）、Day 6（模型计算） |
| 8 | 退出登录 | 回到登录页；**杀进程重开仍是登录页**（磁盘已清干净） | Day 7（内存态 + 磁盘态同步清） |
| 9 | 杀进程重开（登录状态） | 直接进首页，不用重新登录 | Day 7（持久化） |
| 10 | 断网 / 弱网 | 有「连不上服务器/超时」这类人话提示 + 重试按钮，不是红屏 | Day 6（`friendlyMessage` + 重试） |
| 11 | 切换主题 | 浅色/深色/跟随系统都能立刻生效，且没有「白底白字」的地方 | Day 8（主题与深色模式） |
| 12 | 切后台再回来 | 状态不丢、不闪退、不重复请求 | Day 1（生命周期）、Day 6（请求发起时机） |
| 13 | 返回键 / 侧滑返回 | 路由栈正确，不会退到不该出现的页面 | Day 4（`push` / `pushReplacement`） |
| 14 | release 包再走一遍 | 前面 13 条在 release 包上同样成立（这一步才最接近真实用户） | Day 9（打包与装机验证） |

> 走查时的记录方式建议：**截图 + 一句话**。例如「#5 返回后列表跳到顶部了」——这种带现象的记录，比「路由有问题」有用一百倍，直接就能去 Day 4 笔记里找 `PageStorageKey` 相关做法。

## 4. 毕业自检 13 条（附标准答案）

这 13 条就是 [Flutter学习总纲.md](Flutter学习总纲.md) 里 Day 10 要逐项确认的内容。**先自己答，再对答案**；答不上来的，按第 1.3 节写最小 demo 补。

### ① 能解释 `StatelessWidget` 和 `StatefulWidget` 的区别

**标准答案**：`StatelessWidget` 没有可变状态，界面完全由构造参数（和上层的 `InheritedWidget`）决定，`build` 应当是纯函数；`StatefulWidget` 本身仍然不可变，但它的 `State` 对象在重建之间**长期存在**，可以持有会变的数据，并通过 `setState` 请求重建。选择标准很简单：**这份数据会在这个组件内部变化吗？会 → Stateful；不会 → Stateless**（能外部传进来的就外部传，优先 Stateless）。

**证明你会了**：写一个「收藏按钮」，用 `StatefulWidget` 做内部状态；再写一个「收藏数展示」，用 `StatelessWidget` 接收数字。

### ② 能解释 `setState` 为什么能刷新界面

**标准答案**：`setState` 做两件事——把你传进去的闭包执行完（改数据），然后把当前 `State` 标记为「需要重建」（`markNeedsBuild`）。框架在下一帧把该 Element 加入重建队列，重新调用 `build`，产出新的 Widget 描述，再把差异更新到渲染树。**所以「改了变量界面不变」的原因永远是：改的是普通变量，没有触发重建**（比如把数据存进了 `State` 之外的变量，或者在 `await` 之后没判断 `mounted` 就改状态）。

**证明你会了**：写一个计数器，在 `build` 里 `debugPrint('build')`；点按钮时先故意用「不 setState」的写法（界面不变、日志不打印），再改成 `setState`（两者都动）。

### ③ 能解释约束向下、尺寸向上

**标准答案**：布局是「父 → 子」传约束（最小/最大宽高），「子 → 父」报尺寸，父再决定子的位置。所以**一个 Widget 的大小不是自己说了算**，而是「想要多大」和「父给多少」共同的结果；`Container` 之所以「有时撑满、有时收缩」，就是因为它的行为取决于父给的约束是否紧（`BoxConstraints.tight`）。

**证明你会了**：把一个 `Container` 分别放进 `Center`、`Row`、`Column`、`SizedBox`，观察它什么时候撑满、什么时候缩小到内容大小。

### ④ 能处理 `Row` / `Column` 溢出

**标准答案**：溢出（黄黑条纹 + `RenderFlex overflowed by X pixels`）说明子项总宽/高超过了可用空间。处理手段按场景选：**① 让某一项可伸缩**（`Expanded` / `Flexible` 包住文本或图片）；**② 让文本自己省略**（`maxLines: 1` + `overflow: TextOverflow.ellipsis`）；**③ 换布局**（`Wrap` 自动换行）；**④ 让它能滚**（`ListView` / `SingleChildScrollView`）；**⑤ 缩短内容**（图标改小、字号改小）。

**证明你会了**：`Row(children: [Icon(), Text('很长很长……')])` 故意溢出，然后用 `Expanded` + 省略号修好。

### ⑤ 能用 `ListView.builder` 渲染长列表

**标准答案**：`ListView(children: [...])` 会一次性构建所有子项；`ListView.builder` 只在需要显示时才调用 `itemBuilder`（惰性构建），滚出屏幕的项会被回收，所以长列表必须用 `builder`。配合的常用件：`itemCount`、`separatorBuilder`（`ListView.separated`）、上拉加载（滚动监听 / `NotificationListener`）、下拉刷新（`RefreshIndicator`）。

**证明你会了**：渲染 1000 条数据，在 `itemBuilder` 里打印 index，滚动时只看到可见范围附近的打印。

### ⑥ 能用 `Form` 做输入校验

**标准答案**：`Form` + `GlobalKey<FormState>`，里面放 `TextFormField`，每个字段写 `validator`（返回 `null` 表示通过，返回字符串作为错误提示）。提交时 `if (_formKey.currentState!.validate())` 才继续；错误提示由框架渲染在输入框下方。别忘记 `TextEditingController` 要在 `dispose` 里释放。

**证明你会了**：写一个邮箱 + 密码的登录表单，邮箱格式错、密码太短时分别给出不同提示，并且「提交」时能打印出通过校验的数据。

### ⑦ 能完成路由跳转、传参、结果回传

**标准答案**：`Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(id: id)))` 完成跳转并把参数通过构造函数传进去；返回值用 `pop(result)` 传出、用 `await Navigator.push<ResultType>(...)` 接住（注意判空和 `context.mounted`）。`pushReplacement` 是「替换当前页」（登录成功进首页就别让用户再退回登录页）。

**证明你会了**：列表点进详情，详情里选一个数量，`pop` 回列表后把数量显示出来。

### ⑧ 能用 Riverpod 共享全局状态

**标准答案**：把跨页面共享的数据放进 `NotifierProvider`（如购物车），组件用 `ConsumerWidget` / `ConsumerStatefulWidget` 的 `ref.watch(provider)` 订阅，用 `ref.read(provider.notifier).method()` 触发动作。派生数据用 `Provider` 计算（如总件数），避免在多个页面各算一遍。判断标准：**只在一个页面内部用的状态，`setState` 就够了**；跨页面 / 需要被多处订阅的，才上全局状态。

**证明你会了**：详情页「加入购物车」，底部 Tab 角标和购物车页同时更新。

### ⑨ 能用 `dio` 封装请求、拦截器、错误处理

**标准答案**：`Dio(BaseOptions(baseUrl: ..., connectTimeout: ..., receiveTimeout: ...))` 集中配置；拦截器分三个回调 `onRequest`（统一加 Token/日志）、`onResponse`、`onError`（统一处理 401/文案翻译），**每个回调都要调用 `handler.next(...)` 放行**，否则请求永远挂起。错误先用 `DioExceptionType` 分类（超时/连接失败/`badResponse`/取消），再翻译成用户能懂的一句话。

**证明你会了**：把 baseUrl 改成一个不存在的域名，界面显示「连不上服务器，请检查网络」+ 重试按钮。

### ⑩ 能用 `shared_preferences` 持久化 Token

**标准答案**：`shared_preferences` 是「内存缓存 + 磁盘文件」：**读是同步的**（`prefs.getString`），**写是异步的**（`await prefs.setString`）。所以启动时先在 `main` 里 `await SharedPreferences.getInstance()` 并注入全 App，之后拦截器和页面都能同步读到 Token；登录成功写入、启动读取、退出登录清除，写的时候一定要 `await`（否则进程被杀就丢了）。敏感场景（长期有效 Token）改用 `flutter_secure_storage`。

**证明你会了**：登录后杀进程重开，仍然在首页；退出登录后杀进程重开，回到登录页。

### ⑪ 能配置主题与暗黑模式

**标准答案**：`MaterialApp(theme: 亮色, darkTheme: 暗色, themeMode: 用户选择)` 三件套；两套主题都用 `ColorScheme.fromSeed(brightness:)` 生成，颜色一律从 `colorScheme` 取（不写死 hex），组件样式集中在 `AppTheme` 里配（`AppBarThemeData`、`CardThemeData`、`FilledButtonThemeData` 等）。用户选择存进 prefs，重启后恢复。

**证明你会了**：切到深色模式逐页翻一遍，没有「白底白字」，卡片层次依然清楚。

### ⑫ 能加入 `Hero` / 隐式动画

**标准答案**：`Hero` 用于两个页面之间的共享元素转场——两页都要有 `Hero`、`tag` 相同且页内唯一、通过 `push/pop` 触发。隐式动画用于「同一属性从 A 到 B」的过渡：`AnimatedContainer`、`AnimatedOpacity`、`AnimatedSwitcher`（**换孩子时必须给不同的 key**）、`TweenAnimationBuilder`。需要控制播放（暂停/反向/循环）或一个动画值驱动多处时，才用 `AnimationController`（记着 `dispose`）。

**证明你会了**：列表图 → 详情图有飞行效果；加购数字变化有缩放淡入，而不是硬跳。

### ⑬ 能跑通 `flutter build apk --release`

**标准答案**：先 `flutter doctor -v` 确认工具链，再生成 keystore、写 `android/key.properties`、在 `android/app/build.gradle.kts` 里配 release 签名，然后：

```bash
flutter clean
flutter pub get
flutter analyze
flutter build apk --release --dart-define-from-file=config/prod.json
```

产物在 `build/app/outputs/flutter-apk/app-release.apk`，装机后走完整链路验证；上架用 `flutter build appbundle`。密钥文件必须备份——丢了就再也发不出「同一个 App」的更新。

**证明你会了**：把 release 包装到真机，不看日志也能把「登录 → 列表 → 详情 → 加购 → 退出」走通。

## 5. 快问快答 12 题

这一节是「合上笔记能不能答上」的自测。先遮住答案自己说一遍。

**① `final` 和 `const` 有什么区别？Widget 什么时候该加 `const`？**
`const` 是编译期常量（值必须能在编译时算出来），`final` 是「只能赋值一次的运行期变量」；`const` 隐含 `final`。Widget 加 `const` 的条件是：**构造参数全是编译期常量**（没有运行时的值）。加了 `const` 之后，同一处在重建时可以直接复用同一个实例，少一次构建开销，所以 `SizedBox(height: 8)`、`Text('标题')` 这类应该顺手加上。

**② `String?` 和 `String` 差在哪？`!` 和 `?.` 分别是什么意思？**
`String?` 表示「可能是 null」，用之前必须处理；`String` 保证不为 null。`x!` 是「我确定它不是 null，否则运行时崩」；`x?.length` 是「是 null 就整体返回 null」。原则：**能用 `??` / 判空解决的，就别用 `!`**——`!` 是把风险留到运行时。

**③ `Future` 和 `async/await` 是什么关系？**
`Future` 是「将来的一个值」（异步结果的容器），`async/await` 只是**把 `then/catchError` 写成同步样子的语法糖**：`await` 在等 `Future` 完成，异常用 `try/catch` 接。异步函数本身仍然返回 `Future`。

**④ `ref.watch` 和 `ref.read` 什么时候用哪个？**
`ref.watch` 用在 `build` 里**订阅**状态（状态变了会重建）；`ref.read` 用在事件回调里**取一次**（点击、提交）。最常见的 bug 就是该订阅的地方写了 `read`——于是状态变了界面不刷新，还不报错。

**⑤ `setState` 之后 `await` 再用 `context`，为什么要判 `mounted`？**
因为 `await` 期间用户可能已经离开这个页面，Widget 被销毁了，这时再 `Navigator.of(context)` 或弹 SnackBar 会报错。规则很简单：**任何 `await` 之后用到 `context`，先 `if (!mounted) return;`**（`StatefulWidget` 用 `mounted`，其他地方用 `context.mounted`）。

**⑥ `ListView.builder` 和 `SingleChildScrollView + Column` 怎么选？**
内容「数量固定且很少」→ 后者更简单；**数量多或不确定 → 一律 `ListView.builder`**（惰性构建，只渲染可见项）。用 `Column` 硬堆几百条，内存和渲染都会崩。

**⑦ `TextEditingController` 什么时候必须 `dispose`？**
在 `State.dispose()` 里。控制器、`AnimationController`、`ScrollController`、`FocusNode` 这类都持有资源，不释放会报泄漏（热重载时尤其明显）。口诀：**`initState` 建的，`dispose` 都要拆**。

**⑧ 接口返回 401 时应该做什么？**
清掉本地登录态（内存 + 磁盘）、把用户送回登录页，并给一句「登录已过期，请重新登录」。这一步通常放在 Dio 的 `onError` 拦截器里统一做——但要注意拦截器里没有 `context`，跳转要靠全局 `navigatorKey`。

**⑨ `shared_preferences` 和 `sqflite` 怎么选？**
问三件事：数据量大不大、要不要查询排序分页、敏不敏感。少量键值（Token、主题、开关）→ `prefs`；要按条件查询/排序/分页/跨表（浏览记录、离线列表、订单）→ `sqflite`；敏感信息 → `flutter_secure_storage`；二进制文件 → 文件系统。

**⑩ 加了 `AnimatedSwitcher` 却没动画，最可能是什么原因？**
`child` 的 **key 没变**。`AnimatedSwitcher` 靠「key 或类型不同」判断孩子换了；用 `ValueKey(会变的值)` 才行，永远不要用 `UniqueKey()`。

**⑪ `Hero` 明明是同一张图却报错 / 不飞，最常见的原因？**
报 `multiple heroes that share the same tag` → 同屏出现了重复 tag（底部 Tab 里多个列表最容易踩），把 tag 加上页面前缀或用 `HeroMode(enabled: false)`；完全不飞 → 两个页面的 tag 不一致，或者只有一边写了 `Hero`。

**⑫ debug 一切正常，release 包网络全挂，先怀疑什么？**
`android/app/src/main/AndroidManifest.xml` 少了 `<uses-permission android:name="android.permission.INTERNET"/>`（debug 清单默认带，release 不带）。其次怀疑 `baseUrl` 指向了错误环境、或用了明文 HTTP 被系统拦。

## 6. 高频坑总榜（九篇汇总）

按「踩到的概率」排序，前五名几乎人人都会遇到一次：

| 排名 | 坑 | 症状 | 修法 | 出处 |
| --- | --- | --- | --- | --- |
| 1 | 改了变量界面不刷新 | 数据变了，UI 没动 | 用 `setState` 或状态管理，触发重建 | Day 1 |
| 2 | 该订阅的地方写了 `ref.read` | 状态变了界面不动，且不报错 | `build` 里用 `ref.watch`，回调里用 `ref.read` | Day 5 |
| 3 | 拦截器忘了 `handler.next()` | 请求永远 pending，没有结果 | 三个回调都记得放行 | Day 6 |
| 4 | `Row` / `Column` 溢出 | 黄黑条纹 + `overflowed by X pixels` | `Expanded` / 省略号 / 换 `Wrap` / 可滚动 | Day 2 |
| 5 | release 缺 `INTERNET` 权限 | debug 正常、release 全网络失败 | 在 main 清单里补权限 | Day 6、Day 9 |
| 6 | `FutureBuilder` 的 future 写在 `build` 里 | 每次重建都重新请求 | 存进 `State` 字段，或用 `FutureProvider` | Day 6 |
| 7 | `AnimatedSwitcher` 没给 key | 数字变化没有动画 | `key: ValueKey(值)` | Day 8 |
| 8 | 长列表用 `ListView(children: [...])` | 列表一长就卡、内存飙升 | 换成 `ListView.builder` | Day 3 |
| 9 | 控制器忘了 `dispose` | 资源泄漏告警、动画乱跑 | `initState` 建的都在 `dispose` 拆 | Day 3、Day 8 |
| 10 | 页面里写死颜色 | 深色模式白底白字 | 颜色全部从 `colorScheme` 取 | Day 8 |
| 11 | 组件主题用了旧类名 | 编译报错（`CardTheme` 不是数据类） | 改成 `CardThemeData` / `AppBarThemeData` | Day 8 |
| 12 | Hero tag 重复 | 运行时报 multiple heroes 异常 | tag 加页面前缀、用 `id` | Day 8 |
| 13 | 改表结构没写迁移 | 升级安装后 `no such column` 崩溃 | `version` +1 并在 `onUpgrade` 补迁移 | Day 7 |
| 14 | `key.properties` 路径写反斜杠 | 报找不到 keystore | 路径用正斜杠 | Day 9 |

> 建议把你自己**真实踩过的 3 个坑**单独写下来（第 11 节的收尾清单里有这一项）——亲手踩过的坑记一辈子，别人总结的坑看三遍还是会踩。

## 7. 项目收尾：清死代码、写 README、整理提交

### 7.1 清死代码（30 分钟就能做完）

| 动作 | 怎么查 |
| --- | --- |
| 删掉没用到的 import / 变量 / 私有方法 | `flutter analyze` 会提示 |
| 删掉没用到的页面、Widget、模型 | 全局搜类名（VS Code 里右键 → Find All References） |
| 删掉没用到的 assets | 搜文件名，没有引用就删，并从 `pubspec.yaml` 移除声明 |
| 删掉调试残留 | 搜 `print(`、`debugPrint(`、`TODO`、`// 测试用` |
| 删掉注释掉的大段代码 | 版本库就是你的备份，别用注释保存历史 |
| 统一命名 | 文件 `snake_case`、类 `UpperCamelCase`，页面以 `_page.dart` 结尾 |
| 检查依赖是否都用得上 | `flutter pub deps --style=compact` + 逐个确认 |

### 7.2 写一份 README（模板可直接抄）

README 是「三个月后的你」和「面试官」看到的第一份东西。放在项目根目录：

```markdown
# 商城 Demo（Flutter 练习项目）

一个用来练手的极简商城 App：商品列表 → 详情 → 加购 → 结算，含登录态持久化。
技术栈：Flutter 3.47 / Riverpod / Dio / shared_preferences / sqflite。

## 功能
- 登录（DummyJSON 测试账号 emilys / emilyspass），登录态本地持久化
- 商品列表（下拉刷新、三态 UI）、详情页（Hero 转场）
- 购物车（跨页共享状态、角标动画）
- 最近浏览（本地数据库）
- 主题切换（浅色 / 深色 / 跟随系统）

## 目录结构
lib/
├── core/      # env / logger / network / storage
├── models/    # 数据模型
├── services/  # 接口封装
├── state/     # Riverpod 全局状态
├── pages/     # 页面
└── widgets/   # 通用组件

## 运行
flutter pub get
flutter run --dart-define-from-file=config/dev.json

## 打包
flutter build apk --release --dart-define-from-file=config/prod.json

## 已知问题
- 结算页只有占位实现
- 搜索功能未做防抖
```

### 7.3 检查 `.gitignore`

确认这些**没有**被提交（Flutter 模板默认已经处理好大部分）：

```
build/
.dart_tool/
.flutter-plugins*
.idea/
*.iml
android/key.properties      # 签名密码，绝对不能提交
**/*.jks
**/*.keystore
android/local.properties
```

自己再确认一次：

```bash
git status --short          # 看看有没有意外的新文件
git check-ignore -v android/key.properties   # 有输出说明已被忽略
```

### 7.4 提交习惯：一次只做一件事

| 类型 | 消息格式 | 例子 |
| --- | --- | --- |
| 新功能 | `feat: ...` | `feat: 商品详情页加入 Hero 转场` |
| 修 bug | `fix: ...` | `fix: 修复深色模式下购物车角标看不清` |
| 重构 | `refactor: ...` | `refactor: 抽出 core/network/dio_client` |
| 文档 | `docs: ...` | `docs: 补 README 与打包说明` |
| 杂事 | `chore: ...` | `chore: 升级 riverpod 到 3.x` |

**提交前的 30 秒清单**：`flutter analyze` 无报错 → 关键页面手动点一遍 → 提交消息写清「做了什么」。

### 7.5 留一份作品集素材（顺手就能做）

趁项目还是新鲜的，花 10 分钟做三件事：

1. 录一段 30 秒的**操作视频**（登录 → 列表 → 详情 → 加购 → 切深色）；
2. 截 3-5 张关键页面图（列表、详情、购物车、深色模式）；
3. 给当前版本打个 tag：`git tag v0.1.0-study`。

这些东西面试、写简历、发朋友圈都用得上，而且**过期就懒得补了**。

## 8. 调试工具箱总览

### 8.1 报错怎么读（五步法）

Flutter 的红屏信息量很大，但**读法有固定套路**：

1. **先读最后一行**：`RenderFlex overflowed by 32 pixels`、`Null check operator used on a null value` 这类结论通常在尾部；
2. **找关键句**：`The following assertion was thrown...` 后面往往直接指出是哪个 Widget、哪一行；
3. **看 `Consider` / `Expected` 建议**：框架经常把修法写出来了（比如「wrap it in a Expanded」）；
4. **在堆栈里找自己的文件**：跳过 `package:flutter/...`，找 `lib/` 里第一处；
5. **最小化复现**：把相关代码拷到一个空页面里，删到只剩触发问题的那几行。

### 8.2 常见红屏速查

| 报错 | 意思 | 怎么办 |
| --- | --- | --- |
| `RenderFlex overflowed by X pixels` | Row/Column 空间不够 | `Expanded` / 省略号 / 换 `Wrap` / 可滚动（Day 2） |
| `Vertical viewport was given unbounded height` | 可滚动组件被放在没有高度约束的地方（比如 `Column` 里直接放 `ListView`） | 用 `Expanded` 包住，或给它固定高度 |
| `Incorrect use of ParentDataWidget` | `Expanded` / `Positioned` 放错了父级 | `Expanded` 必须在 `Row`/`Column`/`Flex` 里 |
| `setState() or markNeedsBuild() called during build` | 在 `build` 里改了状态 | 挪到事件回调，或 `WidgetsBinding.instance.addPostFrameCallback` |
| `Null check operator used on a null value` | 用了 `!` 但值确实为 null | 检查数据来源，改成判空 / `??` 兜底 |
| `LateInitializationError` | `late` 变量还没赋值就被用 | 在 `initState` 里先赋值 |
| `No Material widget found` | 用了 Material 组件但上层没有 `Material` | 外层加 `Scaffold` / `Material` |
| `Unable to load asset` | 资源没在 `pubspec.yaml` 声明，或路径写错 | 检查 `assets:` 与路径大小写（Day 9） |

### 8.3 工具清单

| 工具 | 什么时候用 |
| --- | --- |
| `flutter analyze` | 改完代码先跑它（默认连 info 级问题都算失败，可用 `--no-fatal-infos` 放宽） |
| 热重载 `r` / 热重启 `R` | 改 UI 用 `r`；改了 `main`、状态初始化、插件用 `R` |
| DevTools 的 **Widget Inspector** | 布局不对时首选：能看到每个 Widget 的约束、尺寸、层级 |
| DevTools 的 **Performance** | 掉帧、卡顿时看帧耗时；`MaterialApp(showPerformanceOverlay: true)` 能直接在界面上显示帧率条 |
| DevTools 的 **Network** | 看请求耗时、状态码（比翻日志直观） |
| 断点调试 | 逻辑绕不清时，断点比日志强十倍（VS Code 里点行号左侧） |
| `flutter run --release` | 只在 release 出现的问题（白屏、网络失败） |
| `git bisect` | 突然「昨天还好好的」，用二分查找定位到具体提交 |
| 二分注释法 | 不知道哪段代码出问题时，注释掉一半再跑 |

### 8.4 提问 / 搜索的正确姿势

无论问同事、问社区还是问 AI，**带上这四样**，得到有效回答的概率会翻倍：

1. Flutter 版本（`flutter --version`）；
2. 你想做什么（预期）；
3. 实际发生了什么（现象 + 完整报错，不要只截图一小块）；
4. 你试过什么（改过哪些地方、结果如何）。

截图时尽量给**完整报错文本**（DevTools 控制台可以复制），因为报错里的 Widget 名字和行号才是定位线索。

## 9. 下一步往哪走

十天冲刺到此结束。现在你手上有一个能跑的 App、十篇笔记和一套自检方法。接下来有三条路，**选一条，别同时开三条**：

| 路线 | 适合谁 | 做什么 | 产出物 | 投入 |
| --- | --- | --- | --- | --- |
| **A. 复刻旧项目**（最推荐） | 想快速把 Flutter 变成「能用于工作」的人 | 挑一个你以前用 uniapp 写过的页面/功能，用 Flutter 重写 | 一个能跑的完整功能模块 | 1-2 周 |
| B. 深挖状态管理与架构 | 想往中高级走、对代码组织有要求的人 | Riverpod 进阶（`AsyncNotifier` / 代码生成）、分层架构、依赖注入、测试 | 一次架构重构 + 单元测试 | 2-3 周 |
| C. 打磨与上架 | 想真正发布一个 App 的人 | 崩溃监控、埋点、隐私合规、商店素材、灰度发布 | 一个上架的 App | 2-4 周 |

### 4 周进阶表（按路线 A 举例）

| 周 | 主题 | 产出物 |
| --- | --- | --- |
| 第 1 周 | 把旧项目的「列表 + 详情」用 Flutter 重写 | 两个页面 + 接口对接 |
| 第 2 周 | 补齐表单、校验、登录态、路由 | 可登录的完整流程 |
| 第 3 周 | 状态管理整理 + 主题统一 + 交互打磨 | 视觉与代码都干净的一版 |
| 第 4 周 | 打包、真机测试、录屏归档 | 可安装的 release 包 + 演示素材 |

### 顺便值得补的四块（不急，但早晚要用）

| 方向 | 为什么值得学 | 入门动作 |
| --- | --- | --- |
| 测试 | 改代码不怕回归，是「敢重构」的前提 | 写一个 widget test：点按钮 → 断言文字变了（`flutter test`） |
| 性能 | 列表/图片/动画是 Flutter 的强项，用不好就白搭 | 用 DevTools Performance 看一帧；给网络图加 `cacheWidth` |
| 代码生成 | 少写一堆样板代码 | 试 `json_serializable` 或 `riverpod_generator` |
| CI | 让「检查 + 打包」自动化 | GitHub Actions 跑 `flutter analyze` + `flutter test` + `flutter build apk` |

### 三个「不要」

1. **不要在还写不清 `setState` 的时候上「完整 Clean Architecture」**——先能跑，再谈架构；
2. **不要同时学 Flutter 和原生开发**（Kotlin/Swift），先把一侧打通；
3. **不要为了追新而换技术栈**（今天 Riverpod、明天换 BLoC），一个方案用到熟，比浅尝五个强。

## 10. 笔记索引与产出物总表

### Flutter 部分（本次冲刺的 10 篇）

| 编号 | 文件 | 主题 | 关键产出物 |
| --- | --- | --- | --- |
| 01 | Flutter学习笔记-01-Widget与布局.md | 项目结构、Widget、`setState` | 可点击计数器 |
| 02 | Flutter学习笔记-02-布局体系.md | 约束模型、`Row`/`Column`/`Stack`、`Expanded` | 静态首页布局 |
| 03 | Flutter学习笔记-03-列表与表单.md | `ListView.builder`、刷新加载、`Form` 校验 | 商品列表 + 登录表单 |
| 04 | Flutter学习笔记-04-路由与页面组织.md | `Navigator`、传参回传、底部 Tab | 多页骨架 |
| 05 | Flutter学习笔记-05-状态管理.md | `setState` 局限、Provider 思想、Riverpod | 全局购物车 |
| 06 | Flutter学习笔记-06-网络请求.md | `dio`、拦截器、JSON 转模型、三态 UI | 真实 API 商品列表 |
| 07 | Flutter学习笔记-07-本地存储.md | `shared_preferences`、`sqflite`、Token 持久化 | 登录态保持 + 最近浏览 |
| 08 | Flutter学习笔记-08-主题与动画.md | `ThemeData`、深色模式、隐式/显式动画、`Hero` | 主题切换 + 动效 + 转场 |
| 09 | Flutter学习笔记-09-工程化与打包.md | 分层、多环境、签名、release 打包 | 可安装的 release apk |
| 10 | Flutter学习笔记-10-复盘与补漏.md | 知识地图、走查、自检、收尾 | **本文：一张能力网 + 干净的项目** |

### Dart 部分（前置基础，6 篇）

| 编号 | 文件 | 主题 |
| --- | --- | --- |
| Dart 01 | Dart学习笔记-01-数据类型与内置方法.md | 类型、集合、空安全、Record、Enum |
| Dart 02 | Dart学习笔记-02-运算符与表达式.md | 运算符与表达式 |
| Dart 03 | Dart学习笔记-03-控制流与函数.md | 分支、循环、闭包、高阶函数 |
| Dart 04 | Dart学习笔记-04-类与对象.md | 类、继承、mixin、泛型、扩展方法 |
| Dart 05 | Dart学习笔记-05-异步编程.md | `Future`、`async/await`、`Stream` |
| Dart 06 | Dart学习笔记-06-错误与异常.md | `Error` / `Exception`、自定义异常 |

### 一页纸「我学到的核心概念」

把这 12 条抄进自己的话，就是这十天最值钱的产出：

1. **一切皆 Widget**：UI 是树，样式是参数，没有 CSS。
2. **UI = f(state)**：界面不更新，先查「状态变了没、谁负责重建」。
3. **约束向下、尺寸向上**：布局问题的第一问永远是「约束是什么」。
4. **布局靠嵌套**：`Row`/`Column` 排版，`Stack` 叠放，`Expanded` 分配剩余空间。
5. **长列表用 `builder`**：惰性构建是 Flutter 的性能底线。
6. **表单靠 `Form` + `validator`**：校验逻辑写在字段上，提交前统一触发。
7. **跨页状态上 Riverpod**：`watch` 订阅、`read` 触发，派生状态单独算。
8. **网络三态是标配**：加载中 / 成功 /（失败 + 空），失败必须能重试。
9. **边界处转模型**：JSON 和数据库行都在入口转成 Dart 对象。
10. **登录态 = 内存 + 磁盘**：读同步、写异步，两边一起改。
11. **主题集中、颜色语义化**：`ColorScheme` 一处定义，深色模式白送。
12. **交付才算完成**：`flutter analyze` 干净 + release 包真机跑通，才算做完。

## 11. 今日自检（收尾清单）

做完下面五件事，十天的冲刺正式结束：

- [ ] 13 条毕业自检逐条过（第 4 节），没过的都写了最小 demo 补上
- [ ] 全链路走查 14 步走完（第 3 节），并且**在 release 包上再走一遍**
- [ ] 项目收尾完成：死代码清干净、README 写好、`.gitignore` 检查过、最后一次提交
- [ ] 写下**你自己真实踩过的 3 个坑**（现象 + 原因 + 修法），贴进这篇笔记末尾
- [ ] 定下下一步路线（A 复刻 / B 架构 / C 上架），并写清第一周要做什么

### 收尾三问（对答案）

**① 现在的你能独立做什么？**
能独立搭一个多页面 App：布局、列表、表单、路由、状态管理、网络请求、本地持久化、主题与动效、目录分层、多环境配置、release 打包。**这就是「能开发」和「能交付」的分界线**——你已经跨过去了。

**② 还有哪些必须查笔记？**
这份清单里的一切都值得诚实面对：`AnimationController` 的细节、`sqflite` 的迁移写法、Gradle 报错、`go_router`、测试、性能分析。**「需要查笔记」不丢人，「假装会」才丢人**——真实开发中 90% 的 API 也没人背，查得准、用得对才是能力。

**③ 下一步第一周做什么？**
选路线 A 的话：找一个你熟悉的旧页面，**只用 Flutter 重写它**，要求是「接口对上、三态齐全、release 包能装」。一周结束时你会明显感觉到：写 Flutter 的注意力已经从「语法」转移到「业务设计」上了——那才是真正学会的信号。
