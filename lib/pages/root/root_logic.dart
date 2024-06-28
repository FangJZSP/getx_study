import 'package:get/get.dart';

import '../../route/routers.dart';
import 'root_state.dart';

class RootLogic extends GetxController {
  final RootState state = RootState();

  void goFirstPage() {
    Get.toNamed(Routers.first);
  }

  void goSecondPage() {
    Get.toNamed(Routers.second);
  }
}
