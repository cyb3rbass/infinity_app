import 'package:flutter/material.dart';
import 'package:vimeo_player_flutter/vimeo_player_flutter.dart';
import 'dart:io';

class VideoPage extends StatefulWidget {
  final String videoUrl;
  final String courseName;
  final String teacherName;
  final List<Map<String, String>> relatedVideos;

  const VideoPage({
    super.key,
    required this.videoUrl,
    required this.courseName,
    required this.teacherName,
    required this.relatedVideos,
  });

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  String? _currentVideoId;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer(widget.videoUrl);
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
    }
  }

  String? _extractVimeoId(String url) {
    final regex = RegExp(r'vimeo\.com/(\d+)');
    final match = regex.firstMatch(url);
    return match?.group(1);
  }

  void _playNewVideo(String url) {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'رابط الفيديو غير صالح',
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Tajawal',
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
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
                    // Note: Ensure Vimeo video settings are configured for desired playback behavior (e.g., autoplay)
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
                    const SizedBox(height: 8),
                    Text(
                      'الوصف:',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 8),
                    widget.relatedVideos.isEmpty
                        ? Text(
                      'لا يوجد وصف',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontFamily: 'Tajawal',
                      ),
                    )
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.relatedVideos.length,
                      itemBuilder: (context, index) {
                        final video = widget.relatedVideos[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            video['description'] ?? 'لا يوجد وصف',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontFamily: 'Tajawal',
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        );
                      },
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
                    widget.relatedVideos.isEmpty
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
                      itemCount: widget.relatedVideos.length,
                      itemBuilder: (context, index) {
                        final video = widget.relatedVideos[index];
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