### 依赖注入

依赖注入的方式

#### put使用

```dart
/// 使用put进行依赖注入
var controller = Get.put(XxxController());
// demo中我们这么写
final logic = Get.put(DependenceInjectionLogic());

/// getx 接口
class _GetImpl extends GetInterface {}

/// 注释 // ignore: non_constant_identifier_names 是 Dart 分析器的一部分，它告诉分析器忽略接下来的一行中的特定代码规则检查
/// 全局、只读变量 实现单例
/// getX暴露出来给我们使用的接口
final Get = _GetImpl();

/// 拓展
extension Inst on GetInterface {

  S put<S>(S dependency,
      {String? tag,
        bool permanent = false,
        InstanceBuilderCallback<S>? builder}) =>
      GetInstance().put<S>(dependency, tag: tag, permanent: permanent);
}

```

#### put的逻辑

看一下代码，学习一下

点进去 GetInstance().put<S>(dependency, tag: tag, permanent: permanent);

```dart
/// 主要的逻辑看来还是GetInstance中
class GetInstance {
  /// 项目经常使用的单例模式
  factory GetInstance() => _getInstance ??= GetInstance._();

  const GetInstance._();

  static GetInstance? _getInstance;

  /// 全局的数据都是存在 _singl 中，这是一个map类型
  /// key：对象的runtimeType或者类的Type + tag
  /// value：_InstanceBuilderFactory类，我们传入dependency对象会存入这个类中
  /// 如果map中有key和传入key相同的数据，传入的数据将不会被存储
  /// 也就是说相同类实例的对象，传入并不会被覆盖，只会存储第一条数据，后续被放弃
  static final Map<String, _InstanceBuilderFactory> _singl = {};

  /// 在内存中注入一个实例' <s> '以便全局访问。
  /// 不需要定义泛型类型' <s> '，因为它是从[dependency]推断出来的。
  /// - [dependency]要注入的实例。
  /// - [tag]可选，使用[tag]作为“id”来创建多个相同类型的记录<[S]>;
  /// - [permanent]将Instance保存在内存中，而不是跟随Get.smartManagement规则。
  S put<S>(S dependency, {
    String? tag,
    bool permanent = false,
    @deprecated InstanceBuilderCallback<S>? builder,
  }) {
    /// 调用_insert方法 注册实例
    _insert(
        isSingleton: true,
        name: tag,
        permanent: permanent,
        builder: builder ?? (() => dependency));

    /// 使用find方法返回实例
    return find<S>(tag: tag);
  }

  /// 向_signal map中开始存放实例
  void _insert<S>({
    bool? isSingleton,
    String? name,
    bool permanent = false,
    required InstanceBuilderCallback<S> builder,
    bool fenix = false,
  }) {
    final key = _getKey(S, name);

    if (_singl.containsKey(key)) {
      final dep = _singl[key];

      /// 在 GetX 框架中，一个对象标记为 "脏"（dep.isDirty 返回 true）表示在没有观察者监听此对象时，它可以被清除或替换。
      /// 这是一个内存优化策略，让没有用到的对象可以被合适地清理，这样就可以防止内存的浪费并且提升性能。
      /// 为什么要检查 dep.isDirty 并给 _singl[key] 重新赋值？
      /// 如果map _singl 中已有对应的 key，代码会检查对应的值 dep 是否存在，并检查它是否被标记为 "脏" (isDirty 是 true）。
      /// 如果满足这些条件，那么代码会用新的 _InstanceBuilderFactory 替代旧的，这样可以释放旧的 dep 对象所占用的内存，用新的 _InstanceBuilderFactory 对象代替，从而达到内存管理的目的。
      /// 这样的策略就是在一定的程度上最优化了内存的使用，保留必要的对象，且及时清理不再需要的对象。这就是为什么有 dep.isDirty 的判断，并且在该对象 "脏" 的情况下，重新给 _singl[key] 赋值。
      if (dep != null && dep.isDirty) {
        _singl[key] = _InstanceBuilderFactory<S>(
          isSingleton,
          builder,
          permanent,
          false,
          fenix,
          name,
          lateRemove: dep as _InstanceBuilderFactory<S>,
        );
      }
    } else {
      _singl[key] = _InstanceBuilderFactory<S>(
        isSingleton,
        builder,
        permanent,
        false,
        fenix,
        name,
      );
    }
  }

  /// 根据类型(也可以是名称)生成键，以便在map中注册Instance Builder。
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }
}

```

