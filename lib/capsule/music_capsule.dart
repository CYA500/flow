import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/overlay_channel.dart';
import '../theme/nowbar_theme.dart';

class MusicCapsuleContent extends StatefulWidget {
  final Map<String, dynamic> data;

  const MusicCapsuleContent({
    super.key,
    required this.data,
  });

  @override
  State<MusicCapsuleContent> createState() => _MusicCapsuleContentState();
}

class _MusicCapsuleContentState extends State<MusicCapsuleContent>
    with SingleTickerProviderStateMixin {
  
  String _title = 'No music playing';
  String _artist = '';
  String _album = '';
  bool _isPlaying = false;
  double _progress = 0.0;
  
  late AnimationController _playPauseController;
  late Animation<double> _scaleAnimation;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _playPauseController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _loadMediaInfo();
    _startProgressTimer();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && mounted) {
        setState(() {
          _progress = (_progress + 0.01).clamp(0.0, 1.0);
        });
      }
    });
  }

  Future<void> _loadMediaInfo() async {
    try {
      final mediaInfo = await OverlayChannel.getActiveMediaSession();
      if (mediaInfo.isNotEmpty && mounted) {
        setState(() {
          _title = mediaInfo['title'] ?? 'Unknown';
          _artist = mediaInfo['artist'] ?? 'Unknown Artist';
          _album = mediaInfo['album'] ?? '';
          _isPlaying = mediaInfo['isPlaying'] ?? false;
        });
        
        if (_isPlaying) {
          _playPauseController.forward();
        }
      } else {
        // Use data from provider or defaults
        final musicData = widget.data;
        if (musicData.isNotEmpty) {
          setState(() {
            _title = musicData['title'] ?? 'Unknown';
            _artist = musicData['artist'] ?? 'Unknown Artist';
            _isPlaying = musicData['isPlaying'] ?? false;
          });
        }
      }
    } catch (e) {
      // Use fallback data
    }
  }

  Future<void> _sendMediaCommand(String action) async {
    try {
      await OverlayChannel.sendMediaCommand(action);
      
      if (action == 'play_pause') {
        setState(() {
          _isPlaying = !_isPlaying;
        });
        if (_isPlaying) {
          _playPauseController.forward();
        } else {
          _playPauseController.reverse();
        }
      } else if (action == 'next') {
        setState(() {
          _progress = 0;
        });
      } else if (action == 'previous') {
        setState(() {
          _progress = 0;
        });
      }
    } catch (e) {
      debugPrint('Media command error: $e');
    }
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Song info
        Row(
          children: [
            // Album art placeholder with glow
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9F0A).withOpacity(0.6),
                    const Color(0xFFFF375F).withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9F0A).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Song details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _title,
                    style: NowBarTheme.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _artist,
                    style: NowBarTheme.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_album.isNotEmpty)
                    Text(
                      _album,
                      style: NowBarTheme.captionStyle.copyWith(
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            minHeight: 4,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF9F0A)),
          ),
        ),
        const SizedBox(height: 16),
        // Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous
            _buildControlButton(
              Icons.skip_previous_rounded,
              () => _sendMediaCommand('previous'),
            ),
            const SizedBox(width: 24),
            // Play/Pause
            _buildPlayPauseButton(),
            const SizedBox(width: 24),
            // Next
            _buildControlButton(
              Icons.skip_next_rounded,
              () => _sendMediaCommand('next'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Visualizer effect
        if (_isPlaying)
          SizedBox(
            height: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                20,
                (index) => _buildVisualizerBar(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: () => _sendMediaCommand('play_pause'),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFFF9F0A).withOpacity(0.8),
                    const Color(0xFFFF375F).withOpacity(0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9F0A).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _playPauseController,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisualizerBar(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 3,
      height: _isPlaying
          ? 8 + math.Random().nextInt(16).toDouble()
          : 4,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: const Color(0xFFFF9F0A).withOpacity(
          0.3 + (index % 3) * 0.2,
        ),
      ),
    );
  }
}
