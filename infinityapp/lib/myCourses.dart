import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedTabIndex = 0;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;
  static const double _courseCardWidth = 160.0;

  final List<String> tabs = ['الجارية', 'المكتملة', 'المحفوظة'];
  final List<Map<String, dynamic>> ongoingCourses = [
    {
      'title': 'أساسيات التصميم الجرافيكي',
      'instructor': 'أحمد محمد',
      'progress': 0.65,
      'image': 'assets/images/design.jpg',
      'category': 'التصميم'
    },
    {
      'title': 'تعلم برمجة Flutter',
      'instructor': 'يحيى أحمد',
      'progress': 0.30,
      'image': 'assets/images/flutter.jpg',
      'category': 'البرمجة'
    },
  ];

  final List<Map<String, dynamic>> completedCourses = [
    {
      'title': 'أساسيات التسويق الرقمي',
      'instructor': 'سارة خالد',
      'completedDate': '2023-10-15',
      'image': 'assets/images/marketing.jpg',
      'category': 'التسويق'
    },
  ];

  final List<Map<String, dynamic>> savedCourses = [
    {
      'title': 'دورة اللغة الإنجليزية',
      'instructor': 'جون سميث',
      'price': '15.00',
      'image': 'assets/images/language.jpg',
      'category': 'اللغات'
    },
  ];

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

    SchedulerBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
        title: Text(
          'دوراتي',
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCoursesList(context, ongoingCourses, isOngoing: true),
                  _buildCoursesList(context, completedCourses, isCompleted: true),
                  _buildCoursesList(context, savedCourses, isSaved: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TabBar(
          tabs: tabs.map((tab) => Tab(text: tab)).toList(),
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: cs.primary,
          ),
          labelColor: cs.onPrimary,
          unselectedLabelColor: cs.onSurface.withOpacity(0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          dividerColor: Colors.transparent,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
        ),
      ),
    );
  }

  Widget _buildCoursesList(
      BuildContext context,
      List<Map<String, dynamic>> courses, {
        bool isOngoing = false,
        bool isCompleted = false,
        bool isSaved = false,
      }) {
    if (courses.isEmpty) {
      return _buildEmptyState(context, isOngoing, isCompleted, isSaved);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
      child: ListView.separated(
        padding: const EdgeInsets.only(top: _itemSpacing, bottom: _sectionPadding * 2),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
        itemBuilder: (context, index) {
          final course = courses[index];
          return _buildCourseCard(context, course, isOngoing, isCompleted, isSaved);
        },
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context,
      Map<String, dynamic> course,
      bool isOngoing,
      bool isCompleted,
      bool isSaved,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

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
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  course['image'],
                  width: _courseCardWidth,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['category'],
                      style: tt.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مع ${course['instructor']}',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (isOngoing) _buildProgressIndicator(context, course['progress']),
                    if (isCompleted) _buildCompletedBadge(context, course['completedDate']),
                    if (isSaved) _buildPriceTag(context, course['price']),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  isSaved ? Icons.favorite_rounded : Icons.more_vert_rounded,
                  color: isSaved ? cs.error : cs.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  if (isSaved) {
                    // TODO: Remove from saved
                  } else {
                    // TODO: Show options menu
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(BuildContext context, double progress) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${(progress * 100).toStringAsFixed(0)}% مكتمل',
          style: TextStyle(
            fontSize: 12,
            color: cs.onSurface.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.surfaceVariant.withOpacity(0.3),
          color: cs.primary,
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }

  Widget _buildCompletedBadge(BuildContext context, String date) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: cs.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'مكتمل',
                style: tt.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'تم الانتهاء في $date',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceTag(BuildContext context, String price) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Text(
      '$price د.ك',
      style: tt.titleMedium?.copyWith(
        color: cs.primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context,
      bool isOngoing,
      bool isCompleted,
      bool isSaved,
      ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOngoing
                  ? Icons.play_circle_outline_rounded
                  : isCompleted
                  ? Icons.check_circle_outline_rounded
                  : Icons.bookmark_border_rounded,
              size: 64,
              color: cs.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: _itemSpacing),
            Text(
              isOngoing
                  ? 'لا توجد دورات جارية'
                  : isCompleted
                  ? 'لا توجد دورات مكتملة'
                  : 'لا توجد دورات محفوظة',
              style: tt.titleMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: _smallSpacing),
            Text(
              isOngoing
                  ? 'ابدأ دورة جديدة اليوم!'
                  : isCompleted
                  ? 'أكمل بعض الدورات لرؤيتها هنا'
                  : 'احفظ الدورات التي تهمك',
              style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: _itemSpacing),
            if (isOngoing || isSaved)
              FilledButton(
                onPressed: () {
                  // TODO: Navigate to courses
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'تصفح الدورات',
                  style: tt.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}