#### find逻辑

- find方法 就是从map中取数据的操作

```dart
// 项目中我们这么用 -> 点进去看方法
final state = Get
    .find<DependenceInjectionLogic>()
    .state;

S find<S>({String? tag}) => GetInstance().find<S>(tag: tag);

class GetInstance {

  factory GetInstance() => _getInstance ??= GetInstance._();

  const GetInstance._();

  static GetInstance? _getInstance;

  static final Map<String, _InstanceBuilderFactory> _singl = {};

  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }

  bool isRegistered<S>({String? tag}) => _singl.containsKey(_getKey(S, tag));

  S find<S>({String? tag}) {
    final key = _getKey(S, tag);

    /// 如果含有该key说明注册过
    if (isRegistered<S>(tag: tag)) {
      /// 再判断 _singl 中是否含有该key的value，有则取，无则抛异常
      if (_singl[key] == null) {
        /// 顺带把tag的情况 一起带着抛
        if (tag == null) {
          throw 'Class "$S" is not registered';
        } else {
          throw 'Class "$S" with tag "$tag" is not registered';
        }
      }
      final i = _initDependencies<S>(name: tag);
      return i ?? _singl[key]!.getDependency() as S;
    } else {
      /// 连key都没有，直接抛出异常
      // ignore: lines_longer_than_80_chars
      throw '"$S" not found. You need to call "Get.put($S())" or "Get.lazyPut(()=>$S())"';
    }
  }
}

S? _initDependencies<S>({String? name}) {
  final key = _getKey(S, name); // 根据 S 和 name 获取键
  final isInit = _singl[key]!.isInit; // 检查当前实例是否已经被初始化
  S? i;
  if (!isInit) { // 如果实例尚未被初始化
    i = _startController<S>(tag: name); // 启动控制器并返回实例
    if (_singl[key]!.isSingleton!) { // 如果实例是单例
      _singl[key]!.isInit = true; // 标记该实例已被初始化
      if (Get.smartManagement != SmartManagement.onlyBuilder) { // 如果 smartManagement 设置为非 onlyBuilder 模式
        RouterReportManager.reportDependencyLinkedToRoute(_getKey(S, name)); // 报告路由与实例的依赖关系
      }
    }
  }
  return i; // 返回实例
}

/// 通过它的 [builderFunc] 获取实际的实例，或者获取持久化的实例。
S getDependency() {
  if (isSingleton!) { // 如果这个实例是单例
    if (dependency == null) { // 如果这个单例还未被初始化
      _showInitLog(); // 显示初始化的日志
      dependency = builderFunc(); // 通过 builderFunc 来构建这个实例
    }
    return dependency!; // 返回这个单例
  } else { // 如果这个实例不是单例
    return builderFunc(); // 直接通过 builderFunc 来构建并返回这个实例
  }
}


```

### 刷新机制

#### GetBuilder

##### 使用场景展示一下

##### GetBuilder 内置回收机制 + 刷新逻辑

代码如下 -> 精简版

