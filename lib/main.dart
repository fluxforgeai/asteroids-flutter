import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'game/asteroids_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // Enable fullscreen
  await Flame.device.fullScreen();
  
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
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late AsteroidsGame game;
  
  @override
  void initState() {
    super.initState();
    game = AsteroidsGame();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: game),
          // Game UI overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            right: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Score and Lives
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: game.scoreNotifier,
                      builder: (context, score, child) {
                        return Text(
                          'Score: $score',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.cyan,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: game.livesNotifier,
                      builder: (context, lives, child) {
                        return Text(
                          'Lives: $lives',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10,
                                color: Colors.cyan,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                // High Score
                ValueListenableBuilder<int>(
                  valueListenable: game.highScoreNotifier,
                  builder: (context, highScore, child) {
                    return Text(
                      'High: $highScore',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10,
                            color: Colors.cyan,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Mobile Controls
          if (Theme.of(context).platform == TargetPlatform.android ||
              Theme.of(context).platform == TargetPlatform.iOS)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Container(
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Left rotation
                    _buildControlButton(
                      icon: Icons.rotate_left,
                      onPressed: () => game.rotateLeft = true,
                      onReleased: () => game.rotateLeft = false,
                    ),
                    // Right rotation
                    _buildControlButton(
                      icon: Icons.rotate_right,
                      onPressed: () => game.rotateRight = true,
                      onReleased: () => game.rotateRight = false,
                    ),
                    // Thrust
                    _buildControlButton(
                      icon: Icons.keyboard_arrow_up,
                      onPressed: () => game.thrust = true,
                      onReleased: () => game.thrust = false,
                    ),
                    // Fire
                    _buildControlButton(
                      icon: Icons.circle,
                      label: 'FIRE',
                      color: Colors.orange,
                      onPressed: () => game.fire(),
                    ),
                    // Hyperspace
                    _buildControlButton(
                      icon: Icons.flash_on,
                      label: 'H',
                      onPressed: () => game.hyperspace(),
                    ),
                  ],
                ),
              ),
            ),
          // Game Over overlay
          ValueListenableBuilder<GameState>(
            valueListenable: game.gameStateNotifier,
            builder: (context, state, child) {
              if (state == GameState.gameOver) {
                return _buildGameOverOverlay();
              } else if (state == GameState.paused) {
                return _buildPauseOverlay();
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    String? label,
    Color? color,
    required VoidCallback onPressed,
    VoidCallback? onReleased,
  }) {
    return GestureDetector(
      onTapDown: (_) => onPressed(),
      onTapUp: (_) => onReleased?.call(),
      onTapCancel: () => onReleased?.call(),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color ?? Colors.cyan, width: 2),
          color: (color ?? Colors.cyan).withOpacity(0.2),
          boxShadow: [
            BoxShadow(
              color: color ?? Colors.cyan,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: label != null
            ? Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color ?? Colors.cyan,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              )
            : Icon(
                icon,
                color: color ?? Colors.cyan,
                size: 30,
              ),
      ),
    );
  }
  
  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: Colors.cyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ValueListenableBuilder<int>(
              valueListenable: game.scoreNotifier,
              builder: (context, score, child) {
                return Text(
                  'Final Score: $score',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => game.restart(),
              child: const Text('PLAY AGAIN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.cyan,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 20,
                    color: Colors.cyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => game.resume(),
              child: const Text('RESUME'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
