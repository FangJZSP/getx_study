import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NavUtils {
  static Future showNormalDialog({
    required String routeName,
    Widget? child,
    var routeNodeArguments,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    bool useSafeArea = true,
  }) {
    // todo dialog参数合法化
    return Get.dialog(
      child ?? defaultChild(routeName + Get.arguments.toString()),
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black.withOpacity(0.5),
      routeSettings:
          RouteSettings(name: routeName, arguments: routeNodeArguments),
    );
  }

  static Widget defaultChild(String arguments) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          color: Colors.redAccent,
          child: GestureDetector(
            child: Text(arguments),
            onTap: () => Get.back(),
          ),
        ),
      ),
    );
  }
}
