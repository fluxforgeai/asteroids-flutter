import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/simple_asteroids_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  runApp(const AsteroidsApp());
}

class AsteroidsApp extends StatelessWidget {
  const AsteroidsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Asteroids',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const SimpleAsteroidsGame(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Simplified main app - game screen is now in simple_asteroids_game.dart
