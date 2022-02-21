import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'core.dart';

extension StreamEffect<S> on Stream<S> {
  BlocEffect<Event> asEffect<Event>({Key? key}) => BlocEffect<Event>(key: key, stream: this as Stream<Event>);

  BlocEffect<Event> mapResultToEffect<Event>(Event Function(S) convert) => map<Event>((e) => convert(e)).asEffect();
}

extension FutureEffect<S> on Future<S> {
  BlocEffect<Event> asEffect<Event>({Key? key}) => asStream().asEffect(key: key);

  BlocEffect<Event> mapResultToEffect<Event>(Event Function(S) transformer) =>
      asStream().mapResultToEffect(transformer);
}

extension StreamExtension<T> on Stream<T?> {
  Stream<T> unwrap() => where((e) => e != null).map((e) => e!);
}

extension FutureExtension<T> on Future<T?> {
  Stream<T> unwrapAsStream() => asStream().unwrap();
}

EventTransformer<Event> debounce<Event>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);
