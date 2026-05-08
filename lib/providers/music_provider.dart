import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class MusicProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _activeMusicUrl;
  String? _activeMusicTitle;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  String? get activeMusicUrl => _activeMusicUrl;
  String? get activeMusicTitle => _activeMusicTitle;
  PlayerState get playerState => _playerState;
  bool get isPlaying => _playerState == PlayerState.playing;
  Duration get duration => _duration;
  Duration get position => _position;
  double get progress => _duration.inMilliseconds > 0 
      ? _position.inMilliseconds / _duration.inMilliseconds 
      : 0.0;

  MusicProvider() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    _audioPlayer.onDurationChanged.listen((d) {
      _duration = d;
      notifyListeners();
    });
    _audioPlayer.onPositionChanged.listen((p) {
      _position = p;
      notifyListeners();
    });
  }

  Future<void> playMusic(String url, String title) async {
    _activeMusicUrl = url;
    _activeMusicTitle = title;
    final fullUrl = ApiService.getImageUrl(url);
    if (fullUrl != null) {
      await _audioPlayer.play(UrlSource(fullUrl));
    }
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else if (_playerState == PlayerState.paused) {
      await _audioPlayer.resume();
    }
    notifyListeners();
  }

  Future<void> pauseIfPlaying() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      notifyListeners();
    }
  }

  Future<void> seek(double value) async {
    final target = _duration * value;
    await _audioPlayer.seek(target);
  }

  Future<void> stopMusic() async {
    await _audioPlayer.stop();
    _activeMusicUrl = null;
    _activeMusicTitle = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
