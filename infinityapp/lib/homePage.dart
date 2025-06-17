import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  int _selectedCategoryIndex = 0;
  bool _isLoading = true;
  bool _showError = false;
  List<Map<String, dynamic>> _allCourses = [];
  late AnimationController _bannerAnimationController;
  late Animation<double> _bannerAnimation;
  late AnimationController _refreshAnimationController;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;
  static const double _chipSpacing = 12.0;
  static const double _courseCardWidth = 220.0;

  final List<String> categories = [
    'الكل',
    'التصميم',
    'البرمجة',
    'التسويق',
    'اللغات',
    'التطوير الذاتي'
  ];

  @override
  void initState() {
    super.initState();

    // Banner animation setup
    _bannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerAnimationController,
      curve: Curves.easeInOut,
    );

    // Refresh animation setup
    _refreshAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fetchCourses();

    // Start animations after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bannerAnimationController.forward();
    });
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _showError = false;
      _refreshAnimationController.repeat();
    });

    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay

    try {
      final response = await http.get(
        Uri.parse('https://eclipsekw.com/InfinityCourses/fetch_courses.php'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _allCourses = List<Map<String, dynamic>>.from(data['courses']);
            _isLoading = false;
            _refreshAnimationController.stop();
            _refreshAnimationController.reset();
          });
        } else {
          setState(() {
            _showError = true;
            _isLoading = false;
            _refreshAnimationController.stop();
            _refreshAnimationController.reset();
          });
        }
      } else {
        setState(() {
          _showError = true;
          _isLoading = false;
          _refreshAnimationController.stop();
          _refreshAnimationController.reset();
        });
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _isLoading = false;
        _refreshAnimationController.stop();
        _refreshAnimationController.reset();
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

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Container(
          height: 48,
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: cs.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'ابحث عن دورات...',
              hintStyle: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.5),
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: cs.onSurface.withOpacity(0.5),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        actions: [
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
          PopupMenuButton<String>(
            child: Padding(
              padding: const EdgeInsets.only(right: _sectionPadding),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cs.primary.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: const AssetImage('assets/images/profile.jpg'),
                ),
              ),
            ),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  Navigator.pushReplacementNamed(context, '/login');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, color: cs.onSurface),
                      const SizedBox(width: 12),
                      Text('الملف الشخصي'),
                    ],
                  )),
              PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_outlined, color: cs.onSurface),
                      const SizedBox(width: 12),
                      Text('الإعدادات'),
                    ],
                  )),
              const PopupMenuDivider(),
              PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: cs.error),
                      const SizedBox(width: 12),
                      Text('تسجيل الخروج'),
                    ],
                  )),
            ],
          ),
        ],
      ),
      body: _showError
          ? _buildErrorState(cs, tt)
          : _isLoading
          ? _buildLoadingState()
          : RefreshIndicator.adaptive(
        onRefresh: _fetchCourses,
        displacement: 60,
        strokeWidth: 2,
        backgroundColor: cs.surface,
        color: cs.primary,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
                child: _buildBannerCarousel(cs, tt)),
            SliverToBoxAdapter(
                child: _buildCategoryChips(cs, tt)),
            _buildCourseSection(
              title: 'مقترحة لك',
              courses: _allCourses,
            ),
            _buildCourseSection(
              title: 'الأكثر مبيعاً',
              courses: _allCourses,
            ),
            _buildCourseSection(
              title: 'إصدارات جديدة',
              courses: _allCourses,
            ),
            const SliverToBoxAdapter(
                child: SizedBox(height: _sectionPadding * 2)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme cs, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        _sectionPadding,
        _itemSpacing,
        _sectionPadding,
        _itemSpacing,
      ),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, __) => const SizedBox(width: _chipSpacing),
          itemBuilder: (context, index) {
            final selected = index == _selectedCategoryIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
                    : null,
              ),
              child: ChoiceChip(
                label: Text(
                  categories[index],
                  style: tt.labelLarge?.copyWith(
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategoryIndex = index),
                selectedColor: cs.primary,
                backgroundColor: cs.surfaceVariant.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: _itemSpacing,
                  vertical: _smallSpacing,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected
                        ? Colors.transparent
                        : cs.outline.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                elevation: 0,
                showCheckmark: false,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBannerCarousel(ColorScheme cs, TextTheme tt) {
    return ScaleTransition(
      scale: _bannerAnimation,
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primary.withOpacity(0.8),
                          cs.primaryContainer.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -30,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.primary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _itemSpacing,
                    right: _itemSpacing,
                    bottom: _itemSpacing,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'خصم 30% على جميع الدورات',
                          style: tt.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: _smallSpacing),
                        Text(
                          'لمدة محدودة فقط',
                          style: tt.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        const SizedBox(height: _itemSpacing),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Text(
                            'إكتشف الآن',
                            style: tt.labelLarge?.copyWith(
                              color: cs.primary,
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
      ),
    );
  }

  SliverToBoxAdapter _buildCourseSection({
    required String title,
    required List<Map<String, dynamic>> courses,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              _sectionPadding,
              _itemSpacing,
              _sectionPadding,
              _itemSpacing,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: tt.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          'عرض الكل',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
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
            height: 260,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
              itemBuilder: (context, index) {
                final course = courses[index];
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: SizedBox(
                    width: _courseCardWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: cs.surfaceVariant.withOpacity(0.05),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    Image.network(
                                      'https://eclipsekw.com/InfinityCourses/${course['image']}',
                                      height: 80,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (BuildContext context, Widget child,
                                          ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 80,
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
                                      errorBuilder: (context, error, stackTrace) =>
                                          Container(
                                            height: 80,
                                            width: double.infinity,
                                            color: cs.surfaceVariant,
                                            child: Center(
                                              child: Icon(
                                                Icons.broken_image_rounded,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      left: 8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: cs.primary.withOpacity(0.9),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'جديد',
                                          style: tt.labelSmall?.copyWith(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                course['title'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                course['major'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: tt.bodySmall?.copyWith(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded,
                                      size: 16, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    (course['rating'] ?? '4.5').toString(),
                                    style: tt.bodySmall,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    course['comments'] != null
                                        ? '(${course['comments']})'
                                        : '(120)',
                                    style: tt.bodySmall?.copyWith(
                                      color: cs.onSurface.withOpacity(0.4),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${course['price']} د.ك',
                                    style: tt.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: cs.primary,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.favorite_border_rounded,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                    onPressed: () {},
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    iconSize: 20,
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

  Widget _buildErrorState(ColorScheme cs, TextTheme tt) => Center(
    child: Padding(
      padding: const EdgeInsets.all(_sectionPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 48, color: cs.error.withOpacity(0.8)),
          const SizedBox(height: _itemSpacing),
          Text(
            'حدث خطأ في تحميل البيانات',
            style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'الرجاء التحقق من اتصال الإنترنت والمحاولة مرة أخرى',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: _itemSpacing),
          FilledButton(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: _itemSpacing * 1.5,
                vertical: _smallSpacing * 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: cs.primary,
            ),
            onPressed: _fetchCourses,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 1.0)
                      .animate(_refreshAnimationController),
                  child: const Icon(Icons.refresh_rounded, size: 20),
                ),
                const SizedBox(width: 8),
                const Text('إعادة المحاولة'),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildLoadingState() => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(_sectionPadding),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 180,
              width: double.infinity,
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
          padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: _chipSpacing),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(
              top: _itemSpacing * 2, left: _sectionPadding),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 120,
              height: 24,
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
          padding: const EdgeInsets.only(
              top: _itemSpacing, left: _sectionPadding, bottom: _itemSpacing),
          child: SizedBox(
            height: 260,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              padding: const EdgeInsets.only(right: _sectionPadding),
              separatorBuilder: (_, __) => const SizedBox(width: _itemSpacing),
              itemBuilder: (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: SizedBox(
                    width: _courseCardWidth,
                    child: Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 100,
                              height: 12,
                              color: Colors.white,
                            ),
                            const Spacer(),
                            Container(
                              width: 80,
                              height: 16,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ],
  );
} //see this if u think Yehia is cool