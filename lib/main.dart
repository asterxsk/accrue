import 'package:flutter/material.dart';

import 'app.dart';
import 'util/app_version.dart';
import 'state/habit_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppVersion.load();
  final store = await HabitStore.load();
  runApp(HabitApp(store: store));
}
