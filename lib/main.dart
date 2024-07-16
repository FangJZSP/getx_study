import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:getx_study/tools/router_helper.dart';

import 'route/routers.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GetX Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      initialRoute: '/',
      getPages: Routers.getPages,
      routingCallback: (r) {
        RouterHelper.collectRouters(r);
      },
    );
  }
}
