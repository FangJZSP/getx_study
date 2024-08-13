import 'package:get/get.dart';
import 'package:getx_study/tools/nav_utils.dart';

import '../../route/routers.dart';
import '../second/second_state.dart';
import 'root_state.dart';

class RootLogic extends GetxController {
  final RootState state = RootState();

  void goFirstPage() {
    Get.toNamed(Routers.first);
  }

  // 演示 参数传递问题
  void goSecondPage() {
    // Get.toNamed(Routers.second, arguments: '我是参数');
    // NavUtils.showNormalDialog(routeName: '捣乱分子', routeNodeArguments: '怎么会是我');
    // NavUtils.showNormalDialog(
    //   routeName: '捣乱分子',
    // );
    Get.toNamed(Routers.second, arguments: SecondPageArgs('我是参数'));
    NavUtils.showNormalDialog(
        routeName: DialogName.naughtyDialog.routeName,
        routeNodeArguments: '怎么会是我');
  }

  void goTestPage() {
    Get.toNamed(Routers.testChangeNotifier);
  }
}
