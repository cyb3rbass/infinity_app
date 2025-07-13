import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class VideoPage extends StatefulWidget {
  final int courseId;
  final String courseName;
  final String? teacherName;

  const VideoPage({
    Key? key,
    required this.courseId,
    required this.courseName,
    this.teacherName,
  }) : super(key: key);

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  List<Map<String, dynamic>> _videos = [];
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _fetchCourseVideos();
  }

  Future<void> _fetchCourseVideos() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        throw Exception('User authentication missing!');
      }

      final response = await http.post(
        Uri.parse('https://eclipsekw.com/InfinityCourses/get_related_videos.php'),
        body: {
          'user_id': userId,
          'token': token,
          'course_id': widget.courseId.toString(),
        },
      );

      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(data['videos']);
          _isLoading = false;
        });
        if (_videos.isNotEmpty) {
          _initializePlayer(_videos[0]['url']);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to load videos');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  void _initializePlayer(String url) {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _videoPlayerController = VideoPlayerController.network(url)
      ..initialize().then((_) {
        setState(() {
          _chewieController = ChewieController(
            videoPlayerController: _videoPlayerController!,
            autoPlay: true,
            looping: false,
            aspectRatio: _videoPlayerController!.value.aspectRatio,
          );
        });
      });
  }

  void _onVideoSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _initializePlayer(_videos[index]['url']);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.courseName, style: tt.titleMedium),
        backgroundColor: cs.surface,
        elevation: 1,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text(_errorMessage ?? 'خطأ في تحميل الفيديوهات'))
          : Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _chewieController != null &&
                _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.teacherName ?? '',
                  style: tt.labelMedium?.copyWith(color: cs.primary),
                ),
                Text(
                  'جميع الفيديوهات',
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _videos.length,
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (_, i) {
                final video = _videos[i];
                final isSelected = i == _selectedIndex;
                return ListTile(
                  leading: Icon(
                    isSelected ? Icons.play_circle_fill : Icons.play_circle_outline,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                  title: Text(
                    video['title'] ?? 'بدون عنوان',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    video['description'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  selected: isSelected,
                  onTap: () => _onVideoSelect(i),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
//tyy