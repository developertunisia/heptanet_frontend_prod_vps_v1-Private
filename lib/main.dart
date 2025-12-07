import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'presentation/viewmodels/email_check_viewmodel.dart';
import 'presentation/viewmodels/register_user_viewmodel.dart';
import 'presentation/viewmodels/authorized_email_viewmodel.dart';
import 'presentation/viewmodels/dashboard/conversations_viewmodel.dart';
import 'data/datasources/user_hive_datasource.dart';
import 'data/datasources/authorized_email_hive_datasource.dart';
import 'data/datasources/settings_hive_datasource.dart';
import 'data/datasources/voice_message_hive_datasource.dart';
import 'data/datasources/signalr_service.dart';
import 'data/repositories/user_repository_impl.dart';
import 'data/repositories/authorized_email_repository_impl.dart';
import 'data/repositories/messaging_repository_impl.dart';
import 'domain/repositories/messaging_repository.dart';
import 'core/routes.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  print('🚀 Initializing Hive...');
  await Hive.initFlutter();
  
  // Initialize Hive datasources
  final userHiveDataSource = UserHiveDataSource();
  await userHiveDataSource.init();
  
  final emailHiveDataSource = AuthorizedEmailHiveDataSource();
  await emailHiveDataSource.init();
  
  final settingsDataSource = SettingsHiveDataSource();
  await settingsDataSource.init();
  
  final voiceCache = VoiceMessageHiveDataSource();
  await voiceCache.init();
  
  print('✅ Hive initialization complete!');
  
  // Create repositories with caching
  final userRepository = UserRepositoryImpl(
    hiveDataSource: userHiveDataSource,
    settingsDataSource: settingsDataSource,
  );
  
  final emailRepository = AuthorizedEmailRepositoryImpl(
    hiveDataSource: emailHiveDataSource,
    settingsDataSource: settingsDataSource,
  );
  
  // Initialize SignalR service (singleton)
  final signalRService = SignalRService();
  
  // Create messaging repository
  final messagingRepository = MessagingRepositoryImpl(
    signalRService: signalRService,
  );
  
  runApp(
    MultiProvider(
      providers: [
        // Provide datasources for direct access if needed
        Provider<UserHiveDataSource>.value(value: userHiveDataSource),
        Provider<AuthorizedEmailHiveDataSource>.value(value: emailHiveDataSource),
        Provider<SettingsHiveDataSource>.value(value: settingsDataSource),
        
        // Provide SignalR service
        Provider<SignalRService>.value(value: signalRService),
        
        // Provide repositories
        Provider<UserRepositoryImpl>.value(value: userRepository),
        Provider<AuthorizedEmailRepositoryImpl>.value(value: emailRepository),
        Provider<MessagingRepository>.value(value: messagingRepository),
        
        // ViewModels (properly injected with repositories)
        ChangeNotifierProvider(create: (_) => EmailCheckViewModel()),
        ChangeNotifierProvider(
          create: (_) => RegisterUserViewModel(repository: userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthorizedEmailViewModel(repository: emailRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ConversationsViewModel(repository: messagingRepository),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HeptaNet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black87,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          tertiary: Colors.grey,
          onTertiary: Colors.black,
          shadow: Colors.black12,
          surfaceContainerHighest: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.black, width: 2),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
        ),
      ),
      // ✅ Utilisation des routes centralisées
      initialRoute: AppRoutes.splash, // ou AppRoutes.emailCheck selon votre besoin
      routes: AppRoutes.routes,
    );
  }
}