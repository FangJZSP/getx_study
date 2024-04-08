#### Stream 和 StreamSubscription的关系

`Stream` 和 `StreamSubscription` 是 Dart 异步编程中非常重要的两个概念，它们在实现异步数据流处理上发挥着关键的作用。

`Stream` 是 Dart
中的一种异步数据流，它可以发出多个值（也可能是零个值），并且这些值在时间上是分离的。也就是说，你可以在任何时间点从 `Stream`
中获取一个新的值，不需要等待它计算完成。这对于处理如用户输入或网络请求等事件驱动型的数据非常有用。

`StreamSubscription` 是订阅了 `Stream` 的对象，当你订阅一个 `Stream`
时，会返回一个 `StreamSubscription` 实例，这个实例包含了你可以操作这个订阅的很多方法，如：

- `cancel()`：退出订阅, 不再接收新的数据事件
- `pause([Future? resumeSignal])`：暂停订阅, 直到调用 `resume()` 或者 `resumeSignal` 完成
- `resume()`：恢复订阅，再次开始接收新的数据事件。

所以可以说，`Stream` 和 `StreamSubscription` 是相互关联的，`Stream`
负责数据的生成和发送，而 `StreamSubscription` 负责数据的接收和处理，并且可以控制接收数据的流程（如暂停和恢复）。

#### FutureOr

FutureOr<T> 在 Dart 语言中是一个特殊的类型，表示一个值可以是一个 Future<T>，也可以是 T 类型的一个直接值。

当你编写异步函数时，传统的做法是返回一个 Future<T>
，这样调用者就知道要等待这个值的计算完成。但是在某些情况下，你可能已经有了一个直接的值，而不需要进行异步计算。在这种情况下，你可能想直接返回这个值，而不是将其包装在
Future 中。
FutureOr<T> 允许你做到这一点。例如，你可以有一个函数，它的返回类型是 FutureOr<int>。这个函数有时会返回一个
Future<int>，有时会直接返回一个 int 的值。这对于编写灵活的 API 和提高性能（避免不必要的异步操作）很有用。
例如：

```dart
import 'dart:async';

FutureOr<int> getNum() {
  if (SomeCondition) {
    return Future.delayed(Duration(seconds: 2), () {
      return 42;
    });
  } else {
    return 42;
  }
}
```

在上述示例中，getNum 函数可以根据条件返回一个 Future<int> 或一个直接的 int 值，另一个函数调用 getNum
可以用 await 来处理得到的值，无论它是否是 Future。