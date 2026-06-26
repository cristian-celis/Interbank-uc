import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/sales/presentation/sales_home_page.dart';

class SalesShell extends StatelessWidget {
  const SalesShell({super.key, required this.dependencies, required this.user});

  final AppDependencies dependencies;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return SalesHomePage(dependencies: dependencies, user: user);
  }
}
