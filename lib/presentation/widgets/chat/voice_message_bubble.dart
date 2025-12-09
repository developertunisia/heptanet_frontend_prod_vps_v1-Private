import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import '../../../domain/models/message_response_dto.dart';
import '../../../domain/models/message_attachment_dto.dart';
import '../../../domain/models/message_type.dart';

class VoiceMessageBubble extends StatefulWidget {
  final MessageResponseDto message;
  final bool isCurrentUser;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final Duration? position;
  final Duration? duration;

  const VoiceMessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onPlay,
    this.isPlaying = false,
    this.position,
    this.duration,
  });

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

// Service pour calculer la durée des fichiers audio
class _AudioDurationHelper {
  static Future<int?> calculateDurationFromFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return null;
    
    try {
      final player = AudioPlayer();
      try {
        // Si c'est une URL HTTP/HTTPS, utiliser UrlSource
        if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
          // Pour les URLs distantes, utiliser onDurationChanged pour obtenir la durée
          Duration? duration;
          bool durationReceived = false;
          
          final subscription = player.onDurationChanged.listen((d) {
            if (d.inSeconds > 0) {
              duration = d;
              durationReceived = true;
            }
          });
          
          try {
            await player.setSource(UrlSource(filePath));
            
            // Attendre que la durée soit disponible (max 5 secondes)
            for (int i = 0; i < 50 && !durationReceived; i++) {
              await Future.delayed(const Duration(milliseconds: 100));
              if (duration != null && duration!.inSeconds > 0) {
                break;
              }
              // Essayer aussi getDuration périodiquement
              if (i % 5 == 0) {
                try {
                  final d = await player.getDuration();
                  if (d != null && d.inSeconds > 0) {
                    duration = d;
                    durationReceived = true;
                    break;
                  }
                } catch (_) {
                  // Ignorer les erreurs
                }
              }
            }
          } catch (e) {
            print('⚠️ [DURÉE HELPER] Erreur lors du chargement de l\'URL: $e');
          }
          
          // Si toujours pas de durée, essayer getDuration directement une dernière fois
          if (duration == null || duration!.inSeconds == 0) {
            try {
              await Future.delayed(const Duration(milliseconds: 500));
              final d = await player.getDuration();
              if (d != null && d.inSeconds > 0) {
                duration = d;
              }
            } catch (e) {
              print('⚠️ [DURÉE HELPER] Erreur lors de getDuration: $e');
            }
          }
          
          await subscription.cancel();
          await player.dispose();
          
          if (duration != null && duration!.inSeconds > 0) {
            print('✅ [DURÉE HELPER] Durée calculée depuis URL: ${duration!.inSeconds} secondes');
            return duration!.inSeconds;
          }
        } 
        // Sinon, c'est un chemin local
        else {
          final file = File(filePath);
          if (!await file.exists()) {
            await player.dispose();
            return null;
          }
          await player.setSource(DeviceFileSource(filePath));
          
          // Attendre que le player charge les métadonnées
          await Future.delayed(const Duration(milliseconds: 800));
          
          // Essayer plusieurs fois de récupérer la durée
          Duration? duration;
          for (int i = 0; i < 3; i++) {
            duration = await player.getDuration();
            if (duration != null && duration.inSeconds > 0) {
              break;
            }
            await Future.delayed(const Duration(milliseconds: 300));
          }
          
          await player.dispose();
          
          if (duration != null && duration.inSeconds > 0) {
            return duration.inSeconds;
          }
        }
      } catch (e) {
        await player.dispose();
        print('❌ [DURÉE HELPER] Erreur lors du calcul: $e');
      }
    } catch (e) {
      print('❌ [DURÉE HELPER] Erreur: $e');
    }
    return null;
  }
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  int? _calculatedDuration; // Durée calculée depuis le fichier si nécessaire
  bool _isCalculatingDuration = false;
  
  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
  
  // Obtenir le texte de durée à afficher
  String _getDurationText(int durationSeconds, Duration? effectiveDuration) {
    // Calculer la durée à partir des variables disponibles
    int finalDurationSeconds = 0;
    
    // PRIORITÉ 1: Utiliser effectiveDuration si disponible et > 0
    if (effectiveDuration != null && effectiveDuration.inSeconds > 0) {
      finalDurationSeconds = effectiveDuration.inSeconds;
    }
    // PRIORITÉ 2: Utiliser durationSeconds directement
    else if (durationSeconds > 0) {
      finalDurationSeconds = durationSeconds;
    }
    // PRIORITÉ 3: Utiliser _calculatedDuration si disponible
    else if (_calculatedDuration != null && _calculatedDuration! > 0) {
      finalDurationSeconds = _calculatedDuration!;
    }
    // PRIORITÉ 4: Essayer de récupérer depuis l'attachment directement (dernier recours)
    else {
      final attachment = widget.message.audioAttachment;
      if (attachment != null && attachment.durationSeconds != null && attachment.durationSeconds! > 0) {
        finalDurationSeconds = attachment.durationSeconds!;
        print('✅ [GET DURATION TEXT] Durée récupérée depuis attachment: $finalDurationSeconds secondes');
      } else if (widget.message.attachments.isNotEmpty) {
        // Chercher dans tous les attachments
        for (var att in widget.message.attachments) {
          if (att.contentType.startsWith('audio/') && att.durationSeconds != null && att.durationSeconds! > 0) {
            finalDurationSeconds = att.durationSeconds!;
            print('✅ [GET DURATION TEXT] Durée récupérée depuis attachments: $finalDurationSeconds secondes');
            break;
          }
        }
      }
    }
    
    // Formater et retourner
    if (finalDurationSeconds > 0) {
      return '${finalDurationSeconds ~/ 60}:${(finalDurationSeconds % 60).toString().padLeft(2, '0')}';
    }
    
    // Dernier recours: 0:00
    return '0:00';
  }
  
  // Calculer la durée depuis le fichier si elle n'est pas disponible
  Future<void> _calculateDurationIfNeeded() async {
    // Ne calculer que si la durée n'est pas disponible et qu'on n'est pas déjà en train de calculer
    if (_isCalculatingDuration || _calculatedDuration != null) return;
    
    final attachment = widget.message.audioAttachment;
    if (attachment == null) return;
    
    // Si durationSeconds est null ou 0, essayer de calculer depuis le fichier
    if (attachment.durationSeconds == null || attachment.durationSeconds == 0) {
      // PRIORITÉ 1: Utiliser fullFileUrl (URL complète) si disponible
      var filePath = attachment.fullFileUrl.isNotEmpty 
          ? attachment.fullFileUrl 
          : attachment.fileUrl;
      
      // Si fileUrl est relatif mais fullFileUrl est vide, construire l'URL complète
      if (!filePath.startsWith('http') && !filePath.startsWith('/')) {
        // C'est un chemin local
        if (filePath.isEmpty) {
          return;
        }
      } else if (filePath.startsWith('/') && !filePath.startsWith('http')) {
        // C'est un chemin relatif, on ne peut pas le charger directement
        // Essayer avec fullFileUrl
        if (attachment.fullFileUrl.isNotEmpty) {
          filePath = attachment.fullFileUrl;
        } else {
          print('⚠️ [CALCUL DURÉE] Chemin relatif sans fullFileUrl: $filePath');
          return;
        }
      }
      
      if (filePath.isNotEmpty) {
        _isCalculatingDuration = true;
        print('🔍 [CALCUL DURÉE] Tentative de calcul depuis: $filePath');
        final calculated = await _AudioDurationHelper.calculateDurationFromFile(filePath);
        if (mounted && calculated != null && calculated > 0) {
          setState(() {
            _calculatedDuration = calculated;
            _isCalculatingDuration = false;
          });
          print('✅ [CALCUL DURÉE] Durée calculée avec succès: $calculated secondes');
        } else {
          _isCalculatingDuration = false;
          print('❌ [CALCUL DURÉE] Échec du calcul de la durée');
        }
      }
    }
  }
  
  @override
  void initState() {
    super.initState();
    // Calculer la durée si nécessaire au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateDurationIfNeeded();
    });
  }
  
  @override
  void didUpdateWidget(VoiceMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Vérifier si le message a changé (messageId différent)
    final messageIdChanged = oldWidget.message.messageId != widget.message.messageId;
    
    // Vérifier si l'attachment ou sa durée a changé
    final oldAttachment = oldWidget.message.audioAttachment;
    final newAttachment = widget.message.audioAttachment;
    final attachmentChanged = oldAttachment?.durationSeconds != newAttachment?.durationSeconds ||
                              oldAttachment?.fileUrl != newAttachment?.fileUrl;
    
    // Si le message change ou si l'attachment change, réinitialiser et recalculer si nécessaire
    if (messageIdChanged || attachmentChanged) {
      // Si la durée est maintenant disponible dans le nouvel attachment, réinitialiser _calculatedDuration
      if (newAttachment != null && 
          newAttachment.durationSeconds != null && 
          newAttachment.durationSeconds! > 0) {
        _calculatedDuration = null; // Utiliser la durée de l'attachment
        _isCalculatingDuration = false;
        print('✅ [WIDGET UPDATE] Durée disponible dans attachment: ${newAttachment.durationSeconds} secondes');
      } else {
        // Sinon, réinitialiser et recalculer
        _calculatedDuration = null;
        _isCalculatingDuration = false;
        _calculateDurationIfNeeded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.message.audioAttachment;
    
    // Calculer la durée à afficher : priorité à widget.duration, puis durationSeconds de l'attachment
    // CRITIQUE: S'assurer que la durée est TOUJOURS disponible pour l'affichage
    Duration? effectiveDuration;
    int durationSeconds = 0;
    
    // ÉTAPE 1: Si widget.duration est disponible et valide, l'utiliser (durée en cours de lecture)
    if (widget.duration != null && widget.duration!.inSeconds > 0) {
      effectiveDuration = widget.duration;
      durationSeconds = widget.duration!.inSeconds;
    } 
    // ÉTAPE 2: Utiliser durationSeconds de l'attachment (durée stockée) - PRIORITÉ ABSOLUE
    else {
      // Chercher la durée dans l'attachment audio
      MessageAttachmentDto? audioAtt = attachment;
      if (audioAtt == null && widget.message.attachments.isNotEmpty) {
        // Chercher un attachment audio dans la liste
        try {
          audioAtt = widget.message.attachments.firstWhere(
            (a) => a.contentType.startsWith('audio/'),
          );
        } catch (_) {
          // Pas d'attachment audio trouvé
        }
      }
      
      if (audioAtt != null) {
        // PRIORITÉ 1: Utiliser durationSeconds de l'attachment si disponible
        if (audioAtt.durationSeconds != null && audioAtt.durationSeconds! > 0) {
          durationSeconds = audioAtt.durationSeconds!;
          effectiveDuration = Duration(seconds: durationSeconds);
          print('✅ [AFFICHAGE] Durée depuis attachment: $durationSeconds secondes (messageId: ${widget.message.messageId})');
        }
        // PRIORITÉ 2: Utiliser la durée calculée depuis le fichier si disponible
        else if (_calculatedDuration != null && _calculatedDuration! > 0) {
          durationSeconds = _calculatedDuration!;
          effectiveDuration = Duration(seconds: durationSeconds);
          print('✅ [AFFICHAGE] Utilisation de la durée calculée depuis le fichier: $durationSeconds secondes');
        }
        // PRIORITÉ 3: Déclencher le calcul si pas déjà en cours et durationSeconds est null ou 0
        else if (!_isCalculatingDuration && (audioAtt.durationSeconds == null || audioAtt.durationSeconds == 0)) {
          print('⚠️ [AFFICHAGE] Durée manquante, déclenchement du calcul depuis le fichier...');
          _calculateDurationIfNeeded();
        }
      } else {
        // Pas d'attachment trouvé - log pour debug
        if (widget.message.type == MessageType.audio) {
          print('⚠️ [AFFICHAGE] Pas d\'attachment audio trouvé pour messageId: ${widget.message.messageId}');
          print('   - attachments.length: ${widget.message.attachments.length}');
        }
      }
    }
    
    // Debug si problème de durée
    if (widget.message.type == MessageType.audio && durationSeconds == 0) {
      print('❌ [AFFICHAGE] PROBLÈME DE DURÉE - messageId: ${widget.message.messageId}');
      print('   - widget.duration: ${widget.duration}');
      print('   - attachment: ${attachment != null ? "existe" : "null"}');
      print('   - attachment.durationSeconds: ${attachment?.durationSeconds}');
      print('   - message.attachments.length: ${widget.message.attachments.length}');
      if (widget.message.attachments.isNotEmpty) {
        for (var att in widget.message.attachments) {
          print('   - attachment: ${att.toJson()}');
        }
      }
      print('   - _calculatedDuration: $_calculatedDuration');
    }
    
    // Debug: Afficher les valeurs pour le débogage (uniquement si problème)
    // if (widget.message.type == MessageType.audio && durationSeconds == 0) {
    //   print('🔍 VoiceMessageBubble - messageId: ${widget.message.messageId}, durationSeconds: $durationSeconds, effectiveDuration: $effectiveDuration, widget.duration: ${widget.duration}');
    // }
    
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    // Si pas d'attachment mais que c'est un message audio, afficher quand même avec un bouton play
    if (attachment == null && widget.message.type == MessageType.audio) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisAlignment: widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!widget.isCurrentUser) ...[
              _buildAvatar(),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: widget.isCurrentUser ? Colors.black : Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(widget.isCurrentUser ? 16 : 4),
                    bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 16),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bouton play même pour les messages en cours d'envoi
                    if (widget.onPlay != null)
                      GestureDetector(
                        onTap: widget.onPlay,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.2)
                                : Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: widget.isCurrentUser ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                        ),
                      ),
                    if (widget.onPlay != null) const SizedBox(width: 12),
                    Icon(
                      Icons.mic,
                      color: widget.isCurrentUser ? Colors.white : Colors.black87,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    // Afficher la durée et le temps
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDurationText(durationSeconds, effectiveDuration),
                          style: TextStyle(
                            fontSize: 14,
                            color: widget.isCurrentUser ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatTime(widget.message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (widget.isCurrentUser) ...[
              const SizedBox(width: 8),
              _buildAvatar(),
            ],
          ],
        ),
      );
    }
    
    if (attachment == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: widget.isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isCurrentUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              constraints: BoxConstraints(maxWidth: maxWidth),
              decoration: BoxDecoration(
                color: widget.isCurrentUser ? Colors.black : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(widget.isCurrentUser ? 16 : 4),
                  bottomRight: Radius.circular(widget.isCurrentUser ? 4 : 16),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouton play/pause
                  GestureDetector(
                    onTap: widget.onPlay,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.isCurrentUser
                            ? Colors.white.withOpacity(0.2)
                            : Colors.black.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: widget.isCurrentUser ? Colors.white : Colors.black87,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Barre de progression
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Barre de progression visuelle
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.3)
                                : Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: effectiveDuration != null && effectiveDuration!.inSeconds > 0
                              ? Stack(
                                  children: [
                                    // Fond de la barre
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: widget.isCurrentUser
                                            ? Colors.white.withOpacity(0.3)
                                            : Colors.black.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    // Barre de progression
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: widget.position != null && effectiveDuration!.inSeconds > 0
                                          ? (widget.position!.inSeconds / effectiveDuration!.inSeconds).clamp(0.0, 1.0)
                                          : 0.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: widget.isCurrentUser
                                              ? Colors.white
                                              : Colors.black87,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                        const SizedBox(height: 4),
                        
                        // Durée - AFFICHER TOUJOURS la durée disponible
                        Text(
                          _getDurationText(durationSeconds, effectiveDuration),
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.7)
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Temps d'envoi
                        Text(
                          _formatTime(widget.message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isCurrentUser
                                ? Colors.white.withOpacity(0.6)
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.isCurrentUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat.Hm().format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat.Hm().format(dateTime)}';
    } else {
      return DateFormat.MMMd().add_Hm().format(dateTime);
    }
  }

  Widget _buildAvatar() {
    final avatarUrl = widget.message.senderAvatar;
    final initials = _getInitials(widget.message.senderName);
    
    return CircleAvatar(
      radius: 18,
      backgroundColor: widget.isCurrentUser ? Colors.black : Colors.grey.shade300,
      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
          ? NetworkImage(avatarUrl)
          : null,
      child: avatarUrl == null || avatarUrl.isEmpty
          ? Text(
              initials,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: widget.isCurrentUser ? Colors.white : Colors.grey.shade700,
              ),
            )
          : null,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}


