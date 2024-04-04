import 'package:get/get.dart';

class DependenceInjectionState {
  String count1Id = "count1Id";
  //RxInt count1 = RxInt(0);
  /// .obs 语法糖
  RxInt count1 = 0.obs;

  String count2Id = "count2Id";
  int count2 = 0;

  String count3Id = "count3Id";
  int count3 = 100;

  DependenceInjectionState() {
    ///Initialize variables
  }
}
