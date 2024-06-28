import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/base_scaffold.dart';
import 'second_logic.dart';

class SecondPage extends StatelessWidget {
  SecondPage({Key? key}) : super(key: key);

  final logic = Get.put(SecondLogic());
  final state = Get.find<SecondLogic>().state;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(pageTitle: 'Second');
  }
}
