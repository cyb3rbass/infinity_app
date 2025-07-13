import 'package:flutter/material.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoPage extends StatefulWidget {
  final String videoUrl;
  final String courseName;
  final String teacherName;
  final int courseId;

  const VideoPage({
    super.key,
    required this.videoUrl,
    required this.courseName,
    required this.teacherName,
    required this.courseId,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String? _currentVideoId;
  bool _hasError = false;
  bool _isLoading = false;
  List<Map<String, String>> relatedVideos = [];

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.videoUrl);
    _fetchRelatedVideos();
  }

  void _initializePlayer(String url) {
    try {
      print('Initializing video: $url');
      final videoId = _extractVimeoId(url);
      if (videoId == null) {
        throw Exception('Invalid Vimeo URL');
      }
      setState(() {
        _currentVideoId = videoId;
        _hasError = false;
      });
    } catch (e) {
      setState(() => _hasError = true);
      print('Video initialization error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ في تحميل الفيديو: $e',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String? _extractVimeoId(String url) {
    // Match Vimeo ID from URLs like vimeo.com/123456789 or player.vimeo.com/video/123456789
    final regex = RegExp(r'(?:vimeo\.com\/|player\.vimeo\.com\/video\/)(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  Future<void> _fetchRelatedVideos() async {
    setState(() => _isLoading = true);
    try {
      // Replace with your actual API URL
      final response = await http.get(
        Uri.parse('https://eclipsekw.com/InfinityCourses/get_related_videos.php=${widget.courseId}'),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['videos'] != null) {
          setState(() {
            relatedVideos = List<Map<String, String>>.from(
              data['videos'].map((video) => {
                'id': video['id'].toString(),
                'title': video['title'] ?? 'فيديو بدون عنوان',
                'description': video['description'] ?? 'لا يوجد وصف',
                'url': video['url'] ?? '',
              }),
            );
            // Filter out the current video from related videos to avoid duplication
            relatedVideos.removeWhere((video) => video['url'] == widget.videoUrl);
          });
          print('Fetched related videos: $relatedVideos');
        } else {
          print('API error: ${data['message'] ?? 'Unknown error'}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'خطأ في جلب الفيديوهات: ${data['message'] ?? 'خطأ غير معروف'}',
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontFamily: 'Tajawal'),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في الاتصال بالخادم: ${response.statusCode}',
              textDirection: TextDirection.rtl,
              style: const TextStyle(fontFamily: 'Tajawal'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      print('Error fetching related videos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'تعذر جلب الفيديوهات ذات الصلة: $e',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _playNewVideo(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رابط الفيديو غير صالح',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    if (url == widget.videoUrl) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'هذا الفيديو قيد التشغيل بالفعل',
            textDirection: TextDirection.rtl,
            style: const TextStyle(fontFamily: 'Tajawal'),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
      return;
    }
    _initializePlayer(url);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.background,
      appBar: AppBar(
        title: Text(
          widget.courseName,
          style: tt.titleLarge?.copyWith(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.bold,
          ),
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.rtl,
            children: [
              // Video Player Section
              Container(
                color: Colors.black,
                child: _hasError || _currentVideoId == null
                    ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: cs.error,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'تعذر تحميل الفيديو',
                        style: tt.bodyLarge?.copyWith(
                          color: cs.error,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                )
                    : SizedBox(
                  height: 200,
                  child: VimeoPlayer(
                    videoId: _currentVideoId!,
                    // Removed autoPlay parameter as it's not supported
                  ),
                ),
              ),
              // Course Details Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      widget.courseName,
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.person, color: cs.primary, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          'المدرّس: ${widget.teacherName}',
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'الوصف:',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      relatedVideos.isNotEmpty
                          ? relatedVideos.first['description'] ?? 'لا يوجد وصف'
                          : 'لا يوجد وصف',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const Divider(height: 32, thickness: 1),
                    // Related Videos Section
                    Text(
                      'فيديوهات ذات صلة',
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : relatedVideos.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'لا توجد فيديوهات ذات صلة',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontFamily: 'Tajawal',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: relatedVideos.length,
                      itemBuilder: (context, index) {
                        final video = relatedVideos[index];
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: cs.primaryContainer,
                              child: Icon(
                                Icons.play_arrow,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                            title: Text(
                              video['title'] ?? 'فيديو بدون عنوان',
                              style: tt.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            subtitle: Text(
                              video['description'] ?? 'لا يوجد وصف',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontFamily: 'Tajawal',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            onTap: () => _playNewVideo(video['url']!),
                          ),
                        );
                      },
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
}