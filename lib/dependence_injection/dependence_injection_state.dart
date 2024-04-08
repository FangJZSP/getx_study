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

  /// 实体类
  Rxn<Cat> cat1 = Rxn<Cat>();
  Rx<Cat> cat2 = Cat.fromJson({}).obs;
  Rx<Cat> cat3 = Cat().obs;

  DependenceInjectionState() {
    ///Initialize variables
  }
}

class Cat {
  String? name;
  int? age;

  Cat({this.age, this.name});

  Cat.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    age = json['age'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = name;
    data['age'] = age;
    return data;
  }
}
