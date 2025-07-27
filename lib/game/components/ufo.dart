import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'bullet.dart';
import 'ship.dart';

class UFO extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  final Ship target;
  final VoidCallback onDestroyed;
  final Function(Bullet) onFire;
  
  Vector2 velocity = Vector2.zero();
  double fireTimer = 0;
  double fireCooldown = 1.5;
  double changeDirectionTimer = 0;
  double changeDirectionCooldown = 2.0;
  
  static const double speed = 80.0;
  static const double ufoSize = 30.0;
  
  UFO({
    required Vector2 position,
    required this.target,
    required this.onDestroyed,
    required this.onFire,
  }) : super(
         position: position,
         size: Vector2.all(ufoSize),
       ) {
    // Add collision detection
    add(RectangleHitbox(size: Vector2.all(ufoSize)));
    
    // Initial random velocity
    _changeDirection();
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update timers
    fireTimer += dt;
    changeDirectionTimer += dt;
    
    // Change direction periodically
    if (changeDirectionTimer >= changeDirectionCooldown) {
      _changeDirection();
      changeDirectionTimer = 0;
    }
    
    // Fire at ship
    if (fireTimer >= fireCooldown) {
      _fireAtShip();
      fireTimer = 0;
    }
    
    // Apply velocity
    position += velocity * dt;
  }
  
  void _changeDirection() {
    final angle = Random().nextDouble() * 2 * pi;
    velocity = Vector2(cos(angle), sin(angle)) * speed;
  }
  
  void _fireAtShip() {
    // Calculate direction to ship
    final direction = (target.position - position).normalized();
    
    // Add some inaccuracy
    final inaccuracy = 0.3;
    final angle = atan2(direction.y, direction.x) + 
                  (Random().nextDouble() - 0.5) * inaccuracy;
    
    final bulletVelocity = Vector2(cos(angle), sin(angle)) * 300;
    final bullet = Bullet(
      position: position.clone(),
      velocity: bulletVelocity,
      isPlayerBullet: false,
    );
    
    onFire(bullet);
  }
  
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    // Draw UFO body (classic flying saucer)
    final center = size / 2;
    
    // Main body (ellipse)
    final bodyRect = Rect.fromCenter(
      center: Offset(center.x, center.y),
      width: ufoSize * 0.8,
      height: ufoSize * 0.4,
    );
    canvas.drawOval(bodyRect, paint);
    
    // Top dome
    final domeRect = Rect.fromCenter(
      center: Offset(center.x, center.y - ufoSize * 0.1),
      width: ufoSize * 0.4,
      height: ufoSize * 0.3,
    );
    canvas.drawOval(domeRect, paint);
    
    // Details
    final detailPaint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    // Windows/lights
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi;
      final lightPos = Vector2(
        center.x + cos(angle) * ufoSize * 0.25,
        center.y + sin(angle) * ufoSize * 0.1,
      );
      
      canvas.drawCircle(
        Offset(lightPos.x, lightPos.y),
        3,
        detailPaint,
      );
    }
    
    // Glowing effect
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.x, center.y),
        width: ufoSize * 1.2,
        height: ufoSize * 0.6,
      ),
      glowPaint,
    );
  }
  
  void wrapPosition(Vector2 screenSize) {
    final margin = size / 2;
    
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
    
    // Handle collision with ship
    if (other is Ship) {
      destroy();
      return true;
    }
    
    return false;
  }
  
  void destroy() {
    removeFromParent();
    onDestroyed();
  }
}