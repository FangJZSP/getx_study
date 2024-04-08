import 'dart:async';

// 创建 StreamController
StreamController<int> controller = StreamController<int>();

// 从 StreamController 获取 Stream
Stream<int> numberStream = controller.stream;

StreamSubscription<int>? numberSubscription;

void onData(int number) {
  print('Number: $number');
}

void onError(Object error, StackTrace stackTrace) {
  print('Got an error: $error');
}

void onDone() {
  print('Stream has been closed');
}

void handleSubscription() {
  numberSubscription = numberStream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: false,
  );
}

Future<void> main() async {
  handleSubscription();

  // 添加数据到 Stream
  for (var i = 1; i <= 5; i++) {
    await Future.delayed(const Duration(seconds: 2));
    controller.sink.add(i);
  }

  Future.delayed(const Duration(seconds: 5), () => controller.sink.add(6));

  // 关闭 StreamController
  //controller.close();
}
