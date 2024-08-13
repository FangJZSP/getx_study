import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_study/widgets/base_scaffold.dart';

import 'root_logic.dart';

class RootPage extends StatelessWidget {
  RootPage({Key? key}) : super(key: key);

  final logic = Get.put(RootLogic());
  final state = Get.find<RootLogic>().state;

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(pageTitle: 'Root', mainContent: mainContent());
  }

  Widget mainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('GetX 路由讲解'),
        Expanded(
          child: TextButton(
            onPressed: logic.goFirstPage,
            child: Text('go first page'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: logic.goSecondPage,
            child: Text('go second page'),
          ),
        ),
        Expanded(
          child: TextButton(
            onPressed: logic.goTestPage,
            child: Text('goTestPage'),
          ),
        ),
      ],
    );
  }
}
