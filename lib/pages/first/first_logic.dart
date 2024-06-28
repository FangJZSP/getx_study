import 'package:get/get.dart';

import '../../route/routers.dart';
import 'first_state.dart';

class FirstLogic extends GetxController {
  final FirstState state = FirstState();

  void goSecondPage() {
    Get.toNamed(Routers.second);
  }
}
