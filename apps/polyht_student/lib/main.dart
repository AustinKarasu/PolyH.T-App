import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/test_list_screen.dart';

void main() {
  runApp(const PolyHtStudentApp());
}

class PolyHtStudentApp extends StatelessWidget {
  const PolyHtStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider()..restoreSession(),
      child: MaterialApp(
        title: 'PolyH.T Student',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            return auth.isAuthenticated ? const TestListScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
