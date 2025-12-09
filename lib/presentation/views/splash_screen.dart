import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../core/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _auth = AuthRepositoryImpl();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    try {
      final isLoggedIn = await _auth.checkAuthStatus().timeout(
        const Duration(seconds: 5),
        onTimeout: () => false,
      );
      if (!mounted) return;
      if (isLoggedIn) {
        try {
          final token = await _auth.getAccessToken();
          if (token != null) {
            final isBlacklisted = await _auth.checkBlacklistStatus(token).timeout(
              const Duration(seconds: 3),
              onTimeout: () => false,
            );
            if (!mounted) return;
            if (!isBlacklisted) {
              AppRoutes.goToHome(context);
              return;
            }
          }
        } catch (e) {
          print('Erreur lors de la vérification blacklist: $e');
        }
      }
    } catch (e) {
      print('Erreur lors de la vérification auth: $e');
    }
    if (!mounted) return;
    AppRoutes.goToLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/image/heptanetlogo_with_desc.png', height: 96),
            const SizedBox(height: 24),
            Text(
              'HeptaNet',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}


