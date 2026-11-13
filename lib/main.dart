import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MarabuntaIntranetApp());
}

class MarabuntaIntranetApp extends StatefulWidget {
  const MarabuntaIntranetApp({super.key});

  @override
  State<MarabuntaIntranetApp> createState() => _MarabuntaIntranetAppState();
}

class _MarabuntaIntranetAppState extends State<MarabuntaIntranetApp> {
  final AuthService _authService = AuthService();
  bool _authenticated = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Intranet Marabunta R.L.',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFFF59E0B),
        useMaterial3: true,
      ),
      home: _authenticated
          ? HomeScreen(
              authService: _authService,
              onSignedOut: () => setState(() => _authenticated = false),
            )
          : LoginScreen(
              authService: _authService,
              onAuthenticated: () => setState(() => _authenticated = true),
            ),
    );
  }
}