```dart
typedef GetControllerBuilder<T extends DisposableInterface> = Widget Function(
    T controller);

/// 继承了GetxController 和 StatefulWidget
class GetBuilder<T extends GetxController> extends StatefulWidget {
  final GetControllerBuilder<T> builder;
  final bool global;
  final Object? id;
  final String? tag;
  final bool autoRemove;
  final bool assignId;
  final Object Function(T value)? filter;
  final void Function(GetBuilderState<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(GetBuilder oldWidget, GetBuilderState<T> state)?
  didUpdateWidget;
  final T? init;

  const GetBuilder({
    Key? key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  }) : super(key: key);

  @override
  GetBuilderState<T> createState() => GetBuilderState<T>();
}

class GetBuilderState<T extends GetxController> extends State<GetBuilder<T>>
    with GetStateUpdaterMixin {
  T? controller;
  bool? _isCreator = false;
  VoidCallback? _remove;
  Object? _filter;

  @override
  void initState() {
    widget.initState?.call(this);

    /// 通过传入 GetBuilder上泛型获取相应GetXController实例
    /// eg : DependenceInjectionLogic? init,
    var isRegistered = GetInstance().isRegistered<T>(tag: widget.tag);

    if (widget.global) {
      if (isRegistered) {
        /// 存在：直接使用 init传入的实例无效
        /// isPrepared 用来 检查特定类型 S 的引用是否已被准备好（即已在内存中注册），且还未被初始化。
        if (GetInstance().isPrepared<T>(tag: widget.tag)) {
          _isCreator = true;
        } else {
          _isCreator = false;
        }
        controller = GetInstance().find<T>(tag: widget.tag);
      } else {
        /// 不存在: 使用init传入的实例
        controller = widget.init;
        _isCreator = true;
        GetInstance().put<T>(controller!, tag: widget.tag);
      }
    } else {
      controller = widget.init;
      _isCreator = true;
      controller?.onStart();
    }

    if (widget.filter != null) {
      _filter = widget.filter!(controller!);
    }


    _subscribeToController();
  }

  /// 确保订阅了 controller 的更新。
  /// 当 _filter 非空时，意味这不是所有的更新都会导致 widget 更新，而是当 _filter 判断为真时才更新。
  /// 当 _filter 为空时，所有的更新都会触发 widget 的更新。
  void _subscribeToController() {
    _remove?.call();
    _remove = (widget.id == null)
        ? controller?.addListener(

      /// 添加监听回调
      /// 标签 <GetBuild核心>
      _filter != null ? _filterUpdate : getUpdate,
    )
        : controller?.addListenerId(

      /// 添加监听回调，必须设置id，update刷新的时候也必须写上配套的id
      widget.id,
      _filter != null ? _filterUpdate : getUpdate,
    );
  }

  /// _filterUpdate 这个方法用于当过滤条件改变时，调用 getUpdate 来进行相应的更新操作
  void _filterUpdate() {
    var newFilter = widget.filter!(controller!);
    if (newFilter != _filter) {
      _filter = newFilter;

      ///getUpdate()逻辑就是 setState()，刷新当前GetBuilder
      getUpdate();
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.dispose?.call(this);

    /// autoRemove可以控制是否自动回收GetXController实例
    if (_isCreator! || widget.assignId) {
      /// 默认为true：默认开启自动回收
      if (widget.autoRemove && GetInstance().isRegistered<T>(tag: widget.tag)) {
        GetInstance().delete<T>(tag: widget.tag);
      }
    }

    _remove?.call();

    controller = null;
    _isCreator = null;
    _remove = null;
    _filter = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.didChangeDependencies?.call(this);
  }

  @override
  void didUpdateWidget(GetBuilder oldWidget) {
    super.didUpdateWidget(oldWidget as GetBuilder<T>);
    // to avoid conflicts when modifying a "grouped" id list.
    if (oldWidget.id != widget.id) {
      _subscribeToController();
    }
    widget.didUpdateWidget?.call(oldWidget, this);
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(controller!);
  }
}

/// 这个混入影响了一个 GetStateUpdater 函数，它可能被 GetBuilder()、SimpleBuilder()（或类似的）用来满足 GetStateUpdate 签名，用以替换 StateSetter。
/// 这避免了控件处于 dispose() 状态时可能（但极其罕见）遇到的问题，并且将 API 从不优雅的 fn((){}) 中抽象出来。
/// 函数签名通常指的是函数的名称，以及输入参数的数量、顺序和类型，还有函数返回值的类型
mixin GetStateUpdaterMixin<T extends StatefulWidget> on State<T> {
  // To avoid the creation of an anonym function to be GC later.
  // ignore: prefer_function_declarations_over_variables

  /// Experimental method to replace setState((){});
  /// Used with GetStateUpdate.
  void getUpdate() {
    if (mounted) setState(() {});
  }
}

```

##### Update

```dart
abstract class GetxController extends DisposableInterface
    with ListenableMixin, ListNotifierMixin {

  /// 每次调用 update() 时都会重建 GetBuilder；
  /// 可以接受一个 id 的列表，只会更新匹配的 GetBuilder(id: )，而这些 id 可以在 GetBuilders 之间重用，像组标签一样。
  /// 只有当条件为真时，更新才会通知这些控件。
  /// condition : 是否刷新一个判断条件，默认为true（假设必须某个id大于3才能刷新：update([1, 2, 3, 4], index > 3) ）
  void update([List<Object>? ids, bool condition = true]) {
    if (!condition) {
      return;
    }
    if (ids == null) {
      refresh();
    } else {
      /// ids：和上面的Getbuilder中设置的id对应起来了，可刷新对应设置id的GetBuilder
      for (final id in ids) {
        refreshGroup(id);
      }
    }
  }
}

```

