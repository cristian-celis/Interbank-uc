import 'app_dependencies.dart';

AppDependencies buildAppDependencies() {
  const dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'api',
  );
  const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8003',
  );

  return switch (dataSource) {
    'api' => AppDependencies.coreMobileApi(baseUrl: apiBaseUrl),
    _ => AppDependencies.mock(),
  };
}
