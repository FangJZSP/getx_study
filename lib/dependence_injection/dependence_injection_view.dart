import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'dependence_injection_logic.dart';

class DependenceInjectionPage extends StatelessWidget {
  DependenceInjectionPage({Key? key}) : super(key: key);

  final logic = Get.put(DependenceInjectionLogic());
  final state = Get.find<DependenceInjectionLogic>().state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("GetX Demo"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "不使用任何更新方式",
            ),
            Text(
              state.count1.value.toString(),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const Text(
              "使用obx进行包裹",
            ),
            Obx(() {
              return Text(
                state.count2.toString(),
                style: Theme.of(context).textTheme.headlineMedium,
              );
            }),
            const Text(
              "使用getBuilder 不加id",
            ),
            GetBuilder<DependenceInjectionLogic>(
              /// 无id 使用update可以更新所有ui
              assignId: true,
              builder: (logic) {
                return Text(
                  state.count2.toString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const Text(
              "使用getBuilder 加id",
            ),
            GetBuilder<DependenceInjectionLogic>(
              /// 根据id进行更新 指定的id
              id: state.count3Id,
              assignId: true,
              builder: (logic) {
                return Text(
                  state.count3.toString(),
                  style: Theme.of(context).textTheme.headlineMedium,
                );
              },
            ),
            const SizedBox(
              height: 100,
            ),
            Expanded(
              child: GestureDetector(
                onTap: logic.changeCat1,
                child: Column(
                  children: [
                    Obx(() {
                      return Text(
                        "cat1: ${state.cat1.value?.name ?? ''}  ${state.cat1.value?.age ?? 0}",
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    }),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: logic.changeCat2,
                child: Column(
                  children: [
                    Obx(() {
                      return Text(
                        "cat2: ${state.cat2.value.name ?? ''}  ${state.cat2.value.age ?? 0}",
                        style: Theme.of(context).textTheme.headlineMedium,
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: logic.count1add,
            child: const Icon(Icons.exposure_plus_1),
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton(
            onPressed: logic.count2sub,
            child: const Icon(Icons.exposure_minus_1),
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton(
            onPressed: logic.count3sub,
            child: const Icon(Icons.exposure_minus_2),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
