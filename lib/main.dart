import 'package:flutter/material.dart';

import 'app/customer_banking_app.dart';
import 'app/dependency_bootstrap.dart';

void main() {
  runApp(CustomerBankingApp(dependencies: buildAppDependencies()));
}
