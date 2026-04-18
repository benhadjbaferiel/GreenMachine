import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recycle_app/pages/worker_page.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/settings_page.dart';
import 'pages/analytics_page.dart';
import 'providers/machine_provider.dart';
import 'providers/notification_provider.dart';
import 'models/login_model.dart';
import 'models/dashboard_model.dart';
import 'providers/settings_provider.dart';
import 'providers/worker_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MachineProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => LoginModel()),
        ChangeNotifierProvider(create: (_) => DashboardPageModel()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()), // Register SettingsProvider
        ChangeNotifierProvider(create: (_) => WorkerProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'My Dashboard App',
            locale: settings.locale, // Localisation simple
            
            // THÈME CLAIR
            themeMode: settings.themeMode, 
            theme: ThemeData(
              useMaterial3: true,
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: const Color(0xFFF8FAFB),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.black87),
              ),
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            ),

            // THÈME SOMBRE (Amélioré)
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primarySwatch: Colors.green,
              scaffoldBackgroundColor: const Color(0xFF0F172A), // Bleu foncé premium
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E293B),
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.white),
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.green,
                brightness: Brightness.dark,
                surface: const Color(0xFF1E293B),
              ),
            ),

            home: const LoginPage(),
            routes: {
              "/login": (context) => const LoginPage(),
              "/dashboard": (context) => const DashboardPage(),
              "/worker": (context) => const WorkerPage(),
              "/settings": (context) => const SettingsPage(),
              "/analytics":(context)=> const AnalyticsPage(),
            },
          );
        },
      ),
    );
  }
}
