import 'package:flutter/material.dart';

import 'app/dependency_bootstrap.dart';
import 'app/sales_force_app.dart';

void main() {
  runApp(SalesForceApp(dependencies: buildAppDependencies()));
}
