# GetX路由管理

## 路由基础

### Flutter路由

#### Route

Route代表应用中页面，包含页面布局/逻辑/生命周期等信息。Route继承PageRoute。

PageRoute是一个抽象类，可以用于Navigator的页面。PageRoute包含了页面构建方法、过渡动画以及页面生命周期回调。

// 使用MaterialPageRoute创建一个新页面
MaterialPageRoute(builder: (context) => NewPage());

// 使用CupertinoPageRoute创建一个新页面
CupertinoPageRoute(builder: (context) => NewPage());

#### Navigator

Navigator顾名思义导航器。

Navigator 是一个管理应用页面栈的组件，它负责处理页面之间的跳转、导航以及参数传递等操作。

对于栈，这个数据结构我们并不陌生，可以有效管理元素的进出。

### GetX路由

#### 从`Routers.getPages`的构成了解GetX的Route的使命 - 静态配置

从上述的讲解中我们可以知道Route其实就是一个页面的灵魂。那GetX是如何实现页面的灵魂的呢？

我们的页面是GetPage，继承了Page，Page继承了RouteSetting

继承自Page，Page中实现了创建路由方法（createRoute），而Page继承了RouteSetting，提供了创建路由所需的**必要
**配置。

```dart
/// navigator.dart Page类
@factory
Route<T> createRoute(BuildContext context);
```

在GetPage中，我们实现父类方法createRoute

```dart
/// get_route.dart GetPage类
@override
Route<T> createRoute(BuildContext context) {
  // return GetPageRoute<T>(settings: this, page: page);
  final page = PageRedirect(
    route: this, // GetPage
    settings: this, // RouteSetting
    unknownRoute: unknownRoute,
  ).getPageToRoute<T>(this, unknownRoute);

  return page;
}
```

通过PageRedirect提供的getPageToRoute，最终返回了我们的Route

```dart
/// route_middleware.dart PageRedirect类
GetPageRoute<T> getPageToRoute<T>(GetPage rou, GetPage? unk) {
  while (needRecheck()) {}
  final r = (isUnknown ? unk : rou)!;

  return GetPageRoute<T>(
    // ...
  );
}
```

其中GetPageRoute继承了PageRoute，在GetPageRoute中我们完成了最重要的页面build方法

并且混入了页面切换以及页面切换报告方法，可以实现页面的动画已经页面的载入和销毁

```dart
/// default_route.dart GetPageRoute类
class GetPageRoute<T> extends PageRoute<T>
    with GetPageRouteTransitionMixin<T>, PageRouteReportMixin {

  GetPageRoute( // ..
      ) : super(settings: settings, fullscreenDialog: fullscreenDialog);

  @override
  final Duration transitionDuration;
  final GetPageBuilder? page;
  final String? routeName;

  @override
  Widget buildContent(BuildContext context) {
    return _getChild();
  }

// ...
}

```

其中PageRoute的顶级父类是Route，而在Route中，我们通过navigator我们完成了对页面的行为的监控。

#### 一直强调的Navigator到底是什么？ - 动态监控

在此之前，我们一直强调Navigator，但是我们不知道Navigator从何处被new出来的。

简而言之，一个能观察到所有页面的顶层组件，必然是在我们runApp之后不久就应该产生的。

那让我们一起探索一下这个神奇的组件。
从runApp之后的我们组件是GetMaterialApp，
再往上一直走，我们可以看到WidgetsApp，在它的build方法中赫然出现了Navigator，
所以从一开始，我们的app就是一个Navigator组件下嵌套了各种各样的页面，并可予以观察。

那我着重观察一下监听路由的行为了解，监听器在何时被安排在了生成的页面中。

回到runApp，组件是GetMaterialApp，其中有一参数名为navigatorObservers，我们一路观察下去。
最终我们在Navigator中找到参数observers！！！

接着探索，我们发现Navigator的observers在NavigatorState initState时被传入给_effectiveObservers

在NavigatorState看到一个重要的方法flush，通知观察者刷新

其中的_observedRouteAdditions&_observedRouteDeletions，字面意思一个路由添加、一个路由删除。
在navigator执行路由添加时，将**_NavigatorObservation**
的子类添加到_observedRouteAdditions队列中，删除则添加到_observedRouteDeletions

最后统一由通知给路由观察者发送通知，并执行路由通知者中的观察到刷新后观察者自己的任务

```dart
  void _flushObserverNotifications() {
  if (_effectiveObservers.isEmpty) {
    _observedRouteDeletions.clear();
    _observedRouteAdditions.clear();
    return;
  }
  while (_observedRouteAdditions.isNotEmpty) {
    final _NavigatorObservation observation = _observedRouteAdditions.removeLast();
    _effectiveObservers.forEach(observation.notify);
  }

  while (_observedRouteDeletions.isNotEmpty) {
    final _NavigatorObservation observation = _observedRouteDeletions.removeFirst();
    _effectiveObservers.forEach(observation.notify);
  }
}
```

