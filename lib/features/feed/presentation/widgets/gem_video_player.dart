import 'dart:async';
import 'package:flutter/material.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';
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
  bool _isPlaying = true;
  bool _userPaused = false;
  String? _errorMessage;

  StreamSubscription<double>? _volumeSubscription;
  Timer? _hideSliderTimer;
  double _currentVolume = 0.5;
  bool _isVolumeSliderVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.isPreload) {
      _initializePlayer();
    }

    PerfectVolumeControl.hideUI = true;

    Future.microtask(() async {
      _currentVolume = await PerfectVolumeControl.getVolume();
      if (mounted) setState(() {});
    });

    _volumeSubscription = PerfectVolumeControl.stream.listen((volume) {
      if (!mounted) return;
      if (volume != _currentVolume) {
        setState(() {
          _currentVolume = volume;
          _isVolumeSliderVisible = true;
        });
        _resetHideSliderTimer();
      }
    });
  }

  void _resetHideSliderTimer() {
    _hideSliderTimer?.cancel();
    _hideSliderTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isVolumeSliderVisible = false;
        });
      }
    });
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

    // Listen to playing state for UI overlay
    player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() {
        _isPlaying = playing;
      });
    });

    // Configure loop and mute
    player.setPlaylistMode(PlaylistMode.single);
    player.setVolume(100.0);

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
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void didUpdateWidget(GemVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reset explicit pause state when the video is scrolled back into view
    if (!oldWidget.isActive && widget.isActive) {
      _userPaused = false;
    }

    final navigationIndex = ref.read(navigationIndexProvider);
    final shouldBePlaying = widget.isActive && (navigationIndex == 0) && !_userPaused;

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
    _hideSliderTimer?.cancel();
    _volumeSubscription?.cancel();
    _disposePlayer();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_isVolumeSliderVisible) {
      setState(() {
        _isVolumeSliderVisible = false;
      });
      return;
    }

    if (_player == null) return;
    setState(() {
      _userPaused = !_userPaused;
    });
    if (_userPaused) {
      _player!.pause();
    } else {
      _player!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    // If navigation index changes, didUpdateWidget won't automatically trigger,
    // so we listen to it here to manage player lifecycle on actual tab changes.
    ref.listen<int>(navigationIndexProvider, (previous, current) {
      if (current == 0) {
        // Returned to feed
        if (widget.isPreload && _player == null) {
          _initializePlayer();
        } else if (widget.isActive && !_userPaused) {
          _player?.play();
        }
      } else {
        // Navigated away from feed - aggressively free up hardware decoders
        _disposePlayer();
      }
    });

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
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayPause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Video(
            controller: _videoController!,
            fit: BoxFit.cover,
            controls: NoVideoControls,
          ),
          if (!_isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          if (_isVolumeSliderVisible)
            Positioned(
              top: 100,
              right: 16,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Slider(
                    value: _currentVolume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: Colors.white,
                    inactiveColor: Colors.white30,
                    onChanged: (value) {
                      setState(() {
                        _currentVolume = value;
                      });
                      PerfectVolumeControl.setVolume(value);
                      _resetHideSliderTimer();
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}