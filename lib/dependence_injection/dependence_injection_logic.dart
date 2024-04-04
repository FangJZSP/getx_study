import 'package:get/get.dart';

import 'dependence_injection_state.dart';

class DependenceInjectionLogic extends GetxController {
  final DependenceInjectionState state = DependenceInjectionState();

  /// 使用OBX
  void count1add() {
    state.count1.value++;
  }

  /// 使用GetBuilder()
  void count2sub() {
    state.count2--;

    /// 1. 不使用id 可以直接使用update
    update();
  }

  void count3sub() {
    /// 2. 使用id 可以更新指定的getBuilder构建的ui
    state.count3--;
    state.count3--;
    update([state.count3Id]);
  }
}
