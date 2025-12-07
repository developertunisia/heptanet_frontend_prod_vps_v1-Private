import 'package:flutter/material.dart';
import '../../data/repository.dart';

class CounterViewModel extends ChangeNotifier {
  final CounterRepository _repository = CounterRepository();

  int get counter => _repository.counter.value;

  void increment() {
    _repository.increment();
    notifyListeners();
  }
}
