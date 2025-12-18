import 'package:ai_powered_learning_application/pages/student_profile.dart';
import 'package:flutter/material.dart';
import '../pages/course_enrollment.dart';
import '../pages/loginpage.dart';
import '../pages/registrationpage.dart';
import '../pages/splashscreen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String register = '/register';
  static const String login = '/login';
  static const String studentprofile = '/studentprofile';
  static const String course_enrollment = '/course_enrollment';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegistrationPage());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case studentprofile:
        final args = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => StudentProfilePage(studentId: args),
        );
      case course_enrollment:
        return MaterialPageRoute(
          builder: (_) =>
              RecommendedCoursesPage(studentId: settings.arguments as String),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
