import 'package:flutter/material.dart';

class BroadcastStat {
  const BroadcastStat({
    required this.title,
    required this.value,
    this.icon = Icons.wifi_tethering,
  });

  final String title;
  final String value;
  final IconData icon;
}

class BroadcastViewModel extends ChangeNotifier {
  final List<BroadcastStat> _stats = [];

  List<BroadcastStat> get stats => List.unmodifiable(_stats);

  void setStats(List<BroadcastStat> stats) {
    _stats
      ..clear()
      ..addAll(stats);
    notifyListeners();
  }

  void clear() {
    if (_stats.isEmpty) return;
    _stats.clear();
    notifyListeners();
  }
}
