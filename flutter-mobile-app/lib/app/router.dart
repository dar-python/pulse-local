import 'package:flutter/widgets.dart';

import '../features/auth/login_screen.dart';

class AppRouter {
  const AppRouter._();

  static Widget get home => const LoginScreen();
}
