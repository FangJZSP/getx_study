import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BaseScaffold extends StatefulWidget {
  final String pageTitle;
  final Function()? onTapLeading;
  final Widget? mainContent;

  const BaseScaffold(
      {required this.pageTitle,
      this.onTapLeading,
      this.mainContent,
      super.key});

  @override
  State<BaseScaffold> createState() => _BaseScaffoldState();
}

class _BaseScaffoldState extends State<BaseScaffold> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (widget.onTapLeading != null) {
              widget.onTapLeading?.call();
            } else {
              Get.back();
            }
          },
        ),
      ),
      body: Center(child: widget.mainContent ?? Text('这里空空如也～')),
    );
  }
}
