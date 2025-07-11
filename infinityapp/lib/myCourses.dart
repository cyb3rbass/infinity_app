import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shimmer/shimmer.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _courseCardHeight = 120.0;

  List<Map<String, dynamic>> _userCourses = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchUserCourses();
    _setupAutoRefresh();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuart,
    ));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) _fetchUserCourses();
    });
  }

  Future<void> _fetchUserCourses() async {
    try {
      setState(() => _isLoading = true);

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');
      final regCourses = prefs.getInt('reg_courses');

      if (userId == null || token == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/get_user_courses.php'),
        body: {
          'user_id': userId,
          'token': token,
          'course_id': regCourses?.toString() ?? '',
        },
      ).timeout(const Duration(seconds: 30));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _userCourses = List<Map<String, dynamic>>.from(data['courses']);
          _isLoading = false;
          _hasError = false;
        });
      } else {
        throw Exception(data['message'] ?? 'Failed to load courses');
      }
    } catch (e) {
      final message = e.toString();

      if (message.contains('Missing required fields')) {
        // Backend is saying “you have no courses” → show empty state
        setState(() {
          _userCourses = [];
          _isLoading = false;
          _hasError = false; // clear the error flag
        });
      } else {
        // Any other real error → show your error state
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = message.replaceFirst('Exception: ', '');
        });
      }
    }
  }

    @override
  void dispose() {
    _animationController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: _isLoading && _userCourses.isEmpty
            ? _buildShimmerLoader()
            : SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    _sectionPadding,
                    _sectionPadding,
                    _sectionPadding,
                    _itemSpacing,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'دوراتي',
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: _fetchUserCourses,
                          tooltip: 'تحديث',
                        ),
                      ],
                    ),
                  ),
                ),

                // Content
                if (_hasError)
                  SliverFillRemaining(
                    child: _buildErrorState(),
                  )
                else if (_userCourses.isEmpty)
                  SliverFillRemaining(
                    child: _buildEmptyState(),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth < 600
                          ? _sectionPadding
                          : _sectionPadding * 2,
                    ),
                    sliver: SliverList.separated(
                      itemCount: _userCourses.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: _itemSpacing),
                      itemBuilder: (_, i) =>
                          _buildCourseCard(_userCourses[i]),
                    ),
                  ),
              ],
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

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to course details
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                  width: _courseCardHeight * 0.8,
                  height: _courseCardHeight * 0.8,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: _courseCardHeight * 0.8,
                    height: _courseCardHeight * 0.8,
                    color: cs.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Course Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      course['major'] ?? 'غير محدد',
                      style: tt.labelSmall?.copyWith(
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['title'] ?? 'بدون عنوان',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    if (progress < 1.0 && progress > 0.0)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: cs.surfaceVariant,
                            color: cs.primary,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: tt.labelSmall?.copyWith(
                                  color: cs.primary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                statusText,
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    else if (progress == 1.0)
                      Text(
                        statusText,
                        style: tt.labelSmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateProgress(String? status) {
    switch (status) {
      case 'ongoing':
        return 0.65;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'ongoing':
        return 'قيد التقدم';
      case 'completed':
        return 'مكتمل - ${DateTime.now().toString().substring(0, 10)}';
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
              size: 72,
              color: cs.onSurface.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد دورات مسجلة',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'يمكنك تصفح الدورات المتاحة وتسجيل في ما يعجبك',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                // TODO: Navigate to courses page
              },
              child: const Text('تصفح الدورات'),
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
              size: 72,
              color: cs.error.withOpacity(0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'حدث خطأ',
              style: tt.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'تعذر تحميل الدورات',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _fetchUserCourses,
              child: const Text('إعادة المحاولة'),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  width: 100,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
                itemBuilder: (_, __) => Container(
                  height: _courseCardHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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