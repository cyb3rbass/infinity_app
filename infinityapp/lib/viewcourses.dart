import 'package:flutter/material.dart';
import 'course_overview.dart';

class ViewCoursesPage extends StatefulWidget {
  final List<Map<String, dynamic>> courses; // Should be the enriched API list!

  const ViewCoursesPage({super.key, required this.courses});

  @override
  State<ViewCoursesPage> createState() => _ViewCoursesPageState();
}

enum ViewLevel { universities, majors, courses }

class _ViewCoursesPageState extends State<ViewCoursesPage> {
  ViewLevel _currentLevel = ViewLevel.universities;
  String? _selectedUniversity;
  String? _selectedMajor;

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
    (c['university'] ?? '') == university &&
        (c['major'] ?? '') == major)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    // ---- PAGE 1: Universities ----
    if (_currentLevel == ViewLevel.universities) {
      final universities = getUniversities();
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          title: Text('الجامعات',
              style: tt.titleLarge?.copyWith(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: cs.onSurface),
              textDirection: TextDirection.rtl),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: universities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (context, i) {
            final uni = universities[i];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                title: Text(
                  uni['university'],
                  style: tt.titleMedium?.copyWith(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  'عدد التخصصات: ${uni['majorsCount']}',
                  style: tt.bodySmall?.copyWith(
                      fontFamily: 'Tajawal',
                      color: cs.onSurface.withOpacity(0.7)),
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  setState(() {
                    _selectedUniversity = uni['university'];
                    _currentLevel = ViewLevel.majors;
                  });
                },
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            );
          },
        ),
      );
    }

    // ---- PAGE 2: Majors ----
    if (_currentLevel == ViewLevel.majors && _selectedUniversity != null) {
      final majors = getMajors(_selectedUniversity!);
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
            onPressed: () =>
                setState(() => _currentLevel = ViewLevel.universities),
          ),
          title: Text(
            _selectedUniversity!,
            style: tt.titleLarge?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: cs.onSurface),
            textDirection: TextDirection.rtl,
          ),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: majors.length,
          separatorBuilder: (_, __) => const SizedBox(height: 18),
          itemBuilder: (context, i) {
            final major = majors[i];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                title: Text(
                  major['major'],
                  style: tt.titleMedium?.copyWith(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                  textDirection: TextDirection.rtl,
                ),
                subtitle: Text(
                  'عدد المواد: ${major['coursesCount']}',
                  style: tt.bodySmall?.copyWith(
                      fontFamily: 'Tajawal',
                      color: cs.onSurface.withOpacity(0.7)),
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  setState(() {
                    _selectedMajor = major['major'];
                    _currentLevel = ViewLevel.courses;
                  });
                },
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
              ),
            );
          },
        ),
      );
    }

    // ---- PAGE 3: Courses ----
    if (_currentLevel == ViewLevel.courses &&
        _selectedUniversity != null &&
        _selectedMajor != null) {
      final courses = getCourses(_selectedUniversity!, _selectedMajor!);
      return Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          backgroundColor: cs.surface,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface),
            onPressed: () => setState(() => _currentLevel = ViewLevel.majors),
          ),
          title: Text(
            _selectedMajor!,
            style: tt.titleLarge?.copyWith(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: cs.onSurface),
            textDirection: TextDirection.rtl,
          ),
        ),
        body: GridView.builder(
          padding: const EdgeInsets.all(24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: screenWidth < 400 ? 1 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          CourseOverviewPage(course: course),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          // Use your real domain and correct field
                          'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                          height: 70,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 70,
                                width: double.infinity,
                                color: cs.surfaceVariant,
                                child: Center(
                                    child: Icon(Icons.broken_image_rounded,
                                        color: cs.onSurfaceVariant, size: 22)),
                              ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        course['title'] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                        style: tt.bodyLarge?.copyWith(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['price'] != null
                            ? '${course['price']} د.ك'
                            : '',
                        style: tt.titleMedium?.copyWith(
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                            fontSize: 14),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            // Use 'ratings' field as float
                            (course['ratings']?.toString() ?? '4.5'),
                            style: tt.bodySmall?.copyWith(
                                fontFamily: 'Tajawal', fontSize: 12),
                            textDirection: TextDirection.rtl,
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // --- Fallback ---
    return const SizedBox.shrink();
  }
}
