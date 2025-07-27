import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'bullet.dart';
import 'asteroid.dart';
import 'ufo.dart';

class Ship extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  static const double maxSpeed = 300.0;
  static const double acceleration = 200.0;
  static const double friction = 0.98;
  static const double rotationSpeed = 5.0;
  
  Vector2 velocity = Vector2.zero();
  double rotation = 0;
  bool isThrusting = false;
  bool isInvulnerable = false;
  double invulnerabilityTimer = 0;
  
  final VoidCallback onDestroyed;
  
  Ship({
    required Vector2 position,
    required this.onDestroyed,
  }) : super(position: position, size: Vector2(20, 20)) {
    // Add collision detection
    add(PolygonHitbox([
      Vector2(0, -10),
      Vector2(-8, 10),
      Vector2(0, 5),
      Vector2(8, 10),
    ]));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update invulnerability
    if (isInvulnerable) {
      invulnerabilityTimer -= dt;
      if (invulnerabilityTimer <= 0) {
        isInvulnerable = false;
      }
    }
    
    // Apply velocity
    position += velocity * dt;
    
    // Apply friction
    velocity *= friction;
    
    // Limit speed
    if (velocity.length > maxSpeed) {
      velocity = velocity.normalized() * maxSpeed;
    }
  }
  
  @override
  void render(Canvas canvas) {
    // Save canvas state
    canvas.save();
    
    // Set ship color (flashing when invulnerable)
    final paint = Paint()
      ..color = isInvulnerable && (invulnerabilityTimer * 10) % 2 < 1
          ? Colors.cyan.withOpacity(0.5)
          : Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw SpaceX Starship-inspired design
    final path = Path();
    
    // Main body (cylindrical section)
    path.moveTo(0, -10); // Tip
    path.lineTo(-3, -5); // Upper left
    path.lineTo(-3, 8);  // Lower left
    path.lineTo(0, 10);  // Bottom center
    path.lineTo(3, 8);   // Lower right
    path.lineTo(3, -5);  // Upper right
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw fins
    final finPaint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Left fin
    canvas.drawLine(Offset(-3, 5), Offset(-6, 8), finPaint);
    canvas.drawLine(Offset(-6, 8), Offset(-3, 8), finPaint);
    
    // Right fin
    canvas.drawLine(Offset(3, 5), Offset(6, 8), finPaint);
    canvas.drawLine(Offset(6, 8), Offset(3, 8), finPaint);
    
    // Draw thrust flame if thrusting
    if (isThrusting) {
      final flamePaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;
      
      final flameLength = 8 + Random().nextDouble() * 4;
      final flamePath = Path();
      flamePath.moveTo(-2, 10);
      flamePath.lineTo(0, 10 + flameLength);
      flamePath.lineTo(2, 10);
      flamePath.close();
      
      canvas.drawPath(flamePath, flamePaint);
      
      // Inner flame
      final innerFlamePaint = Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.fill;
      
      final innerFlamePath = Path();
      innerFlamePath.moveTo(-1, 10);
      innerFlamePath.lineTo(0, 10 + flameLength * 0.7);
      innerFlamePath.lineTo(1, 10);
      innerFlamePath.close();
      
      canvas.drawPath(innerFlamePath, innerFlamePaint);
    }
    
    canvas.restore();
  }
  
  void rotate(double deltaRotation) {
    rotation += deltaRotation;
    angle = rotation;
  }
  
  void applyThrust() {
    isThrusting = true;
    final thrustVector = Vector2(sin(rotation), -cos(rotation)) * acceleration;
    velocity += thrustVector * 0.016; // Approximate dt
  }
  
  Bullet? fire() {
    final bulletPosition = position + Vector2(sin(rotation), -cos(rotation)) * 15;
    final bulletVelocity = Vector2(sin(rotation), -cos(rotation)) * 400 + velocity;
    
    return Bullet(
      position: bulletPosition,
      velocity: bulletVelocity,
      isPlayerBullet: true,
    );
  }
  
  void hyperspace() {
    // Random teleportation
    if (parent != null) {
      final gameSize = (parent as HasGameRef).gameRef.size;
      position = Vector2(
        Random().nextDouble() * gameSize.x,
        Random().nextDouble() * gameSize.y,
      );
      velocity = Vector2.zero();
      
      // Temporary invulnerability
      isInvulnerable = true;
      invulnerabilityTimer = 2.0;
    }
  }
  
  void wrapPosition(Vector2 screenSize) {
    if (position.x < 0) position.x = screenSize.x;
    if (position.x > screenSize.x) position.x = 0;
    if (position.y < 0) position.y = screenSize.y;
    if (position.y > screenSize.y) position.y = 0;
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    if (!isInvulnerable) {
      // Collide with asteroids, UFOs, and enemy bullets
      if (other is Asteroid || 
          other is UFO || 
          (other is Bullet && !other.isPlayerBullet)) {
        destroy();
        return true;
      }
    }
    return false;
  }
  
  void destroy() {
    removeFromParent();
    onDestroyed();
  }
}