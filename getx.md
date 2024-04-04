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

/// 拓展类
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
    - 大家可以看看这地方单例的实现，我发现很多源码都用这种方式写的，非常简洁
-
    - 全局的数据都是存在 _singl 中，这是个Map
-
    -
        - key：对象的runtimeType或者类的Type + tag
-
    -
        - value：_InstanceBuilderFactory类，我们传入dependecy对象会存入这个类中
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

#####      

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

/// .obs 语法糖
extension IntExtension on int {
  /// Returns a `RxInt` with [this] `int` as initial value.
  RxInt get obs => RxInt(this);
}

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

```

- 看一下Rx父类

```dart
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

/// 引出一个非常重要的类 => _RxImpl

```

- _RxImpl 类继承了 RxNotifier 并且 with 了 RxObjectMixin
- 这个类挺复杂的，看起来是 RxNotifier 和 RxObjectMixin 内容很多
- 代码很多，先展示下完整代码，然后一一解释

```dart
/// Rx 的基础类，管理所有类型的流逻辑。
/// "流逻辑"是在编程中处理数据流的概念和技术，通常在处理异步数据源时使用，如用户输入、文件、Web API请求等。
/// 流通常被视为可处理的数据元素序列，这些元素随时间推移而产生。流可以被观察（订阅）和操作（如筛选、转化、组合等），这就是所谓的"流逻辑"。
abstract class _RxImpl<T> extends RxNotifier<T> with RxObjectMixin<T> {
  _RxImpl(T initial) {
    _value = initial;
  }

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  Stream<R> map<R>(R mapper(T? data)) => stream.map(mapper);

  void update(void fn(T? val)) {
    fn(_value);
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

/// with 是一个关键字，主要用于 mixin 的实现。
/// Mixin 是一种代码重用的技术，允许你在一个类中使用其他类的代码。
/// 这个关键字使得你可以在不使用继承的情况下，将其他类的代码和功能整合到一个类中。
class RxNotifier<T> = RxInterface<T> with NotifyManager<T>;

mixin NotifyManager<T> {
  GetStream<T> subject = GetStream<T>();
  final _subscriptions = <GetStream, List<StreamSubscription>>{};

  bool get canUpdate => _subscriptions.isNotEmpty;

  /// 内置callBack 的 GetStream类型
  void addListener(GetStream<T> rxGetx) {
    if (!_subscriptions.containsKey(rxGetx)) {
      final subs = rxGetx.listen((data) {
        if (!subject.isClosed) subject.add(data);
      });
      final listSubscriptions =
      _subscriptions[rxGetx] ??= <StreamSubscription>[];
      listSubscriptions.add(subs);
    }
  }

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

mixin RxObjectMixin<T> on NotifyManager<T> {
  late T _value;

  void refresh() {
    subject.add(value);
  }

  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  bool firstRebuild = true;

  String get string => value.toString();

  @override
  String toString() => value.toString();

  dynamic toJson() => value;

  @override
  bool operator ==(dynamic o) {
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  int get hashCode => _value.hashCode;

  /// subject.add(_value)，内部逻辑是自动刷新操作
  set value(T val) {
    if (subject.isClosed) return;
    if (_value == val && !firstRebuild) return;
    firstRebuild = false;
    _value = val;

    subject.add(_value);
  }

  /// 会有一个添加监听的操作
  T get value {
    if (RxInterface.proxy != null) {
      RxInterface.proxy!.addListener(subject);
    }
    return _value;
  }

  Stream<T?> get stream => subject.stream;

  void bindStream(Stream<T> stream) {
    final listSubscriptions =
    _subscriptions[subject] ??= <StreamSubscription>[];
    listSubscriptions.add(stream.listen((va) => value = va));
  }
}

```

简化 _RxImpl，把需要关注的内容展示出来：此处有几个需要重点关注的点

- RxInt是一个内置callback的数据类型（GetStream）
- RxInt的value变量改变的时候（set value），会触发subject.add(_value)，内部逻辑是自动刷新操作
- 获取RxInt的value变量的时候（get value），会有一个添加监听的操作

```dart
/// 代码简化后
abstract class _RxImpl<T> extends RxNotifier<T> with RxObjectMixin<T> {

  void update(void fn(T? val)) {
    fn(_value);
    subject.add(_value);
  }
}

class RxNotifier<T> = RxInterface<T> with NotifyManager<T>;

mixin NotifyManager<T> {
  GetStream<T> subject = GetStream<T>();
  final _subscriptions = <GetStream, List<StreamSubscription>>{};

  bool get canUpdate => _subscriptions.isNotEmpty;

  ///  这是一个内部方法。订阅内部流的变化。
  ///  这个方法的作用是：它监听并订阅内部数据流的变化，每当数据流有变动时，此方法都能接收到这些变化，然后进行相应的处理。
  ///  这在响应式编程中是非常常见的操作，常用于处理异步数据的变更，例如网络请求、用户输入等等。
  void addListener(GetStream<T> rxGetx) {
    if (!_subscriptions.containsKey(rxGetx)) {
      final subs = rxGetx.listen((data) {
        if (!subject.isClosed) subject.add(data);
      });
      final listSubscriptions =
      _subscriptions[rxGetx] ??= <StreamSubscription>[];
      listSubscriptions.add(subs);
    }
  }
}

mixin RxObjectMixin<T> on NotifyManager<T> {
  late T _value;

  void refresh() {
    subject.add(value);
  }

  set value(T val) {
    if (subject.isClosed) return;
    if (_value == val && !firstRebuild) return;
    firstRebuild = false;
    _value = val;

    subject.add(_value);
  }

  T get value {
    if (RxInterface.proxy != null) {
      RxInterface.proxy!.addListener(subject);
    }
    return _value;
  }
}

```

说完了_RxImpl 这类继承又with的，那么要看with的这个RxNotifier的RxInterface
with的NotifyManager中的GetStream

那为啥GetStream的add会有刷新操作，根据大佬的说法和猜测

- 调用add方法时候，会调用 _notifyData 方法
- _notifyData 方法中，会遍历 _onData 列表，根据条件会执行其泛型的 _data 的方法
- 我猜，_data 中的方法体，十有八九在某个地方肯定添加了 setState()

下面看一下GetStream这个类

```dart
class GetStream<T> {
  GetStream({this.onListen, this.onPause, this.onResume, this.onCancel});

  List<LightSubscription<T>>? _onData = <LightSubscription<T>>[];

  FutureOr<void> addSubscription(LightSubscription<T> subs) async {
    if (!_isBusy!) {
      return _onData!.add(subs);
    } else {
      await Future.delayed(Duration.zero);
      return _onData!.add(subs);
    }
  }

  void _notifyData(T data) {
    _isBusy = true;
    for (final item in _onData!) {
      if (!item.isPaused) {
        item._data?.call(data);
      }
    }
    _isBusy = false;
  }

  T? _value;

  T? get value => _value;

  void add(T event) {
    assert(!isClosed, 'You cannot add event to closed Stream');
    _value = event;
    _notifyData(event);
  }
}

typedef OnData<T> = void Function(T data);

class LightSubscription<T> extends StreamSubscription<T> {
  OnData<T>? _data;
}

```






