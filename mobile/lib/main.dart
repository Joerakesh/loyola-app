import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/auth/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorage();
  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient, storage);
  final authProvider = AuthProvider(authService);

  final appRouter = AppRouter(apiClient);

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: LoyolaApp(appRouter: appRouter),
    ),
  );
}
