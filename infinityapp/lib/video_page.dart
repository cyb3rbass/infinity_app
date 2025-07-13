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
      print('API Response: $data'); // Debug API response
      if (response.statusCode == 200 && data['status'] == 'success') {
        setState(() {
          _videos = List<Map<String, dynamic>>.from(data['videos']);
          print('Video URLs: ${_videos.map((v) => v['url'])}'); // Debug URLs
          _isLoading = false;
        });
        if (_videos.isNotEmpty && _videos[0].containsKey('url')) {
          _initializePlayer(_videos[0]['url']);
        } else {
          throw Exception('No valid video URL found');
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
    print('Initializing Vimeo video with URL: $url');
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    _videoPlayerController = VideoPlayerController.network(
      url,
      httpHeaders: {
        // Uncomment if Vimeo requires an access token
        // 'Authorization': 'Bearer YOUR_VIMEO_ACCESS_TOKEN',
      },
      formatHint: url.endsWith('.m3u8') ? VideoFormat.hls : null, // Support HLS
    )..initialize().then((_) {
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
          aspectRatio: _videoPlayerController!.value.aspectRatio != 0
              ? _videoPlayerController!.value.aspectRatio
              : 16 / 9,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                'Playback error: $errorMessage',
                style: TextStyle(color: Colors.red),
              ),
            );
          },
        );
        print('Video player initialized successfully');
      });
    }).catchError((error) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize video: $error';
        print('Initialization error: $error');
      });
    });
  }

  void _onVideoSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_videos[index].containsKey('url')) {
      _initializePlayer(_videos[index]['url']);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'No valid video URL for selected video';
      });
    }
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
          ? Center(child: Text(_errorMessage ?? 'Error loading videos'))
          : Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _hasError
                ? Center(child: Text(_errorMessage ?? 'Error loading video'))
                : _chewieController != null &&
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
                  'All Videos',
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
                    video['title'] ?? 'No Title',
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