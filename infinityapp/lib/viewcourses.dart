import 'package:flutter/material.dart';
import 'course_overview.dart';

class ViewCoursesPage extends StatefulWidget {
  final List<Map<String, dynamic>> courses;

  const ViewCoursesPage({super.key, required this.courses});

  @override
  State<ViewCoursesPage> createState() => _ViewCoursesPageState();
}

enum ViewLevel { universities, majors, courses }

class _ViewCoursesPageState extends State<ViewCoursesPage> {
  ViewLevel _currentLevel = ViewLevel.universities;
  String? _selectedUniversity;
  String? _selectedMajor;
  final TextEditingController _searchController = TextEditingController();
  final _pageTransitionDuration = const Duration(milliseconds: 300);
  final _pageTransitionCurve = Curves.easeInOut;

  // Filtered data based on search
  List<Map<String, dynamic>> get filteredUniversities {
    final searchTerm = _searchController.text.toLowerCase();
    final unis = getUniversities();
    if (searchTerm.isEmpty) return unis;
    return unis.where((uni) =>
        uni['university'].toLowerCase().contains(searchTerm)
    ).toList();
  }

  List<Map<String, dynamic>> get filteredMajors {
    if (_selectedUniversity == null) return [];
    final searchTerm = _searchController.text.toLowerCase();
    final majors = getMajors(_selectedUniversity!);
    if (searchTerm.isEmpty) return majors;
    return majors.where((major) =>
        major['major'].toLowerCase().contains(searchTerm)
    ).toList();
  }

  List<Map<String, dynamic>> get filteredCourses {
    if (_selectedUniversity == null || _selectedMajor == null) return [];
    final searchTerm = _searchController.text.toLowerCase();
    final courses = getCourses(_selectedUniversity!, _selectedMajor!);
    if (searchTerm.isEmpty) return courses;
    return courses.where((course) =>
    (course['title']?.toString().toLowerCase().contains(searchTerm) ?? false) ||
        (course['description']?.toString().toLowerCase().contains(searchTerm) ?? false)
    ).toList();
  }

  List<Map<String, dynamic>> getUniversities() {
    final uniMajors = <String, Set<String>>{};
    for (final course in widget.courses) {
      final university = course['university'] ?? 'جامعة غير معروفة';
      final major = course['major'] ?? '';
      uniMajors.putIfAbsent(university, () => <String>{});
      uniMajors[university]!.add(major);
    }
    return uniMajors.entries
        .map((e) => {
      'university': e.key,
      'majorsCount': e.value.length,
    })
        .toList();
  }

  List<Map<String, dynamic>> getMajors(String university) {
    final majorCourses = <String, int>{};
    for (final course in widget.courses) {
      if ((course['university'] ?? '') == university) {
        final major = course['major'] ?? '';
        majorCourses[major] = (majorCourses[major] ?? 0) + 1;
      }
    }
    return majorCourses.entries
        .map((e) => {
      'major': e.key,
      'coursesCount': e.value,
    })
        .toList();
  }

  List<Map<String, dynamic>> getCourses(String university, String major) {
    return widget.courses
        .where((c) =>
    (c['university'] ?? '') == university && (c['major'] ?? '') == major)
        .toList();
  }

