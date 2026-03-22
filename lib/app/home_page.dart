import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:duckmouth/core/di/service_locator.dart';
import 'package:duckmouth/features/recording/ui/recording_controls.dart';
import 'package:duckmouth/features/recording/ui/recording_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<RecordingCubit>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Duckmouth'),
        ),
        body: const Center(
          child: RecordingControls(),
        ),
      ),
    );
  }
}
