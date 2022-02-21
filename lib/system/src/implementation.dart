import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core.dart';

class ReducibleBloc<State, Event, Environment> extends Bloc<Event, State> {
  final Environment _environment;
  final BlocReducer<State, Event, Environment> _reducer;
  final Map<BlocEffect, StreamSubscription> _effectsMap = {};

  ReducibleBloc({
    required State initialState,
    required Environment environment,
    required BlocReducer<State, Event, Environment> reducer,
  })  : _environment = environment,
        _reducer = reducer,
        super(initialState);

  void onReducible<E extends Event>({
    EventTransformer<E>? transformer,
  }) =>
      super.on<E>(_handler, transformer: transformer);

  @override
  void on<E extends Event>(
    EventHandler<E, State> handler, {
    EventTransformer<E>? transformer,
  }) {
    assert((false), 'on<Event>() not allowed in this class, use onReducible<Event>()');
  }

  void _handler(Event event, Emitter emit) {
    final result = _reducer.reduce(super.state, event, _environment);

    // cancel effects
    final cancelledEffects = result.effects.where((e) => e.stream == null);
    for (var e in cancelledEffects) {
      _effectsMap[e]?.cancel();
    }
    _effectsMap.removeWhere((key, _) => cancelledEffects.contains(key));

    // emit state
    emit(result.state);

    // add new effects
    for (var effect in result.effects) {
      final subscription = effect.stream?.listen((event) => add(event));
      if (subscription != null) {
        subscription.onDone(() {
          _effectsMap.removeWhere((key, value) => key == effect);
        });
        _effectsMap[effect] = subscription;
      }
    }
  }

  @override
  Future<void> close() {
    for (var e in _effectsMap.values) {
      e.cancel();
    }
    return super.close();
  }
}
