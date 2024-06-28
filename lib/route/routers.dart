import 'package:get/get.dart';

import '../pages/first/first_view.dart';
import '../pages/root/root_view.dart';
import '../pages/second/second_view.dart';

class Routers {
  static const root = '/';
  static const first = '/first';
  static const second = '/second';

  static List<GetPage> getPages = [
    GetPage(name: root, page: () => RootPage()),
    GetPage(name: first, page: () => FirstPage()),
    GetPage(name: second, page: () => SecondPage()),
  ];
}
