import 'dart:async';

import 'package:flutter/widgets.dart';

class BlocEffect<Event> {
  final Key? key;
  final Stream<Event>? stream;

  BlocEffect({Key? key, this.stream}) : key = key ?? UniqueKey();

  factory BlocEffect.cancel({required Key key}) => BlocEffect(key: key);

  factory BlocEffect.fireAndForget(void Function() work) {
    WidgetsBinding.instance?.addPostFrameCallback((_) => work.call());
    return BlocEffect(stream: const Stream.empty());
  }

  @override
  bool operator ==(Object other) => other.runtimeType == runtimeType && other is BlocEffect && key == other.key;

  @override
  int get hashCode => key.hashCode;
}

extension BlocEffectExtensions on BlocEffect {
  BlocEffect cancellable({required Key key}) => BlocEffect(key: key, stream: stream);
}

class BlocReducerResult<State, Event> {
  final State state;
  final List<BlocEffect> effects;

  BlocReducerResult(this.state, this.effects);
}

abstract class BlocReducer<State, Event, Environment> {
  BlocReducerResult<State, List<BlocEffect>> reduce(State state, Event event, Environment environment);
}
