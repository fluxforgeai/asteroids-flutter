import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'asteroid.dart';
import 'ship.dart';
import 'ufo.dart';

class Bullet extends PositionComponent with HasCollisionDetection, CollisionCallbacks {
  final Vector2 velocity;
  final bool isPlayerBullet;
  double lifeTime = 0;
  static const double maxLifeTime = 2.0; // 2 seconds
  bool shouldRemove = false;
  
  Bullet({
    required Vector2 position,
    required this.velocity,
    required this.isPlayerBullet,
  }) : super(
         position: position,
         size: Vector2(4, 4),
       ) {
    // Add collision detection
    add(CircleHitbox(radius: 2));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update lifetime
    lifeTime += dt;
    if (lifeTime >= maxLifeTime) {
      shouldRemove = true;
      return;
    }
    
    // Apply velocity
    position += velocity * dt;
  }
  
  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = isPlayerBullet ? Colors.cyan : Colors.red
      ..style = PaintingStyle.fill;
    
    // Draw bullet as a small circle
    canvas.drawCircle(Offset(2, 2), 2, paint);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = (isPlayerBullet ? Colors.cyan : Colors.red).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(2, 2), 4, glowPaint);
  }
  
  @override
  bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    // Don't collide with the entity that fired it
    if (isPlayerBullet && other is Ship) {
      return false;
    }
    if (!isPlayerBullet && other is UFO) {
      return false;
    }
    
    // Collide with asteroids and ships/UFOs
    if (other is Asteroid || 
        (isPlayerBullet && other is UFO) ||
        (!isPlayerBullet && other is Ship)) {
      destroy();
      return true;
    }
    
    return false;
  }
  
  void destroy() {
    shouldRemove = true;
    removeFromParent();
  }
}