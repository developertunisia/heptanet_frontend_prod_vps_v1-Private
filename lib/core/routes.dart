import 'package:flutter/material.dart';
import '../domain/models/auth_model.dart';
import '../presentation/views/splash_screen.dart';
import '../presentation/views/login_screen.dart';
import '../presentation/views/home_screen.dart';
import '../presentation/views/forgot_password_screen.dart';
import '../presentation/views/email_check_screen.dart';
import '../presentation/views/register_user_screen.dart';
import '../presentation/views/otp_validation_screen.dart';
import '../presentation/views/counter_screen.dart';
import '../presentation/views/reset_password_screen.dart';
import '../presentation/views/chat/chat_view.dart';

class AppRoutes {
  // ============================================
  // NOMS DES ROUTES (constantes)
  // ============================================
  static const String splash = '/';
  static const String emailCheck = '/email-check';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpValidation = '/otp-validation';
  static const String home = '/home';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String counter = '/counter';
  static const String chat = '/chat';

  // ============================================
  // MAPPING DES ROUTES
  // ============================================
  static Map<String, Widget Function(BuildContext)> get routes {
    return {
      splash: (context) => const SplashScreen(),
      emailCheck: (context) => const EmailCheckScreen(),
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterUserScreen(),
      home: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        final user = args is User ? args : null;
        return HomeScreen(initialUser: user);
      },
      forgotPassword: (context) => const ForgotPasswordScreen(),
      counter: (context) => const CounterScreen(),
      // Route avec paramètres (gérées séparément)
      otpValidation: (context) {
        // Récupérer les arguments passés lors de la navigation
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          return OtpValidationScreen(email: args);
        }
        // Fallback si aucun argument n'est fourni
        throw ArgumentError('Email requis pour OtpValidationScreen');
      },
      resetPassword: (context) {
        // Récupérer les arguments passés lors de la navigation
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          return ResetPasswordScreen(email: args);
        }
        // Fallback si aucun argument n'est fourni
        throw ArgumentError('Email requis pour ResetPasswordScreen');
      },
      chat: (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Map<String, dynamic>) {
          return ChatView(
            conversationId: args['conversationId'] as int,
            conversationName: args['conversationName'] as String?,
          );
        }
        throw ArgumentError('Arguments requis pour ChatView');
      },
    };
  }

  // ============================================
  // MÉTHODES HELPER DE NAVIGATION
  // ============================================

  /// Naviguer vers une nouvelle route (ajoute à la pile)
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  /// Remplacer la route actuelle (remplace dans la pile)
  static Future<T?> pushReplacementNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.pushReplacementNamed<T, Object?>(
      context,
      routeName,
      arguments: arguments,
    );
  }

  /// Remplacer toutes les routes précédentes (nouvelle pile)
  static Future<T?> pushNamedAndRemoveUntil<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool Function(Route<dynamic>)? predicate,
  }) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      routeName,
      predicate ?? (route) => false,
      arguments: arguments,
    );
  }

  /// Retourner à la route précédente
  static void pop<T>(BuildContext context, [T? result]) {
    Navigator.pop<T>(context, result);
  }

  /// Retourner jusqu'à une route spécifique
  static void popUntil(BuildContext context, String routeName) {
    Navigator.popUntil(context, ModalRoute.withName(routeName));
  }

  // ============================================
  // MÉTHODES SPÉCIFIQUES PAR ÉCRAN
  // ============================================

  /// Naviguer vers le Splash Screen (route initiale)
  static Future<void> goToSplash(BuildContext context) {
    return pushNamedAndRemoveUntil(context, splash);
  }

  /// Naviguer vers l'écran de vérification d'email
  static Future<void> goToEmailCheck(BuildContext context) {
    return pushNamedAndRemoveUntil(context, emailCheck);
  }

  /// Naviguer vers l'écran de connexion
  static Future<void> goToLogin(BuildContext context) {
    return pushReplacementNamed(context, login);
  }

  /// Naviguer vers l'écran d'inscription
  static Future<void> goToRegister(BuildContext context, {String? email}) {
    return pushNamed(context, register, arguments: email);
  }

  /// Naviguer vers l'écran de validation OTP avec email
  static Future<void> goToOtpValidation(BuildContext context, String email) {
    return pushNamed(context, otpValidation, arguments: email);
  }

  /// Naviguer vers l'écran d'accueil
  static Future<void> goToHome(BuildContext context, {User? user}) {
    return pushReplacementNamed(context, home, arguments: user);
  }

  /// Naviguer vers l'écran de mot de passe oublié
  static Future<void> goToForgotPassword(BuildContext context) {
    return pushNamed(context, forgotPassword);
  }

  /// Naviguer vers l'écran Counter (exemple)
  static Future<void> goToCounter(BuildContext context) {
    return pushNamed(context, counter);
  }

  /// Naviguer vers l'écran de chat
  static Future<void> goToChat(
    BuildContext context, {
    required int conversationId,
    String? conversationName,
  }) {
    return pushNamed(
      context,
      chat,
      arguments: {
        'conversationId': conversationId,
        'conversationName': conversationName,
      },
    );
  }
}