**refresh()**

```dart

/// GetStateUpdate的方法体是setState，每创建一个GetBuilder，都会在_updaters列表中，增加一个GetStateUpdate实例
typedef GetStateUpdate = void Function();

class ListNotifier implements Listenable {
  /// _updaters中泛型就是一个方法
  /// _updaters 列表用于存储当前添加的所有监听器
  List<GetStateUpdate?>? _updaters = <GetStateUpdate?>[];

  /// id情况下的更新方法
  HashMap<Object?, List<GetStateUpdate>>? _updatersGroupIds = HashMap<Object?, List<GetStateUpdate>>();

  /// 更新所有
  @protected
  void refresh() {
    assert(_debugAssertNotDisposed());

    /// 标签 <GetBuild核心>
    _notifyUpdate();
  }

  void _notifyUpdate() {
    for (var element in _updaters!) {
      /// setState ！！！
      element!();
    }
  }

  void _notifyIdUpdate(Object id) {
    if (_updatersGroupIds!.containsKey(id)) {
      final listGroup = _updatersGroupIds![id]!;
      for (var item in listGroup) {
        item();
      }
    }
  }

  /// 更新对应相应
  @protected
  void refreshGroup(Object id) {
    assert(_debugAssertNotDisposed());
    _notifyIdUpdate(id);
  }

  /// 小插曲: 怎么理解addListener方法
  /// addListener 是一个常用于处理事件或数据更改的函数。
  /// 通常情况下，你会将一个回调函数 作为参数传给 addListener，这个函数会在某个特定的事件发生 (比如数据变化）时被自动调用。
  @override
  Disposer addListener(GetStateUpdate listener) {
    assert(_debugAssertNotDisposed());

    /// 添加监听器到 GetBuilder，监听器是一个包含 setState() 的函数
    _updaters!.add(listener);

    /// 当GetBuilder被更新后，返回的 dispose 函数将被调用，从 _updaters 列表中移除当前添加的监听器
    /// 这样可以防止因重新构建时重复通知监听器而产生的性能问题
    return () => _updaters!.remove(listener);
  }

  Disposer addListenerId(Object? key, GetStateUpdate listener) {
    _updatersGroupIds![key] ??= <GetStateUpdate>[];

    /// 在GetBuilder中添加的监听就是一个方法参数，方法体里面就是 setState()
    _updatersGroupIds![key]!.add(listener);
    return () => _updatersGroupIds![key]!.remove(listener);
  }

/// ... 省略
}
```

##### GetBuilder总结

GetBuilder 的刷新机制主要由以下几个步骤组成：

1. GetBuilder 控件在建立时，会将包含 setState() 方法的监听器添加到其 _updaters 列表中。setState() 是导致控件重新构建的主要方法。
2. 当你通过调用 update() 方法来更新 GetBuilder 时，它会触发所有在 _updaters 列表中的监听器，从而导致所有相关的 GetBuilder
   控件重新构建。
3. 重新构建完成后，GetBuilder 会通过调用返回的 Disposer 函数来从 _updaters 列表中移除相关的监听器。这样做可以防止因重复通知监听器而造成的性能问题。
   简单来说，GetBuilder 的刷新机制基于监听器模式，通过监听器的添加和移除，实现了对特定控件的高效的、有目的性的更新，而非全局刷新。

#### Obx刷新机制

##### 小总结

- 变量上：基础类型，实体以及列表之类的数据类型，作者都封装了一套Rx类型，快捷在数据后加obs
-
    - 例如：RxString msg = "test".obs（var msg = "test".obs）
- 更新上：基础类型直接更新数据就行，实体类需要以 .update() 的形式
- 使用上：使用这类变量，一般要加上 .value

Obx刷新机制，最有趣应该就是变量改变后，包裹该变量的Obx会自动刷新 => 可以得出一个概念，最好obx只管理最小的ui，这样效果是最好的

##### Rx变量

以RxInt为例子

```dart
class RxInt extends Rx<int> {
  RxInt(int initial) : super(initial);

  /// Addition operator.
  RxInt operator +(int other) {
    value = value + other;
    return this;
  }

  /// Subtraction operator.
  RxInt operator -(int other) {
    value = value - other;
    return this;
  }
}

/// .obs 语法糖
extension IntExtension on int {
  /// Returns a `RxInt` with [this] `int` as initial value.
  RxInt get obs => RxInt(this);
}

```

