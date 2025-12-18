import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/provider.dart';
import 'routes/routes.dart';

class NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child; // removes Android glow
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiKey = String.fromEnvironment('API_KEY');
  if (apiKey.isEmpty) {
    print("❌ ERROR: API_KEY not provided. Use --dart-define=API_KEY=your_key");
  }

  try {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        authDomain: "ai-powered-app-9f8f5.firebaseapp.com",
        appId: "1:1008440496133:web:3561214bf7ba63548c8c6c",
        measurementId: "G-SQGHDB2386",
        messagingSenderId: "1008440496133",
        projectId: "ai-powered-app-9f8f5",
        storageBucket: "ai-powered-app-9f8f5.firebasestorage.app",
      ),
    );
    print("✅ Firebase initialized successfully.");
  } catch (e) {
    print("❌ Firebase initialization error: $e");
  }

  runApp(const AppRoot());
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Learning App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      scrollBehavior: NoGlowScrollBehavior(),
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
