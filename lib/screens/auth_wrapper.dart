import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        if (auth.isLoading) {
          // If still checking session after splash screen, show a simple loader
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (auth.isAuthenticated) {
          return const HomeScreen();
        }
        
        return const AuthScreen();
      },
    );
  }
}