- 看一下Rx父类

```dart

/// 继承自_RxImpl
class Rx<T> extends _RxImpl<T> {
  Rx(T initial) : super(initial);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw '$T has not method [toJson]';
    }
  }
}

```

引出一个非常重要的类 => _RxImpl
**简单来看**

- _RxImpl 类继承了 RxNotifier 并且 with 了 RxObjectMixin
- 这个类挺复杂的，看起来是 RxNotifier 和 RxObjectMixin 内容很多
- 代码很多，先展示下完整代码
-
    - RxNotifier猜名字就是负责通知
-
    - RxObjectMixin猜名字 是Rx类型的父类 -> 猜错了 只是提供代码重用技术

```dart
/// Rx 的基础类，管理所有类型的流逻辑。
/// "流逻辑"是在编程中处理数据流的概念和技术，通常在处理异步数据源时使用，如用户输入、文件、Web API请求等。
/// 流通常被视为可处理的数据元素序列，这些元素随时间推移而产生。流可以被观察（订阅）和操作（如筛选、转化、组合等），这就是所谓的"流逻辑"。
/// 
/// with 是一个关键字，主要用于 mixin 的实现。
/// Mixin 是一种代码重用的技术，允许你在一个类中使用其他类的代码。
/// 这个关键字使得你可以在不使用继承的情况下，将其他类的代码和功能整合到一个类中。
abstract class _RxImpl<T> extends RxNotifier<T> with RxObjectMixin<T> {
  _RxImpl(T initial) {
    /// _values是RxObjectMixin中的成员属性
    _value = initial;
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  /// 这个函数用于将数据流中的每一项都通过一个你提供的函数（mapper）转换成新的形式。
  Stream<R> map<R>(R mapper(T? data)) => stream.map(mapper);

  /// 这个函数接收一个函数作为参数，这个函数会用当前值作为参数调用。然后将当前值传给 subject。
  /// 当 subject 状态变化了，所有的订阅者都会更新。
  void update(void fn(T? val)) {
    fn(_value);

    /// subject是NotifyManager中的成员属性
    subject.add(_value);
  }

  void trigger(T v) {
    var firstRebuild = this.firstRebuild;
    value = v;
    if (!firstRebuild) {
      subject.add(v);
    }
  }
}

class RxNotifier<T> = RxInterface<T> with NotifyManager<T>;


/// 看名字就像一个 通知管理者
mixin NotifyManager<T> {

  /// 声明并初始化了一个类型为 GetStream 的流对象 subject
  GetStream<T> subject = GetStream<T>();

  /// 一个包含流及其订阅的map _subscriptions， key是Stream，value是StreamSubscription列表
  final _subscriptions = <GetStream, List<StreamSubscription>>{};

  /// 订阅该stream的streamSubscription列表不为空 则可以更新
  bool get canUpdate => _subscriptions.isNotEmpty;

  /// 内置callBack 的 GetStream类型
  /// 这个方法接受一个 GetStream<T> 对象作为参数，并检查它是否已在 _subscriptions 中。
  /// 如果不在，它就创建一个订阅到该流的 StreamSubscription，并将其添加到 _subscriptions 中。
  /// 这样，当流发出新的数据时，它就会接收并将其添加到 subject 中。
  /// 
  ///  这是一个内部方法。订阅内部流的变化。
  ///  这个方法的作用是：它监听并订阅内部数据流的变化，每当数据流有变动时，此方法都能接收到这些变化，然后进行相应的处理。
  ///  这在响应式编程中是非常常见的操作，常用于处理异步数据的变更，例如网络请求、用户输入等等。
  void addListener(GetStream<T> rxGetx) {
    if (!_subscriptions.containsKey(rxGetx)) {
      final subs = rxGetx.listen((data) {
        if (!subject.isClosed) subject.add(data);
      });
      final listSubscriptions = _subscriptions[rxGetx] ??= <StreamSubscription>[];
      listSubscriptions.add(subs);
    }
  }

  /// 监听这个事情
  StreamSubscription<T> listen(void Function(T) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      subject.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError ?? false,
      );

  /// 关闭
  void close() {
    _subscriptions.forEach((getStream, _subscriptions) {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
    });

    _subscriptions.clear();
    subject.close();
  }
}

///  on 说明只能在 NotifyManager 这个类或这个类的子类 上用 
mixin RxObjectMixin<T> on NotifyManager<T> {
  late T _value;

  /// 将 value 直接更新并将其添加到数据流中
  void refresh() {
    subject.add(value);
  }

  bool firstRebuild = true;
  bool sentToStream = false;

  /// Same as `toString()` but using a getter.
  String get string => value.toString();

  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() => value;

  /// This equality override works for _RxImpl instances and the internal
  /// values.
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object o) {
    // Todo, find a common implementation for the hashCode of different Types.
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => _value.hashCode;

  /// 一个value的setter函数。
  /// 更新value的值，并将其添加到数据流中，更新观察者小部件
  /// subject.add(_value)，内部逻辑是自动刷新操作
  set value(T val) {
    if (subject.isClosed) return;
    sentToStream = false;
    if (_value == val && !firstRebuild) return;
    firstRebuild = false;
    _value = val;
    sentToStream = true;
    subject.add(_value);
  }

  /// 在返回 _value 值之前，会添加一个监听器到 subject。
  /// <getValue>
  T get value {
    RxInterface.proxy?.addListener(subject);
    return _value;
  }

  Stream<T> get stream => subject.stream;

  /// 立即使用当前value启动流
  StreamSubscription<T> listenAndPump(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    subject.add(value);

    return subscription;
  }

  /// bindStream函数就是用来将一个Stream<T>绑定到一个Rx<T>对象上，以此来保持它们的值同步更新。
  void bindStream(Stream<T> stream) {
    final listSubscriptions = _subscriptions[subject] ??= <StreamSubscription>[];
    listSubscriptions.add(stream.listen((va) => value = va));
  }
}

```

