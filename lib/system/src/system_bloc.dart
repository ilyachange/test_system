import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'system.dart';

class SystemBloc<State, Event, Environment> extends Bloc<Event, State> {
  final Environment _environment;
  final Reducer<State, Event, Environment> _reducer;
  final Map<Effect, StreamSubscription> _effectsMap = {};

  SystemBloc({
    required State initialState,
    required Environment environment,
    required Reducer<State, Event, Environment> reducer,
  })  : _environment = environment,
        _reducer = reducer,
        super(initialState) {
    on<Event>(_dispatchEvent);
  }

  void _dispatchEvent(Event event, Emitter emit) {
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
