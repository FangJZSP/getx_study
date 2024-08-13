import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:getx_study/widgets/base_scaffold.dart';

import 'test_change_notifier_logic.dart';

class TestChangeNotifierPage extends StatefulWidget {
  TestChangeNotifierPage({Key? key}) : super(key: key);

  @override
  State<TestChangeNotifierPage> createState() => _TestChangeNotifierPageState();
}

class _TestChangeNotifierPageState extends State<TestChangeNotifierPage> {
  final logic = Get.put(TestChangeNotifierLogic());

  final state = Get.find<TestChangeNotifierLogic>().state;

  @override
  void initState() {
    super.initState();
    state.count.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      pageTitle: '测试changeNotifier',
      mainContent: mainContent(),
    );
  }

  Widget mainContent() {
    return GestureDetector(
        onTap: logic.add, child: Text('${state.count.value}'));
  }
}
