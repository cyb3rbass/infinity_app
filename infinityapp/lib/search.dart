import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';
import 'dart:async';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  List<Map<String, dynamic>> _allCourses = [];
  bool _isLoading = false;
  bool _initialLoad = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAllCourses();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (_controller.text.isEmpty) {
        setState(() => _results = []);
      } else {
        _performSearch(_controller.text);
      }
    });
  }

  Future<void> _fetchAllCourses() async {
    setState(() => _initialLoad = true);

    try {
      final response = await http.get(
        Uri.parse('https://eclipsekw.com/InfinityCourses/fetch_courses.php'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _allCourses = List<Map<String, dynamic>>.from(data['courses']);
          _initialLoad = false;
        });
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      print('Error: $e');
      setState(() => _initialLoad = false);
    }
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _isLoading = true);

    final filtered = _allCourses.where((course) {
      final title = course['title']?.toString().toLowerCase() ?? '';
      final description = course['description']?.toString().toLowerCase() ?? '';
      final searchTerm = query.toLowerCase();
      return title.contains(searchTerm) || description.contains(searchTerm);
    }).toList();

    setState(() {
      _results = List<Map<String, dynamic>>.from(filtered);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Search Bar
              Container(
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  textDirection: TextDirection.rtl,
                  style: tt.bodyLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن الدورات...',
                    hintStyle: tt.bodyLarge?.copyWith(
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    suffixIcon: _controller.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurface.withOpacity(0.5),
                      ),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    )
                        : null,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Search Results
              if (_initialLoad)
                _buildShimmerLoader()
              else if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_results.isEmpty && _controller.text.isNotEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: cs.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد نتائج لبحثك',
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ],
                    ),
                  )
                else if (_results.isEmpty)
                    Center(
                      child: Text(
                        'ابدأ بالكتابة للبحث عن الدورات',
                        style: tt.bodyLarge?.copyWith(
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final course = _results[index];
                          return _buildCourseCard(course, cs, tt, screenWidth);
                        },
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard(
      Map<String, dynamic> course, ColorScheme cs, TextTheme tt, double screenWidth) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: cs.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: Navigate to course details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              // Course Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://eclipsekw.com/InfinityCourses/${course['thumbnail']}',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: cs.surfaceVariant,
                    child: Icon(
                      Icons.image_not_supported_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 80,
                      height: 80,
                      color: cs.surfaceVariant,
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
                ),
              ),

              const SizedBox(width: 12),

              // Course Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      course['title'] ?? 'بدون عنوان',
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['university'] ?? '',
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          '${course['price'] ?? '؟'} د.ك',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course['ratings']?.toString() ?? '4.5',
                          style: tt.bodySmall,
                        ),
                      ],
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

  Widget _buildShimmerLoader() {
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: Shimmer.fromColors(
        baseColor: cs.surfaceVariant.withOpacity(0.3),
        highlightColor: cs.surfaceVariant.withOpacity(0.1),
        child: ListView.builder(
          itemCount: 6,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 120,
                          height: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: 80,
                          height: 14,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}