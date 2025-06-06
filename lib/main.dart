import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Rainbow Trail',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[200],
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.grey[800],
          ),
          themeMode: themeProvider.themeMode,
          home: const RainbowTrailPage(),
        );
      },
    );
  }
}

class RainbowTrailPage extends StatefulWidget {
  const RainbowTrailPage({super.key});

  @override
  RainbowTrailPageState createState() => RainbowTrailPageState();
}

class RainbowTrailPageState extends State<RainbowTrailPage>
    with TickerProviderStateMixin {
  List<TrailPoint> trailPoints = [];
  List<Particle> particles = [];
  Random random = Random();
  Ticker? ticker;

  @override
  void initState() {
    super.initState();

    ticker = createTicker((elapsed) {
      setState(() {
        // Update trail points (fade out)
        trailPoints = trailPoints
            .map((point) => point.copyWith(opacity: point.opacity - 0.01))
            .where((point) => point.opacity > 0)
            .toList();

        // Update particles (gravity, movement)
        particles = particles
            .map((particle) {
              final newY = particle.y + particle.gravity;
              final newX = particle.x + particle.velocityX;

              return particle.copyWith(
                x: newX,
                y: newY,
                life: particle.life - 1,
              );
            })
            .where((particle) => particle.life > 0)
            .toList();
      });
    });

    ticker?.start();
  }

  @override
  void dispose() {
    ticker?.dispose();
    super.dispose();
  }

  void addTrailPoint(Offset position) async {
    setState(() {
      trailPoints.add(
        TrailPoint(
          position: position,
          color: HSLColor.fromAHSL(
            1.0,
            random.nextDouble() * 360,
            0.8, // Reduced saturation
            0.4, // Reduced lightness
          ).toColor(),
          opacity: 1.0,
        ),
      );

      // Add glitter particles
      for (int i = 0; i < 5; i++) {
        particles.add(
          Particle(
            x: position.dx,
            y: position.dy,
            color: HSLColor.fromAHSL(
              1.0,
              random.nextDouble() * 360,
              0.7, // Reduced saturation
              0.6, // Reduced lightness
            ).toColor(),
            size: random.nextDouble() * 4 + 2,
            gravity: random.nextDouble() * 0.5 + 0.1,
            velocityX: (random.nextDouble() - 0.5) * 5,
            life: 50 + random.nextInt(50),
          ),
        );
      }

      // Add confetti particles
      for (int i = 0; i < 3; i++) {
        particles.add(
          Particle(
            x: position.dx,
            y: position.dy,
            color: HSLColor.fromAHSL(
              1.0,
              random.nextDouble() * 360,
              0.6, // Reduced saturation
              0.5, // Reduced lightness
            ).toColor(),
            size: random.nextDouble() * 8 + 4,
            gravity: random.nextDouble() * 1 + 0.2,
            velocityX: (random.nextDouble() - 0.5) * 10,
            life: 40 + random.nextInt(40),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rainbow Trail'),
            actions: [
              Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.toggleTheme();
                },
              ),
            ],
          ),
          body: GestureDetector(
            onPanDown: (details) => addTrailPoint(details.localPosition),
            onPanUpdate: (details) => addTrailPoint(details.localPosition),
            child: CustomPaint(
              painter: TrailPainter(
                trailPoints: trailPoints,
                particles: particles,
              ),
              child: Container(),
            ),
          ),
        );
      },
    );
  }
}

class TrailPainter extends CustomPainter {
  final List<TrailPoint> trailPoints;
  final List<Particle> particles;

  TrailPainter({required this.trailPoints, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw trail
    for (var point in trailPoints) {
      final paint = Paint()
        ..color = point.color.withValues(alpha: point.opacity)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      canvas.drawPoints(PointMode.points, [point.position], paint);
    }

    // Draw particles
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant TrailPainter oldDelegate) {
    return oldDelegate.trailPoints != trailPoints ||
        oldDelegate.particles != particles;
  }
}

class TrailPoint {
  final Offset position;
  final Color color;
  final double opacity;

  TrailPoint({
    required this.position,
    required this.color,
    required this.opacity,
  });

  TrailPoint copyWith({Offset? position, Color? color, double? opacity}) {
    return TrailPoint(
      position: position ?? this.position,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
    );
  }
}

class Particle {
  final double x;
  final double y;
  final Color color;
  final double size;
  final double gravity;
  final double velocityX;
  final int life;

  Particle({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.gravity,
    required this.velocityX,
    required this.life,
  });

  Particle copyWith({
    double? x,
    double? y,
    Color? color,
    double? size,
    double? gravity,
    double? velocityX,
    int? life,
  }) {
    return Particle(
      x: x ?? this.x,
      y: y ?? this.y,
      color: color ?? this.color,
      size: size ?? this.size,
      gravity: gravity ?? this.gravity,
      velocityX: velocityX ?? this.velocityX,
      life: life ?? this.life,
    );
  }
}
