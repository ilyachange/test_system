import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:quiver/async.dart';

import '../system/system.dart';

part 'example_bloc.g.dart';

abstract class ExampleEvent extends Equatable {}

class ExampleEventUserDidSelectLoad extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventDidLoad extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventTimerDidUpdate extends ExampleEvent {
  final int secondsRemaining;

  ExampleEventTimerDidUpdate(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class ExampleEventTimerDidComplete extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventUserDidToggleTimer extends ExampleEvent {
  final bool start;

  ExampleEventUserDidToggleTimer(this.start);

  @override
  List<Object?> get props => [start];
}

class ExampleEventUserDidSelectOneUiShot extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventUserDidSelectNavigation extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventUserDidEndNavigation extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventUserDidSelectNavigationWithResult extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

class ExampleEventUserDidEndNavigationWithResult extends ExampleEvent {
  final int result;

  ExampleEventUserDidEndNavigationWithResult(this.result);

  @override
  List<Object?> get props => [result];
}

@CopyWith()
class ExampleState extends Equatable {
  final bool loading;
  final bool isTimerRunning;
  final int secondsRemaining;
  final int navigationCounter;

  const ExampleState({
    this.loading = false,
    this.isTimerRunning = false,
    this.secondsRemaining = 0,
    this.navigationCounter = 0,
  });

  @override
  List<Object?> get props => [
        loading,
        isTimerRunning,
        secondsRemaining,
        navigationCounter,
      ];
}

class ExampleEnvironment {
  Stream<CountdownTimer> Function(int seconds) getTimer;
  void Function() getOneUiShot;
  Future<void> Function() getNavigation;
  Future<int?> Function(int input) getNavigationWithResult;
  void Function(String) getShowMessage;

  ExampleEnvironment(
    this.getTimer,
    this.getOneUiShot,
    this.getNavigation,
    this.getNavigationWithResult,
    this.getShowMessage,
  );
}

class ExampleBloc extends SystemBloc<ExampleState, ExampleEvent, ExampleEnvironment> {
  ExampleBloc({required ExampleEnvironment environment})
      : super(
          initialState: const ExampleState(),
          environment: environment,
          reducer: _ExampleReducer(),
        );
}

const _timerKey = Key('timerKey');
const _timerSeconds = 10;

class _ExampleReducer extends Reducer<ExampleState, ExampleEvent, ExampleEnvironment> {
  @override
  ReducerResult<ExampleState, List<Effect>> reduce(
      ExampleState state, ExampleEvent event, ExampleEnvironment environment) {
    // Future example
    if (event is ExampleEventUserDidSelectLoad) {
      return ReducerResult(state.copyWith(loading: true),
          [Future.delayed(const Duration(seconds: 3)).mapResultToEffect((_) => ExampleEventDidLoad())]);
    }

    if (event is ExampleEventDidLoad) {
      return ReducerResult(state.copyWith(loading: false), []);
    }
    //

    // Event stream example
    if (event is ExampleEventUserDidToggleTimer) {
      return ReducerResult(
        state.copyWith(isTimerRunning: event.start, secondsRemaining: event.start ? _timerSeconds : 0),
        [
          Effect.cancel(key: _timerKey), // ensure cancelling the running timer effect by key
          if (event.start) // example of filling arrays without empty data
            environment
                .getTimer(_timerSeconds)
                // here we map stream events to bloc ones
                .mapResultToEffect((timer) => timer.remaining.inSeconds == 0
                    ? ExampleEventTimerDidComplete()
                    : ExampleEventTimerDidUpdate(timer.remaining.inSeconds))
                .cancellable(key: _timerKey) // effect with cancellation key
        ],
      );
    }

    if (event is ExampleEventTimerDidUpdate) {
      return ReducerResult(state.copyWith(secondsRemaining: event.secondsRemaining), []);
    }

    if (event is ExampleEventTimerDidComplete) {
      return ReducerResult(state.copyWith(isTimerRunning: false, secondsRemaining: 0), []);
    }
    //

    // One ui shot example
    if (event is ExampleEventUserDidSelectOneUiShot) {
      return ReducerResult(state, [Effect.fireAndForget(() => environment.getOneUiShot())]);
    }
    //

    // Navigation example
    if (event is ExampleEventUserDidSelectNavigation) {
      return ReducerResult(state, [
        environment.getNavigation().mapResultToEffect((_) => ExampleEventUserDidEndNavigation()),
      ]);
    }

    if (event is ExampleEventUserDidEndNavigation) {
      return ReducerResult(state, [Effect.fireAndForget(() => environment.getShowMessage('Back from navigation'))]);
    }
    //

    // Navigation with result example
    if (event is ExampleEventUserDidSelectNavigationWithResult) {
      return ReducerResult(state, [
        environment
            .getNavigationWithResult(state.navigationCounter)
            .unwrapAsStream()
            .mapResultToEffect((result) => ExampleEventUserDidEndNavigationWithResult(result))
      ]);
    }

    if (event is ExampleEventUserDidEndNavigationWithResult) {
      return ReducerResult(state.copyWith(navigationCounter: event.result), []);
    }
    //

    return ReducerResult(state, []);
  }
}
