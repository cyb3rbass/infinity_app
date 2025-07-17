import 'package:flutter/material.dart';
import 'dart:math';

class StartingPage extends StatefulWidget {
  const StartingPage({super.key});

  @override
  State<StartingPage> createState() => _StartingPageState();
}

class _StartingPageState extends State<StartingPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoAnim;
  late Animation<double> _cardAnim;
  late Animation<double> _buttonsAnim;
  final List<AbstractShape> _shapes = [];
  final Color primaryColor = const Color(0xFF00A3A9);
  final Color secondaryColor = const Color(0xFFF36829);

  // For background shape animation
  late AnimationController _bgController;

  @override
  void initState() {
    super.initState();

    // Main animations (ONE TIME, FASTER)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _logoAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _cardAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic));
    _buttonsAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1, curve: Curves.decelerate));
    _controller.forward();

    // Separate infinite background animation controller
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initialize abstract shapes
    for (int i = 0; i < 8; i++) {
      _shapes.add(AbstractShape(
        color: i.isEven ? primaryColor.withOpacity(0.08) : secondaryColor.withOpacity(0.08),
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  Widget glassCard({required Widget child, double blur = 16}) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.18),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    ),
  );

  void _updateShapes() {
    for (var shape in _shapes) {
      shape.update();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,

      ),
      body: Stack(
        children: [
          // White background
          Container(color: Colors.white),

          // Abstract shapes background
          AnimatedBuilder(
            animation: _bgController,
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
                  // Logo with single zoom-in animation
                  Hero(
                    tag: 'logo',
                    child: ScaleTransition(
                      scale: _logoAnim,
                      child: AnimatedBuilder(
                        animation: _bgController,
                        builder: (context, child) {
                          return AnimatedContainer(
                            duration: const Duration(seconds: 3),
                            curve: Curves.easeInOut,
                            transform: Matrix4.translationValues(
                              0,
                              -15 * (0.5 + 0.5 * sin(_bgController.value * 2 * pi)),
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
                                  'assets/images/starting.jpg',
                                  height: 300,
                                  filterQuality: FilterQuality.high,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: _cardAnim,
                    child: glassCard(
                      blur: 18,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                        child: Column(
                          children: [
                            Text(
                              'اختر طريقة المتابعة',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.grey.shade700,
                                letterSpacing: 1.2,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'سجل الدخول أو أنشئ حساب جديد للوصول إلى جميع الميزات',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 29),
                  FadeTransition(
                    opacity: _buttonsAnim,
                    child: Column(
                      children: [
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
                            onPressed: () => Navigator.pushNamed(context, '/login'),
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
                                // Remove animated position zoom, keep the rest simple
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'تسجيل الدخول',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        fontFamily: 'Tajawal',
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Fast, single rotation on appear
                                    AnimatedBuilder(
                                      animation: _logoAnim,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle: _logoAnim.value * 2 * pi,
                                          child: const Icon(Icons.arrow_forward_rounded),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        MouseRegion(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, width: 1.5),
                            ),
                            child: InkWell(
                              onTap: () => Navigator.pushNamed(context, '/register'),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _logoAnim,
                                    builder: (context, child) {
                                      return Transform.translate(
                                        offset: Offset(_logoAnim.value * 5, 0),
                                        child: Text(
                                          'إنشاء حساب جديد',
                                          style: theme.textTheme.titleMedium?.copyWith(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w500,
                                            fontFamily: 'Tajawal',
                                          ),
                                        ),
                                      );
                                    },
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
                  ),
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
