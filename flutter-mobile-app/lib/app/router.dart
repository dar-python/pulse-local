import 'package:flutter/widgets.dart';

import '../features/checkout_risk/presentation/screens/checkout_risk_screen.dart';

class AppRouter {
  const AppRouter._();

  static Widget get home => const CheckoutRiskScreen();
}
