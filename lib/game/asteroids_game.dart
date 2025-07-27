import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/ship.dart';
import 'components/asteroid.dart';
import 'components/bullet.dart';
import 'components/ufo.dart';
import 'systems/sound_system.dart';

enum GameState { menu, playing, paused, gameOver }

class AsteroidsGame extends FlameGame with HasKeyboardHandlerComponents, HasCollisionDetection {
  // Game state
  final ValueNotifier<GameState> gameStateNotifier = ValueNotifier(GameState.playing);
  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> livesNotifier = ValueNotifier(3);
  final ValueNotifier<int> highScoreNotifier = ValueNotifier(0);
  
  // Game objects
  late Ship ship;
  final List<Asteroid> asteroids = [];
  final List<Bullet> bullets = [];
  UFO? ufo;
  
  // Systems
  late SoundSystem soundSystem;
  
  // Input states
  bool rotateLeft = false;
  bool rotateRight = false;
  bool thrust = false;
  
  // Game settings
  static const int initialLives = 3;
  static const int asteroidCount = 8;
  static const double ufoSpawnChance = 0.001;
  
  // Timing
  double lastFireTime = 0;
  double fireCooldown = 0.2;
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Initialize systems
    soundSystem = SoundSystem();
    await soundSystem.initialize();
    
    // Load high score
    await _loadHighScore();
    
