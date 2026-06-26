import 'package:flutter/material.dart';

import '../../app/app_dependencies.dart';
import '../../features/auth/domain/entities/auth_user.dart';
import '../../features/banking/presentation/customer_home_page.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({
    super.key,
    required this.dependencies,
    required this.user,
  });

  final AppDependencies dependencies;
  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    return CustomerHomePage(dependencies: dependencies, user: user);
  }
}
