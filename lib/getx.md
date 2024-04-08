### 依赖注入

依赖注入的方式

#### put使用

```dart
/// 使用put进行依赖注入
var controller = Get.put(XxxController());
final logic = Get.put(DependenceInjectionLogic());

/// getx 的接口
class _GetImpl extends GetInterface {}

/// 注释 // ignore: non_constant_identifier_names 是 Dart 分析器的一部分，它告诉分析器忽略接下来的一行中的特定代码规则检查
/// 全局、只读变量 实现单例
final Get = _GetImpl();

/// 拓展
extension Inst on GetInterface {

  /// 在内存中注入实例<s>。
  /// 不需要定义泛型类型`<[S]>`;因为它是从依赖参数推断出来的。
  /// dependency要注入的实例
  /// tag可选，使用一个标签作为“id”来创建多个相同“类型”的记录，标签不会与其他依赖类型使用的相同标签冲突。
  /// permanent将实例保存在内存中并持久化它，而不是遵循Get。smartManagement”规则。虽然可以通过' GetInstance.reset() '和' Get.delete() '删除
  /// 如果定义了依赖项，则必须从这里返回
  S put<S>(S dependency,
      {String? tag,
        bool permanent = false,
        InstanceBuilderCallback<S>? builder}) =>
      GetInstance().put<S>(dependency, tag: tag, permanent: permanent);
}

```

#### put的逻辑

- 主要的逻辑看来还是GetInstance中
-
    - 单例的实现，我们项目中的manager都用这种方式写的
-
    - 全局的数据都是存在 _singl 中，这是一个map类型
-
    -
        - key：对象的runtimeType或者类的Type + tag
-
    -
        - value：_InstanceBuilderFactory类，我们传入dependency对象会存入这个类中
-
    - _singl 用这个map存值的时候
-
    -
        - 如果map中有key和传入key相同的数据，传入的数据将不会被存储
-
    -
        - 也就是说相同类实例的对象，传入并不会被覆盖，只会存储第一条数据，后续被放弃
-
    - 最后使用find方法，返回传入的实例

```dart
class GetInstance {
  /// 项目经常使用的单例模式
  factory GetInstance() => _getInstance ??= GetInstance._();

  const GetInstance._();

  static GetInstance? _getInstance;

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
    /// 使用find方法返回实例
    _insert(
        isSingleton: true,
        name: tag,
        permanent: permanent,
        builder: builder ?? (() => dependency));
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

      /// 在 GetX 中，标记为 "脏" 的依赖项是指在观察者没有监听这个依赖项时，可以被清除的对象。
      /// 要清除的对象被标记为 "脏" 并放入队列中，当垃圾回收启动时，应用程序将会清除这些被标记为 "脏" 的对象，从而管理和释放内存。
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

  /// 根据类型(也可以是名称)生成键，以便在hashmap中注册Instance Builder。
  String _getKey(Type type, String? name) {
    return name == null ? type.toString() : type.toString() + name;
  }
}

```

#### find逻辑

- find方法 就是从map中取数据的操作

```dart

S find<S>({String? tag}) => GetInstance().find<S>(tag: tag);

final state = Get
    .find<DependenceInjectionLogic>()
    .state;

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

```

### 刷新机制

#### GetBuilder刷新机制

##### 使用场景展示一下

##### 内置回收机制

```dart
class GetBuilder<T extends GetxController> extends StatefulWidget {
  final GetControllerBuilder<T> builder;
  final bool global;
  final String? tag;
  final bool autoRemove;
  final T? init;

  const GetBuilder({
    Key? key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.initState,
    this.tag,
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
    super.initState();
    widget.initState?.call(this);

    var isRegistered = GetInstance().isRegistered<T>(tag: widget.tag);

    if (widget.global) {
      if (isRegistered) {
        controller = GetInstance().find<T>(tag: widget.tag);
      } else {
        controller = widget.init;
        GetInstance().put<T>(controller!, tag: widget.tag);
      }
    } else {
      controller = widget.init;
      controller?.onStart();
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.dispose?.call(this);
    if (_isCreator! || widget.assignId) {
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
  Widget build(BuildContext context) {
    return widget.builder(controller!);
  }
}

```

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

#### Obx刷新机制

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

##### 总结