简化 _RxImpl，把需要关注的内容展示出来：此处有几个需要重点关注的点

- RxInt是一个内置callback的数据类型（GetStream）
- RxInt的value变量改变的时候（set value），会触发subject.add(_value)，猜测内部逻辑是自动刷新操作
- 获取RxInt的value变量的时候（get value），会有一个添加监听的操作 RxInterface.proxy?.addListener(subject);

看样子subject很关键 我们看一下subject，它是一个GetStream实例

那为啥GetStream的add会有刷新操作

- 调用add方法时候，会调用 _notifyData 方法
- _notifyData 方法中，会遍历 _onData 列表，根据条件会执行其泛型的 _data 的方法

下面看一下GetStream这个类

```dart
typedef OnData<T> = void Function(T data);

/// 继承自StreamSubscription 意味着可以处理流
class LightSubscription<T> extends StreamSubscription<T> {
  final RemoveSubscription<T> _removeSubscription;

  LightSubscription(this._removeSubscription,
      {this.onPause, this.onResume, this.onCancel});

  final void Function()? onPause;
  final void Function()? onResume;
  final FutureOr<void> Function()? onCancel;

  bool? cancelOnError = false;

  @override
  Future<void> cancel() {
    _removeSubscription(this);
    onCancel?.call();
    return Future.value();
  }

  OnData<T>? _data;

  Function? _onError;

  Callback? _onDone;

  bool _isPaused = false;

  @override
  void onData(OnData<T>? handleData) => _data = handleData;

  @override
  void onError(Function? handleError) => _onError = handleError;

  @override
  void onDone(Callback? handleDone) => _onDone = handleDone;

  @override
  void pause([Future<void>? resumeSignal]) {
    _isPaused = true;
    onPause?.call();
  }

  @override
  void resume() {
    _isPaused = false;
    onResume?.call();
  }

  @override
  bool get isPaused => _isPaused;

  @override
  Future<E> asFuture<E>([E? futureValue]) => Future.value(futureValue);
}

/// 继承自Stream 意味着就是流对象
class GetStreamTransformation<T> extends Stream<T> {
  final AddSubscription<T> _addSubscription;
  final RemoveSubscription<T> _removeSubscription;

  GetStreamTransformation(this._addSubscription, this._removeSubscription);

  @override
  LightSubscription<T> listen(void Function(T event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subs = LightSubscription<T>(_removeSubscription)
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone);
    _addSubscription(subs);
    return subs;
  }
}

class GetStream<T> {
  void Function()? onListen;
  void Function()? onPause;
  void Function()? onResume;
  FutureOr<void> Function()? onCancel;

  GetStream({this.onListen, this.onPause, this.onResume, this.onCancel});

  /// 待刷新元素 _onData列表
  List<LightSubscription<T>>? _onData = <LightSubscription<T>>[];

  bool? _isBusy = false;

  FutureOr<bool?> removeSubscription(LightSubscription<T> subs) async {
    if (!_isBusy!) {
      return _onData!.remove(subs);
    } else {
      await Future.delayed(Duration.zero);
      return _onData?.remove(subs);
    }
  }

  /// 加上监听
  FutureOr<void> addSubscription(LightSubscription<T> subs) async {
    if (!_isBusy!) {
      return _onData!.add(subs);
    } else {
      await Future.delayed(Duration.zero);
      return _onData!.add(subs);
    }
  }

  int? get length => _onData?.length;

  bool get hasListeners => _onData!.isNotEmpty;

  /// 遍历_onData列表元素 猜测_data方法中 应该有setState
  void _notifyData(T data) {
    _isBusy = true;
    for (final item in _onData!) {
      if (!item.isPaused) {
        item._data?.call(data);
      }
    }
    _isBusy = false;
  }

  void _notifyError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, 'You cannot add errors to a closed stream.');
    _isBusy = true;
    var itemsToRemove = <LightSubscription<T>>[];
    for (final item in _onData!) {
      if (!item.isPaused) {
        if (stackTrace != null) {
          item._onError?.call(error, stackTrace);
        } else {
          item._onError?.call(error);
        }

        if (item.cancelOnError ?? false) {
          //item.cancel?.call();
          itemsToRemove.add(item);
          item.pause();
          item._onDone?.call();
        }
      }
    }
    for (final item in itemsToRemove) {
      _onData!.remove(item);
    }
    _isBusy = false;
  }

  void _notifyDone() {
    assert(!isClosed, 'You cannot close a closed stream.');
    _isBusy = true;
    for (final item in _onData!) {
      if (!item.isPaused) {
        item._onDone?.call();
      }
    }
    _isBusy = false;
  }

  T? _value;

  T? get value => _value;

  /// 调用add后 再调用_notifyData
  void add(T event) {
    assert(!isClosed, 'You cannot add event to closed Stream');
    _value = event;

    /// 开始刷新状态
    _notifyData(event);
  }

  bool get isClosed => _onData == null;

  void addError(Object error, [StackTrace? stackTrace]) {
    assert(!isClosed, 'You cannot add error to closed Stream');
    _notifyError(error, stackTrace);
  }

  void close() {
    assert(!isClosed, 'You cannot close a closed Stream');
    _notifyDone();
    _onData = null;
    _isBusy = null;
    _value = null;
  }

  LightSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) {
    final subs = LightSubscription<T>(
      removeSubscription,
      onPause: onPause,
      onResume: onResume,
      onCancel: onCancel,
    )

    /// .. 相当于给对象设置成员属性或者成员方法
      ..onData(onData)
      ..onError(onError)
      ..onDone(onDone)
      ..cancelOnError = cancelOnError;

    /// _onData列表加上 该流的处理对象
    addSubscription(subs);

    onListen?.call();
    return subs;
  }

  Stream<T> get stream =>
      GetStreamTransformation(addSubscription, removeSubscription);
}
```

