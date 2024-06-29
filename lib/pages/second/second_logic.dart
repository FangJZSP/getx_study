import 'package:get/get.dart';
import 'package:getx_study/tools/router_helper.dart';

import '../../route/routers.dart';
import 'second_state.dart';

class SecondLogic extends GetxController {
  final SecondState state = SecondState();

  @override
  void onInit() {
    super.onInit();
    // state.a = Get.arguments;
    // state.a = RouterHelper.nodeRouteList
    //     .firstWhereOrNull((element) =>
    //         (element is PageNodeRoute) && (element.current == Routers.second))
    //     ?.args;
    state.a = RouterHelper.getMatchArg<SecondPage>(Routers.second)?.a;
  }
}
