import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/app_state_provider.dart';
import 'providers/batch_provider.dart';
import 'providers/session_provider.dart';
import 'providers/logging_provider.dart';
import 'screens/splash_screen.dart';
import 'utils/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  runApp(const BatchMateApp());
}

class BatchMateApp extends StatelessWidget {
  const BatchMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => BatchProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => LoggingProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appStateProvider, child) {
          return MaterialApp(
            title: 'BatchMate',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: AppColors.textColorLight,
                secondary: AppColors.secondary,
                onSecondary: AppColors.textColorLight,
                surface: AppColors.surfaceLight,
                onSurface: AppColors.onSurfaceLight,
                error: AppColors.error,
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: AppColors.backgroundLight,
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: AppColors.surfaceLight,
                foregroundColor: AppColors.textColorLight,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: AppColors.textColorLight,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.buttonText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              cardTheme: const CardThemeData(
                color: AppColors.cardBackgroundLight,
                elevation: 4,
                shadowColor: AppColors.cardShadow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                onPrimary: AppColors.textColorDark,
                secondary: AppColors.secondary,
                onSecondary: AppColors.textColorDark,
                surface: AppColors.surfaceDark,
                onSurface: AppColors.onSurfaceDark,
                error: AppColors.error,
                onError: Colors.white,
              ),
              scaffoldBackgroundColor: AppColors.backgroundDark,
              appBarTheme: AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: AppColors.surfaceDark,
                foregroundColor: AppColors.textColorDark,
                surfaceTintColor: Colors.transparent,
                titleTextStyle: TextStyle(
                  color: AppColors.textColorDark,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor,
                  foregroundColor: AppColors.buttonText,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
              ),
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.buttonText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              cardTheme: const CardThemeData(
                color: AppColors.cardBackgroundDark,
                elevation: 6,
                shadowColor: AppColors.cardShadowDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            themeMode: ThemeMode.dark, // Default to professional dark theme
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
