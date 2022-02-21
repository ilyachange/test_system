import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:test_system/example/example_bloc.dart';

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ExampleBloc>(
      create: (context) => ExampleBloc(
        environment: ExampleEnvironment(
          _eventStreamExample,
          () => _oneUiShotExample(context),
          () => _navigationExample(context),
          (input) => _navigationWithResultExample(context, input),
          (message) => _showMessage(context, message),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(),
        body: BlocBuilder<ExampleBloc, ExampleState>(builder: (context, state) => _TestWidget(state)),
      ),
    );
  }
}

class _TestWidget extends StatelessWidget {
  final ExampleState state;

  const _TestWidget(this.state);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Text('Future handling example'),
          state.loading
              ? const CircularProgressIndicator()
              : TextButton(
                  onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidSelectLoad()),
                  child: const Text('Start loading'),
                ),
          const Divider(),
          const Text('Continuous stream with completion example. Includes cancellation'),
          TextButton(
            onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidToggleTimer(!state.isTimerRunning)),
            child: Text(state.isTimerRunning ? 'Stop timer' : 'Start timer'),
          ),
          Text('Timer: ${state.secondsRemaining}'),
          const Divider(),
          TextButton(
            onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidSelectOneUiShot()),
            child: const Text('One shot ui example'),
          ),
          const Divider(),
          TextButton(
            onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidSelectNavigation()),
            child: const Text('Navigation example'),
          ),
          const Divider(),
          TextButton(
            onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidSelectNavigationWithResult()),
            child: const Text('Navigation with result example'),
          ),
          Text('Navigation counter: ${state.navigationCounter}'),
          const Divider(),
          TextButton(
            onPressed: () => context.read<ExampleBloc>().add(ExampleEventUserDidSelectToggle()),
            child: const Text('Debounce example, 2 seconds'),
          ),
          Text('Toggled: ${state.toggle}'),
          const Divider(),
        ],
      ),
    );
  }
}

// These can be taken from Injector, for this example just functions
Stream<int> _eventStreamExample(int seconds) => Stream<int>.periodic(const Duration(seconds: 1), (x) => seconds - x - 1 ).take(seconds);

// UI stuff
void _showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

void _oneUiShotExample(BuildContext context) => _showMessage(context, 'One ui shot');

Future<void> _navigationExample(BuildContext context) async {
  return Navigator.push<void>(context, MaterialPageRoute(builder: (context) {
    return Scaffold(
        appBar: AppBar(
      leading: CloseButton(
        onPressed: () => Navigator.pop(context),
      ),
    ));
  }));
}

Future<int?> _navigationWithResultExample(BuildContext context, int input) async {
  return Navigator.push<int?>(context, MaterialPageRoute(builder: (context) {
    return Scaffold(
        appBar: AppBar(
          leading: CloseButton(
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
            child: Column(
          children: [
            TextButton(
                onPressed: () => Navigator.pop(context, input + 1), child: Text('Press me to return ${input + 1}'))
          ],
        )));
  }));
}
