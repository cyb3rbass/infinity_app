import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _courseCardWidth = 160.0;

  final List<Map<String, dynamic>> allCourses = [
    {
      'title': 'أساسيات التصميم الجرافيكي',
      'instructor': 'أحمد محمد',
      'progress': 0.65,
      'image': 'https://eclipsekw.com/InfinityCourses/design.jpg',
      'category': 'التصميم',
      'rating': 4.7,
      'students': 125,
      'status': 'ongoing',
    },
    {
      'title': 'تعلم برمجة Flutter',
      'instructor': 'يحيى أحمد',
      'progress': 0.30,
      'image': 'https://eclipsekw.com/InfinityCourses/flutter.jpg',
      'category': 'البرمجة',
      'rating': 4.9,
      'students': 89,
      'status': 'ongoing',
    },
    {
      'title': 'أساسيات التسويق الرقمي',
      'instructor': 'سارة خالد',
      'completedDate': '2023-10-15',
      'image': 'https://eclipsekw.com/InfinityCourses/marketing.jpg',
      'category': 'التسويق',
      'rating': 4.5,
      'students': 210,
      'status': 'completed',
    },
    {
      'title': 'دورة اللغة الإنجليزية',
      'instructor': 'جون سميث',
      'price': '15.00',
      'image': 'https://eclipsekw.com/InfinityCourses/language.jpg',
      'category': 'اللغات',
      'rating': 4.8,
      'students': 156,
      'status': 'saved',
    },
  ];

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'دوراتي',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: _buildCoursesList(context),
      ),
    );
  }

  Widget _buildCoursesList(BuildContext context) {
    if (allCourses.isEmpty) {
      return _buildEmptyState(context);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
      child: ListView.separated(
        padding: const EdgeInsets.only(
          top: _itemSpacing,
          bottom: _sectionPadding * 2,
        ),
        itemCount: allCourses.length,
        separatorBuilder: (_, __) => const SizedBox(height: _itemSpacing),
        itemBuilder: (context, index) => _buildCourseCard(context, allCourses[index]),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Map<String, dynamic> course) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: Navigate to details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  course['image'],
                  width: _courseCardWidth,
                  height: 100,
                  fit: BoxFit.cover,
                  loadingBuilder: (ctx, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      width: _courseCardWidth,
                      height: 100,
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
                    width: _courseCardWidth,
                    height: 100,
                    color: cs.surfaceVariant,
                    child: Center(child: Icon(Icons.broken_image_rounded, color: cs.onSurfaceVariant)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['category'],
                      style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['title'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'مع ${course['instructor']}',
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 16, color: cs.primary),
                        const SizedBox(width: 4),
                        Text(course['rating'].toString(), style: tt.bodySmall),
                        const SizedBox(width: 4),
                        Text('(${course['students']})',
                            style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.4))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (course['status'] == 'ongoing') _buildProgressIndicator(context, course['progress']),
                    if (course['status'] == 'completed')
                      _buildCompletedBadge(context, course['completedDate']),
                    if (course['status'] == 'saved') _buildPriceTag(context, course['price']),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  course['status'] == 'saved' ? Icons.favorite_rounded : Icons.more_vert_rounded,
                  color: course['status'] == 'saved' ? cs.error : cs.onSurface.withOpacity(0.6),
                ),
                onPressed: () {
                  // TODO: handle saved/un-saved or show menu
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
        Text('${(progress * 100).toStringAsFixed(0)}% مكتمل',
            style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.8))),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: cs.surfaceVariant.withOpacity(0.3),
          color: cs.primary,
          minHeight: 6,
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
          decoration: BoxDecoration(color: cs.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text('مكتمل', style: tt.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text('تم الانتهاء في $date', style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildPriceTag(BuildContext context, String price) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Text('$price د.ك', style: tt.titleMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.bold));
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_sectionPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline_rounded, size: 64, color: cs.onSurface.withOpacity(0.3)),
            const SizedBox(height: _itemSpacing),
            Text('لا توجد دورات مسجلة',
                style: tt.titleMedium?.copyWith(color: cs.onSurface.withOpacity(0.6))),
            const SizedBox(height: 8),
            Text('ابدأ دورة جديدة اليوم!',
                style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.4))),
            const SizedBox(height: _itemSpacing),
            FilledButton(
              onPressed: () {
                // TODO: navigate to browse
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('تصفح الدورات',
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
