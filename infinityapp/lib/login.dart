import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'register.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController phoneNumber = TextEditingController();
  final TextEditingController password = TextEditingController();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _controller;
  late Animation<double> _avatarAnim;
  late Animation<double> _formAnim;
  late Animation<double> _buttonsAnim;
  final List<AbstractShape> _shapes = [];
  final Color primaryColor = const Color(0xFF00A3A9);
  final Color secondaryColor = const Color(0xFFF36829);

  @override
  void initState() {
    super.initState();
    try {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1200),
      )..forward();
      _initializeAnimations();
      for (int i = 0; i < 5; i++) {
        _shapes.add(AbstractShape(
          color: i.isEven ? primaryColor.withOpacity(0.06) : secondaryColor.withOpacity(0.06),
        ));
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _tickShapes());
    } catch (e) {
      print('Error initializing animations: $e');
      showErrorSnackbar('حدث خطأ أثناء تحميل الصفحة');
    }
  }

  void _initializeAnimations() {
    _avatarAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _formAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic));
    _buttonsAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.decelerate));
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
    phoneNumber.dispose();
    password.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://eclipsekw.com/InfinityCourses/login.php"),
        body: {
          'phone_number': phoneNumber.text,
          'password': password.text,
          'action': 'login',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          // Save user data and token to SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_id', responseData['user']['id'].toString());
          await prefs.setString('full_name', responseData['user']['full_name'] ?? '');
          await prefs.setString('profile_image', responseData['user']['profile_image'] ?? '');
          await prefs.setString('university', responseData['user']['university'] ?? '');
          await prefs.setString('major', responseData['user']['major'] ?? '');
          await prefs.setString('gender', responseData['user']['gender'] ?? '');
          await prefs.setString('phone_number', responseData['user']['phone_number'] ?? '');
          await prefs.setString('email', responseData['user']['email'] ?? '');
          await prefs.setString('created_at', responseData['user']['created_at'] ?? '');
          await prefs.setString('role', responseData['user']['role'] ?? 'student');
          await prefs.setString('token', responseData['user']['token'] ?? '');
// Store reg_courses as a stringified JSON array in SharedPreferences
          if (responseData['user']['reg_courses'] != null) {
            await prefs.setString('reg_courses', json.encode(responseData['user']['reg_courses']));
          } else {
            await prefs.setString('reg_courses', '[]');
          }

          Navigator.pushReplacementNamed(context, '/home');
        } else {
          showErrorSnackbar('فشل تسجيل الدخول: ${responseData['message']}');
        }
      } else {
        showErrorSnackbar('فشل تسجيل الدخول: رقم الهاتف أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      showErrorSnackbar('حدث خطأ: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        backgroundColor: Theme.of(context).colorScheme.error,
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
        color: Colors.white.withOpacity(0.15),
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
    final cs = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // <<--- THIS REMOVES THE BACK ARROW
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'تسجيل الدخول',
          // ...
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    Image.asset(
                      'assets/images/7605750.jpg',
                      width: 500,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 32),
                    FadeTransition(
                      opacity: _formAnim,
                      child: glassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildAnimatedIcon(Icons.auto_awesome, 0),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Tajawal',
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  _buildAnimatedIcon(Icons.auto_awesome, 2),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: phoneNumber,
                                focusNode: _phoneFocus,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: "رقم الهاتف",
                                  prefixIcon: Icon(
                                    Icons.phone_outlined,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                  filled: true,
                                  fillColor: cs.surfaceVariant.withOpacity(0.1),
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
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: password,
                                focusNode: _passwordFocus,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: "كلمة المرور",
                                  prefixIcon: Icon(
                                    Icons.lock_outlined,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  filled: true,
                                  fillColor: cs.surfaceVariant.withOpacity(0.1),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
                                  ),
                                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
                                  if (v.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                                  return null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => login(),
                                style: const TextStyle(fontFamily: 'Tajawal'),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot');
                                  },
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      color: primaryColor,
                                      fontFamily: 'Tajawal',
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),

                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _buttonsAnim,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'تسجيل الدخول',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 17,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeTransition(
                      opacity: _buttonsAnim,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'ليس لديك حساب؟ ',
                            style: TextStyle(fontFamily: 'Tajawal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegistrationPage()),
                            ),
                            child: Text(
                              'إنشاء حساب جديد',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildAnimatedIcon(IconData icon, double delay) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2 * pi,
          child: Transform.translate(
            offset: Offset(0, -8 * sin(_controller.value * 2 * pi + delay)),
            child: Icon(
              icon,
              color: secondaryColor,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}

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