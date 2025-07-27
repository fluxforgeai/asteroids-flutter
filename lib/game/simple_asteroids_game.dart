import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

enum AsteroidSize { small, medium, large }

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
    // Reset game state
    score = 0;
    lives = 3;
    bullets.clear();
    
    ship = Ship(
      position: Offset(gameSize.width / 2, gameSize.height / 2),
    );
    
    // Create initial asteroids
    asteroids.clear();
    for (int i = 0; i < 5; i++) {
      asteroids.add(_createRandomAsteroid());
    }
  }

  Asteroid _createRandomAsteroid({AsteroidSize? asteroidSize, Offset? position}) {
    final random = Random();
    final size = asteroidSize ?? AsteroidSize.large;
    
    return Asteroid(
      position: position ?? Offset(
        random.nextDouble() * gameSize.width,
        random.nextDouble() * gameSize.height,
      ),
      velocity: Offset(
        (random.nextDouble() - 0.5) * 100,
        (random.nextDouble() - 0.5) * 100,
      ),
      asteroidSize: size,
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
        if (_isColliding(bullet.position, asteroids[i].position, asteroids[i].getRadius())) {
          final asteroid = asteroids.removeAt(i);
          
          // Play asteroid destruction sound
          SystemSound.play(SystemSoundType.click);
          
          // Add score based on asteroid size
          switch (asteroid.asteroidSize) {
            case AsteroidSize.large:
              score += 20;
              break;
            case AsteroidSize.medium:
              score += 50;
              break;
            case AsteroidSize.small:
              score += 100;
              break;
          }
          
          // Split asteroid into smaller pieces
          _splitAsteroid(asteroid);
          
          return true;
        }
      }
      return false;
    });
    
    // Ship-asteroid collisions
    for (var asteroid in asteroids) {
      if (_isColliding(ship.position, asteroid.position, asteroid.getRadius() + 10)) {
        _shipHit();
        break;
      }
    }
  }
  
  void _splitAsteroid(Asteroid asteroid) {
    if (asteroid.asteroidSize == AsteroidSize.small) return;
    
    final newSize = asteroid.asteroidSize == AsteroidSize.large 
        ? AsteroidSize.medium 
        : AsteroidSize.small;
    
    // Create 2 smaller asteroids
    for (int i = 0; i < 2; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      final speed = 50 + Random().nextDouble() * 50;
      
      asteroids.add(_createRandomAsteroid(
        asteroidSize: newSize,
        position: asteroid.position,
      ));
      
      // Give them different velocities
      asteroids.last.velocity = Offset(
        cos(angle) * speed,
        sin(angle) * speed,
      );
    }
  }
  
  void _shipHit() {
    // Play explosion sound
    SystemSound.play(SystemSoundType.alert);
    
    lives--;
    print('Ship hit! Lives remaining: $lives'); // Debug output
    
    if (lives <= 0) {
      isGameRunning = false;
      print('Game Over!'); // Debug output
    } else {
      // Reset ship position to center
      ship.position = Offset(gameSize.width / 2, gameSize.height / 2);
      ship.velocity = Offset.zero;
      ship.rotation = 0;
    }
  }

  bool _isColliding(Offset pos1, Offset pos2, double radius) {
    final distance = (pos1 - pos2).distance;
    return distance < radius;
  }

  void _fire() {
    // Play fire sound
    SystemSound.play(SystemSoundType.click);
    
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
            // Game Over overlay
            if (!isGameRunning)
              Container(
                color: Colors.black.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'GAME OVER',
                        style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Final Score: $score',
                        style: const TextStyle(
                          color: Colors.cyan,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _initializeGame();
                            isGameRunning = true;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text(
                          'PLAY AGAIN',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
    rotation -= 0.05;
  }

  void rotateRight() {
    rotation += 0.05;
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
  AsteroidSize asteroidSize;
  double rotation;
  List<Offset> shape = [];
  
  static const Map<AsteroidSize, double> sizeMap = {
    AsteroidSize.small: 15,
    AsteroidSize.medium: 25,
    AsteroidSize.large: 40,
  };

  Asteroid({
    required this.position,
    required this.velocity,
    required this.asteroidSize,
  }) : rotation = 0 {
    _generateShape();
  }
  
  void _generateShape() {
    shape.clear();
    final radius = getRadius();
    final points = 8 + Random().nextInt(4); // 8-11 points
    
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * pi;
      final variation = 0.7 + Random().nextDouble() * 0.6; // 0.7-1.3 variation
      final r = radius * variation;
      
      shape.add(Offset(
        cos(angle) * r,
        sin(angle) * r,
      ));
    }
  }
  
  double getRadius() {
    return sizeMap[asteroidSize]!;
  }

  void update(Size gameSize) {
    position += velocity * 0.016;
    rotation += 0.02;
    
    final radius = getRadius();
    
    // Wrap around screen
    if (position.dx < -radius) position = Offset(gameSize.width + radius, position.dy);
    if (position.dx > gameSize.width + radius) position = Offset(-radius, position.dy);
    if (position.dy < -radius) position = Offset(position.dx, gameSize.height + radius);
    if (position.dy > gameSize.height + radius) position = Offset(position.dx, -radius);
  }

  void draw(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(rotation);

    // Draw asteroid using generated shape
    if (shape.isNotEmpty) {
      final path = Path();
      path.moveTo(shape[0].dx, shape[0].dy);
      
      for (int i = 1; i < shape.length; i++) {
        path.lineTo(shape[i].dx, shape[i].dy);
      }
      path.close();
      
      canvas.drawPath(path, paint);
    }

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