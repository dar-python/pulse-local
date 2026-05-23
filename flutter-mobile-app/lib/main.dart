import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app/foodpulse_app.dart';
import 'features/auth/demo_account.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env", isOptional: true);
  await DemoAccount.load();

  runApp(const FoodPulseApp());
}
