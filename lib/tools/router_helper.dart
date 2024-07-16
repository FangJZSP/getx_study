import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

// 抽象routing类
abstract class NodeRoute {
  dynamic args;
  Route<dynamic>? route;

  NodeRoute(this.args, this.route);
}

class PageNodeRoute extends NodeRoute {
  String? current;

  PageNodeRoute(this.current, super.args, super.route);
}

class DialogNodeRoute extends NodeRoute {
  DialogNodeRoute(super.args, super.route);
}

class BottomSheetNodeRoute extends NodeRoute {
  BottomSheetNodeRoute(super.args, super.route);
}

class RouterHelper {
  // todo addNodeList & deleteNodeList 根据isBack区分
  static List<NodeRoute> get nodeRouteList => _nodeRouteList;

  static final List<NodeRoute> _nodeRouteList = [];

  // current 为Page参数独有
  static void collectRouters(Routing? routing) {
    print('---收集routing开始工作啦---');
    if (routing?.isBack == true) {
      print('---返回过程中 -> 清除记录参数哦---');
      _nodeRouteList.removeWhere(
          (element) => element.route?.settings.name == routing?.current);
      return;
    }
    if (routing?.isBottomSheet == true) {
      // todo 收集bottomSheet参数，并添加到列表中
      print('---可收集BottomSheet参数---');
      return;
    }
    if (routing?.isDialog == true) {
      // todo 收集dialog参数，并添加到列表中
      print('---可收集Dialog参数---');
      return;
    }
    NodeRoute? newRouting =
        PageNodeRoute(routing?.current, routing?.args, routing?.route);
    _nodeRouteList.insert(0, newRouting);
    for (var r in _nodeRouteList) {
      print('name: ${r.route?.settings.name ?? ''} args: ${r.args}');
    }
  }

  // todo 改进参数校验规则
  static T? getMatchArg<T>(String routeName) {
    var args = nodeRouteList
        .firstWhereOrNull(
            (element) => element.route?.settings.name == routeName)
        ?.args;
    if (args is T) {
      return args;
    }
    return null;
  }
}