那我们作为观察者观察一下 -》 不难发现，其实观察者可以有很多，这样我们可以实现一个切面思想，针对路由的行为，自定义我们观察到路由变化的事件。

我们看GetX实现的GetObserver，重写了很多方法，并一一实现了自己的观察到路由变化后执行的操作。

当我们回看到自己的项目时，里面也有MyRouteObserver。我们同样重写方法，didPop/didPush等等，那他们什么时候调用的呢？

我们再回到_NavigatorObservation，他定义了一个notify方法.

当_NavigatorObservation的子类如_NavigatorPopObservation
我们发现它重写了notify方法,

```dart
abstract class _NavigatorObservation {
  _NavigatorObservation(this.primaryRoute,
      this.secondaryRoute,);

  final Route<dynamic> primaryRoute;
  final Route<dynamic>? secondaryRoute;

  void notify(NavigatorObserver observer);
}

class _NavigatorPopObservation extends _NavigatorObservation {
  _NavigatorPopObservation( //... 
      );

  @override
  void notify(NavigatorObserver observer) {
    observer.didPop(primaryRoute, secondaryRoute);
  }
}
```

这里调用观察者的方法，在这一刻路由行为的观察并进行行动终于形成了闭环。

并且，通过这一思想，我们就可以自定义实现我们项目中的路由链了。

#### 从`Get.toNamed()` 了解GetX的路由跳转及页面生成 - 贯穿始终

##### 路由的奇幻漂流 - 路由历史

```dart
  Future<T?>? toNamed<T>(String page, {
  dynamic arguments,
  int? id,
  bool preventDuplicates = true,
  Map<String, String>? parameters,
}) {
  // 当前路由和跳转路由重复时且阻止重复页面时，跳转无效
  if (preventDuplicates && page == currentRoute) {
    return null;
  }

  // 当跳转时携带参数回拼接给页面
  // 我们项目中没有使用这种方法，而是使用了Get.arguments
  if (parameters != null) {
    final uri = Uri(path: page, queryParameters: parameters);
    page = uri.toString();
  }

  // 通过 NavigatorState 的方法实现往路由栈添加页面
  return global(id).currentState?.pushNamed<T>(
    page,
    arguments: arguments,
  );
}

// global方法通过GlobalKey返回NavigatorState
GlobalKey<NavigatorState> global(int? k) {
  GlobalKey<NavigatorState> newKey;

  // ...

  return newKey;
}

@optionalTypeArgs
abstract class GlobalKey<T extends State<StatefulWidget>> extends Key {

  /// GetX默认创建的全局键
  factory GlobalKey({ String? debugLabel }) => LabeledGlobalKey<T>(debugLabel);


  /// 创建一个不带标签的全局键
  const GlobalKey.constructor() : super.empty();

  Element? get _currentElement => WidgetsBinding.instance.buildOwner!._globalKeyRegistry[this];

  /// 具有此键的组件在其中构建的构建上下文。
  /// 如果树中没有与此全局键匹配的组件，则当前上下文为空。
  BuildContext? get currentContext => _currentElement;


  /// 树中当前具有此全局键的组件。
  /// 如果树中没有与此全局键匹配的小部件，则当前组件为空。
  Widget? get currentWidget => _currentElement?.widget;


  /// 树中当前具有此全局键的小部件的State。
  /// 1. 要stateful
  /// 2. 和这个State要相同
  /// 否则返回空
  T? get currentState {
    final Element? element = _currentElement;
    if (element is StatefulElement) {
      final StatefulElement statefulElement = element;
      final State state = statefulElement.state;
      if (state is T) {
        return state;
      }
    }
    return null;
  }
}
```

通过阅读源码，当你使用GetX没有设置默认Key时，Get.toNamed的时候默认拿到的是GlobalKey是默认创建的
**var _key = GlobalKey<NavigatorState>(debugLabel: 'Key Created by default');**
这个key的NavigatorState为包裹该GetMaterialApp的父组件，你可以使用它来完成路由的跳转.

继续阅读源码

