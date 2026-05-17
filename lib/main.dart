import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/router/app_router.dart';
import 'core/constants/app_colors.dart';
import 'firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pedi/core/utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Google Sign-In for Android v7+ flow
  try {
    await GoogleSignIn.instance.initialize(
      serverClientId:
          '847505776831-09pvrec5k6uan1asvbijfkbec0uh04cm.apps.googleusercontent.com',
    );
    logger.i('Google Sign-In initialized successfully');
  } catch (e) {
    logger.e('Google Sign-In initialization failed: $e');
  }

  runApp(const ProviderScope(child: PediApp()));
}

class PediApp extends ConsumerWidget {
  const PediApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pedi',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        primaryColor: AppColors.primaryBlue,
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
