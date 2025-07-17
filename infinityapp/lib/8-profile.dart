import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import '14-settings.dart';


class ProfilePage extends StatefulWidget {
  final VoidCallback onBack;                    // ← add this
  const ProfilePage({super.key, required this.onBack});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // User data from SharedPreferences
  String? fullName;
  String? email;
  String? phoneNumber;
  String? createdAt;
  String? profileImage;
  bool _isLoading = true;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;

  bool get isMounted => mounted;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (isMounted) {
        _animationController.forward();
        _loadUserData();
      }
    });
  }

  // Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (isMounted) {
        setState(() {
          fullName = prefs.getString('full_name') ?? 'غير متوفر';
          email = prefs.getString('email') ?? 'غير متوفر';
          phoneNumber = prefs.getString('phone_number') ?? 'غير متوفر';
          createdAt = prefs.getString('created_at') ?? 'غير متوفر';
          profileImage = prefs.getString('profile_image');
          _isLoading = false;
        });
      }
    } catch (e) {
      if (isMounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('خطأ في تحميل البيانات: $e');
      }
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (isMounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (isMounted) {
        _showSnackBar('خطأ في تسجيل الخروج: $e');
      }
    }
  }

  // Show password change dialog
  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تغيير كلمة المرور',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: oldPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('كلمة المرور القديمة'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور القديمة';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('كلمة المرور الجديدة'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء إدخال كلمة المرور الجديدة';
                          }
                          if (value.length < 6) {
                            return 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: _inputDecoration('تأكيد كلمة المرور الجديدة'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'الرجاء تأكيد كلمة المرور';
                          }
                          if (value != newPasswordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                          return null;
                        },
                        style: const TextStyle(fontFamily: 'Tajawal'),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await _updatePassword(
                        oldPasswordController.text,
                        newPasswordController.text,
                      );
                      if (isMounted) {
                        Navigator.pop(context);
                      }
                    }

                  },
                  style: _buttonStyle(context),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('تغيير', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            );
          },
        );
      },
    );

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  // Update password via API
  Future<void> _updatePassword(String oldPassword, String newPassword) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        if (isMounted) {
          _showSnackBar('خطأ: يجب تسجيل الدخول أولاً');
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (isMounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          });
        }
        return;
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/update_profile.php'),
        body: {
          'user_id': userId,
          'token': token,
          'action': 'update_password',
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        if (isMounted) {
          _showSnackBar('انتهت مهلة الطلب');
        }
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          if (isMounted) {
            _showSnackBar('تم تغيير كلمة المرور بنجاح');
          }
        } else {
          if (isMounted) {
            _showSnackBar('فشل تغيير كلمة المرور: ${responseData['message']}');
          }
        }
      } else {
        if (isMounted) {
          _showSnackBar('خطأ في الاتصال بالخادم');
        }
      }
    } catch (e) {
      if (isMounted) {
        _showSnackBar('خطأ: $e');
      }
    }
  }

  // Update full name dialog
  Future<void> _updateFullName() async {
    final nameController = TextEditingController(text: fullName);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تغيير الاسم الكامل',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration('الاسم الكامل'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال الاسم الكامل';
                    }
                    return null;
                  },
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  textDirection: TextDirection.rtl,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await _updateProfileField('full_name', nameController.text);
                      if (isMounted) {
                        Navigator.pop(context);
                      }
                    }

                  },
                  style: _buttonStyle(context),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('تحديث', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
  }

  // Update email dialog
  Future<void> _updateEmail() async {
    final emailController = TextEditingController(text: email);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تغيير البريد الإلكتروني',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration('البريد الإلكتروني'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال البريد الإلكتروني';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'الرجاء إدخال بريد إلكتروني صالح';
                    }
                    return null;
                  },
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  textDirection: TextDirection.rtl,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await _updateProfileField('email', emailController.text);
                      if (isMounted) {
                        Navigator.pop(context);
                      }
                    }

                  },
                  style: _buttonStyle(context),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('تحديث', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
  }

  // Update phone number dialog
  Future<void> _updatePhoneNumber() async {
    final phoneController = TextEditingController(text: phoneNumber);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تغيير رقم الهاتف',
                style: TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: phoneController,
                  decoration: _inputDecoration('رقم الهاتف'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رقم الهاتف';
                    }
                    if (!RegExp(r'^\+?\d{8,}$').hasMatch(value)) {
                      return 'الرجاء إدخال رقم هاتف صالح';
                    }
                    return null;
                  },
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  textDirection: TextDirection.rtl,
                  keyboardType: TextInputType.phone,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء', style: TextStyle(fontFamily: 'Tajawal')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      await _updateProfileField('phone_number', phoneController.text);
                      if (isMounted) {
                        Navigator.pop(context);
                      }
                    }

                  },
                  style: _buttonStyle(context),
                  child: isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('تحديث', style: TextStyle(fontFamily: 'Tajawal')),
                ),
              ],
            );
          },
        );
      },
    );

    phoneController.dispose();
  }

  // Update profile picture
  Future<void> _updateProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');
      if (userId == null || token == null) {
        if (isMounted) {
          _showSnackBar('خطأ: يجب تسجيل الدخول أولاً');
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (isMounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          });
        }
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://eclipsekw.com/InfinityCourses/update_profile.php'),
      );
      request.fields['user_id'] = userId;
      request.fields['token'] = token;
      request.fields['action'] = 'update_profile';
      request.files.add(await http.MultipartFile.fromPath('profile_image', pickedFile.path));

      final response = await request.send().timeout(const Duration(seconds: 30), onTimeout: () {
        if (isMounted) {
          _showSnackBar('انتهت مهلة الطلب');
        }
        throw TimeoutException('Request timed out');
      });
      final responseData = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData.body);
        if (jsonData['status'] == 'success') {
          if (isMounted) {
            setState(() {
              profileImage = jsonData['profile_image'];
            });
            await prefs.setString('profile_image', jsonData['profile_image']);
            _showSnackBar('تم تحديث الصورة الشخصية بنجاح');
          }
        } else {
          if (isMounted) {
            _showSnackBar('فشل تحديث الصورة: ${jsonData['message']}');
          }
        }
      } else {
        if (isMounted) {
          _showSnackBar('خطأ في الاتصال بالخادم');
        }
      }
    } catch (e) {
      if (isMounted) {
        _showSnackBar('خطأ: $e');
      }
    }
  }

  // Generic function to update profile fields
  Future<void> _updateProfileField(String field, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        if (isMounted) {
          _showSnackBar('خطأ: يجب تسجيل الدخول أولاً');
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (isMounted) {
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            }
          });
        }
        return;
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/update_profile.php'),
        body: {
          'user_id': userId,
          'token': token,
          'action': 'update_profile',
          field: value,
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        if (isMounted) {
          _showSnackBar('انتهت مهلة الطلب');
        }
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          if (isMounted) {
            setState(() {
              if (field == 'full_name') fullName = value;
              if (field == 'email') email = value;
              if (field == 'phone_number') phoneNumber = value;
            });
            await prefs.setString(field, value);
            _showSnackBar('تم تحديث $field بنجاح');
          }
        } else {
          if (isMounted) {
            _showSnackBar('فشل تحديث $field: ${responseData['message']}');
          }
        }
      } else {
        if (isMounted) {
          _showSnackBar('خطأ في الاتصال بالخادم');
        }
      }
    } catch (e) {
      if (isMounted) {
        _showSnackBar('خطأ: $e');
      }
    }
  }

  // Show snackbar for messages
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Tajawal')),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Input decoration for dialogs
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
      labelStyle: const TextStyle(fontFamily: 'Tajawal'),
      alignLabelWithHint: true,
    );
  }

  // Button style for dialogs
  ButtonStyle _buttonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      elevation: 2,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
    );
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'الملف الشخصي',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 18 : 22,
            color: cs.onSurface,
          ),
          textDirection: TextDirection.rtl,
        ),
        centerTitle: true,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth < 600 ? _sectionPadding : _sectionPadding * 1.5,
              vertical: _sectionPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProfileHeader(cs, tt, screenWidth),
                const SizedBox(height: _sectionPadding),
                _buildProfileSection(
                  title: 'المعلومات الشخصية',
                  icon: Icons.person_outline_rounded,
                  children: [
                    _buildInfoItem(
                      label: 'الاسم الكامل',
                      value: fullName ?? 'غير متوفر',
                      icon: Icons.person,
                      onTap: _updateFullName,
                    ),
                    const Divider(height: 1),
                    _buildInfoItem(
                      label: 'البريد الإلكتروني',
                      value: email ?? 'غير متوفر',
                      icon: Icons.email_outlined,
                      onTap: _updateEmail,
                    ),
                    const Divider(height: 1),
                    _buildInfoItem(
                      label: 'رقم الهاتف',
                      value: phoneNumber ?? 'غير متوفر',
                      icon: Icons.phone_iphone_rounded,
                      onTap: _updatePhoneNumber,
                    ),
                  ],
                ),
                const SizedBox(height: _sectionPadding),
                _buildProfileSection(
                  title: 'الإعدادات',
                  icon: Icons.settings_outlined,
                  children: [
                    _buildActionItem(
                      label: 'تغيير كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
              _buildActionItem(
                label: 'الإعدادات',
                icon: Icons.settings,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                },
              ),
                    const Divider(height: 1),
                    _buildActionItem(
                      label: 'الإشعارات',
                      icon: Icons.notifications_active_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: _sectionPadding),
                _buildProfileSection(
                  title: 'عام',
                  icon: Icons.info_outline_rounded,
                  children: [
                    _buildActionItem(
                      label: 'سياسة الخصوصية',
                      icon: Icons.privacy_tip_outlined,
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildActionItem(
                      label: 'الشروط والأحكام',
                      icon: Icons.description_outlined,
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildActionItem(
                      label: 'تواصل معنا',
                      icon: Icons.contact_support_outlined,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: _sectionPadding * 2),
                _buildLogoutButton(context),
                const SizedBox(height: _sectionPadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ColorScheme cs, TextTheme tt, double screenWidth) {
    return Column(
      children: [
        GestureDetector(
          onTap: _updateProfileImage,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.primary.withOpacity(0.3), width: 3),
                  ),
                  child: CircleAvatar(
                    radius: screenWidth < 400 ? 40 : 50,
                    backgroundColor: cs.surfaceVariant,
                    backgroundImage: profileImage != null && profileImage!.isNotEmpty
                        ? NetworkImage(profileImage!)
                        : const AssetImage('assets/images/profile.jpg'),
                  ),
                ),
                CircleAvatar(
                  radius: screenWidth < 400 ? 16 : 18,
                  backgroundColor: cs.primary,
                  child: Icon(Icons.edit_rounded, size: screenWidth < 400 ? 16 : 18, color: cs.onPrimary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: _itemSpacing),
        Text(
          fullName ?? 'غير متوفر',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 20 : 24,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: _smallSpacing),
        Text(
          createdAt != null && createdAt!.isNotEmpty
              ? 'عضو منذ ${createdAt!.substring(0, 4)}'
              : 'عضو منذ غير متوفر',
          style: tt.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 14 : 16,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildProfileSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: screenWidth < 400 ? 18 : 20, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: screenWidth < 400 ? 16 : 18,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
        ),
        const SizedBox(height: _itemSpacing),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: screenWidth < 400 ? 18 : 20,
              backgroundColor: cs.primary.withOpacity(0.1),
              child: Icon(icon, size: screenWidth < 400 ? 18 : 20, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    label,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withOpacity(0.6),
                      fontFamily: 'Tajawal',
                      fontSize: screenWidth < 400 ? 12 : 14,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: tt.bodyLarge?.copyWith(
                      fontFamily: 'Tajawal',
                      fontSize: screenWidth < 400 ? 14 : 16,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.edit_rounded,
                  size: screenWidth < 400 ? 16 : 18,
                  color: cs.onSurface.withOpacity(0.4),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required String label,
    required IconData icon,
    String? value,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: screenWidth < 400 ? 18 : 20,
              backgroundColor: cs.primary.withOpacity(0.1),
              child: Icon(icon, size: screenWidth < 400 ? 18 : 20, color: cs.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: tt.bodyLarge?.copyWith(
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth < 400 ? 14 : 16,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
            if (value != null)
              Text(
                value,
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth < 400 ? 12 : 14,
                ),
                textDirection: TextDirection.rtl,
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: screenWidth < 400 ? 14 : 16,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return FilledButton.icon(
      onPressed: _logout,
      icon: Icon(Icons.logout_rounded, color: cs.onErrorContainer),
      label: Text(
        'تسجيل الخروج',
        style: tt.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontFamily: 'Tajawal',
          fontSize: screenWidth < 400 ? 16 : 18,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: cs.errorContainer,
        foregroundColor: cs.onErrorContainer,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        shadowColor: cs.shadow.withOpacity(0.3),
      ),
    );
  }
}