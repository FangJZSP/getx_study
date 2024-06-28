import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../widgets/base_scaffold.dart';
import 'second_logic.dart';

class SecondPage extends StatefulWidget {
  SecondPage({Key? key}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  final logic = Get.put(SecondLogic());

  final state = Get.find<SecondLogic>().state;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      pageTitle: 'Second',
      mainContent: mainContent(),
    );
  }

  Widget mainContent() {
    return Center(child: Text(state.a ?? '我的参数呢？'));
  }
}
