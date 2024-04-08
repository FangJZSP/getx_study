import 'dart:async';

Stream<int> numberStream = Stream.fromIterable([1, 2, 3, 4, 5]);

StreamSubscription? numberSubscription;

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

void main() {
  handleSubscription();
}
