import 'package:flutter/material.dart';
import '../viewmodels/counter_viewmodel.dart';
import 'package:provider/provider.dart';

class CounterScreen extends StatelessWidget {
  const CounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CounterViewModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Counter MVVM')),
      body: Center(child: Text('Counter: ${viewModel.counter}')),
      floatingActionButton: FloatingActionButton(
        onPressed: viewModel.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}

