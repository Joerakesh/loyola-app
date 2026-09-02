import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/services/auth_provider.dart';
import 'features/auth/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = SecureStorage();
  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient, storage);
  final authProvider = AuthProvider(authService);

  runApp(
    ChangeNotifierProvider.value(value: authProvider, child: const LoyolaApp()),
  );
}
