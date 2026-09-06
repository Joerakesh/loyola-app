import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_router.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'services/auth_provider.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorage();
  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient, storage);
  final authProvider = AuthProvider(authService);

  final appRouter = AppRouter(
    apiClient: apiClient,
    authProvider: authProvider,
  );

  // Re-evaluate protected routes whenever authentication state changes.
  authProvider.addListener(appRouter.refresh);

  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: LoyolaApp(appRouter: appRouter),
    ),
  );
}