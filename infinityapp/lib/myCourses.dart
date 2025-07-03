import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _courseCardWidth = 160.0;

  List<Map<String, dynamic>> userCourses = [];
  bool _isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
        _fetchUserCourses();
      }
    });
  }

  // Fetch user courses from API
  Future<void> _fetchUserCourses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');
      final regCourses = prefs.getInt('reg_courses'); // Changed from getString to getInt

      if (userId == null || token == null || regCourses == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            errorMessage = 'لم يتم العثور على دورات مسجلة';
          });
        }
        return;
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/get_user_courses.php'),
        body: {
          'user_id': userId,
          'token': token,
          'course_id': regCourses.toString(), // Convert int to String for API
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            errorMessage = 'انتهت مهلة الطلب';
          });
        }
        throw TimeoutException('Request timed out');
      });

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == 'success') {
          if (mounted) {
            setState(() {
              userCourses = List<Map<String, dynamic>>.from(responseData['courses']);
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
              errorMessage = responseData['message'] ?? 'فشل تحميل الدورات';
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            errorMessage = 'خطأ في الاتصال بالخادم';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          errorMessage = 'خطأ: $e';
        });
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'دوراتي',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 18 : 22,
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
          child: _buildCoursesList(context),
        ),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context) {
    if (userCourses.isEmpty) {
      return _buildEmptyState(context);
    }
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 600 ? _sectionPadding : _sectionPadding * 1.5),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: _itemSpacing, bottom: _sectionPadding * 2),
        itemCount: userCourses.length,
        separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
        itemBuilder: (context, index) => _buildCourseCard(context, userCourses[index]),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // Simulate progress and status for now, as database doesn't provide them
    final progress = course['status'] == 'ongoing' ? 0.65 : course['status'] == 'completed' ? 1.0 : 0.0;
    final completedDate = course['status'] == 'completed' ? '2025-07-01' : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      shadowColor: cs.shadow.withOpacity(0.2),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to course details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                  width: screenWidth < 400 ? _courseCardWidth * 0.8 : _courseCardWidth,
                  height: screenWidth < 400 ? 80 : 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: screenWidth < 400 ? _courseCardWidth * 0.8 : _courseCardWidth,
                      height: screenWidth < 400 ? 80 : 100,
                      color: cs.surfaceVariant.withOpacity(0.2),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: screenWidth < 400 ? _courseCardWidth * 0.8 : _courseCardWidth,
                    height: screenWidth < 400 ? 80 : 100,
                    color: cs.surfaceVariant,
                    child: Center(child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      course['major'] ?? 'غير محدد',
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        fontSize: screenWidth < 400 ? 12 : 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['title'] ?? 'غير متوفر',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                        fontSize: screenWidth < 400 ? 14 : 16,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مدة: ${course['duration'] ?? 'غير متوفر'}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                        fontFamily: 'Tajawal',
                        fontSize: screenWidth < 400 ? 12 : 13,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${course['ratings']?.toString() ?? 'غير متوفر'}',
                          style: tt.bodySmall?.copyWith(
                            fontFamily: 'Tajawal',
                            fontSize: screenWidth < 400 ? 12 : 13,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.star_rounded, size: screenWidth < 400 ? 14 : 16, color: cs.primary),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (course['status'] == 'ongoing')
                      _buildProgressIndicator(context, progress, screenWidth),
                    if (course['status'] == 'completed')
                      _buildCompletedBadge(context, completedDate, screenWidth),
                    if (course['status'] == 'saved')
                      _buildPriceTag(context, course['price']?.toString() ?? '0.00', screenWidth),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  course['status'] == 'saved' ? Icons.favorite_rounded : Icons.more_vert_rounded,
                  color: course['status'] == 'saved' ? cs.error : cs.onSurface.withOpacity(0.6),
                  size: screenWidth < 400 ? 20 : 24,
                ),
                onPressed: () {
                  // TODO: Handle saved/un-saved or show menu
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, double progress, double screenWidth) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${(progress * 100).toStringAsFixed(0)}% مكتمل',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.8),
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 11 : 12,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.surfaceVariant.withOpacity(0.3),
          color: cs.primary,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildCompletedBadge(BuildContext context, String? date, double screenWidth) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'تم الانتهاء في ${date ?? 'غير متوفر'}',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
            fontFamily: 'Tajawal',
            fontSize: screenWidth < 400 ? 11 : 12,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مكتمل',
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth < 400 ? 11 : 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: screenWidth < 400 ? 14 : 16, color: cs.primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTag(BuildContext context, String price, double screenWidth) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text(
      '$price د.ك',
      style: tt.titleMedium?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.bold,
        fontFamily: 'Tajawal',
        fontSize: screenWidth < 400 ? 14 : 16,
      ),
      textDirection: TextDirection.rtl,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: screenWidth < 400 ? 56 : 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              errorMessage ?? 'لا توجد دورات مسجلة',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
                fontFamily: 'Tajawal',
                fontSize: screenWidth < 400 ? 16 : 18,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            Text(
              'ابدأ دورة جديدة اليوم!',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
                fontFamily: 'Tajawal',
                fontSize: screenWidth < 400 ? 14 : 16,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: _itemSpacing),
            FilledButton(
              onPressed: () {
                // TODO: Navigate to browse courses
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                shadowColor: cs.shadow.withOpacity(0.3),
              ),
              child: Text(
                'تصفح الدورات',
                style: tt.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Tajawal',
                  fontSize: screenWidth < 400 ? 14 : 16,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ),
      ),
    );
  }
}