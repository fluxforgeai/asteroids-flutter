import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'bullet.dart';

enum AsteroidSize { small, medium, large }

class Asteroid extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  final AsteroidSize asteroidSize;
  final Function(Asteroid) onDestroyed;
  Vector2 velocity;
  double rotationSpeed;
  List<Vector2> shape = [];
  
  static const Map<AsteroidSize, double> sizeMap = {
    AsteroidSize.small: 15,
    AsteroidSize.medium: 25,
    AsteroidSize.large: 40,
  };
  
  static const Map<AsteroidSize, double> speedMap = {
    AsteroidSize.small: 120,
    AsteroidSize.medium: 80,
    AsteroidSize.large: 50,
  };
  
  Asteroid({
    required Vector2 position,
    required this.asteroidSize,
    required this.onDestroyed,
    Vector2? velocity,
  }) : velocity = velocity ?? _generateRandomVelocity(asteroidSize),
       rotationSpeed = (Random().nextDouble() - 0.5) * 4,
       super(
         position: position,
         size: Vector2.all(sizeMap[asteroidSize]! * 2),
       ) {
    
    // Generate random asteroid shape
    _generateShape();
    
    // Add collision detection
    add(PolygonHitbox(shape));
  }
  
  static Vector2 _generateRandomVelocity(AsteroidSize size) {
    final angle = Random().nextDouble() * 2 * pi;
    final speed = speedMap[size]! * (0.5 + Random().nextDouble() * 0.5);
    return Vector2(cos(angle), sin(angle)) * speed;
  }
  
  void _generateShape() {
    final radius = sizeMap[asteroidSize]!;
    final points = 8 + Random().nextInt(4); // 8-11 points
    shape.clear();
    
    for (int i = 0; i < points; i++) {
      final angle = (i / points) * 2 * pi;
      final variation = 0.7 + Random().nextDouble() * 0.6; // 0.7-1.3 variation
      final r = radius * variation;
      
      shape.add(Vector2(
        cos(angle) * r,
        sin(angle) * r,
      ));
    }
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Apply velocity
    position += velocity * dt;
    
    // Rotate
    angle += rotationSpeed * dt;
  }
  
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw asteroid shape
    if (shape.isNotEmpty) {
      final path = Path();
      path.moveTo(shape[0].x, shape[0].y);
      
      for (int i = 1; i < shape.length; i++) {
        path.lineTo(shape[i].x, shape[i].y);
      }
      path.close();
      
      canvas.drawPath(path, paint);
    }
    
    // Draw some surface details for larger asteroids
    if (asteroidSize != AsteroidSize.small) {
      final detailPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      
      final radius = sizeMap[asteroidSize]! * 0.6;
      for (int i = 0; i < 3; i++) {
        final angle = Random().nextDouble() * 2 * pi;
        final start = Vector2(cos(angle), sin(angle)) * radius * 0.3;
        final end = Vector2(cos(angle), sin(angle)) * radius * 0.8;
        
        canvas.drawLine(
          Offset(start.x, start.y),
          Offset(end.x, end.y),
          detailPaint,
        );
      }
    }
  }
  
  void wrapPosition(Vector2 screenSize) {
    final margin = sizeMap[asteroidSize]!;
    
    if (position.x < -margin) position.x = screenSize.x + margin;
    if (position.x > screenSize.x + margin) position.x = -margin;
    if (position.y < -margin) position.y = screenSize.y + margin;
    if (position.y > screenSize.y + margin) position.y = -margin;
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Handle collision with player bullets
    if (other is Bullet && other.isPlayerBullet) {
      destroy();
      return true;
    }
    return false;
  }
  
  void destroy() {
    removeFromParent();
    onDestroyed(this);
  }
}