总结Rx<T>内置了GetStream实例，类似于ChangeNotifier，添加callBack回调，外部可以手动触发，
使用set Value时，会触发 subject.add(_value), 内部就是自动刷新，
使用get Value就是添加监听操作

##### Obx组件

先看一下Obx的代码

```dart
typedef WidgetCallback = Widget Function();

class Obx extends ObxWidget {
  final WidgetCallback builder;

  const Obx(this.builder, {Key? key}) : super(key: key);

  @override
  Widget build() => builder();
}

class ObxValue<T extends RxInterface> extends ObxWidget {
  final Widget Function(T) builder;
  final T data;

  const ObxValue(this.builder, this.data, {Key? key}) : super(key: key);

  @override
  Widget build() => builder(data);
}

/// 说明obx实际上也是 statefulWidget
abstract class ObxWidget extends StatefulWidget {
  const ObxWidget({Key? key}) : super(key: key);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ObjectFlagProperty<Function>.has('builder', build));
  }

  @override
  ObxState createState() => ObxState();

  @protected
  Widget build();
}

class ObxState extends State<ObxWidget> {

  /// 实例化一个 RxNotifier() 对象， 称为 _observer
  /// class RxNotifier<T> = RxInterface<T> with NotifyManager<T>;
  final _observer = RxNotifier();

  late StreamSubscription subs;

  @override
  void initState() {
    super.initState();

    /// 初始化时 将setState 传到_observer的监听方法中 -> 引出疑问 RxNotifier 到底是什么呢
    /// _updateTree 是传入的 onData方法
    subs = _observer.listen(_updateTree, cancelOnError: false);

    /// 这里 源码走几步看看
  }

  void _updateTree(_) {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    subs.cancel();
    _observer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RxInterface.notifyChildren(_observer, widget.build);
}
```

