import 'package:get/get.dart';

import 'dependence_injection_state.dart';

class DependenceInjectionLogic extends GetxController {
  final DependenceInjectionState state = DependenceInjectionState();

  @override
  void onInit() {
    super.onInit();
    state.cat1.value = Cat()
      ..name = "一键"
      ..age = 0;
    state.cat2.value.name = "三连";
    state.cat2.value.age = 100;
  }

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

  /// 使用实体类
  void changeCat1() {
    state.cat1.value?.name = "${state.cat1.value?.name}wa";
    state.cat1.value?.age = (state.cat1.value?.age ?? 0) + 1;
    print(state.cat1.value);
    state.cat1.refresh();
  }

  void changeCat2() {
    state.cat2.value.name = "${state.cat2.value.name}la";
    state.cat2.value.age = (state.cat2.value.age ?? 0) - 1;
    state.cat2.refresh();
    // state.cat2.update((val) {
    //   val?.name = "???";
    // });
  }
}
