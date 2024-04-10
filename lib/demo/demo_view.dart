import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'demo_logic.dart';

class DemoPage extends StatelessWidget {
  DemoPage({Key? key}) : super(key: key);

  final logic = Get.put(DemoLogic());
  final state = Get.find<DemoLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
