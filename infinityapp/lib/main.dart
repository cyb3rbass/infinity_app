import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'welcomePage.dart';
import 'startingPage.dart';
import 'login.dart';
import 'register.dart';
import 'homePage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Function to check if user is logged in by checking for a token
  Future<String> _getInitialRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty ? '/home' : '/';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getInitialRoute(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading screen while checking login status
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Set the initial route based on login status
        final initialRoute = snapshot.data ?? '/';

        return MaterialApp(
          title: 'Infinity Courses',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            fontFamily: 'Poppins',
          ),
          initialRoute: initialRoute,
          routes: {
            '/': (_) => const WelcomePage(),
            '/starting': (_) => const StartingPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegistrationPage(),
            '/home': (_) => const HomePage(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}