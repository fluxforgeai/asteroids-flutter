import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

class SimpleAsteroidsGame extends StatefulWidget {
  const SimpleAsteroidsGame({Key? key}) : super(key: key);

  @override
  _SimpleAsteroidsGameState createState() => _SimpleAsteroidsGameState();
}

class _SimpleAsteroidsGameState extends State<SimpleAsteroidsGame>
    with TickerProviderStateMixin {
  late AnimationController _gameController;
  late Ship ship;
  List<Asteroid> asteroids = [];
  List<Bullet> bullets = [];
  int score = 0;
  int lives = 3;
  bool isGameRunning = true;
  Size gameSize = const Size(800, 600);
  
  // Keyboard input states
  bool _isLeftPressed = false;
  bool _isRightPressed = false;
  bool _isUpPressed = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _gameController = AnimationController(
      duration: const Duration(milliseconds: 16), // 60 FPS
      vsync: this,
    );
    
    _initializeGame();
    _startGameLoop();
    
    // Request focus for keyboard input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _initializeGame() {
    ship = Ship(
      position: Offset(gameSize.width / 2, gameSize.height / 2),
    );
    
    // Create initial asteroids
    asteroids.clear();
    for (int i = 0; i < 5; i++) {
      asteroids.add(_createRandomAsteroid());
    }
  }

  Asteroid _createRandomAsteroid() {
    final random = Random();
    return Asteroid(
      position: Offset(
        random.nextDouble() * gameSize.width,
        random.nextDouble() * gameSize.height,
      ),
      velocity: Offset(
        (random.nextDouble() - 0.5) * 100,
        (random.nextDouble() - 0.5) * 100,
      ),
      size: 30 + random.nextDouble() * 20,
    );
  }

  void _startGameLoop() {
    _gameController.repeat();
    _gameController.addListener(_updateGame);
  }

  void _updateGame() {
    if (!isGameRunning) return;

    setState(() {
      // Handle continuous keyboard input
      if (_isLeftPressed) ship.rotateLeft();
      if (_isRightPressed) ship.rotateRight();
      if (_isUpPressed) ship.thrust();
      
      // Update ship
      ship.update(gameSize);
      
      // Update bullets
      bullets.removeWhere((bullet) {
        bullet.update();
        return bullet.position.dx < 0 || 
               bullet.position.dx > gameSize.width ||
               bullet.position.dy < 0 || 
               bullet.position.dy > gameSize.height;
      });
      
      // Update asteroids
      for (var asteroid in asteroids) {
        asteroid.update(gameSize);
      }
      
      // Check collisions
      _checkCollisions();
      
      // Spawn new asteroids if needed
      if (asteroids.length < 3) {
        asteroids.add(_createRandomAsteroid());
      }
    });
  }

  void _checkCollisions() {
    // Bullet-asteroid collisions
    bullets.removeWhere((bullet) {
      for (int i = 0; i < asteroids.length; i++) {
        if (_isColliding(bullet.position, asteroids[i].position, asteroids[i].size)) {
          asteroids.removeAt(i);
          score += 100;
          return true;
        }
      }
      return false;
    });
  }

  bool _isColliding(Offset pos1, Offset pos2, double radius) {
    final distance = (pos1 - pos2).distance;
    return distance < radius;
  }

  void _fire() {
    bullets.add(Bullet(
      position: ship.position,
      velocity: Offset(
        sin(ship.rotation) * 300,
        -cos(ship.rotation) * 300,
      ),
    ));
  }
  
  void _onKeyEvent(KeyEvent event) {
    final isPressed = event is KeyDownEvent;
    
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.keyA:
        _isLeftPressed = isPressed;
        break;
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.keyD:
        _isRightPressed = isPressed;
        break;
      case LogicalKeyboardKey.arrowUp:
      case LogicalKeyboardKey.keyW:
        _isUpPressed = isPressed;
        break;
      case LogicalKeyboardKey.space:
        if (isPressed) _fire();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: Stack(
          children: [
            CustomPaint(
              painter: GamePainter(
                ship: ship,
                asteroids: asteroids,
                bullets: bullets,
                score: score,
                lives: lives,
              ),
              size: Size.infinite,
            ),
            // Controls instructions
            Positioned(
              top: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan, width: 1),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONTROLS:',
                      style: TextStyle(
                        color: Colors.cyan,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '← → or A D: Rotate',
                      style: TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                    Text(
                      '↑ or W: Thrust',
                      style: TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                    Text(
                      'SPACE: Fire',
                      style: TextStyle(color: Colors.cyan, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

class GamePainter extends CustomPainter {
  final Ship ship;
  final List<Asteroid> asteroids;
  final List<Bullet> bullets;
  final int score;
  final int lives;

  GamePainter({
    required this.ship,
    required this.asteroids,
    required this.bullets,
    required this.score,
    required this.lives,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw ship
    ship.draw(canvas);
    
    // Draw asteroids
    for (var asteroid in asteroids) {
      asteroid.draw(canvas);
    }
    
    // Draw bullets
    for (var bullet in bullets) {
      bullet.draw(canvas);
    }
    
    // Draw UI
    _drawUI(canvas, size);
  }

  void _drawUI(Canvas canvas, Size size) {
    final textPaint = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    // Score
    textPaint.text = TextSpan(
      text: 'Score: $score',
      style: const TextStyle(color: Colors.cyan, fontSize: 24),
    );
    textPaint.layout();
    textPaint.paint(canvas, const Offset(20, 20));
    
    // Lives
    textPaint.text = TextSpan(
      text: 'Lives: $lives',
      style: const TextStyle(color: Colors.cyan, fontSize: 24),
    );
    textPaint.layout();
    textPaint.paint(canvas, const Offset(20, 60));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Ship {
  Offset position;
  Offset velocity;
  double rotation;

  Ship({required this.position})
      : velocity = Offset.zero,
        rotation = 0;

  void update(Size gameSize) {
    // Apply velocity
    position += velocity * 0.016;
    
    // Apply friction
    velocity *= 0.98;
    
    // Wrap around screen
    if (position.dx < 0) position = Offset(gameSize.width, position.dy);
    if (position.dx > gameSize.width) position = Offset(0, position.dy);
    if (position.dy < 0) position = Offset(position.dx, gameSize.height);
    if (position.dy > gameSize.height) position = Offset(position.dx, 0);
  }

  void rotateLeft() {
    rotation -= 0.2;
  }

  void rotateRight() {
    rotation += 0.2;
  }

  void thrust() {
    velocity += Offset(sin(rotation) * 5, -cos(rotation) * 5);
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Draw ship as triangle
    final path = Path();
    path.moveTo(0, -15);
    path.lineTo(-10, 15);
    path.lineTo(10, 15);
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

class Asteroid {
  Offset position;
  Offset velocity;
  double size;
  double rotation;

  Asteroid({
    required this.position,
    required this.velocity,
    required this.size,
  }) : rotation = 0;

  void update(Size gameSize) {
    position += velocity * 0.016;
    rotation += 0.02;
    
    // Wrap around screen
    if (position.dx < -size) position = Offset(gameSize.width + size, position.dy);
    if (position.dx > gameSize.width + size) position = Offset(-size, position.dy);
    if (position.dy < -size) position = Offset(position.dx, gameSize.height + size);
    if (position.dy > gameSize.height + size) position = Offset(position.dx, -size);
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Draw asteroid as irregular polygon
    final path = Path();
    final points = 8;
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * pi;
      final radius = size * (0.7 + 0.3 * sin(i * 1.5));
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }
}

class Bullet {
  Offset position;
  Offset velocity;

  Bullet({required this.position, required this.velocity});

  void update() {
    position += velocity * 0.016;
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 3, paint);
  }
}