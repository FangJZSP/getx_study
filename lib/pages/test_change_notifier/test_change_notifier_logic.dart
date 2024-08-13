import 'package:get/get.dart';

import 'test_change_notifier_state.dart';

class TestChangeNotifierLogic extends GetxController {
  final TestChangeNotifierState state = TestChangeNotifierState();

  void add() {
    state.count.value++;
  }
}
