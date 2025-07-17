import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:math';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Controllers
  final TextEditingController name = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  // State variables
  File? profileImage;
  bool _isLoading = false;
  bool _isFetchingData = true;
  late AnimationController _controller;
  late Animation<double> _avatarAnim;
  late Animation<double> _formAnim;
  late Animation<double> _buttonsAnim;
  final List<AbstractShape> _shapes = [];
  final Color primaryColor = const Color(0xFF00A3A9);
  final Color secondaryColor = const Color(0xFFF36829);
  List<Map<String, dynamic>> universities = [];
  List<Map<String, dynamic>> majors = [];
  String? selectedUniversity;
  String? selectedMajor;
  String? selectedGender;

  // Focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _universityFocus = FocusNode();
  final FocusNode _majorFocus = FocusNode();
  final FocusNode _genderFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _avatarAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _formAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic));
    _buttonsAnim = CurvedAnimation(parent: _controller, curve: const Interval(0.4, 1.0, curve: Curves.decelerate));

    // Initialize abstract shapes
    for (int i = 0; i < 5; i++) {
      _shapes.add(AbstractShape(
        color: i.isEven ? primaryColor.withOpacity(0.06) : secondaryColor.withOpacity(0.06),
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _tickShapes());

    // Fetch universities and majors
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(Uri.parse('https://eclipsekw.com/InfinityCourses/fetch_data.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            universities = List<Map<String, dynamic>>.from(data['universities']);
            majors = List<Map<String, dynamic>>.from(data['majors']);
            _isFetchingData = false;
          });
        } else {
          showErrorSnackbar('فشل في جلب البيانات: ${data['message']}');
          setState(() => _isFetchingData = false);
        }
      } else {
        showErrorSnackbar('فشل في جلب البيانات: ${response.statusCode}');
        setState(() => _isFetchingData = false);
      }
    } catch (e) {
      showErrorSnackbar('حدث خطأ: ${e.toString()}');
      setState(() => _isFetchingData = false);
    }
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
    _pageController.dispose();
    _controller.dispose();
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    _nameFocus.dispose();
    _universityFocus.dispose();
    _majorFocus.dispose();
    _genderFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => profileImage = File(picked.path));
      }
    } catch (e) {
      showErrorSnackbar('فشل في اختيار الصورة: ${e.toString()}');
    }
  }

  Future<void> register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (password.text != confirmPassword.text) {
      showErrorSnackbar('كلمة المرور وتأكيدها غير متطابقين');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final uri = Uri.parse("https://eclipsekw.com/InfinityCourses/register.php");
      final request = http.MultipartRequest("POST", uri)
        ..fields.addAll({
          "full_name": name.text,
          "university": selectedUniversity ?? '',
          "major": selectedMajor ?? '',
          "gender": selectedGender ?? '',
          "phone_number": phone.text,
          "email": email.text,
          "password": password.text,
        });
      if (profileImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            profileImage!.path,
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }
      final response = await request.send();
      final body = await response.stream.bytesToString();
      if (response.statusCode == 200) {
        final data = json.decode(body);
        if (data['status'] == 'success') {
          showSuccessDialog();
        } else {
          showErrorSnackbar('فشل التسجيل: ${data['message']}');
        }
      } else {
        showErrorSnackbar('فشل التسجيل: $body');
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
      ),
    );
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: primaryColor, size: 60),
              const SizedBox(height: 20),
              const Text(
                'تم التسجيل بنجاح',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 10),
              const Text(
                'تم إنشاء حسابك بنجاح. يمكنك الآن تسجيل الدخول.',
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Tajawal'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('حسناً', style: TextStyle(color: Colors.white, fontFamily: 'Tajawal')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 2 && (_formKey.currentState?.validate() ?? false)) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
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

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'إنشاء حساب جديد',
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 24 : 12,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i ? primaryColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildPersonalInfoPage(),
                        _buildContactInfoPage(),
                        _buildSecurityInfoPage(),
                      ],
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _buttonsAnim,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      children: [
                        if (_currentPage > 0)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _previousPage,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryColor,
                                side: BorderSide(color: primaryColor),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('السابق', style: TextStyle(fontFamily: 'Tajawal')),
                            ),
                          ),
                        if (_currentPage > 0) const SizedBox(width: 16),
                        Expanded(
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
                              onPressed: _currentPage < 2 ? _nextPage : register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading && _currentPage == 2
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                _currentPage < 2 ? 'التالي' : 'تسجيل',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 17,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
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
                      'المعلومات الشخصية',
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
                GestureDetector(
                  onTap: pickImage,
                  child: ScaleTransition(
                    scale: _avatarAnim,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profileImage != null ? FileImage(profileImage!) : null,
                          child: profileImage == null
                              ? Icon(Icons.camera_alt, size: 30, color: Colors.grey.shade600)
                              : null,
                        ),
                        if (profileImage != null)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: primaryColor,
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: name,
                  focusNode: _nameFocus,
                  decoration: const InputDecoration(
                    labelText: "الاسم بالكامل",
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال الاسم' : null,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _universityFocus.requestFocus(),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                _isFetchingData
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                  focusNode: _universityFocus,
                  value: selectedUniversity,
                  decoration: const InputDecoration(
                    labelText: "الجامعة",
                    prefixIcon: Icon(Icons.school_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: universities.isEmpty
                      ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('لا توجد جامعات متاحة', style: TextStyle(fontFamily: 'Tajawal')),
                    ),
                  ]
                      : universities.map((uni) {
                    return DropdownMenuItem<String>(
                      value: uni['university_name'],
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4, // Constrain width
                        child: Text(
                          uni['university_name'],
                          style: const TextStyle(fontFamily: 'Tajawal' , color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedUniversity = value);
                    _majorFocus.requestFocus();
                  },
                  validator: (v) => v == null ? 'الرجاء اختيار الجامعة' : null,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                _isFetchingData
                    ? const CircularProgressIndicator()
                    : DropdownButtonFormField<String>(
                  focusNode: _majorFocus,
                  value: selectedMajor,
                  decoration: const InputDecoration(
                    labelText: "التخصص",
                    prefixIcon: Icon(Icons.menu_book_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: majors.isEmpty
                      ? [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('لا توجد تخصصات متاحة', style: TextStyle(fontFamily: 'Tajawal')),
                    ),
                  ]
                      : majors.map((major) {
                    return DropdownMenuItem<String>(
                      value: major['name_en'],
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.4, // Constrain width
                        child: Text(
                          major['name_en'],
                          style: const TextStyle(fontFamily: 'Tajawal' , color: Colors.black),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedMajor = value);
                    _nextPage();
                  },
                  validator: (v) => v == null ? 'الرجاء اختيار التخصص' : null,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
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
                      'معلومات التواصل',
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
                DropdownButtonFormField<String>(
                  focusNode: _genderFocus,
                  value: selectedGender,
                  decoration: const InputDecoration(
                    labelText: "الجنس",
                    prefixIcon: Icon(Icons.transgender),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'ذكر', child: Text('ذكر', style: TextStyle(fontFamily: 'Tajawal' ,color: Colors.black))),
                    DropdownMenuItem(value: 'أنثى', child: Text('أنثى', style: TextStyle(fontFamily: 'Tajawal', color: Colors.black))),
                  ],
                  onChanged: (value) {
                    setState(() => selectedGender = value);
                    _phoneFocus.requestFocus();
                  },
                  validator: (v) => v == null ? 'الرجاء اختيار الجنس' : null,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phone,
                  focusNode: _phoneFocus,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: "رقم الهاتف",
                    prefixIcon: Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال رقم الهاتف' : null,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: email,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: "البريد الإلكتروني",
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'الرجاء إدخال البريد الإلكتروني' : null,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _nextPage(),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: FadeTransition(
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
                      'معلومات الأمان',
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
                  controller: password,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "كلمة المرور",
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'الرجاء إدخال كلمة المرور';
                    if (v.length < 6) return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmPassword,
                  focusNode: _confirmPasswordFocus,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "تأكيد كلمة المرور",
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'الرجاء تأكيد كلمة المرور';
                    if (v != password.text) return 'كلمة المرور غير متطابقة';
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => register(),
                  style: const TextStyle(fontFamily: 'Tajawal'),
                ),
                const SizedBox(height: 24),
                Text(
                  'بتسجيلك فإنك توافق على الشروط والأحكام وسياسة الخصوصية',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Tajawal'),
                ),
              ],
            ),
          ),
        ),
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

// Abstract shape animation classes
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