  Widget _buildSearchField(ColorScheme cs, TextTheme tt, double screenWidth) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
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
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textDirection: TextDirection.rtl,
        style: tt.bodyMedium?.copyWith(
          fontFamily: 'Tajawal',
          color: cs.onSurface,
          fontSize: screenWidth < 400 ? 14 : 16,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث هنا...',
          hintStyle: tt.bodyMedium?.copyWith(
            fontFamily: 'Tajawal',
            color: cs.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: cs.onSurface.withOpacity(0.5),
            size: screenWidth < 400 ? 20 : 24,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            vertical: screenWidth < 400 ? 10 : 14,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildUniversityCard(
      BuildContext context, Map<String, dynamic> uni, ColorScheme cs, TextTheme tt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedUniversity = uni['university'];
            _currentLevel = ViewLevel.majors;
            _searchController.clear();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.school_rounded, color: cs.primary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      uni['university'],
                      style: tt.titleMedium?.copyWith(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${uni['majorsCount']} تخصص',
                      style: tt.bodySmall?.copyWith(
                        fontFamily: 'Tajawal',
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: cs.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMajorCard(
      BuildContext context, Map<String, dynamic> major, ColorScheme cs, TextTheme tt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedMajor = major['major'];
            _currentLevel = ViewLevel.courses;
            _searchController.clear();
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: cs.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: cs.secondary, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      major['major'],
                      style: tt.titleMedium?.copyWith(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${major['coursesCount']} مادة',
                      style: tt.bodySmall?.copyWith(
                        fontFamily: 'Tajawal',
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: cs.onSurface.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(
      BuildContext context, Map<String, dynamic> course, ColorScheme cs, TextTheme tt) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outline.withOpacity(0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            PageRouteBuilder(
              transitionDuration: _pageTransitionDuration,
              pageBuilder: (context, animation, secondaryAnimation) =>
                  CourseOverviewPage(course: course),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: TextDirection.rtl,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  width: double.infinity,
                  color: cs.surfaceVariant,
                  child: Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: cs.onSurfaceVariant, size: 32),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    course['title'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: tt.titleSmall?.copyWith(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${course['price']} د.ك',
                          style: tt.labelLarge?.copyWith(
                            fontFamily: 'Tajawal',
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            course['ratings']?.toString() ?? '4.5',
                            style: tt.labelMedium?.copyWith(
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star_rounded, size: 18, color: Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, TextTheme tt, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: cs.onSurface.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: tt.bodyLarge?.copyWith(
              fontFamily: 'Tajawal',
              color: cs.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return AnimatedSwitcher(
      duration: _pageTransitionDuration,
      switchInCurve: _pageTransitionCurve,
      switchOutCurve: _pageTransitionCurve,
      child: _buildCurrentView(cs, tt, screenWidth),
    );
  }

  Widget _buildCurrentView(ColorScheme cs, TextTheme tt, double screenWidth) {
    switch (_currentLevel) {
      case ViewLevel.universities:
        return _buildUniversitiesView(cs, tt, screenWidth);
      case ViewLevel.majors:
        return _buildMajorsView(cs, tt, screenWidth);
      case ViewLevel.courses:
        return _buildCoursesView(cs, tt, screenWidth);
    }
  }

  Widget _buildUniversitiesView(ColorScheme cs, TextTheme tt, double screenWidth) {
    final universities = filteredUniversities;

    return Scaffold(
      key: const ValueKey('universities_view'),
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: _buildSearchField(cs, tt, screenWidth),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              'الجامعات',
              style: tt.titleLarge?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر الجامعة لعرض التخصصات المتاحة',
              style: tt.bodyMedium?.copyWith(
                fontFamily: 'Tajawal',
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: universities.isEmpty
                  ? _buildEmptyState(cs, tt, 'لا توجد جامعات تطابق البحث')
                  : ListView.separated(
                itemCount: universities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _buildUniversityCard(context, universities[i], cs, tt),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMajorsView(ColorScheme cs, TextTheme tt, double screenWidth) {
    if (_selectedUniversity == null) {
      return _buildUniversitiesView(cs, tt, screenWidth);
    }

    final majors = filteredMajors;

    return Scaffold(
      key: ValueKey('majors_view_$_selectedUniversity'),
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () {
            setState(() {
              _currentLevel = ViewLevel.universities;
              _searchController.clear();
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              _selectedUniversity!,
              style: tt.titleMedium?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'اختر التخصص لعرض المواد',
              style: tt.bodySmall?.copyWith(
                fontFamily: 'Tajawal',
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: majors.isEmpty
            ? _buildEmptyState(cs, tt, 'لا توجد تخصصات تطابق البحث')
            : ListView.separated(
          itemCount: majors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) =>
              _buildMajorCard(context, majors[i], cs, tt),
        ),
      ),
    );
  }

  Widget _buildCoursesView(ColorScheme cs, TextTheme tt, double screenWidth) {
    if (_selectedUniversity == null || _selectedMajor == null) {
      return _buildMajorsView(cs, tt, screenWidth);
    }

    final courses = filteredCourses;

    return Scaffold(
      key: ValueKey('courses_view_${_selectedUniversity}_${_selectedMajor}'),
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
          onPressed: () {
            setState(() {
              _currentLevel = ViewLevel.majors;
              _searchController.clear();
            });
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              _selectedMajor!,
              style: tt.titleMedium?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              _selectedUniversity!,
              style: tt.bodySmall?.copyWith(
                fontFamily: 'Tajawal',
                color: cs.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: courses.isEmpty
            ? _buildEmptyState(cs, tt, 'لا توجد مواد تطابق البحث')
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth < 600 ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: screenWidth < 600 ? 1.6 : 1.2,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) =>
              _buildCourseCard(context, courses[index], cs, tt),
        ),
      ),
    );
  }
}