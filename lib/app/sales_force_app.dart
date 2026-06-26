import 'package:flutter/material.dart';

import '../shared/presentation/login_page.dart';
import 'app_dependencies.dart';
import 'theme/interbank_theme.dart';

class SalesForceApp extends StatelessWidget {
  const SalesForceApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Interbank Ventas',
      theme: InterbankTheme.sales(),
      home: LoginPage(
        dependencies: dependencies,
        destination: LoginDestination.salesForce,
      ),
    );
  }
}
