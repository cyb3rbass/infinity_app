import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import '12-video_page.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 20.0;
  static const double _courseCardHeight = 150.0;

  List<Map<String, dynamic>> _userCourses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserCourses();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCirc,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  Future<void> _fetchUserCourses() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');
      final regCoursesString = prefs.getString('reg_courses') ?? '[]';
      final List<dynamic> regCoursesJson = json.decode(regCoursesString);
      final List<String> regCourses = regCoursesJson.map((e) => e.toString()).toList();

      if (userId == null || token == null || regCourses.isEmpty) {
        throw Exception('User not authenticated or no registered courses');
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/get_user_courses.php'),
        body: {
          'user_id': userId,
          'token': token,
          'course_id': json.encode(regCourses),
        },
      ).timeout(const Duration(seconds: 30));

      if (response.body.isEmpty) {
        throw Exception('Empty response from server');
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _userCourses = List<Map<String, dynamic>>.from(data['courses'] ?? []);
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString().contains('Invalid user or token')
            ? 'خطأ في تسجيل الدخول. يرجى تسجيل الدخول مرة أخرى.'
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _fetchUserCourses();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false, // Disable back button
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Remove back button
          title: const Text(
            'دوراتي',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 26),
              onPressed: _fetchUserCourses,
              tooltip: 'تحديث',
            ),
          ],
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(0.1), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: LiquidPullToRefresh(
            onRefresh: _handleRefresh,
            color: cs.primary,
            backgroundColor: cs.surfaceVariant,
            height: 150,
            animSpeedFactor: 2,
            showChildOpacityTransition: false,
            child: _isLoading && _userCourses.isEmpty
                ? _buildShimmerLoader()
                : SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (_hasError)
                      SliverFillRemaining(child: _buildErrorState())
                    else if (_userCourses.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth < 600 ? _sectionPadding : _sectionPadding * 2,
                          vertical: _itemSpacing,
                        ),
                        sliver: SliverList.separated(
                          itemCount: _userCourses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
                          itemBuilder: (_, i) => _buildCourseCard(_userCourses[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = _calculateProgress(course['status']);
    final statusText = _getStatusText(course['status']);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          if (course['video_url'] == null || course['video_url'].isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('لا يوجد رابط فيديو لهذه الدورة', textDirection: TextDirection.rtl),
                backgroundColor: cs.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            return;
          }

          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => VideoPage(
                courseName: course['title'] ?? 'بدون عنوان',
                teacherName: course['teacher'] ?? 'غير محدد',
                courseId: int.parse(course['id'].toString()),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                cs.surfaceVariant.withOpacity(0.3),
                cs.surfaceVariant.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              textDirection: TextDirection.rtl,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Course thumbnail with progress border
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: _courseCardHeight * 0.8,
                      height: _courseCardHeight * 0.8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: cs.primary.withOpacity(0.2),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: cs.surfaceVariant,
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (progress > 0.0 && progress < 1.0)
                      CircularProgressIndicator(
                        value: progress,
                        backgroundColor: cs.surfaceVariant,
                        color: cs.primary,
                        strokeWidth: 3,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.rtl,
                    children: [
                      Text(
                        course['title'] ?? 'بدون عنوان',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                          fontSize: 18,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        course['teacher'] ?? 'غير محدد',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (progress < 1.0 && progress > 0.0)
                        Column(
                          children: [
                            Container(
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: cs.surfaceVariant,
                              ),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  width: MediaQuery.of(context).size.width * progress * 0.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(3),
                                    gradient: LinearGradient(
                                      colors: [cs.primary, cs.primaryContainer],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              textDirection: TextDirection.rtl,
                              children: [
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.primary,
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  statusText,
                                  style: tt.labelSmall?.copyWith(
                                    color: cs.onSurface.withOpacity(0.8),
                                    fontFamily: 'Tajawal',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else if (progress == 1.0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            statusText,
                            style: tt.labelSmall?.copyWith(
                              color: Colors.green,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
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
    );
  }

  double _calculateProgress(String? status) {
    switch (status) {
      case 'active':
        return 0.65;
      case 'inactive':
        return 0.0;
      default:
        return 0.0;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'active':
        return 'قيد التقدم';
      case 'inactive':
        return 'لم يبدأ بعد';
      default:
        return 'لم يبدأ بعد';
    }
  }

  Widget _buildEmptyState() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 100,
              color: cs.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد دورات مسجلة',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يمكنك تصفح الدورات المتاحة وتسجيل في ما يعجبك',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // TODO: Navigate to courses page
              },
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('تصفح الدورات',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 100,
              color: cs.error.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'تعذر تحميل الدورات',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _fetchUserCourses,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
              child: const Text('إعادة المحاولة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoader() {
    final cs = Theme.of(context).colorScheme;

    return Shimmer.fromColors(
      baseColor: cs.surfaceVariant.withOpacity(0.3),
      highlightColor: cs.surfaceVariant.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
                itemBuilder: (_, __) => Container(
                  height: _courseCardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}