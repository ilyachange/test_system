import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'core.dart';

class ReducibleBloc<S, E, Env> extends Bloc<E, S> {
  final Env _environment;
  final BlocReducer<S, E, Env> _reducer;
  final Map<BlocEffect<E>, StreamSubscription> _effectsMap = <BlocEffect<E>, StreamSubscription>{};

  ReducibleBloc({
    required S initialState,
    required Env environment,
    required BlocReducer<S, E, Env> reducer,
  })  : _environment = environment,
        _reducer = reducer,
        super(initialState);

  void onReducible<Event extends E>({
    EventTransformer<Event>? transformer,
  }) =>
      super.on<Event>(_handler, transformer: transformer);

  @override
  void on<Event extends E>(
    EventHandler<Event, S> handler, {
    EventTransformer<Event>? transformer,
  }) {
    assert((false), 'on<Event>() not allowed in this class, use onReducible<Event>()');
  }

  void _handler(E event, Emitter emit) {
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
