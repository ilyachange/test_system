import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Effect<Event> extends Equatable {
  final Key? key;
  final Stream<Event>? stream;

  Effect({Key? key, this.stream}) : key = key ?? Key(_uuid.v1().toString());

  factory Effect.cancel({required Key key}) => Effect(key: key);

  factory Effect.fireAndForget(void Function() work) {
    work.call();
    return Effect(stream: const Stream.empty());
  }

  @override
  List<Object?> get props => [key];
}

extension EffectExtensions on Effect {
  Effect cancellable({required Key key}) => Effect(key: key, stream: stream);
}

class ReducerResult<State, Event> {
  final State state;
  final List<Effect> effects;

  ReducerResult(this.state, this.effects);
}

abstract class Reducer<State, Event, Environment> {
  ReducerResult<State, List<Effect>> reduce(State state, Event event, Environment environment);
}
