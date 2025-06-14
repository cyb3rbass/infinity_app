import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<AbstractShape> _shapes = [];
  final Color primaryColor = const Color(0xFF00A3A9);
  final Color secondaryColor = const Color(0xFFF36829);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize abstract shapes
    for (int i = 0; i < 8; i++) {
      _shapes.add(AbstractShape(
        color: i.isEven ? const Color(0xFF00A3A9).withOpacity(0.08) : const Color(0xFFF36829).withOpacity(0.08),
      )
        );
      }
      }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // White background
          Container(color: Colors.white),

          // Abstract shapes background
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              _updateShapes();
              return CustomPaint(
                painter: AbstractShapePainter(_shapes),
                size: Size(screenWidth, screenHeight),
              );
            },
          ),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // Logo with floating animation
                  Hero(
                    tag: 'logo',
                    child: AnimatedContainer(
                      duration: const Duration(seconds: 3),
                      curve: Curves.easeInOut,
                      transform: Matrix4.translationValues(
                        0,
                        -15 * (0.5 + 0.5 * sin(_controller.value * 2 * pi)),
                        0,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryColor.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                                stops: const [0.1, 1.0],
                              ),
                            ),
                          ),
                          Image.asset(
                            'assets/images/gif3.gif',
                            height: 300,
                            filterQuality: FilterQuality.high,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Modern title with gradient and symbols
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAnimatedIcon(Icons.auto_awesome, 0),
                          const SizedBox(width: 12),
                          Text(
                            'هلا والله فيكم في',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w300,
                              color: Colors.grey.shade700,
                              letterSpacing: 1.2,
                              fontFamily: 'Tajawal', // Arabic font
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildAnimatedIcon(Icons.auto_awesome, 2),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          'Infinity Courses',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                            letterSpacing: 1.5,
                            fontFamily: 'Tajawal', // Arabic font
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Description with animated entry
                  AnimatedOpacity(
                    opacity: 1,
                    duration: const Duration(seconds: 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                height: 1.6,
                                fontFamily: 'Tajawal', // Arabic font
                              ),
                              children: const [
                                TextSpan(text: 'منصة التعلم الذكية التي تفتح '),
                                TextSpan(
                                  text: 'آفاقاً جديدة',
                                  style: TextStyle(
                                    decorationColor: Color(0xFFF36829),
                                    decorationThickness: 2,
                                    decorationStyle: TextDecorationStyle.wavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'للمعرفة والتميز الأكاديمي',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Tajawal', // Arabic font
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Modern buttons with animation
                  Column(
                    children: [
                      // Gradient button with shine effect
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOut,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/starting'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedPositioned(
                                duration: const Duration(seconds: 2),
                                curve: Curves.easeInOut,
                                left: _controller.value * 200 - 50,
                                child: Container(
                                  width: 50,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'ابدأ رحلة التعلم',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      fontFamily: 'Tajawal', // Arabic font
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  AnimatedRotation(
                                    turns: _controller.value,
                                    duration: const Duration(seconds: 8),
                                    child: const Icon(Icons.arrow_forward_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Secondary button with elegant animation
                      MouseRegion(
                        onHover: (_) => _controller.forward(),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  transform: Matrix4.translationValues(
                                    _controller.value * 5,
                                    0,
                                    0,
                                  ),
                                  child: Text(
                                    'لديك حساب بالفعل؟ سجل الدخول',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Tajawal', // Arabic font
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_right_alt_rounded,
                                  color: secondaryColor,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, double delay) {
    return AnimatedRotation(
      turns: _controller.value,
      duration: const Duration(seconds: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          0,
          -8 * sin(_controller.value * 2 * pi + delay),
          0,
        ),
        child: Icon(
          icon,
          color: secondaryColor,
          size: 24,
        ),
      ),
    );
  }

  void _updateShapes() {
    for (var shape in _shapes) {
      shape.update();
    }
  }
}

// Abstract shape animation classes
class AbstractShape {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 100 + 50;
  double rotation = Random().nextDouble() * 2 * pi;
  double rotationSpeed = Random().nextDouble() * 0.02 - 0.01;
  double xSpeed = Random().nextDouble() * 0.5 - 0.25;
  double ySpeed = Random().nextDouble() * 0.5 - 0.25;
  Color color;
  int shapeType = Random().nextInt(3);

  AbstractShape({required this.color});

  void update() {
    x += xSpeed * 0.01;
    y += ySpeed * 0.01;
    rotation += rotationSpeed;

    if (x < -0.2) x = 1.2;
    if (x > 1.2) x = -0.2;
    if (y < -0.2) y = 1.2;
    if (y > 1.2) y = -0.2;
  }
}

class AbstractShapePainter extends CustomPainter {
  final List<AbstractShape> shapes;

  AbstractShapePainter(this.shapes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var shape in shapes) {
      paint.color = shape.color;

      final center = Offset(shape.x * size.width, shape.y * size.height);
      final rect = Rect.fromCenter(
        center: center,
        width: shape.size,
        height: shape.size,
      );

      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation);
      canvas.translate(-center.dx, -center.dy);

      switch (shape.shapeType) {
        case 0:
        // Circle
          canvas.drawCircle(center, shape.size / 2, paint);
          break;
        case 1:
        // Rounded rectangle
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(shape.size / 4)),
            paint,
          );
          break;
        case 2:
        // Triangle
          final path = Path();
          path.moveTo(center.dx, center.dy - shape.size / 2);
          path.lineTo(center.dx + shape.size / 2, center.dy + shape.size / 2);
          path.lineTo(center.dx - shape.size / 2, center.dy + shape.size / 2);
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}