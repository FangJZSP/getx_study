import 'package:get/get.dart';
import 'package:getx_study/pages/test_change_notifier/test_change_notifier_view.dart';

import '../pages/first/first_view.dart';
import '../pages/root/root_view.dart';
import '../pages/second/second_view.dart';

enum DialogName {
  naughtyDialog,
  ;

  String get routeName {
    return '/$name';
  }
}

class Routers {
  static const root = '/';
  static const first = '/first';
  static const second = '/second';
  static const testChangeNotifier = '/testChangeNotifier';

  static List<GetPage> getPages = [
    GetPage(name: root, page: () => RootPage()),
    GetPage(name: first, page: () => FirstPage()),
    GetPage(name: second, page: () => SecondPage()),
    GetPage(name: testChangeNotifier, page: () => TestChangeNotifierPage()),
  ];
}
