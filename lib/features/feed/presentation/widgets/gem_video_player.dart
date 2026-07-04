import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../home/presentation/main_layout.dart';

class GemVideoPlayer extends ConsumerStatefulWidget {
  final String videoUrl;
  final bool isActive;
  final bool isPreload;

  const GemVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.isActive,
    required this.isPreload,
  });

  @override
  ConsumerState<GemVideoPlayer> createState() => _GemVideoPlayerState();
}

class _GemVideoPlayerState extends ConsumerState<GemVideoPlayer> {
  Player? _player;
  VideoController? _videoController;
  bool _isMuted = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.isPreload) {
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    if (_player != null) return;

    final player = Player();
    final controller = VideoController(player);

    _player = player;
    _videoController = controller;

    // Listen to errors
    player.stream.error.listen((error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Playback error occurred";
      });
    });

    // Configure loop and mute
    player.setPlaylistMode(PlaylistMode.loop);
    player.setVolume(_isMuted ? 0.0 : 100.0);

    // Open stream and pause/play based on active state
    player.open(
      Media(widget.videoUrl),
      play: widget.isActive && ref.read(navigationIndexProvider) == 0,
    );
  }

  void _disposePlayer() {
    if (_player != null) {
      final playerToDispose = _player!;
      _player = null;
      _videoController = null;
      playerToDispose.dispose();
    }
  }

  @override
  void didUpdateWidget(GemVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final navigationIndex = ref.read(navigationIndexProvider);
    final shouldBePlaying = widget.isActive && (navigationIndex == 0);

    // Proximity management
    if (widget.isPreload) {
      if (_player == null) {
        _initializePlayer();
      } else {
        // Toggle play/pause based on active changes
        if (shouldBePlaying) {
          _player?.play();
        } else {
          _player?.pause();
        }
      }
    } else {
      // Discard player when moving far away
      _disposePlayer();
    }
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  void _togglePlayPause() {
    _player?.playOrPause();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _player?.setVolume(_isMuted ? 0.0 : 100.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    // If navigation index changes, didUpdateWidget won't automatically trigger,
    // so we watch it here to play/pause.
    final navigationIndex = ref.watch(navigationIndexProvider);
    final shouldBePlaying = widget.isActive && (navigationIndex == 0);

    if (_player != null) {
      if (shouldBePlaying) {
        _player?.play();
      } else {
        _player?.pause();
      }
    }

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

    if (_videoController == null || _player == null) {
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
          Video(
            controller: _videoController!,
            fit: BoxFit.cover,
          ),
          Positioned(
            top: 40,
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