现在_observer拿到了这个obx组件的更新ui的方法，现在要将这个监听对象转移出去

接着看方法 -> RxInterface.notifyChildren(_observer, widget.build);

看类RxInterface

```dart
/// 英文注释 说了啥
/// 这个类是所有响应式(Rx)类的基础，正是这些类让Get变得如此强大。
/// 这个接口是 _RxImpl<T> 在它的所有子类中使用的约定。
abstract class RxInterface<T> {
  static RxInterface? proxy;

  bool get canUpdate;

  /// Adds a listener to stream
  void addListener(GetStream<T> rxGetx);

  /// Close the Rx Variable
  void close();

  /// Calls `callback` with current value, when the value changes.
  StreamSubscription<T> listen(void Function(T event) onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError});

  /// Avoids an unsafe usage of the `proxy`
  static T notifyChildren<T>(RxNotifier observer, ValueGetter<T> builder) {
    /// RxInterface.proxy正常情况为空，但是作为中间变量，可能出现暂存对象的情况
    /// 现在暂时将它的对象取出来，存在oldObserver变量中
    final oldObserver = RxInterface.proxy;

    /// 将在 _ObxState类中实例化的 RxNotifier() 对象的地址赋值给了RxInterface.proxy
    RxInterface.proxy = observer;

    /// 调用我们在外部传进的Widget
    /// 如果这个Widget中有响应式变量，那么一定会调用该变量中获取 get value（不然ui怎么显示出来）
    /// 标识 <getValue> -> 跳转到最最最重要！的一步
    /// 在这里终于建立起联系了，将变量中 GetStream 实例，添加到了Obx中的 RxNotifier() 实例；
    /// RxNotifier()实例中有一个 subject(GetStream) 实例，
    /// Rx类型中数据变化会触发 subject 变化，最终刷新Obx
    final result = builder();

    /// 如果我们传入的Widget中没有Rx类型变量， _subscriptions数组就会为空，这个判断就会过不了
    if (!observer.canUpdate) {
      RxInterface.proxy = oldObserver;
      throw """
      [Get] the improper use of a GetX has been detected. 
      You should only use GetX or Obx for the specific widget that will be updated.
      If you are seeing this error, you probably did not insert any observable variables into GetX/Obx 
      or insert them outside the scope that GetX considers suitable for an update 
      (example: GetX => HeavyWidget => variableObservable).
      If you need to update a parent widget and a child widget, wrap each one in an Obx/GetX.
      """;
    }

    /// 最后将RxInterface.proxy中原来的值，重新赋给自己，
    /// 至此 _ObxState 中的 _observer对象地址，进行了一番奇幻旅游后，结束了自己的使命（掘金作者原话）
    RxInterface.proxy = oldObserver;
    return result;
  }
}
```

##### Obx总结

在GetX框架中，Obx是一个非常重要的组件，它用于观察可观察对象（Obx）的变化，并在检测到状态改变时自动刷新UI。以下是Obx刷新机制的简单总结：

1. 创建状态：Obx 的刷新机制的首要步骤就是创建可观察的状态。在GetX中，我们可以通过.obs操作符创建可观察的状态。
2. 检测状态变化：当你将可观察的状态放入Obx或Obx的别名（中后，GetX会自动监听这个状态的变化。
3. 更新UI：一旦状态发生变化，Obx会自动刷新UI。它会找到引用了这个可观察对象的UI部分，并重新构建这部分UI。
4. 状态修改：为了触发UI更新，我们需要改变可观察的状态。我们不能直接修改状态，而是应该使用.value属性来改变状态。

举例来说：
var count = 0.obs;
Obx(()= Text('${count.value}'));
count.value++;

总的来说，Obx的刷新机制是GetX框架的核心之一，它使我们能够非常容易地在状态改变时更新UI，而不需要显式地调用setState等方法。