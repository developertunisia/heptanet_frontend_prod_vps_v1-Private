import '../domain/counter_model.dart';

class CounterRepository {
  CounterModel counter = CounterModel();

  void increment() {
    counter.value++;
  }
}
