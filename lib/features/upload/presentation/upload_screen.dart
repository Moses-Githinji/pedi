import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:google_places_api_flutter/google_places_api_flutter.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../auth/presentation/providers/auth_provider.dart';
import '../../profile/presentation/providers/profile_provider.dart';
import 'providers/upload_provider.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  File? _videoFile;
  Player? _player;
  VideoController? _videoController;
  bool _isInitialized = false;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _location = '';
  double? _latitude;
  double? _longitude;
  final List<String> _tags = [];
  bool _isPublishing = false;

  @override
  void dispose() {
    _player?.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Pick a video from the gallery
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 60),
      );

      if (pickedFile == null) return;

      // Dispose existing controller if any
      if (_player != null) {
        final oldPlayer = _player!;
        _player = null;
        _videoController = null;
        await oldPlayer.dispose();
      }

      final file = File(pickedFile.path);
      if (mounted) {
        setState(() {
          _videoFile = file;
          _isInitialized = false;
        });
      }

      final player = Player();
      final controller = VideoController(player);

      await player.open(Media(file.path), play: false);
      player.setPlaylistMode(PlaylistMode.single);
      player.setVolume(0.0); // Silent previews
      await player.play();

      if (mounted) {
        setState(() {
          _player = player;
          _videoController = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoFile = null;
          _isInitialized = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load video: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Upload the video and publish the post
  Future<void> _uploadAndPublish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select or record a video first!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    final firebaseUser = authState.asData?.value;
    if (firebaseUser == null) return;

    setState(() {
      _isPublishing = true;
    });

    try {
      // Reset upload progress to zero
      ref.read(uploadProgressProvider.notifier).set(0.0);

      // 1. Fetch current creator details dynamically from Firestore profile stream (fallback to Firebase Auth display name)
      final profileStream = ref.read(
        userProfileStreamProvider(firebaseUser.uid),
      );
      final userProfile = profileStream.asData?.value;
      final creatorName =
          userProfile?.displayName ?? firebaseUser.displayName ?? 'Pedi User';
      final creatorPhotoUrl =
          userProfile?.photoUrl ?? firebaseUser.photoURL ?? '';

      // 2. Upload video file to Storage
      final videoUrl = await ref
          .read(uploadServiceProvider)
          .uploadVideo(
            uid: firebaseUser.uid,
            filePath: _videoFile!.path,
            onProgress: (progress) {
              if (mounted) {
                ref.read(uploadProgressProvider.notifier).set(progress);
              }
            },
          );

      // 3. Create document in Firestore
      await ref
          .read(uploadServiceProvider)
          .createPost(
            creatorId: firebaseUser.uid,
            creatorName: creatorName,
            creatorPhotoUrl: creatorPhotoUrl,
            videoUrl: videoUrl,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            location: _location.isNotEmpty ? _location : 'Universal',
            latitude: _latitude,
            longitude: _longitude,
            tags: _tags,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Post successfully published!',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Reset state
        _player?.dispose();
        _player = null;
        _videoController = null;
        _titleController.clear();
        _descriptionController.clear();
        setState(() {
          _videoFile = null;
          _isInitialized = false;
          _location = '';
          _latitude = null;
          _longitude = null;
          _tags.clear();
        });

        // Route back or redirect to Home feed
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to publish post: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  /// Show premium Location bottom sheet (75% height) using google_places_api_flutter
  void _showLocationBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F16).withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Grab Handle Indicator
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),

              // Header Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blueAccent,
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add Location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Search Field using google_places_api_flutter
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PlaceSearchField(
                          apiKey: "AIzaSyBWKZognadNlfZ7rg5EyDQxHWin8zkmwjE",
                          isLatLongRequired: true,
                          onPlaceSelected: (prediction, placeDetailsModel) async {
                            log('Place ID: ${prediction.place_id}');
                            log('Description: ${prediction.description}');
                            log(
                              'Latitude and Longitude: ${placeDetailsModel?.result.geometry?.location}',
                            );

                            setState(() {
                              _location = prediction.description;
                              final loc =
                                  placeDetailsModel?.result.geometry?.location;
                              if (loc != null) {
                                _latitude = loc.lat;
                                _longitude = loc.lng;
                              } else {
                                _latitude = null;
                                _longitude = null;
                              }
                            });

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          builder: (context, controller, focusNode) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              autofocus: true,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText:
                                    'Search place, region or establishment...',
                                hintStyle: const TextStyle(
                                  color: Colors.white30,
                                  fontSize: 13,
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.3),
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            );
                          },
                          decorationBuilder: (context, child) {
                            return Material(
                              type: MaterialType.card,
                              elevation: 8,
                              color: const Color(0xFF161922),
                              borderRadius: BorderRadius.circular(16),
                              child: child,
                            );
                          },
                          itemBuilder: (context, prediction) {
                            return ListTile(
                              dense: true,
                              leading: const Icon(
                                Icons.location_on,
                                color: Colors.blueAccent,
                                size: 18,
                              ),
                              title: Text(
                                prediction.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Show premium Tag input dialogue
  void _showTagDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: Colors.grey[950]!.withValues(alpha: 0.85),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            title: const Text(
              'Add Post Tags',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type tag...',
                          hintStyle: const TextStyle(color: Colors.white30),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.3),
                          prefixIcon: const Icon(
                            Icons.tag,
                            color: Colors.blueAccent,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (val) {
                          final clean = val.trim().replaceAll('#', '');
                          if (clean.isNotEmpty && !_tags.contains(clean)) {
                            setState(() {
                              _tags.add(clean);
                            });
                            setDialogState(() {
                              controller.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: Colors.blueAccent,
                        size: 36,
                      ),
                      onPressed: () {
                        final clean = controller.text.trim().replaceAll(
                          '#',
                          '',
                        );
                        if (clean.isNotEmpty && !_tags.contains(clean)) {
                          setState(() {
                            _tags.add(clean);
                          });
                          setDialogState(() {
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Current Tags:',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _tags.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No tags added yet.',
                          style: TextStyle(color: Colors.white30, fontSize: 12),
                        ),
                      )
                    : Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: SingleChildScrollView(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _tags.map((tag) {
                              return Chip(
                                backgroundColor: Colors.blueAccent.withValues(
                                  alpha: 0.12,
                                ),
                                label: Text(
                                  '#$tag',
                                  style: const TextStyle(
                                    color: Colors.blueAccent,
                                    fontSize: 12,
                                  ),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                  ),
                                ),
                                deleteIcon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.blueAccent,
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                  setDialogState(() {});
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.asData?.value;
    final isLoggedIn = firebaseUser != null;

    // ── Logged Out / Guest Onboarding UI ──────────────────────────────────────
    if (!isLoggedIn) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Dark Background styling
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black, Color(0xFF0F172A)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Icon(
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: Colors.blueAccent,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Pedi Uploads',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Join Pedi to capture, upload, and share your favorite moments with the world.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => context.push('/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: const Text(
                                'Sign In to Upload',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final uploadProgress = ref.watch(uploadProgressProvider);

    // ── Logged In Upload UI ──────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'New Share',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: (_isPublishing || _videoFile == null)
                  ? null
                  : _uploadAndPublish,
              child: Text(
                'Publish',
                style: TextStyle(
                  color: (_isPublishing || _videoFile == null)
                      ? Colors.grey[700]
                      : Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Media-First Dominant Preview Card ──────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 340,
                    decoration: BoxDecoration(
                      color: Colors.grey[950],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Looping video preview
                        if (_videoFile != null)
                          GestureDetector(
                            onTap: _pickVideo,
                            child: SizedBox.expand(
                              child: _isInitialized && _videoController != null
                                  ? Video(
                                      controller: _videoController!,
                                      fit: BoxFit.cover,
                                      controls: NoVideoControls,
                                    )
                                  : const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 48,
                                            height: 48,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                                            ),
                                          ),
                                          SizedBox(height: 20),
                                          Text(
                                            'Preparing video thumbnail...',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          )
                        else
                          // Picker Placeholder
                          GestureDetector(
                            onTap: _pickVideo,
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox.expand(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.02,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.04,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.video_collection_outlined,
                                      size: 48,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tap to Select Video Preview',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Max duration: 60 seconds',
                                    style: TextStyle(
                                      color: Colors.white30,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Glassmorphic Upload Progression Overlay
                        if (_isPublishing)
                          Positioned.fill(
                            child: ClipRRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          SizedBox(
                                            width: 72,
                                            height: 72,
                                            child: CircularProgressIndicator(
                                              value: uploadProgress,
                                              strokeWidth: 4,
                                              backgroundColor: Colors.white12,
                                              valueColor:
                                                  const AlwaysStoppedAnimation<
                                                    Color
                                                  >(Colors.blueAccent),
                                            ),
                                          ),
                                          Text(
                                            '${(uploadProgress * 100).toStringAsFixed(0)}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Uploading moment...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Almost ready to share with Pedi',
                                        style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Sleek Glassmorphic Form Fields ─────────────────────────────
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLength: 50,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a catchphrase title';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Add an appealing title...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.grey[950],
                    counterStyle: const TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  maxLines: 3,
                  maxLength: 250,
                  decoration: InputDecoration(
                    hintText: 'Write a stunning description...',
                    hintStyle: const TextStyle(color: Colors.white30),
                    filled: true,
                    fillColor: Colors.grey[950],
                    counterStyle: const TextStyle(color: Colors.white30),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.blueAccent,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Minimal Settings Toolbar (Noah Veenstra Cues) ────────────
                const Text(
                  'POST CONFIGURATION',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      // Location Pill
                      GestureDetector(
                        onTap: _showLocationBottomSheet,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _location.isNotEmpty
                                ? Colors.blueAccent.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _location.isNotEmpty
                                  ? Colors.blueAccent.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: _location.isNotEmpty
                                    ? Colors.blueAccent
                                    : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _location.isNotEmpty
                                    ? _location
                                    : 'Add Location',
                                style: TextStyle(
                                  color: _location.isNotEmpty
                                      ? Colors.blueAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: _location.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_location.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _location = '';
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Tags Pill
                      GestureDetector(
                        onTap: _showTagDialog,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _tags.isNotEmpty
                                ? Colors.blueAccent.withValues(alpha: 0.12)
                                : Colors.white.withValues(alpha: 0.02),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _tags.isNotEmpty
                                  ? Colors.blueAccent.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag,
                                size: 16,
                                color: _tags.isNotEmpty
                                    ? Colors.blueAccent
                                    : Colors.white60,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _tags.isNotEmpty
                                    ? '${_tags.length} Tag${_tags.length > 1 ? 's' : ''}'
                                    : 'Add Tags',
                                style: TextStyle(
                                  color: _tags.isNotEmpty
                                      ? Colors.blueAccent
                                      : Colors.white70,
                                  fontSize: 13,
                                  fontWeight: _tags.isNotEmpty
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (_tags.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _tags.clear();
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Render current tags preview below toolbar
                if (_tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.03),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                            color: Colors.white30,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
