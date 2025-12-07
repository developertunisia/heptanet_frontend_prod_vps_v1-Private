import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentPlayingUrl;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;

  // Streams pour notifier l'UI
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _stateController = StreamController<PlayerState>.broadcast();

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<PlayerState> get stateStream => _stateController.stream;

  String? get currentPlayingUrl => _currentPlayingUrl;
  bool get isPlaying => _player.state == PlayerState.playing;

  AudioPlayerService() {
    _positionSubscription = _player.onPositionChanged.listen(_positionController.add);
    _durationSubscription = _player.onDurationChanged.listen(_durationController.add);
    _stateSubscription = _player.onPlayerStateChanged.listen(_stateController.add);
  }

  /// Jouer un fichier audio depuis une URL
  Future<void> play(String url) async {
    try {
      if (_currentPlayingUrl == url && isPlaying) {
        await pause();
        return;
      }

      if (_currentPlayingUrl != url) {
        await _player.stop();
        await _player.play(UrlSource(url));
        _currentPlayingUrl = url;
      } else {
        await _player.resume();
      }
    } catch (e) {
      print('❌ Erreur lors de la lecture: $e');
      throw Exception('Impossible de lire le fichier audio');
    }
  }

  /// Jouer un fichier audio local
  Future<void> playLocal(String filePath) async {
    try {
      if (_currentPlayingUrl == filePath && isPlaying) {
        await pause();
        return;
      }

      if (_currentPlayingUrl != filePath) {
        await _player.stop();
        await _player.play(DeviceFileSource(filePath));
        _currentPlayingUrl = filePath;
      } else {
        await _player.resume();
      }
    } catch (e) {
      print('❌ Erreur lors de la lecture locale: $e');
      throw Exception('Impossible de lire le fichier audio local');
    }
  }

  /// Mettre en pause
  Future<void> pause() async {
    await _player.pause();
  }

  /// Arrêter
  Future<void> stop() async {
    await _player.stop();
    _currentPlayingUrl = null;
  }

  /// Obtenir la durée d'un fichier audio depuis une URL
  Future<Duration?> getDuration(String url) async {
    try {
      await _player.setSource(UrlSource(url));
      return await _player.getDuration();
    } catch (e) {
      print('❌ Erreur lors de la récupération de la durée: $e');
      return null;
    }
  }

  /// Obtenir la durée d'un fichier audio local
  Future<Duration?> getLocalDuration(String filePath) async {
    try {
      await _player.setSource(DeviceFileSource(filePath));
      return await _player.getDuration();
    } catch (e) {
      print('❌ Erreur lors de la récupération de la durée locale: $e');
      return null;
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _stateSubscription?.cancel();
    _positionController.close();
    _durationController.close();
    _stateController.close();
    _player.dispose();
  }
}

