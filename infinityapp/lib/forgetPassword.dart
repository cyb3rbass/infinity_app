import 'package:flutter/material.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneController = TextEditingController();
  bool _isLoading = false;
  bool _sent = false;

  late AnimationController _controller;
  late Animation<double> _anim;
  final List<AbstractShape> _shapes = [];
  final Color primaryColor = const Color(0xFF00A3A9);
  final Color secondaryColor = const Color(0xFFF36829);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    for (int i = 0; i < 6; i++) {
      _shapes.add(AbstractShape(
        color: i.isEven
            ? primaryColor.withOpacity(0.07)
            : secondaryColor.withOpacity(0.07),
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tickShapes());
  }

  void _tickShapes() {
    if (mounted) {
      setState(() {
        for (var shape in _shapes) {
          shape.update();
        }
      });
      Future.delayed(const Duration(milliseconds: 150), _tickShapes);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _sent = false;
    });

    try {
      // TODO: change to your API endpoint and fields
      final response = await http.post(
        Uri.parse("https://eclipsekw.com/InfinityCourses/forgot_password.php"),
        body: {'phone_number': phoneController.text, 'action': 'forgot_password'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() => _sent = true);
          _showSnackbar('تم إرسال رمز الاستعادة إلى هاتفك.');
        } else {
          _showSnackbar('فشل: ${data['message']}');
        }
      } else {
        _showSnackbar('فشل الاتصال بالخادم.');
      }
    } catch (e) {
      _showSnackbar('حدث خطأ: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
    );
  }

  Widget glassCard({required Widget child}) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.17),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'نسيت كلمة المرور',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w700,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(color: Colors.white),
          CustomPaint(
            painter: AbstractShapePainter(_shapes),
            size: Size.infinite,
          ),
          SafeArea(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 64),
                    Image.asset(
                      'assets/images/forgot_password.png', // ← put your asset here!
                      width: 230,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _anim,
                      child: glassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              const Text(
                                'استعادة كلمة المرور',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Tajawal',
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: "رقم الهاتف",
                                  prefixIcon: Icon(
                                    Icons.phone_android_outlined,
                                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.13),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'الرجاء إدخال رقم الهاتف';
                                  if (!RegExp(r'^\d{8,}$').hasMatch(v)) {
                                    return 'رقم الهاتف غير صالح';
                                  }
                                  return null;
                                },
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                              const SizedBox(height: 20),
                              _isLoading
                                  ? const CircularProgressIndicator()
                                  : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _sent ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 0,
                                  ),
                                  child: const Text(
                                    'إرسال رمز الاستعادة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                              ),
                              if (_sent)
                                Padding(
                                  padding: const EdgeInsets.only(top: 18),
                                  child: Text(
                                    'تم إرسال رمز الاستعادة! تحقق من رسائل هاتفك.',
                                    style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Tajawal',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// AbstractShape and AbstractShapePainter classes as in your previous pages
class AbstractShape {
  double x = Random().nextDouble();
  double y = Random().nextDouble();
  double size = Random().nextDouble() * 60 + 40;
  double rotation = Random().nextDouble() * 2 * pi;
  double rotationSpeed = Random().nextDouble() * 0.01 - 0.005;
  double xSpeed = Random().nextDouble() * 0.3 - 0.15;
  double ySpeed = Random().nextDouble() * 0.3 - 0.15;
  Color color;
  int shapeType = Random().nextInt(2);

  AbstractShape({required this.color});

  void update() {
    x += xSpeed * 0.01;
    y += ySpeed * 0.01;
    rotation += rotationSpeed;
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;
    if (y < -0.1) y = 1.1;
    if (y > 1.1) y = -0.1;
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
      final rect = Rect.fromCenter(center: center, width: shape.size, height: shape.size);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(shape.rotation);
      canvas.translate(-center.dx, -center.dy);
      switch (shape.shapeType) {
        case 0:
          canvas.drawCircle(center, shape.size / 2, paint);
          break;
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(shape.size / 4)),
            paint,
          );
          break;
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
