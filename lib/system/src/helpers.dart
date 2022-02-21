import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'core.dart';

extension StreamEffect<S> on Stream<S> {
  BlocEffect<E> asEffect<E>({Key? key}) => BlocEffect<E>(key: key, stream: this as Stream<E>);

  BlocEffect<E> mapResultToEffect<E>(E Function(S) convert) => map<E>((e) => convert(e)).asEffect();
}

extension FutureEffect<S> on Future<S> {
  BlocEffect<E> asEffect<E>({Key? key}) => asStream().asEffect(key: key);

  BlocEffect<E> mapResultToEffect<E>(E Function(S) transformer) => asStream().mapResultToEffect(transformer);
}

extension StreamExtension<T> on Stream<T?> {
  Stream<T> unwrap() => where((e) => e != null).map((e) => e!);
}

extension FutureExtension<T> on Future<T?> {
  Stream<T> unwrapAsStream() => asStream().unwrap();
}

extension CombineExtension<S, E, Env> on BlocReducer<S, E, Env> {
  BlocReducer<S, E, Env> combine(BlocReducer<S, E, Env> reducer) => _CombinableBlocReducer(this, reducer);
}

class _CombinableBlocReducer<S, E, Env> extends BlocReducer<S, E, Env> {
  final BlocReducer<S, E, Env> _reducer1;
  final BlocReducer<S, E, Env> _reducer2;

  _CombinableBlocReducer(this._reducer1, this._reducer2);

  @override
  BlocReducerResult<S, E> reduce(S state, E event, Env environment) {
    final result1 = _reducer1.reduce(state, event, environment);
    final result2 = _reducer2.reduce(result1.state, event, environment);
    return BlocReducerResult(result2.state, [...result1.effects, ...result2.effects]);
  }
}

EventTransformer<E> debounce<E>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);
