import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const TikTokClone());
}

class TikTokClone extends StatelessWidget {
  const TikTokClone({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TikTok Offline',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView(
      scrollDirection: Axis.horizontal,
      children: const [
        VideoFeedScreen(isFavorite: false), // Main TikTok folder
        VideoFeedScreen(isFavorite: true),  // Favorites (TikTok/fav)
      ],
    );
  }
}

class VideoFeedScreen extends StatefulWidget {
  final bool isFavorite;
  const VideoFeedScreen({super.key, required this.isFavorite});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();
  List<File> _videoFiles = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _pageController.addListener(() {
      final newIndex = _pageController.page?.round() ?? 0;
      if (newIndex != _currentIndex) {
        setState(() => _currentIndex = newIndex);
      }
    });
  }

  Future<void> _requestPermissions() async {
    if (await Permission.manageExternalStorage.request().isGranted ||
        await Permission.storage.request().isGranted) {
      _findVideoFiles();
    } else {
      setState(() {
        _errorMessage = "Storage permission not granted.";
        _isLoading = false;
      });
    }
  }

  Future<void> _findVideoFiles() async {
    try {
      final basePaths = [
        '/storage/emulated/0/TikTok',
        '/storage/emulated/10/TikTok',
        '/storage/emulated/10/snaptube/download/SnapTubeVideo',
        '/storage/emulated/0/snaptube/download/SnapTubeVideo'
      ];

      Directory? foundDir;

      for (final base in basePaths) {
        final checkPath = widget.isFavorite ? '$base/fav' : base;
        final dir = Directory(checkPath);
        if (await dir.exists()) {
          foundDir = dir;
          break;
        }
      }

      if (foundDir != null) {
        final files = await foundDir.list(recursive: true).toList();
        _videoFiles = files.whereType<File>().where((file) {
          final name = file.path.toLowerCase();
          return name.endsWith('.mp4') || name.endsWith('.mov') || name.endsWith('.avi');
        }).toList();

        if (_videoFiles.isEmpty) {
          setState(() {
            _errorMessage = 'No videos found in ${widget.isFavorite ? "Favorites" : "Main"} folder.';
          });
        } else {
          _videoFiles.shuffle();
        }
      } else {
        setState(() {
          _errorMessage = 'TikTok folder${widget.isFavorite ? "/fav" : ""} not found.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error accessing storage: $e';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getFileName(File file) => path.basenameWithoutExtension(file.path);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: _videoFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        VideoPlayerItem(
                          videoFile: _videoFiles[index],
                          isCurrent: index == _currentIndex,
                        ),
                        _buildUIOverlay(_videoFiles[index]),
                      ],
                    );
                  },
                ),
    );
  }

  Widget _buildUIOverlay(File videoFile) {
    final fileName = _getFileName(videoFile);

    return Column(
      children: [
        const SizedBox(height: 40),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.isFavorite ? "❤️ Favorites" : "For You",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "@${fileName.split('_').first}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ...fileName
                          .split('_')
                          .skip(1)
                          .map((part) => Text(part, style: const TextStyle(fontSize: 16))),
                      const SizedBox(height: 8),
                      const Text("#fyp #trending #viral", style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.music_note, size: 15),
                          SizedBox(width: 5),
                          Text("Created by Dr MyoThiha", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(Icons.favorite, "24.5K"),
                    const SizedBox(height: 10),
                    _buildActionButton(Icons.comment, "1.2K"),
                    const SizedBox(height: 10),
                    _buildActionButton(Icons.share, "Share"),
                    const SizedBox(height: 10),
                    _buildActionButton(Icons.bookmark, ""),
                    const SizedBox(height: 10),
                    const CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage('assets/tiktok.png'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 35),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ],
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final File videoFile;
  final bool isCurrent;

  const VideoPlayerItem({
    super.key,
    required this.videoFile,
    required this.isCurrent,
  });

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          if (widget.isCurrent) {
            _playVideo();
          }
        }
      })
      ..addListener(_videoListener);
  }

  void _videoListener() {
    if (_controller.value.isInitialized &&
        _controller.value.position >= _controller.value.duration) {
      // Loop video
      _controller
        ..seekTo(Duration.zero)
        ..play();
    }
  }

  void _playVideo() {
    if (_isInitialized && !_controller.value.isPlaying) {
      _controller
        ..seekTo(Duration.zero)
        ..play();
    }
  }

  void _pauseVideo() {
    if (_isInitialized && _controller.value.isPlaying) {
      _controller.pause();
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrent && !oldWidget.isCurrent) {
      _playVideo();
    } else if (!widget.isCurrent && oldWidget.isCurrent) {
      _pauseVideo();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_controller.value.isPlaying) {
          _pauseVideo();
        } else {
          _playVideo();
        }
      },
      child: Stack(
        children: [
          Center(
            child: _isInitialized
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  )
                : const CircularProgressIndicator(),
          ),
          if (!_isInitialized || !_controller.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_filled,
                size: 80,
                color: Colors.white54,
              ),
            ),
        ],
      ),
    );
  }
}
