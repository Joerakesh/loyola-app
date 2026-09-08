import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/app_router.dart';
import 'core/firebase/firebase_init.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'services/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/google_auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initialiseFirebase();

  final storage = SecureStorage();
  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient, storage);
  final googleAuthService = GoogleAuthService();
  final authProvider = AuthProvider(authService, googleAuthService);

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