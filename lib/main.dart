import 'package:flutter/material.dart';

import 'app.dart';
import 'state/habit_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await HabitStore.load();
  runApp(HabitApp(store: store));
}
