import 'package:flutter/material.dart';

import '../shared/presentation/login_page.dart';
import 'app_dependencies.dart';
import 'theme/interbank_theme.dart';

class CustomerBankingApp extends StatelessWidget {
  const CustomerBankingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Interbank Clientes',
      theme: InterbankTheme.customer(),
      home: LoginPage(
        dependencies: dependencies,
        destination: LoginDestination.customerBanking,
      ),
    );
  }
}
