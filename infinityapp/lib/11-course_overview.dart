import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class CourseOverviewPage extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseOverviewPage({super.key, required this.course});

  @override
  State<CourseOverviewPage> createState() => _CourseOverviewPageState();
}

class _CourseOverviewPageState extends State<CourseOverviewPage> {
  static const double _sectionPadding = 24.0;
  static const double _itemSpacing = 16.0;
  static const double _smallSpacing = 8.0;
  bool _alreadyPurchased = false;

  YoutubePlayerController? _youtubeController;
  bool _isVideoInitialized = false;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _checkIfAlreadyPurchased();
    _initializeYouTubePlayer();
  }

  void _initializeYouTubePlayer() {
    final videoUrl = widget.course['intro_video'] as String? ??
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
    String? videoId = YoutubePlayer.convertUrlToId(videoUrl);
    if (videoId == null) {
      videoId = 'dQw4w9WgXcQ';
    }
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        captionLanguage: 'ar',
      ),
    )
      ..addListener(() {
        if (_youtubeController!.value.isReady && !_isVideoInitialized) {
          setState(() {
            _isVideoInitialized = true;
            _videoError = null;
          });
        }
      });
  }

  Future<void> _checkIfAlreadyPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    final regCoursesString = prefs.getString('reg_courses') ?? '[]';
    final List<dynamic> regCoursesJson = json.decode(regCoursesString);
    final regCourses = regCoursesJson.map((e) => e.toString()).toList();
    setState(() {
      _alreadyPurchased = regCourses.contains(widget.course['id'].toString());
    });
  }

  Future<void> purchaseCourse() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final token = prefs.getString('token');
    final courseId = widget.course['id'].toString();
    final amount = widget.course['price'].toString();

    final response = await http.post(
      Uri.parse('https://eclipsekw.com/InfinityCourses/purchase_course.php'),
      body: {
        'user_id': userId,
        'token': token,
        'course_id': courseId,
        'amount': amount,
      },
    );

    final data = json.decode(response.body);
    if (data['status'] == 'success') {
      // Update local regCourses for immediate UI feedback
      final regCoursesString = prefs.getString('reg_courses') ?? '[]';
      final List<dynamic> regCoursesJson = json.decode(regCoursesString);
      final regCourses = regCoursesJson.map((e) => e.toString()).toSet(); // Avoid duplicates
      regCourses.add(courseId);
      await prefs.setString('reg_courses', json.encode(regCourses.toList()));
      setState(() => _alreadyPurchased = true);

      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('تم الشراء بنجاح'),
              content: const Text('تم إضافة الكورس إلى دوراتك.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/my_courses');
                  },
                  child: const Text('الذهاب إلى دوراتي'),
                ),
              ],
            ),
      );
    } else if (data['message'] == 'already_purchased') {
      setState(() => _alreadyPurchased = true);
      showDialog(
        context: context,
        builder: (_) =>
            AlertDialog(
              title: const Text('لقد قمت بشراء هذا الكورس'),
              content: const Text('الذهاب إلى دوراتي'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/my_courses');
                  },
                  child: const Text('الذهاب إلى دوراتي'),
                ),
              ],
            ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: ${data['message']}')),
      );
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme
        .of(context)
        .colorScheme;
    final tt = Theme
        .of(context)
        .textTheme;
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          widget.course['title'] as String? ?? 'دورة',
          style: tt.titleLarge?.copyWith(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 400 ? 16 : 20,
          ),
          textDirection: TextDirection.rtl,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildVideoPlayer(cs, screenWidth, tt)),
          SliverToBoxAdapter(child: _buildCourseDetails(cs, tt, screenWidth)),
          SliverToBoxAdapter(child: _buildTopicsSection(cs, tt, screenWidth)),
          SliverToBoxAdapter(child: _buildVideosSection(cs, tt, screenWidth)),
          SliverToBoxAdapter(child: _buildCommentsSection(cs, tt, screenWidth)),
          SliverToBoxAdapter(
              child: _buildLinkedFilesSection(cs, tt, screenWidth)),
          SliverToBoxAdapter(child: SizedBox(height: _sectionPadding * 2)),
        ],
      ),
      floatingActionButton: _alreadyPurchased
          ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          'لقد قمت بشراء هذا الكورس الذهاب ل دوراتي',
          style: TextStyle(
            color: Colors.green,
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
      )
          : FloatingActionButton.extended(
        onPressed: purchaseCourse,
        backgroundColor: cs.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        label: Text(
          'اشترك بالكورس (${widget.course['price']} د.ك)',
          style: tt.labelLarge?.copyWith(
            fontFamily: 'Tajawal',
            color: cs.onPrimary,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 400 ? 14 : 16,
          ),
          textDirection: TextDirection.rtl,
        ),
        icon: Icon(Icons.add_shopping_cart_rounded, color: cs.onPrimary),
      ),
    );
  }

  Widget _buildVideoPlayer(ColorScheme cs, double screenWidth, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.all(_sectionPadding),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: screenWidth < 400 ? 180 : 200,
          color: cs.surfaceVariant.withOpacity(0.2),
          child: _youtubeController != null
              ? YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: true,
            progressIndicatorColor: cs.primary,
            progressColors: ProgressBarColors(
              playedColor: cs.primary,
              handleColor: cs.primary.withOpacity(0.8),
            ),
            onReady: () {
              if (!_isVideoInitialized) {
                setState(() {
                  _isVideoInitialized = true;
                  _videoError = null;
                });
              }
            },
            onEnded: (metaData) {
              _youtubeController?.pause();
            },
          )
              : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: cs.error,
                  size: screenWidth < 400 ? 32 : 40,
                ),
                const SizedBox(height: _smallSpacing),
                Text(
                  'فشل تحميل الفيديو',
                  style: tt.bodyMedium?.copyWith(
                    fontFamily: 'Tajawal',
                    color: cs.error,
                    fontSize: screenWidth < 400 ? 14 : 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                const SizedBox(height: _smallSpacing),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _videoError = null;
                      _isVideoInitialized = false;
                      _youtubeController?.dispose();
                      _youtubeController = null;
                    });
                    _initializeYouTubePlayer();
                  },
                  child: Text(
                    'إعادة المحاولة',
                    style: tt.labelMedium?.copyWith(
                      fontFamily: 'Tajawal',
                      color: cs.onPrimary,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildCourseDetails(ColorScheme cs, TextTheme tt, double screenWidth) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            widget.course['title'] as String? ?? 'عنوان الدورة',
            style: tt.headlineSmall?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 20 : 24,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'بواسطة: ${widget.course['instructor'] as String? ?? 'اسم المدرب'}',
            style: tt.bodyMedium?.copyWith(
              fontFamily: 'Tajawal',
              color: cs.onSurface.withOpacity(0.6),
              fontSize: screenWidth < 400 ? 14 : 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _smallSpacing),
          Text(
            'التخصص: ${widget.course['major'] as String? ?? 'غير محدد'}',
            style: tt.bodyMedium?.copyWith(
              fontFamily: 'Tajawal',
              color: cs.onSurface.withOpacity(0.6),
              fontSize: screenWidth < 400 ? 14 : 16,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _itemSpacing),
        ],
      ),
    );
  }

  Widget _buildTopicsSection(ColorScheme cs, TextTheme tt, double screenWidth) {
    final topics = (widget.course['topics'] as List<dynamic>?)?.cast<
        String>() ??
        ['مقدمة', 'الجزء الأول', 'الجزء الثاني'];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _sectionPadding, vertical: _itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'المواضيع',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 16 : 20,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _itemSpacing),
          ...topics
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final topic = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: _smallSpacing),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: cs.primary,
                  ),
                  const SizedBox(width: _smallSpacing),
                  Expanded(
                    child: Text(
                      '${index + 1}. $topic',
                      style: tt.bodyMedium?.copyWith(
                        fontFamily: 'Tajawal',
                        fontSize: screenWidth < 400 ? 14 : 16,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildVideosSection(ColorScheme cs, TextTheme tt, double screenWidth) {
    final videos = (widget.course['videos'] as List<dynamic>?)?.cast<
        Map<String, dynamic>>() ??
        [
          {
            'title': 'فيديو 1',
            'url': 'https://www.youtube.com/watch?v=VIDEO_ID_1'
          },
          {
            'title': 'فيديو 2',
            'url': 'https://www.youtube.com/watch?v=VIDEO_ID_2'
          },
        ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _sectionPadding, vertical: _itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'الفيديوهات',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 16 : 20,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _itemSpacing),
          ...videos
              .asMap()
              .entries
              .map((entry) {
            final index = entry.key;
            final video = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: _smallSpacing),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.play_circle_outline_rounded,
                  color: cs.primary,
                  size: screenWidth < 400 ? 24 : 28,
                ),
                title: Text(
                  video['title'] as String? ?? 'فيديو ${index + 1}',
                  style: tt.bodyMedium?.copyWith(
                    fontFamily: 'Tajawal',
                    fontSize: screenWidth < 400 ? 14 : 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  // Implement video navigation or playback
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(ColorScheme cs, TextTheme tt,
      double screenWidth) {
    final comments = [
      {'user': 'أحمد', 'text': 'دورة رائعة، استفدت كثيرًا!', 'rating': 4.5},
      {'user': 'سارة', 'text': 'شرح واضح ومفيد.', 'rating': 4.0},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _sectionPadding, vertical: _itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'التعليقات',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 16 : 20,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _itemSpacing),
          ...comments.map((comment) {
            return Padding(
              padding: const EdgeInsets.only(bottom: _itemSpacing),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outline.withOpacity(0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(_smallSpacing),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    textDirection: TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            comment['user'] as String? ?? '',
                            style: tt.bodyMedium?.copyWith(
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth < 400 ? 14 : 16,
                            ),
                          ),
                          Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                (comment['rating'] as num?)?.toString() ??
                                    '0.0',
                                style: tt.bodySmall?.copyWith(
                                  fontFamily: 'Tajawal',
                                  fontSize: screenWidth < 400 ? 12 : 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.star_rounded,
                                size: screenWidth < 400 ? 16 : 18,
                                color: Colors.amber,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: _smallSpacing),
                      Text(
                        comment['text'] as String? ?? '',
                        style: tt.bodyMedium?.copyWith(
                          fontFamily: 'Tajawal',
                          fontSize: screenWidth < 400 ? 12 : 14,
                          color: cs.onSurface.withOpacity(0.7),
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLinkedFilesSection(ColorScheme cs, TextTheme tt,
      double screenWidth) {
    final files = (widget.course['files'] as List<dynamic>?)?.cast<
        Map<String, dynamic>>() ??
        [
          {'name': 'ملف PDF 1', 'url': 'https://example.com/file1.pdf'},
          {'name': 'ملف PDF 2', 'url': 'https://example.com/file2.pdf'},
        ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: _sectionPadding, vertical: _itemSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            'الملفات المرتبطة',
            style: tt.titleLarge?.copyWith(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.bold,
              fontSize: screenWidth < 400 ? 16 : 20,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(height: _itemSpacing),
          ...files.map((file) {
            return Padding(
              padding: const EdgeInsets.only(bottom: _smallSpacing),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.description_rounded,
                  color: cs.primary,
                  size: screenWidth < 400 ? 24 : 28,
                ),
                title: Text(
                  file['name'] as String? ?? 'ملف',
                  style: tt.bodyMedium?.copyWith(
                    fontFamily: 'Tajawal',
                    fontSize: screenWidth < 400 ? 14 : 16,
                  ),
                  textDirection: TextDirection.rtl,
                ),
                onTap: () {
                  // Implement file download or open logic here
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
