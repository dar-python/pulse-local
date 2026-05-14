import 'package:flutter/material.dart';

import 'router.dart';
import 'theme.dart';

class PulseLocalApp extends StatelessWidget {
  const PulseLocalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PulseLocal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppRouter.home,
    );
  }
}
