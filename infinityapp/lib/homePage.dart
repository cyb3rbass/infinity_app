import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'profile.dart';
import 'settings.dart';
import 'myCourses.dart';
import 'course_overview.dart';
import 'viewcourses.dart'; // Import ViewCoursesPage
import 'package:shared_preferences/shared_preferences.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _showError = false;
  List<Map<String, dynamic>> _allCourses = [];
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;
  late AnimationController _refreshAnimationController;
  int _currentBottomNavIndex = 0;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;
  static const double _courseCardWidth = 220.0;

  String? fullName;
  String? userId;
  String? token;
  String? major;



  @override
  @override
  void initState() {
    super.initState();

    _bannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _checkSession(); // 🔐 Check session before loading user data
    _fetchCourses();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bannerAnimationController.forward();
    });
  }
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fullName = prefs.getString('full_name');
      userId = prefs.getString('user_id');
      token = prefs.getString('token');
      major = prefs.getString('major');
    });
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getString('user_id') != null;
    if (!isLoggedIn) {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } else {
      _loadUserData(); // 👈 Load user data if logged in
    }
  }


  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _showError = false;
      _refreshAnimationController.repeat();
    });
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final response = await http.get(
        Uri.parse('https://eclipsekw.com/InfinityCourses/fetch_courses.php'),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _allCourses = List<Map<String, dynamic>>.from(data['courses']).map((course) {
              return {
                'id': course['id'],
                'title': course['title'] ?? 'دورة',
                'description': course['description'] ?? '',
                'university': course['university'],
                'major': course['major'] ?? 'غير محدد',
                'thumbnail': course['thumbnail'] ?? '',
                'published_by': course['published_by'],
                'published_at': course['published_at'],
                'price': course['price']?.toString() ?? 'غير متوفر',
                'teacher_id': course['teacher_id'],
                'semester': course['semester'],
                'status': course['status'],
                'new_price': course['new_price'],
                'prev_price': course['prev_price'],
                'ratings': course['ratings']?.toString() ?? '4.5',
              };
            }).toList();

            _isLoading = false;
            _refreshAnimationController
              ..stop()
              ..reset();
          });
        } else {
          throw Exception('API returned error');
        }
      } else {
        throw Exception('Network error');
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _isLoading = false;
        _refreshAnimationController
          ..stop()
          ..reset();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAnimationController.dispose();
    _refreshAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: _buildSearchField(cs, tt, screenWidth),
          actions: _buildAppBarActions(cs),
          titleSpacing: _sectionPadding,
        ),
        body: _showError
            ? _buildErrorState(cs, tt, screenWidth)
            : _isLoading
            ? _buildLoadingState(cs, screenWidth)
            : _buildContent(cs, tt, screenWidth),
        bottomNavigationBar: _buildBottomNavigationBar(context, cs, tt, screenWidth),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _searchController.text = '',
          backgroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: Icon(Icons.search_rounded, color: cs.onPrimary),
          tooltip: 'بحث جديد',
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs, TextTheme tt, double screenWidth) {
    return Container(
      height: screenWidth < 400 ? 40 : 48,
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 2),
          ),
          BoxShadow(
            color: cs.surface.withOpacity(0.9),
            blurRadius: 8,
            offset: const Offset(-2, -2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        textDirection: TextDirection.rtl,
        style: tt.bodyMedium?.copyWith(
          fontFamily: 'Tajawal',
          color: cs.onSurface,
          fontSize: screenWidth < 400 ? 14 : 16,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث عن دورات...',
          hintStyle: tt.bodyMedium?.copyWith(
            fontFamily: 'Tajawal',
            color: cs.onSurface.withOpacity(0.5),
            fontSize: screenWidth < 400 ? 14 : 16,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: cs.onSurface.withOpacity(0.5),
            size: screenWidth < 400 ? 20 : 24,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenWidth < 400 ? 10 : 14,
            horizontal: _smallSpacing,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(ColorScheme cs) {
    return [
      IconButton(
        icon: Badge(
          backgroundColor: cs.primary,
          smallSize: 10,
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.notifications_outlined,
            color: cs.onSurface.withOpacity(0.8),
            size: 26,
          ),
        ),
        onPressed: () {},
      ),
      const SizedBox(width: _smallSpacing),
    ];
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, ColorScheme cs, TextTheme tt, double screenWidth) {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: (index) {
        if (index == _currentBottomNavIndex) return;
        setState(() => _currentBottomNavIndex = index);
        Widget page;
        String heroTag;
        switch (index) {
          case 1:
            page = const MyCoursesPage();
            heroTag = 'my_courses';
            break;
          case 2:
            page = const ProfilePage();
            heroTag = 'profile';
            break;
          case 3:
            page = const SettingsPage();
            heroTag = 'settings';
            break;
          default:
            return;
        }
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => Hero(
              tag: heroTag,
              child: page,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      },
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withOpacity(0.6),
      selectedLabelStyle: tt.labelMedium?.copyWith(
        fontFamily: 'Tajawal',
        fontWeight: FontWeight.bold,
        fontSize: screenWidth < 400 ? 12 : 14,
      ),
      unselectedLabelStyle: tt.labelMedium?.copyWith(
        fontFamily: 'Tajawal',
        fontSize: screenWidth < 400 ? 12 : 14,
      ),
      type: BottomNavigationBarType.fixed,
      elevation: 12,
      backgroundColor: cs.surface,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: screenWidth < 400 ? 22 : 26),
          label: 'الرئيسية',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book_outlined, size: screenWidth < 400 ? 22 : 26),
          label: 'دوراتي',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline, size: screenWidth < 400 ? 22 : 26),
          label: 'الملف الشخصي',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined, size: screenWidth < 400 ? 22 : 26),
          label: 'الإعدادات',
        ),
      ],
    );
  }

  Widget _buildContent(ColorScheme cs, TextTheme tt, double screenWidth) {
    return RefreshIndicator.adaptive(
      onRefresh: _fetchCourses,
      displacement: 60,
      strokeWidth: 2,
      backgroundColor: cs.surface,
      color: cs.primary,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildBannerCarousel(cs, tt, screenWidth)),
          _buildCourseSection(
            title: 'مقترحة لك',
            courses: major == null
                ? _allCourses
                : _allCourses.where((course) => course['major'] == major).toList(),
            screenWidth: screenWidth,
          ),
          _buildCourseSection(
            title: 'الأكثر مبيعاً',
            courses: _allCourses,
            screenWidth: screenWidth,
          ),
          _buildCourseSection(
            title: 'إصدارات جديدة',
            courses: _allCourses,
            screenWidth: screenWidth,
          ),
          SliverToBoxAdapter(child: SizedBox(height: _sectionPadding * 2)),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel(ColorScheme cs, TextTheme tt, double screenWidth) {
    return SizedBox(
      height: screenWidth < 400 ? 160 : 180,
      child: PageView.builder(
        itemCount: 3,
        itemBuilder: (context, index) => Padding(
          padding: EdgeInsets.symmetric(horizontal: _sectionPadding),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimatedBuilder(
                  animation: _bannerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(-50 * (1 - _bannerAnimation.value), 0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              cs.primary.withOpacity(0.9),
                              cs.secondary.withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  left: -50,
                  top: -50,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withOpacity(0.15),
                    ),
                    child: const SizedBox(width: 200, height: 200),
                  ),
                ),
                Positioned(
                  right: -30,
                  bottom: -30,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withOpacity(0.15),
                    ),
                    child: const SizedBox(width: 150, height: 150),
                  ),
                ),
                Positioned(
                  right: _itemSpacing,
                  left: _itemSpacing,
                  bottom: _itemSpacing,
                  child: ScaleTransition(
                    scale: _bannerAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'خصم 30% على جميع الدورات',
                          style: tt.titleLarge?.copyWith(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth < 400 ? 16 : 20,
                            height: 1.2,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: _smallSpacing),
                        Text(
                          'لمدة محدودة فقط',
                          style: tt.bodyMedium?.copyWith(
                            fontFamily: 'Tajawal',
                            color: Colors.white.withOpacity(0.9),
                            fontSize: screenWidth < 400 ? 12 : 14,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: _itemSpacing),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: cs.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth < 400 ? 12 : 16,
                              vertical: 8,
                            ),
                            elevation: 4,
                            shadowColor: cs.shadow.withOpacity(0.3),
                          ),
                          onPressed: () {},
                          child: Text(
                            'اكتشف الآن',
                            style: tt.labelLarge?.copyWith(
                              fontFamily: 'Tajawal',
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth < 400 ? 12 : 14,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildCourseSection({
    required String title,
    required List<Map<String, dynamic>> courses,
    required double screenWidth,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(_sectionPadding, _itemSpacing, _sectionPadding, _itemSpacing),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      title,
                      textDirection: TextDirection.rtl,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      maxLines: 1,
                      style: tt.titleLarge?.copyWith(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: screenWidth < 400 ? 16 : 20,
                        height: 1,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ViewCoursesPage(
                          courses: courses,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          'عرض الكل',
                          style: tt.bodyMedium?.copyWith(
                            fontFamily: 'Tajawal',
                            color: cs.primary,
                            fontSize: screenWidth < 400 ? 12 : 14,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: screenWidth < 400 ? 14 : 16,
                          color: cs.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: screenWidth < 400 ? 250 : 270,
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: _sectionPadding),
              scrollDirection: Axis.horizontal,
              reverse: true,
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
              itemBuilder: (context, index) {
                final course = courses[index];
                return SizedBox(
                  width: screenWidth < 400 ? _courseCardWidth * 0.8 : _courseCardWidth,
                  child: ClipRect(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: cs.outline.withOpacity(0.1), width: 1),
                      ),
                      shadowColor: cs.shadow.withOpacity(0.2),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CourseOverviewPage(course: course),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            textDirection: TextDirection.rtl,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                                  height: screenWidth < 400 ? 100 : 120,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: screenWidth < 400 ? 100 : 120,
                                      width: double.infinity,
                                      color: cs.surfaceVariant.withOpacity(0.2),
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                              : null,
                                          strokeWidth: 2,
                                          color: cs.primary,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: screenWidth < 400 ? 100 : 120,
                                    width: double.infinity,
                                    color: cs.surfaceVariant,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: cs.onSurfaceVariant,
                                        size: screenWidth < 400 ? 20 : 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Flexible(
                                child: Text(
                                  course['title'] ?? '',
                                  softWrap: true, // Allows text to wrap if needed
                                  maxLines: 3, // Keeps up to 3 lines but allows full text
                                  overflow: TextOverflow.visible, // Prevents truncation
                                  textDirection: TextDirection.rtl,
                                  style: tt.bodyLarge?.copyWith(
                                    fontFamily: 'Tajawal',
                                    fontWeight: FontWeight.bold,
                                    fontSize: screenWidth < 400 ? 12 : 14, // Slightly reduced for better fit
                                  ),
                                  textScaleFactor: screenWidth < 400 ? 0.9 : 1.0, // Scales text down on smaller screens
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text(
                                    '${course['price']} د.ك',
                                    style: tt.titleMedium?.copyWith(
                                      fontFamily: 'Tajawal',
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                      fontSize: screenWidth < 400 ? 13 : 15,
                                    ),
                                    textDirection: TextDirection.rtl,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite_border_rounded,
                                      color: cs.onSurface.withOpacity(0.6),
                                      size: screenWidth < 400 ? 16 : 18,
                                    ),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: _itemSpacing),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme cs, TextTheme tt, double screenWidth) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: screenWidth < 400 ? 40 : 48,
              color: cs.error.withOpacity(0.8),
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              'حدث خطأ في تحميل البيانات',
              style: tt.titleMedium?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: screenWidth < 400 ? 16 : 18,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              'الرجاء التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                fontFamily: 'Tajawal',
                color: cs.onSurface.withOpacity(0.6),
                fontSize: screenWidth < 400 ? 14 : 16,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: _itemSpacing),
            ElevatedButton.icon(
              onPressed: _fetchCourses,
              icon: RotationTransition(
                turns: Tween(begin: 0.0, end: 1.0).animate(_refreshAnimationController),
                child: Icon(
                  Icons.refresh_rounded,
                  size: screenWidth < 400 ? 18 : 20,
                  color: cs.onPrimary,
                ),
              ),
              label: Text(
                'إعادة المحاولة',
                style: tt.labelLarge?.copyWith(
                  fontFamily: 'Tajawal',
                  color: cs.onPrimary,
                  fontSize: screenWidth < 400 ? 14 : 16,
                ),
                textDirection: TextDirection.rtl,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 400 ? 20 : 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: cs.shadow.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ColorScheme cs, double screenWidth) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(_sectionPadding),
            child: Shimmer.fromColors(
              baseColor: cs.surfaceVariant.withOpacity(0.3),
              highlightColor: cs.surfaceVariant.withOpacity(0.1),
              child: Container(
                height: screenWidth < 400 ? 160 : 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: _itemSpacing * 2, right: _sectionPadding),
            child: Shimmer.fromColors(
              baseColor: cs.surfaceVariant.withOpacity(0.3),
              highlightColor: cs.surfaceVariant.withOpacity(0.1),
              child: Container(
                width: 120,
                height: screenWidth < 400 ? 20 : 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: _itemSpacing, right: _sectionPadding, bottom: _itemSpacing),
            child: SizedBox(
              height: screenWidth < 400 ? 250 : 270,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                reverse: true,
                itemCount: 4,
                padding: EdgeInsets.only(left: _sectionPadding),
                separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: cs.surfaceVariant.withOpacity(0.3),
                  highlightColor: cs.surfaceVariant.withOpacity(0.1),
                  child: SizedBox(
                    width: screenWidth < 400 ? _courseCardWidth * 0.8 : _courseCardWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          textDirection: TextDirection.rtl,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: screenWidth < 400 ? 100 : 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              height: screenWidth < 400 ? 13 : 15,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: 100,
                              height: screenWidth < 400 ? 10 : 12,
                              color: Colors.white,
                            ),
                            const Spacer(),
                            Container(
                              width: 80,
                              height: screenWidth < 400 ? 13 : 15,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}