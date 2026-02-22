import 'package:flutter/material.dart';
import 'presentation/auth/login_page.dart';
import 'presentation/main_wrapper.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';

void main() {
  runApp(const NusaApp());
}

class NusaApp extends StatelessWidget {
  const NusaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUSA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: FutureBuilder<bool>(
        future: TokenStorage.hasToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.backgroundColor,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }
          final bool hasToken = snapshot.data ?? false;

          if (hasToken) {
            return const MainWrapper();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}
