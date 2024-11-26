import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InteractivePainterPage(),
    );
  }
}

class InteractivePainterPage extends StatefulWidget {
  const InteractivePainterPage({super.key});

  @override
  State<InteractivePainterPage> createState() => _InteractivePainterPageState();
}

class _InteractivePainterPageState extends State<InteractivePainterPage>
    with SingleTickerProviderStateMixin {
  // List to store active dots on the screen
  final List<Dot> _dots = [];

  // Manages selected colours for dots
  final ValueNotifier<List<Color>> _selectedColors = ValueNotifier([]);

  // Ticker to update dot positions at each frame
  late Ticker _ticker;

  // Timer for continuously creating dots while tapping
  Timer? _dotCreationTimer;

  // Available colours for selection
  final List<Color> _availableColors = [
    Colors.white,
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.pink,
  ];

  @override
  void initState() {
    super.initState();
    // Start the ticker to handle frame updates
    _ticker = Ticker(_updateDots)..start();

    // Initialise with the first available colour
    _selectedColors.value = [_availableColors.first];
  }

  @override
  void dispose() {
    // Clean up resources
    _ticker.dispose();
    _dotCreationTimer?.cancel();
    _selectedColors.dispose();
    super.dispose();
  }

  // Update dot positions and remove dots with excessive bounces
  void _updateDots(Duration elapsed) {
    final screenBounds = MediaQuery.of(context).size;
    setState(() {
      // Remove dots that have bounced more than 3 times
      _dots.removeWhere((dot) => dot.bounces >= 4);

      // Update position and state for remaining dots
      for (final dot in _dots) {
        dot.update(screenBounds);
      }
    });
  }

  // Start generating dots at the tap position
  void _startCreatingDots(Offset position) {
    _dotCreationTimer = Timer.periodic(
      const Duration(milliseconds: 50), // Dot creation interval
      (_) => _addDot(position),
    );
  }

  // Stop generating dots
  void _stopCreatingDots() {
    _dotCreationTimer?.cancel();
  }

  // Add a new dot at the given position with randomised direction and colour
  void _addDot(Offset position) {
    if (_selectedColors.value.isEmpty) return;

    setState(() {
      _dots.add(Dot(
        position: position,
        direction: Offset(
          Random().nextDouble() * 2 - 1, // Random horizontal direction
          Random().nextDouble() * 2 - 1, // Random vertical direction
        ).normalize(),
        color: _selectedColors
            .value[Random().nextInt(_selectedColors.value.length)],
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background to black
      body: Stack(
        children: [
          // Main area for interaction and rendering dots
          GestureDetector(
            onPanDown: (details) => _startCreatingDots(details.localPosition),
            onPanUpdate: (details) => _addDot(details.localPosition),
            onPanEnd: (_) => _stopCreatingDots(),
            child: ClipRect(
              child: CustomPaint(
                painter: DotPainter(dots: _dots), // Custom painter for dots
                size: Size.infinite,
              ),
            ),
          ),
          // Colour selection panel at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: ValueListenableBuilder<List<Color>>(
              valueListenable: _selectedColors,
              builder: (context, selectedColors, _) {
                return Wrap(
                  spacing: 16,
                  children: _availableColors.map((color) {
                    final isSelected = selectedColors.contains(color);
                    return GestureDetector(
                      onTap: () {
                        // Add or remove colour from the selection
                        if (isSelected) {
                          _selectedColors.value = List.from(selectedColors)
                            ..remove(color);
                        } else {
                          _selectedColors.value = List.from(selectedColors)
                            ..add(color);
                        }
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 40),
                        decoration: BoxDecoration(
                          color: color,
                          shape:
                              isSelected ? BoxShape.circle : BoxShape.rectangle,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Dot {
  Offset position;
  Offset direction;
  int bounces = 0; // Track number of bounces
  final double speed = 5.0; // Movement speed of the dot
  final double radius = 5.0; // Radius of the dot
  final Color color;

  Dot({
    required this.position,
    required this.direction,
    required this.color,
  });

  // Update position and handle screen edge collisions
  void update(Size screenBounds) {
    position += direction * speed;

    // Bounce off edges and slightly rotate direction
    if (position.dx <= 0 || position.dx >= screenBounds.width) {
      direction = Offset(-direction.dx, direction.dy)
          .rotate(Random().nextDouble() * pi / 4);
      bounces++;
    }
    if (position.dy <= 0 || position.dy >= screenBounds.height) {
      direction = Offset(direction.dx, -direction.dy)
          .rotate(Random().nextDouble() * pi / 4);
      bounces++;
    }
  }
}

class DotPainter extends CustomPainter {
  final List<Dot> dots;

  DotPainter({required this.dots});

  @override
  void paint(Canvas canvas, Size size) {
    for (final dot in dots) {
      final paint = Paint()..color = dot.color;
      canvas.drawCircle(dot.position, dot.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Extension for vector normalisation and rotation
extension OffsetExtension on Offset {
  Offset normalize() {
    final length = sqrt(dx * dx + dy * dy);
    return length == 0 ? this : this / length;
  }

  Offset rotate(double angle) {
    final cosTheta = cos(angle);
    final sinTheta = sin(angle);
    return Offset(
      dx * cosTheta - dy * sinTheta,
      dx * sinTheta + dy * cosTheta,
    );
  }
}