    // Initialize game
    _initializeGame();
  }
  
  void _initializeGame() {
    // Clear existing components
    removeAll(children.where((component) => 
        component is Ship || 
        component is Asteroid || 
        component is Bullet || 
        component is UFO).toList());
    
    // Reset game state
    scoreNotifier.value = 0;
    livesNotifier.value = initialLives;
    gameStateNotifier.value = GameState.playing;
    
    // Create ship
    ship = Ship(
      position: size / 2,
      onDestroyed: _onShipDestroyed,
    );
    add(ship);
    
    // Create asteroids
    _spawnAsteroids();
  }
  
  void _spawnAsteroids() {
    asteroids.clear();
    
    for (int i = 0; i < asteroidCount; i++) {
      final position = _getRandomEdgePosition();
      final asteroid = Asteroid(
        position: position,
        asteroidSize: AsteroidSize.large,
        onDestroyed: _onAsteroidDestroyed,
      );
      asteroids.add(asteroid);
      add(asteroid);
    }
  }
  
  Vector2 _getRandomEdgePosition() {
    final random = Random();
    final margin = 100.0;
    
    switch (random.nextInt(4)) {
      case 0: // Top
        return Vector2(random.nextDouble() * size.x, -margin);
      case 1: // Right
        return Vector2(size.x + margin, random.nextDouble() * size.y);
      case 2: // Bottom
        return Vector2(random.nextDouble() * size.x, size.y + margin);
      case 3: // Left
        return Vector2(-margin, random.nextDouble() * size.y);
      default:
        return Vector2.zero();
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (gameStateNotifier.value != GameState.playing) return;
    
    // Handle input
    _handleInput(dt);
    
    // Spawn UFO occasionally
    if (Random().nextDouble() < ufoSpawnChance && ufo == null) {
      _spawnUFO();
    }
    
    // Check for next level
    if (asteroids.isEmpty) {
      _nextLevel();
    }
    
    // Wrap positions
    _wrapPositions();
    
    // Clean up bullets
    _cleanupBullets();
  }
  
  void _handleInput(double dt) {
    if (rotateLeft) {
      ship.rotate(-Ship.rotationSpeed * dt);
    }
    if (rotateRight) {
      ship.rotate(Ship.rotationSpeed * dt);
    }
    if (thrust) {
      ship.applyThrust();
      soundSystem.playThrustSound();
    } else {
      soundSystem.stopThrustSound();
    }
  }
  
  void fire() {
    final currentTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    if (currentTime - lastFireTime >= fireCooldown) {
      final bullet = ship.fire();
      if (bullet != null) {
        bullets.add(bullet);
        add(bullet);
        soundSystem.playFireSound();
        lastFireTime = currentTime;
      }
    }
  }
  
  void hyperspace() {
    ship.hyperspace();
    soundSystem.playHyperspaceSound();
  }
  
  void _spawnUFO() {
    final position = _getRandomEdgePosition();
    ufo = UFO(
      position: position,
      target: ship,
      onDestroyed: _onUFODestroyed,
      onFire: (bullet) {
        bullets.add(bullet);
        add(bullet);
      },
    );
    add(ufo!);
    soundSystem.playUFOSound();
  }
  
  void _onShipDestroyed() {
    soundSystem.playExplosionSound();
    livesNotifier.value--;
    
    if (livesNotifier.value <= 0) {
      _gameOver();
    } else {
      // Respawn ship after delay
      Future.delayed(Duration(seconds: 2), () {
        if (gameStateNotifier.value == GameState.playing) {
          ship = Ship(
            position: size / 2,
            onDestroyed: _onShipDestroyed,
          );
          add(ship);
        }
      });
    }
  }
  
  void _onAsteroidDestroyed(Asteroid asteroid) {
    soundSystem.playExplosionSound();
    asteroids.remove(asteroid);
    
    // Add score based on asteroid size
    switch (asteroid.asteroidSize) {
      case AsteroidSize.large:
        scoreNotifier.value += 20;
        break;
      case AsteroidSize.medium:
        scoreNotifier.value += 50;
        break;
      case AsteroidSize.small:
        scoreNotifier.value += 100;
        break;
    }
    
    // Split large and medium asteroids
    if (asteroid.asteroidSize != AsteroidSize.small) {
      _splitAsteroid(asteroid);
    }
    
    // Update high score
    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
      _saveHighScore();
    }
  }
  
  void _onUFODestroyed() {
    soundSystem.playExplosionSound();
    soundSystem.stopUFOSound();
    scoreNotifier.value += 1000;
    ufo = null;
    
    // Update high score
    if (scoreNotifier.value > highScoreNotifier.value) {
      highScoreNotifier.value = scoreNotifier.value;
      _saveHighScore();
    }
  }
  
  void _splitAsteroid(Asteroid asteroid) {
    final newSize = asteroid.asteroidSize == AsteroidSize.large 
        ? AsteroidSize.medium 
        : AsteroidSize.small;
    
    for (int i = 0; i < 2; i++) {
      final angle = Random().nextDouble() * 2 * pi;
      final velocity = Vector2(cos(angle), sin(angle)) * 100;
      
      final newAsteroid = Asteroid(
        position: asteroid.position.clone(),
        asteroidSize: newSize,
        velocity: velocity,
        onDestroyed: _onAsteroidDestroyed,
      );
      
      asteroids.add(newAsteroid);
      add(newAsteroid);
    }
  }
  
  void _nextLevel() {
    // Increase difficulty by adding more asteroids
    final newAsteroidCount = asteroidCount + 2;
    
    for (int i = 0; i < newAsteroidCount; i++) {
      final position = _getRandomEdgePosition();
      final asteroid = Asteroid(
        position: position,
        asteroidSize: AsteroidSize.large,
        onDestroyed: _onAsteroidDestroyed,
      );
      asteroids.add(asteroid);
      add(asteroid);
    }
  }
  
  void _wrapPositions() {
    // Wrap ship
    ship.wrapPosition(size);
    
    // Wrap asteroids
    for (final asteroid in asteroids) {
      asteroid.wrapPosition(size);
    }
    
    // Wrap UFO
    ufo?.wrapPosition(size);
  }
  
  void _cleanupBullets() {
    bullets.removeWhere((bullet) {
      if (bullet.shouldRemove || 
          bullet.position.x < 0 || 
          bullet.position.x > size.x ||
          bullet.position.y < 0 || 
          bullet.position.y > size.y) {
        bullet.removeFromParent();
        return true;
      }
      return false;
    });
  }
  
  void _gameOver() {
    gameStateNotifier.value = GameState.gameOver;
    soundSystem.stopAllSounds();
  }
  
  void restart() {
    _initializeGame();
  }
  
  void pause() {
    gameStateNotifier.value = GameState.paused;
    soundSystem.pauseAllSounds();
  }
  
  void resume() {
    gameStateNotifier.value = GameState.playing;
    soundSystem.resumeAllSounds();
  }
  
  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScoreNotifier.value = prefs.getInt('high_score') ?? 0;
  }
  
  Future<void> _saveHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('high_score', highScoreNotifier.value);
  }
  
  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Handle keyboard input for desktop/web
    rotateLeft = keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
                 keysPressed.contains(LogicalKeyboardKey.keyA);
    rotateRight = keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
                  keysPressed.contains(LogicalKeyboardKey.keyD);
    thrust = keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
             keysPressed.contains(LogicalKeyboardKey.keyW);
    
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.space) {
        fire();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyH) {
        hyperspace();
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.keyP) {
        if (gameStateNotifier.value == GameState.playing) {
          pause();
        } else if (gameStateNotifier.value == GameState.paused) {
          resume();
        }
        return true;
      }
    }
    
    return false;
  }
}