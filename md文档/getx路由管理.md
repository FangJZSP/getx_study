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

对于栈这个数据结构我们并不陌生，可以有效管理页面的进出。

### GetX路由

#### 从`Routers.getPage`了解GetX的Route使用

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

#### 一直强调的Navigator到底是怎么使用的

在此之前，我们一直强调Navigator，但是我们不知道Navigator从何处被new出来的。

简而言之，一个能观察到所有页面的顶层组件，必然是在我们runApp之后产生的。

那让我们一起探索一下这个神奇的组件。
从runApp之后的我们组件是GetMaterialApp，
再往上走，我们可以看到WidgetsApp，在它的build方法中赫然出现了Navigator，
所以从一开始，我们的app就是一个Navigator组件下嵌套了可以生成各种各样的页面并予以观察。

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

我们看到PI项目里面有MyRouteObserver。里面有挺多重写方法，didPop/didPush等等，那他们什么时候调用的呢？

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

这里调用观察者的方法，这一刻路由行为的观察终于形成了闭环。

并且，通过这一思想，我们就可以自定义实现我们项目中的路由链了。

#### 从`Get.toNamed()` 了解GetX的生命周期