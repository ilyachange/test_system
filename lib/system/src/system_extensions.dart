import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import 'system.dart';

extension StreamEffect on Stream {
  Effect asEffect<Event>({Key? key}) => Effect(key: key, stream: this);

  Effect mapResultToEffect<Event>(Event Function(dynamic) transformer) => map((e) => transformer(e)).asEffect();
}

extension FutureEffect on Future {
  Effect asEffect<Event>({Key? key}) => asStream().asEffect(key: key);

  Effect mapResultToEffect<Event>(Event Function(dynamic) transformer) => asStream().mapResultToEffect(transformer);
}

extension StreamExtension on Stream {
  Stream<T> unwrap<T>() => where((e) => e != null).map((e) => e!);
}

extension FutureExtension on Future {
  Stream<T> unwrapAsStream<T>() => asStream().unwrap();
}

EventTransformer<Event> debounce<Event>(Duration duration) =>
    (events, mapper) => events.debounceTime(duration).switchMap(mapper);
