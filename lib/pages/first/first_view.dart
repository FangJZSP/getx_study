import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/base_scaffold.dart';
import 'first_logic.dart';

class FirstPage extends StatelessWidget {
  FirstPage({Key? key}) : super(key: key);

  final logic = Get.put(FirstLogic());
  final state = Get.find<FirstLogic>().state;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(pageTitle: 'First');
  }
}
