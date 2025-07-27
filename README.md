# Asteroids Flutter

A production-ready Asteroids game built with Flutter and the Flame game engine.

## Features

- 🚀 **SpaceX Starship-inspired ship design** - Detailed ship with realistic fins and thrust flames
- 🎮 **Multi-platform support** - Runs on Android, iOS, and Web
- 📱 **Mobile-optimized controls** - Touch controls optimized for mobile devices
- 🎯 **Classic gameplay** - Faithful to the original Asteroids arcade game
- 🔊 **Sound system** - Integrated audio system (sound files not included)
- 💾 **High score persistence** - Saves your best scores locally
- 🎨 **Retro aesthetics** - Cyan wireframe graphics with glow effects
- ⚡ **Performance optimized** - Smooth 60fps gameplay
- 🎲 **Dynamic asteroid generation** - Randomly generated asteroid shapes
- 👾 **UFO enemies** - Occasional UFO attacks with AI targeting

## Controls

### Desktop/Web
- **Arrow Keys / WASD** - Rotate and thrust
- **Space** - Fire bullets
- **H** - Hyperspace jump
- **P** - Pause/Resume

### Mobile
- **Touch controls** - Five button layout at bottom of screen
- **← →** - Rotate ship left/right
- **↑** - Thrust
- **FIRE** - Shoot bullets
- **H** - Hyperspace jump

## Getting Started

### Prerequisites
- Flutter SDK (3.5.4 or later)
- Dart SDK
- Android Studio / Xcode (for mobile development)

### Installation

1. **Install dependencies:**
   ```bash
   flutter pub get
   ```

2. **Run the app:**
   ```bash
   flutter run
   ```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle:
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

#### Web
```bash
flutter build web --release
```

## Architecture

The game is built using the **Flame game engine** with a component-based architecture:

### Core Components
- **Ship** - Player-controlled spacecraft with SpaceX Starship design
- **Asteroid** - Randomly generated space rocks with realistic physics
- **Bullet** - Projectiles with collision detection
- **UFO** - AI-controlled enemy spacecraft

### Systems
- **Game Engine** - Main game loop and state management
- **Sound System** - Audio management and effects
- **Collision Detection** - Flame's built-in collision system
- **Input Handling** - Keyboard and touch input processing

## Performance Optimizations

- **Efficient rendering** - Custom render methods for each component
- **Object pooling** - Reuse of bullet objects to reduce garbage collection
- **Collision optimization** - Efficient hitbox shapes
- **Memory management** - Proper cleanup of removed components
- **Frame rate limiting** - Consistent 60fps performance

## Technical Details

### Dependencies
- **flame**: Game engine framework
- **flame_audio**: Audio system integration
- **shared_preferences**: Local data persistence
- **flutter_launcher_icons**: App icon generation

### Minimum Requirements
- Android API level 21 (Android 5.0)
- iOS 12.0+
- Web: Modern browsers with WebGL support
