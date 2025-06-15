// lib/main.dart
import 'package:flutter/material.dart';
import 'welcomePage.dart';
import 'startingPage.dart';
import 'login.dart';
import 'register.dart';
import 'homePage.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity Courses',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/',
      routes: {
        '/':        (_) => const WelcomePage(),
        '/starting':(_) => const StartingPage(),
        '/login':   (_) => const LoginPage(),
        '/register':(_) => const RegistrationPage(),
        '/home':    (_) => const HomePage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
//marwan is sexy af
