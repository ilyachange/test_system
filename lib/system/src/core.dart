import 'dart:async';

import 'package:flutter/widgets.dart';

class BlocEffect<E> {
  final Key? key;
  final Stream<E>? stream;

  BlocEffect({Key? key, this.stream}) : key = key ?? UniqueKey();

  factory BlocEffect.cancel({required Key key}) => BlocEffect<E>(key: key);

  factory BlocEffect.fireAndForget(void Function() work) {
    WidgetsBinding.instance?.addPostFrameCallback((_) => work.call());
    return BlocEffect<E>(stream: const Stream.empty());
  }

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && other is BlocEffect<E> && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

extension BlocEffectExtensions<E> on BlocEffect<E> {
  BlocEffect<E> cancellable({required Key key}) => BlocEffect<E>(key: key, stream: stream);
}

class BlocReducerResult<S, E> {
  final S state;
  final List<BlocEffect<E>> effects;

  BlocReducerResult(this.state, this.effects);
}

abstract class BlocReducer<S, E, Env> {
  BlocReducerResult<S, E> reduce(S state, E event, Env environment);
}
