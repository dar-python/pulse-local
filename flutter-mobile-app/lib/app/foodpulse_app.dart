import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/auth/auth_api_service.dart';
import '../features/auth/login_screen.dart';

class FoodPulseApp extends StatelessWidget {
  const FoodPulseApp({super.key, this.authApiService});

  final AuthApiService? authApiService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FoodPulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: LoginScreen(authApiService: authApiService),
    );
  }
}
