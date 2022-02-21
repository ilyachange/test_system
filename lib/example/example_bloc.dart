import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../system/reducible_bloc.dart';

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

class ExampleEventUserDidSelectToggle extends ExampleEvent {
  @override
  List<Object?> get props => [];
}

@CopyWith()
class ExampleState extends Equatable {
  final bool loading;
  final bool isTimerRunning;
  final int secondsRemaining;
  final int navigationCounter;
  final bool toggle;

  const ExampleState({
    this.loading = false,
    this.isTimerRunning = false,
    this.secondsRemaining = 0,
    this.navigationCounter = 0,
    this.toggle = false,
  });

  @override
  List<Object?> get props => [
        loading,
        isTimerRunning,
        secondsRemaining,
        navigationCounter,
        toggle,
      ];
}

class ExampleEnvironment {
  Stream<int> Function(int seconds) getTimer;
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

class ExampleBloc extends ReducibleBloc<ExampleState, ExampleEvent, ExampleEnvironment> {
  ExampleBloc({required ExampleEnvironment environment})
      : super(
          initialState: const ExampleState(),
          environment: environment,
          reducer: _ExampleReducer(),
        ) {
    onReducible<ExampleEventUserDidSelectLoad>();
    onReducible<ExampleEventDidLoad>();
    onReducible<ExampleEventUserDidToggleTimer>();
    onReducible<ExampleEventTimerDidUpdate>();
    onReducible<ExampleEventTimerDidComplete>();
    onReducible<ExampleEventUserDidSelectOneUiShot>();
    onReducible<ExampleEventUserDidSelectNavigation>();
    onReducible<ExampleEventUserDidEndNavigation>();
    onReducible<ExampleEventUserDidSelectNavigationWithResult>();
    onReducible<ExampleEventUserDidEndNavigationWithResult>();
    onReducible<ExampleEventUserDidSelectToggle>(transformer: debounce(const Duration(seconds: 2))); // debounce

    // or handle all events on a base class if no need for specific concurrency transformers
    // onReducible<ExampleEvent>();
  }
}

const _timerKey = Key('timerKey');
const _timerSeconds = 10;

class _ExampleReducer extends BlocReducer<ExampleState, ExampleEvent, ExampleEnvironment> {
  @override
  BlocReducerResult<ExampleState, ExampleEvent> reduce(
      ExampleState state, ExampleEvent event, ExampleEnvironment environment) {
    // Future example
    if (event is ExampleEventUserDidSelectLoad) {
      return BlocReducerResult(state.copyWith(loading: true),
          [Future.delayed(const Duration(seconds: 3)).mapResultToEffect((_) => ExampleEventDidLoad())]);
    }

    if (event is ExampleEventDidLoad) {
      return BlocReducerResult(state.copyWith(loading: false), []);
    }
    //

    // Event stream example
    if (event is ExampleEventUserDidToggleTimer) {
      return BlocReducerResult(
        state.copyWith(isTimerRunning: event.start, secondsRemaining: event.start ? _timerSeconds : 0),
        [
          BlocEffect.cancel(key: _timerKey), // ensure cancelling the running timer effect by key
          if (event.start) // example of filling arrays without empty data
            environment
                .getTimer(_timerSeconds)
                // here we map stream events to bloc ones
                .mapResultToEffect(
                    (counter) => counter == 0 ? ExampleEventTimerDidComplete() : ExampleEventTimerDidUpdate(counter))
                .cancellable(key: _timerKey) // effect with cancellation key
        ],
      );
    }

    if (event is ExampleEventTimerDidUpdate) {
      return BlocReducerResult(state.copyWith(secondsRemaining: event.secondsRemaining), []);
    }

    if (event is ExampleEventTimerDidComplete) {
      return BlocReducerResult(state.copyWith(isTimerRunning: false, secondsRemaining: 0), []);
    }
    //

    // One ui shot example
    if (event is ExampleEventUserDidSelectOneUiShot) {
      return BlocReducerResult(state, [BlocEffect.fireAndForget(() => environment.getOneUiShot())]);
    }
    //

    // Navigation example
    if (event is ExampleEventUserDidSelectNavigation) {
      return BlocReducerResult(state, [
        environment.getNavigation().mapResultToEffect((_) => ExampleEventUserDidEndNavigation()),
      ]);
    }

    if (event is ExampleEventUserDidEndNavigation) {
      return BlocReducerResult(
          state, [BlocEffect.fireAndForget(() => environment.getShowMessage('Back from navigation'))]);
    }
    //

    // Navigation with result example
    if (event is ExampleEventUserDidSelectNavigationWithResult) {
      return BlocReducerResult(state, [
        environment
            .getNavigationWithResult(state.navigationCounter)
            .unwrapAsStream()
            .mapResultToEffect((result) => ExampleEventUserDidEndNavigationWithResult(result))
      ]);
    }

    if (event is ExampleEventUserDidEndNavigationWithResult) {
      return BlocReducerResult(state.copyWith(navigationCounter: event.result), []);
    }
    //

    // debounce example
    if (event is ExampleEventUserDidSelectToggle) {
      return BlocReducerResult(state.copyWith(toggle: !state.toggle), []);
    }
    //

    return BlocReducerResult(state, []);
  }
}