```dart
// 走到了NavigatorState中的pushNamed方法
Future<T?> pushNamed<T extends Object?>(String routeName, {
  Object? arguments,
}) {
  return push<T?>(_routeNamed<T>(routeName, arguments: arguments)!);
}


// _routeNamed 我们根据setting通过onGenerateRoute完成了路由的生成
// 那么我们这个生成器从何？在生成路由的同时，完成了什么工作？这就不得不一步步往上去寻找我们的配置，完成页面生成闭环
/// 但我们暂时按下不表，先把路由插入 讲完
Route<T?>? _routeNamed<T>(String name, { required Object? arguments, bool allowNull = false }) {
  // ...
  final RouteSettings settings = RouteSettings(
    name: name,
    arguments: arguments,
  );
  Route<T?>? route = widget.onGenerateRoute!(settings) as Route<T?>?;

  // ...
  return route;
}

// push方法
@optionalTypeArgs
Future<T?> push<T extends Object?>(Route<T> route) {
  _pushEntry(_RouteEntry(route, pageBased: false, initialState: _RouteLifecycle.push));

  // Future<T?> get popped => _popCompleter.future;
  // final Completer<T?> _popCompleter = Completer<T?>();
  // 当上述行为完成后，一个承诺完成的状态就可以完成了，并返回你想要的泛型
  return route.popped;
}

// 当该route的行为被记录到_history列表中中
// _History类代表的是导航历史的_RouteEntries的集合
void _pushEntry(_RouteEntry entry) {
  // ... 
  _history.add(entry);
  // 刷新路由行为
  _flushHistoryUpdates();
  // ...
  _afterNavigation(entry.route);
}

```

这样一个完整的路由行为就被记录下来，同时也通知了观察者记得刷新哦～

##### 路由的生命过客 - 页面生成

那话说回来，页面又是何时构造的呢？ 书接上回

**onGenerateRoute**是Navigator的参数，上层是WidgetsApp的_onGenerateRoute

```dart
// **onGenerateRoute**是Navigator的参数, 上层是WidgetsApp的_onGenerateRoute
class Navigator extends StatefulWidget {
  const Navigator({
    // ...
    this.onGenerateRoute,
    // ...
  });
}

// 生成路由有两种方式onGenerateRoute/pageRouteBuilder 我们都看一下
class WidgetsApp extends StatefulWidget {
  WidgetsApp({
    // ...
    this.onGenerateRoute,
    // ...
    List<NavigatorObserver> this.navigatorObservers = const <NavigatorObserver>[],
    this.initialRoute,
    this.pageRouteBuilder,
    //...
  });
}

class _WidgetsAppState extends State<WidgetsApp> with WidgetsBindingObserver {

  @override
  Widget build(BuildContext context) {
    Widget? routing;
    routing = FocusScope(
      // ...
      child: Navigator(
        // ...
        onGenerateRoute: _onGenerateRoute,
        // ...
      ),
    );
    return xxx;
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String? name = settings.name;
    final WidgetBuilder? pageContentBuilder = name == Navigator.defaultRouteName &&
        widget.home != null
        ? (BuildContext context) => widget.home!
        : widget.routes![name];

    if (pageContentBuilder != null) {
      assert(
      widget.pageRouteBuilder != null,
      'The default onGenerateRoute handler for WidgetsApp must have a '
          'pageRouteBuilder set if the home or routes properties are set.',
      );
      final Route<dynamic> route = widget.pageRouteBuilder!<dynamic>(
        settings,
        pageContentBuilder,
      );
      return route;
    }
    if (widget.onGenerateRoute != null) {
      return widget.onGenerateRoute!(settings);
    }
    return null;
  }
}
```

内容有点重复，不用代码块了。

如果不传递生成路由方法，可以看到用的是默认构造，

如果我们定义了，就是自己生成路由的方法

---
在往上走到了MaterialApp:

pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
return MaterialPageRoute<T>(settings: settings, builder: builder);
},
onGenerateRoute: widget.onGenerateRoute,

---
再往上走到了GetMaterialApp:

onGenerateRoute:
(getPages != null ? generator : onGenerateRoute),

```dart
// 当我们去到下一个页面时，该方法就会执行
Route<dynamic> generator(RouteSettings settings) {
  return PageRedirect(settings: settings, unknownRoute: unknownRoute).page();
}
```

上述文章已经讲了构建页面的方法，那最后，页面就回在createRoute中完成页面的build，至此页面的生成流程也介绍完毕。

#### 从`捣蛋弹窗`了解参数传递 - Get.arguments

通过debug发现，路由先记录历史记录，记录的同时，GetObserver会通过Get.routing内置的update方法更新自己上一个路由。

```dart
  @override
void didPush(Route route, Route? previousRoute) {
  // ...
  // 更新自己
  _routeSend?.update((value) {
    // Only PageRoute is allowed to change current value
    if (route is PageRoute) {
      value.current = newRoute.name ?? '';
    }
    final previousRouteName = _extractRouteName(previousRoute);
    if (previousRouteName != null) {
      value.previous = previousRouteName;
    }

    value.args = route.settings.arguments;
    value.route = route;
    value.isBack = false;
    value.removed = '';
    value.isBottomSheet =
    newRoute.isBottomSheet ? true : value.isBottomSheet ?? false;
    value.isDialog = newRoute.isDialog ? true : value.isDialog ?? false;
  });

  // ...
}
```

当页面初始化时，此时上一个路由已经为弹窗，则传递给页面的参数获取不到。




