import 'dart:io';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;

  /// Demander la permission d'enregistrer
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// Démarrer l'enregistrement
  Future<String?> startRecording() async {
    if (_isRecording) return null;

    final hasPermission = await requestPermission();
    if (!hasPermission) {
      throw Exception('Permission microphone refusée');
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/voice_message_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      
      // Feedback haptique pour confirmer le début de l'enregistrement
      HapticFeedback.mediumImpact();
      
      return _currentRecordingPath;
    } catch (e) {
      print('❌ Erreur lors du démarrage de l\'enregistrement: $e');
      return null;
    }
  }

  /// Arrêter l'enregistrement et retourner le fichier
  Future<File?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      final path = await _recorder.stop();
      _isRecording = false;

      if (path != null && File(path).existsSync()) {
        return File(path);
      }
      return null;
    } catch (e) {
      print('❌ Erreur lors de l\'arrêt de l\'enregistrement: $e');
      _isRecording = false;
      return null;
    }
  }

  /// Annuler l'enregistrement en cours
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _recorder.stop();
      _isRecording = false;
      
      // Supprimer le fichier si il existe
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      _currentRecordingPath = null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}

