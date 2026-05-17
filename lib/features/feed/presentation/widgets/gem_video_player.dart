import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class GemVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool isActive;

  const GemVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
  });

  @override
  State<GemVideoPlayer> createState() => _GemVideoPlayerState();
}

class _GemVideoPlayerState extends State<GemVideoPlayer> {
  VideoPlayerController? _controller; // Made nullable to safely cycle controllers
  bool _isInitialized = false;
  bool _isMuted = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _errorMessage = null;
    _isInitialized = false;
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    
    _controller!.initialize().then((_) {
      if (!mounted) return;
      
      setState(() {
        _isInitialized = true;
      });
      
      _controller!.setLooping(true);
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
      
      if (widget.isActive) {
        _controller!.play();
      }
    }).catchError((error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Failed to load video";
      });
    });
  }

  @override
  void didUpdateWidget(GemVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Safety check: if url changed, re-initialize completely
    if (oldWidget.videoUrl != widget.videoUrl) {
      _controller?.dispose();
      _initializePlayer();
      return;
    }

    if (_controller == null || !_isInitialized) return;

    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _controller!.play();
      } else {
        _controller!.pause();
        _controller!.seekTo(Duration.zero);
      }
    }
  }

  @override
  void dispose() {
    // Explicitly pause before discarding memory allocation pointers
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    if (!_isInitialized || _controller == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return GestureDetector(
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
          if (!_controller!.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 80,
                color: Colors.white54,
              ),
            ),
          Positioned(
            top: 40, // Lowered from 100 to make it accessible inside viewports
            right: 16,
            child: GestureDetector(
              onTap: _toggleMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}