import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebViewController? _webViewController;

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
          _initializeWebView(_videos[0]['url']);
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

  void _initializeWebView(String url) {
    print('Initializing WebView with URL: $url');

    // Convert Vimeo webpage URL to embed URL if necessary
    String embedUrl = url;
    if (url.contains('vimeo.com/')) {
      final videoId = url.split('vimeo.com/')[1].split('?')[0];
      embedUrl = 'https://player.vimeo.com/video/$videoId';
    }

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Failed to load video: ${error.description}';
              print('WebView error: ${error.description}');
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(embedUrl));
  }

  void _onVideoSelect(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (_videos[index].containsKey('url')) {
      _initializeWebView(_videos[index]['url']);
    } else {
      setState(() {
        _hasError = true;
        _errorMessage = 'No valid video URL for selected video';
      });
    }
  }

  @override
  void dispose() {
    _webViewController = null;
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
          ? const Center(child: CircularProgressIndicator())
          : _hasError
          ? Center(child: Text(_errorMessage ?? 'Error loading videos'))
          : Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _webViewController != null
                ? WebViewWidget(controller: _webViewController!)
                : const Center(child: CircularProgressIndicator()),
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
              separatorBuilder: (_, __) => const Divider(height: 1),
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