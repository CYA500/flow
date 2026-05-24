import 'dart:async';
import 'overlay_channel.dart';

class MusicService {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  Timer? _pollingTimer;
  final StreamController<MusicInfo> _musicController = 
      StreamController<MusicInfo>.broadcast();

  Stream<MusicInfo> get musicStream => _musicController.stream;

  MusicInfo? _currentInfo;
  MusicInfo? get currentInfo => _currentInfo;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollMediaInfo(); // Initial poll
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollMediaInfo();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollMediaInfo() async {
    try {
      final info = await OverlayChannel.getActiveMediaSession();
      
      if (info.isNotEmpty) {
        final musicInfo = MusicInfo.fromMap(info);
        
        // Only emit if changed
        if (_currentInfo == null || _currentInfo!.title != musicInfo.title) {
          _currentInfo = musicInfo;
          _musicController.add(musicInfo);
        }
      } else if (_currentInfo != null) {
        // Media stopped
        _currentInfo = null;
        _musicController.add(MusicInfo.empty());
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> playPause() async {
    await OverlayChannel.sendMediaCommand('play_pause');
  }

  Future<void> next() async {
    await OverlayChannel.sendMediaCommand('next');
  }

  Future<void> previous() async {
    await OverlayChannel.sendMediaCommand('previous');
  }

  void dispose() {
    stopPolling();
    _musicController.close();
  }
}

class MusicInfo {
  final String title;
  final String artist;
  final String album;
  final int duration;
  final bool isPlaying;
  final String? packageName;

  MusicInfo({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    required this.isPlaying,
    this.packageName,
  });

  factory MusicInfo.empty() => MusicInfo(
    title: '',
    artist: '',
    album: '',
    duration: 0,
    isPlaying: false,
  );

  factory MusicInfo.fromMap(Map<String, dynamic> map) => MusicInfo(
    title: map['title'] ?? 'Unknown',
    artist: map['artist'] ?? 'Unknown Artist',
    album: map['album'] ?? '',
    duration: map['duration'] ?? 0,
    isPlaying: map['isPlaying'] ?? false,
    packageName: map['packageName'],
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'artist': artist,
    'album': album,
    'duration': duration,
    'isPlaying': isPlaying,
    'packageName': packageName,
  };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MusicInfo &&
        title == other.title &&
        artist == other.artist &&
        isPlaying == other.isPlaying;
  }

  @override
  int get hashCode => title.hashCode ^ artist.hashCode ^ isPlaying.hashCode;
}