# Documentation Technique - Messages Vocaux (Frontend Flutter)

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture et Principes](#architecture-et-principes)
3. [Dépendances et Configuration](#dépendances-et-configuration)
4. [Modifications Détaillées par Couche](#modifications-détaillées-par-couche)
5. [Flux de Données](#flux-de-données)
6. [Fonctionnalités Implémentées](#fonctionnalités-implémentées)
7. [Gestion des Erreurs et Optimisations](#gestion-des-erreurs-et-optimisations)
8. [Tests et Validation](#tests-et-validation)

---

## 1. Vue d'ensemble

### Contexte
Cette documentation décrit l'implémentation complète de la fonctionnalité de messages vocaux dans l'application Flutter HeptaNet, permettant aux utilisateurs d'enregistrer, envoyer, recevoir et écouter des messages audio dans leurs conversations.

### Objectifs Principaux
1. ✅ Enregistrer des messages vocaux via le microphone
2. ✅ Envoyer des messages vocaux au backend
3. ✅ Recevoir et afficher des messages vocaux
4. ✅ Lire les messages vocaux avec contrôles de lecture
5. ✅ Mettre en cache les messages vocaux pour accès hors ligne
6. ✅ Afficher les avatars des utilisateurs devant chaque message
7. ✅ Gérer correctement les durées des messages vocaux

### Problèmes Résolus
1. **Affichage de la durée** : Correction pour que chaque message affiche sa propre durée
2. **Téléchargement des messages** : Utilisation de l'endpoint API avec authentification
3. **Trafic HTTP cleartext** : Autorisation sur Android pour le développement
4. **Expérience utilisateur** : Ajout d'avatars pour une meilleure visibilité

---

## 2. Architecture et Principes

### Structure Clean Architecture Respectée

```
lib/
├── domain/                    → Couche Domaine (Modèles, Interfaces)
│   ├── models/
│   │   ├── message_attachment_dto.dart
│   │   ├── voice_message_cache.dart
│   │   ├── message_response_dto.dart
│   │   └── message_received_dto.dart
│   └── repositories/
│       └── messaging_repository.dart
├── data/                      → Couche Données (Implémentations)
│   ├── datasources/
│   │   ├── audio_recorder_service.dart
│   │   ├── audio_player_service.dart
│   │   ├── voice_message_hive_datasource.dart
│   │   └── messaging_api_client.dart
│   └── repositories/
│       └── messaging_repository_impl.dart
└── presentation/              → Couche Présentation (UI, ViewModels)
    ├── viewmodels/
    │   └── chat/
    │       └── chat_viewmodel.dart
    ├── views/
    │   └── chat/
    │       └── chat_view.dart
    └── widgets/
        └── chat/
            ├── voice_record_button.dart
            ├── voice_message_bubble.dart
            ├── message_bubble.dart
            └── message_input_field.dart
```

### Principes Appliqués
- **Séparation des responsabilités** : Chaque couche a un rôle précis
- **Dépendances vers l'intérieur** : Les couches externes dépendent des couches internes
- **Inversion de dépendances** : Utilisation d'interfaces dans Domain, implémentations dans Data
- **Réactivité** : Utilisation de streams pour les mises à jour en temps réel
- **Cache local** : Hive pour le stockage hors ligne

---

## 3. Dépendances et Configuration

### 3.1. Dépendances Ajoutées (`pubspec.yaml`)

```yaml
dependencies:
  # Audio recording and playback
  record: ^5.1.1                    # Enregistrement audio
  permission_handler: ^11.3.1      # Gestion des permissions
  audioplayers: ^6.1.0              # Lecture audio
  path: ^1.9.0                      # Utilitaires de chemin de fichier

dependency_overrides:
  # Override record_linux to fix compatibility issue
  record_linux: ^1.2.1
```

**Explication :**
- **record** : Package pour enregistrer l'audio depuis le microphone
- **permission_handler** : Gestion des permissions (microphone, stockage)
- **audioplayers** : Lecture de fichiers audio avec contrôles
- **path** : Manipulation des chemins de fichiers
- **record_linux** : Override pour résoudre un problème de compatibilité

### 3.2. Permissions Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>

<application
    android:usesCleartextTraffic="true">
```

**Explication :**
- **RECORD_AUDIO** : Permission pour enregistrer depuis le microphone
- **WRITE_EXTERNAL_STORAGE** : Permission pour sauvegarder les fichiers audio
- **READ_EXTERNAL_STORAGE** : Permission pour lire les fichiers audio
- **usesCleartextTraffic** : Autorise le trafic HTTP (nécessaire pour le développement)

### 3.3. Permissions iOS (`ios/Runner/Info.plist`)

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Cette application a besoin d'accéder au microphone pour enregistrer des messages vocaux.</string>
```

**Explication :**
- **NSMicrophoneUsageDescription** : Description requise pour demander l'accès au microphone sur iOS

---

## 4. Modifications Détaillées par Couche

### 4.1. Couche Domain (Modèles)

#### 4.1.1. `MessageAttachmentDto` (Nouveau)

**Fichier :** `lib/domain/models/message_attachment_dto.dart`

**Description :** DTO pour représenter les pièces jointes des messages, notamment les fichiers audio.

**Champs principaux :**
```dart
class MessageAttachmentDto {
  final int attachmentId;
  final String fileName;
  final String contentType;
  final String fileUrl;              // URL relative
  final String fullFileUrl;          // URL complète pour téléchargement
  final int fileSize;
  final int? durationSeconds;        // Durée en secondes pour audio
}
```

**Utilisation :** Stocke les métadonnées des fichiers audio attachés aux messages.

#### 4.1.2. `VoiceMessageCache` (Nouveau)

**Fichier :** `lib/domain/models/voice_message_cache.dart`

**Description :** Modèle Hive pour mettre en cache les messages vocaux localement.

**Champs :**
```dart
@HiveType(typeId: 2)
class VoiceMessageCache extends HiveObject {
  @HiveField(0)
  final int messageId;
  
  @HiveField(1)
  final String localFilePath;
  
  @HiveField(2)
  final String? serverUrl;
  
  @HiveField(3)
  final DateTime cachedAt;
  
  @HiveField(4)
  final int? durationSeconds;
}
```

**Utilisation :** Permet de stocker les messages vocaux localement pour un accès hors ligne.

#### 4.1.3. `MessageResponseDto` (Modifié)

**Modifications :**
- Ajout de `List<MessageAttachmentDto> attachments`
- Ajout de `MessageType type`
- Ajout de `String? senderAvatar`
- Ajout de propriétés calculées :
  - `bool get hasAudio`
  - `MessageAttachmentDto? get audioAttachment`

**Explication :** Extension pour supporter les messages avec pièces jointes audio.

#### 4.1.4. `MessageReceivedDto` (Modifié)

**Modifications :**
- Ajout de `List<MessageAttachmentDto> attachments`
- Ajout de `MessageType type`
- Ajout de `String? senderAvatar`

**Explication :** Extension pour recevoir les messages vocaux via SignalR.

### 4.2. Couche Data (Services et Datasources)

#### 4.2.1. `AudioRecorderService` (Nouveau)

**Fichier :** `lib/data/datasources/audio_recorder_service.dart`

**Description :** Service pour enregistrer l'audio depuis le microphone.

**Méthodes principales :**
```dart
class AudioRecorderService {
  Future<bool> requestPermission()           // Demander permission microphone
  Future<String?> startRecording()           // Démarrer l'enregistrement
  Future<File?> stopRecording()              // Arrêter et retourner le fichier
  Future<void> cancelRecording()             // Annuler l'enregistrement
}
```

**Fonctionnalités :**
- Gestion des permissions microphone
- Enregistrement au format M4A (AAC)
- Feedback haptique au démarrage
- Sauvegarde dans le répertoire documents de l'application

**Configuration d'enregistrement :**
```dart
RecordConfig(
  encoder: AudioEncoder.aacLc,
  bitRate: 128000,
  sampleRate: 44100,
)
```

#### 4.2.2. `AudioPlayerService` (Nouveau)

**Fichier :** `lib/data/datasources/audio_player_service.dart`

**Description :** Service pour lire les fichiers audio avec contrôles.

**Méthodes principales :**
```dart
class AudioPlayerService {
  Future<void> play(String url)              // Lire depuis URL
  Future<void> playLocal(String filePath)   // Lire depuis fichier local
  Future<void> pause()                      // Mettre en pause
  Future<void> stop()                       // Arrêter
  Future<Duration?> getDuration(String url)  // Obtenir durée depuis URL
  Future<Duration?> getLocalDuration(String filePath)  // Obtenir durée locale
}
```

**Streams disponibles :**
- `positionStream` : Position actuelle de lecture
- `durationStream` : Durée totale du fichier
- `stateStream` : État du lecteur (playing, paused, stopped)

**Utilisation :** Permet de lire les messages vocaux avec mise à jour en temps réel de la position.

#### 4.2.3. `VoiceMessageHiveDataSource` (Nouveau)

**Fichier :** `lib/data/datasources/voice_message_hive_datasource.dart`

**Description :** Datasource pour gérer le cache local des messages vocaux avec Hive.

**Méthodes principales :**
```dart
class VoiceMessageHiveDataSource {
  Future<void> init()                       // Initialiser Hive
  Future<void> cacheVoiceMessage(...)       // Sauvegarder en cache
  VoiceMessageCache? getCachedVoiceMessage(int messageId)
  bool hasCachedVoiceMessage(int messageId)
  String? getLocalFilePath(int messageId)
  Future<String?> downloadAndCacheVoiceMessageFromApi(...)  // Télécharger via API
  Future<String?> downloadAndCacheVoiceMessage(...)         // Télécharger depuis URL
  Future<void> removeCachedVoiceMessage(int messageId)
  Future<void> cleanupOldCache({int daysOld = 30})
}
```

**Fonctionnalités :**
- Cache persistant avec Hive
- Téléchargement via endpoint API avec authentification
- Téléchargement depuis URL directe (fallback)
- Nettoyage automatique des anciens fichiers

**Structure du cache :**
```
Application Documents/
└── voice_messages/
    └── voice_{messageId}_{timestamp}.m4a
```

#### 4.2.4. `MessagingApiClient` (Modifié)

**Modifications :**
- Ajout de `sendVoiceMessage()` pour envoyer les messages vocaux

**Méthode ajoutée :**
```dart
Future<MessageResponseDto> sendVoiceMessage({
  required int conversationId,
  required File audioFile,
  int? receiverId,
  int? groupId,
  int? replyToMessageId,
})
```

**Fonctionnalités :**
- Upload multipart/form-data avec Dio
- Envoi du fichier audio avec métadonnées
- Gestion de l'authentification via headers

#### 4.2.5. `MessagingRepository` et `MessagingRepositoryImpl` (Modifiés)

**Modifications :**
- Ajout de `sendVoiceMessage()` dans l'interface
- Implémentation dans `MessagingRepositoryImpl`

**Explication :** Extension du repository pour supporter l'envoi de messages vocaux.

### 4.3. Couche Presentation (UI et ViewModels)

#### 4.3.1. `ChatViewModel` (Modifié)

**Fichier :** `lib/presentation/viewmodels/chat/chat_viewmodel.dart`

**Nouvelles dépendances injectées :**
```dart
final AudioRecorderService _audioRecorder;
final AudioPlayerService _audioPlayer;
final VoiceMessageHiveDataSource _voiceCache;
```

**Nouvelles variables d'état :**
```dart
bool _isRecording = false;
int? _currentlyPlayingMessageId;
StreamSubscription<Duration>? _audioPositionSubscription;
StreamSubscription<Duration>? _audioDurationSubscription;
StreamSubscription<PlayerState>? _audioStateSubscription;
```

**Nouvelles méthodes :**
```dart
// Enregistrement
Future<void> startRecording()
Future<void> stopRecording()
Future<void> cancelRecording()

// Envoi
Future<void> _sendVoiceMessage(File audioFile)

// Lecture
Future<void> playVoiceMessage(MessageResponseDto message)
Future<void> stopPlaying()

// Streams
Stream<Duration> get audioPositionStream
Stream<Duration> get audioDurationStream
Stream<PlayerState> get audioStateStream
```

**Fonctionnalités implémentées :**
1. **Enregistrement** :
   - Démarrer l'enregistrement avec feedback haptique
   - Arrêter et envoyer automatiquement
   - Annuler l'enregistrement

2. **Envoi** :
   - Création d'un message temporaire avec durée locale calculée
   - Upload au backend
   - Remplacement par le message confirmé du serveur

3. **Lecture** :
   - Vérification du cache local en premier
   - Téléchargement via API si nécessaire
   - Fallback sur URL directe
   - Gestion de la lecture unique (arrête la précédente)

4. **Gestion des messages reçus** :
   - Mise à jour de `_handleNewMessage()` pour inclure `senderAvatar`
   - Support des attachments dans les messages SignalR

**Améliorations de la durée :**
- Calcul de la durée locale avant l'envoi pour affichage immédiat
- Utilisation de la durée spécifique de chaque message (pas de partage global)

#### 4.3.2. `VoiceRecordButton` (Nouveau)

**Fichier :** `lib/presentation/widgets/chat/voice_record_button.dart`

**Description :** Bouton personnalisé pour l'enregistrement vocal avec interaction long-press.

**Fonctionnalités :**
- **Long press** : Démarre l'enregistrement
- **Release** : Arrête et envoie
- **Cancel** : Annule l'enregistrement
- Animation visuelle pendant l'enregistrement
- Feedback haptique

**Utilisation :**
```dart
VoiceRecordButton(
  onLongPressStart: () => viewModel.startRecording(),
  onLongPressEnd: () => viewModel.stopRecording(),
  onLongPressCancel: () => viewModel.cancelRecording(),
  isRecording: viewModel.isRecording,
)
```

#### 4.3.3. `VoiceMessageBubble` (Nouveau)

**Fichier :** `lib/presentation/widgets/chat/voice_message_bubble.dart`

**Description :** Widget pour afficher les messages vocaux avec contrôles de lecture.

**Composants :**
- **Avatar** : Affiché à gauche (messages reçus) ou droite (messages envoyés)
- **Bouton play/pause** : Contrôle de lecture
- **Barre de progression** : Indicateur visuel de la position
- **Durée** : Affichage de la durée du message

**Fonctionnalités :**
- Affichage de la durée spécifique de chaque message
- Barre de progression animée pendant la lecture
- Support des messages en cours d'envoi
- Design cohérent avec les messages texte

#### 4.3.4. `MessageBubble` (Modifié)

**Modifications :**
- Ajout de l'affichage de l'avatar
- Support des messages vocaux (délègue à `VoiceMessageBubble`)
- Positionnement de l'avatar selon l'utilisateur

**Structure :**
```dart
Row(
  children: [
    if (!isCurrentUser) _buildAvatar(),  // Avatar à gauche
    Flexible(child: messageBubble),      // Bulle de message
    if (isCurrentUser) _buildAvatar(),   // Avatar à droite
  ],
)
```

#### 4.3.5. `MessageInputField` (Modifié)

**Modifications :**
- Intégration de `VoiceRecordButton` dans la barre d'outils
- Connexion aux callbacks du ViewModel

**Layout :**
```
[VoiceRecordButton] [TextField] [SendButton]
```

#### 4.3.6. `ChatView` (Modifié)

**Modifications :**
- Intégration des streams audio pour mise à jour en temps réel
- Passage des paramètres audio à `MessageBubble`
- Calcul de la durée spécifique de chaque message

**Streams souscrits :**
```dart
_audioPositionSubscription = viewModel.audioPositionStream.listen(...)
_audioDurationSubscription = viewModel.audioDurationStream.listen(...)
_audioStateSubscription = viewModel.audioStateStream.listen(...)
```

**Amélioration de la durée :**
- Utilisation de la durée du message depuis son attachment
- Utilisation de la durée du lecteur uniquement pour la barre de progression du message en cours

### 4.4. Configuration et Initialisation

#### 4.4.1. `main.dart` (Modifié)

**Modifications :**
- Initialisation de `VoiceMessageHiveDataSource`
- Ajout au `MultiProvider`

```dart
final voiceCache = VoiceMessageHiveDataSource();
await voiceCache.init();

MultiProvider(
  providers: [
    // ... autres providers
    Provider<VoiceMessageHiveDataSource>.value(value: voiceCache),
  ],
)
```

#### 4.4.2. `constants.dart` (Modifié)

**Modifications :**
- Configuration des URLs pour Android (IP locale au lieu de localhost)
- Support des URLs pour SignalR

**URLs configurées :**
```dart
// Pour Android (téléphone réel)
AppConfig.baseUrl = 'http://192.168.100.242:5106/api'
ApiConstants.signalRHubUrl = 'http://192.168.100.242:5106/hubs/chat'
```

---

## 5. Flux de Données

### 5.1. Envoi d'un Message Vocal

```
┌─────────────┐
│   Utilisateur│
│  (Long Press)│
└──────┬───────┘
       │
       ▼
┌─────────────────────┐
│ VoiceRecordButton   │
│ onLongPressStart()  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ startRecording()    │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ AudioRecorderService│
│ startRecording()    │
└──────┬──────────────┘
       │
       │ (Utilisateur relâche)
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ stopRecording()     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ AudioRecorderService│
│ stopRecording()     │
│ → Retourne File     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ _sendVoiceMessage() │
│ 1. Calcul durée     │
│ 2. Crée message temp│
│ 3. Upload au backend│
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ MessagingApiClient  │
│ sendVoiceMessage()  │
│ (multipart/form-data)│
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ Backend API         │
│ POST /messages/voice│
└──────┬──────────────┘
       │
       │ (Réponse)
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ Remplace message    │
│ temporaire          │
└─────────────────────┘
```

### 5.2. Réception d'un Message Vocal

```
┌─────────────────────┐
│ SignalR Hub         │
│ MessageReceived     │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ _handleNewMessage() │
│ (avec attachments)  │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│ ChatView            │
│ Affiche VoiceMessage│
│ Bubble              │
└─────────────────────┘
```

### 5.3. Lecture d'un Message Vocal

```
┌─────────────┐
│ Utilisateur │
│ (Click Play)│
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ ChatViewModel       │
│ playVoiceMessage()  │
└──────┬──────────────┘
       │
       │ Vérifie cache
       ▼
┌─────────────────────┐
│ VoiceMessageHive    │
│ hasCachedVoiceMessage│
└──────┬──────────────┘
       │
       ├─ OUI → Lit depuis cache
       │
       └─ NON → Télécharge
              │
              ▼
       ┌─────────────────────┐
       │ VoiceMessageHive    │
       │ downloadAndCache... │
       │ (via API endpoint)  │
       └──────┬──────────────┘
              │
              ▼
       ┌─────────────────────┐
       │ AudioPlayerService  │
       │ playLocal()         │
       └──────┬──────────────┘
              │
              ▼
       ┌─────────────────────┐
       │ Streams de position │
       │ → Mise à jour UI    │
       └─────────────────────┘
```

---

## 6. Fonctionnalités Implémentées

### 6.1. Enregistrement Vocal

✅ **Démarrage** : Long press sur le bouton micro
✅ **Feedback haptique** : Vibration au démarrage
✅ **Indicateur visuel** : Animation pendant l'enregistrement
✅ **Arrêt** : Relâchement du bouton
✅ **Annulation** : Glissement ou annulation du gesture

### 6.2. Envoi de Message Vocal

✅ **Upload multipart** : Fichier audio avec métadonnées
✅ **Message temporaire** : Affichage immédiat avec durée locale
✅ **Optimistic UI** : Message visible avant confirmation serveur
✅ **Remplacement** : Message temporaire remplacé par la réponse serveur

### 6.3. Réception de Message Vocal

✅ **SignalR** : Réception en temps réel
✅ **Affichage** : Bulle spéciale avec contrôles
✅ **Avatar** : Affichage de l'avatar de l'expéditeur
✅ **Durée** : Affichage correct de la durée spécifique

### 6.4. Lecture de Message Vocal

✅ **Contrôles** : Play/Pause avec bouton
✅ **Barre de progression** : Indicateur visuel de la position
✅ **Durée** : Affichage de la durée totale
✅ **Cache local** : Lecture depuis cache si disponible
✅ **Téléchargement** : Téléchargement automatique si nécessaire
✅ **Lecture unique** : Arrêt automatique de la lecture précédente

### 6.5. Cache Local

✅ **Hive** : Stockage persistant
✅ **Téléchargement** : Via endpoint API avec authentification
✅ **Fallback** : URL directe si API échoue
✅ **Nettoyage** : Suppression automatique des anciens fichiers

### 6.6. Affichage des Avatars

✅ **Avatar réseau** : Affichage depuis URL si disponible
✅ **Initiales** : Fallback sur initiales si pas d'avatar
✅ **Positionnement** : Gauche pour reçus, droite pour envoyés
✅ **Design cohérent** : Style uniforme avec le reste de l'app

---

## 7. Gestion des Erreurs et Optimisations

### 7.1. Gestion des Permissions

**Android :**
- Vérification automatique des permissions
- Demande si nécessaire
- Gestion du refus

**iOS :**
- Description dans Info.plist
- Demande native iOS

### 7.2. Gestion des Erreurs de Téléchargement

**Stratégie en cascade :**
1. **Cache local** : Vérification en premier
2. **API endpoint** : Téléchargement via `/api/messages/{id}/voice` avec auth
3. **URL directe** : Fallback sur `fullFileUrl`
4. **Lecture directe** : Dernier recours avec `audioplayers`

### 7.3. Gestion de la Durée

**Problème initial :** Tous les messages affichaient la durée du dernier message joué

**Solution :**
- Calcul de la durée locale avant l'envoi
- Stockage de la durée dans chaque message
- Utilisation de la durée spécifique pour l'affichage
- Utilisation de la durée du lecteur uniquement pour la barre de progression

### 7.4. Optimisations

✅ **Cache intelligent** : Vérification avant téléchargement
✅ **Streams** : Mise à jour en temps réel sans rebuild complet
✅ **Optimistic UI** : Affichage immédiat des messages envoyés
✅ **Gestion mémoire** : Nettoyage des anciens fichiers
✅ **Feedback utilisateur** : Haptique et visuel

### 7.5. Configuration Réseau

**Problème :** Connexion refusée sur téléphone Android

**Solutions :**
1. **IP locale** : Utilisation de l'IP de l'ordinateur (192.168.100.242)
2. **Cleartext traffic** : Autorisation dans AndroidManifest
3. **Endpoint API** : Utilisation de l'endpoint avec authentification

---

## 8. Tests et Validation

### 8.1. Tests Fonctionnels

#### Enregistrement
- [x] Démarrage avec long press
- [x] Arrêt avec relâchement
- [x] Annulation fonctionne
- [x] Feedback haptique présent
- [x] Fichier créé correctement

#### Envoi
- [x] Message temporaire affiché
- [x] Upload au backend réussi
- [x] Message confirmé remplace le temporaire
- [x] Durée affichée correctement

#### Réception
- [x] Message reçu via SignalR
- [x] Affichage correct avec avatar
- [x] Durée spécifique affichée

#### Lecture
- [x] Play/Pause fonctionne
- [x] Barre de progression mise à jour
- [x] Cache utilisé si disponible
- [x] Téléchargement si nécessaire
- [x] Lecture unique (arrête la précédente)

### 8.2. Tests de Compatibilité

- [x] Android (téléphone réel)
- [x] Permissions microphone
- [x] Trafic HTTP cleartext
- [x] Format audio M4A

### 8.3. Tests de Performance

- [x] Cache local fonctionne
- [x] Téléchargement rapide
- [x] Pas de fuites mémoire
- [x] Streams performants

---

## 9. Fichiers Créés/Modifiés

### Fichiers Créés

1. `lib/domain/models/message_attachment_dto.dart`
2. `lib/domain/models/voice_message_cache.dart`
3. `lib/domain/models/voice_message_cache.g.dart` (généré)
4. `lib/data/datasources/audio_recorder_service.dart`
5. `lib/data/datasources/audio_player_service.dart`
6. `lib/data/datasources/voice_message_hive_datasource.dart`
7. `lib/presentation/widgets/chat/voice_record_button.dart`
8. `lib/presentation/widgets/chat/voice_message_bubble.dart`

### Fichiers Modifiés

1. `pubspec.yaml` - Ajout des dépendances
2. `android/app/src/main/AndroidManifest.xml` - Permissions et cleartext
3. `ios/Runner/Info.plist` - Permission microphone
4. `lib/domain/models/message_response_dto.dart` - Attachments et avatar
5. `lib/domain/models/message_received_dto.dart` - Attachments et avatar
6. `lib/data/datasources/messaging_api_client.dart` - sendVoiceMessage
7. `lib/domain/repositories/messaging_repository.dart` - Interface
8. `lib/data/repositories/messaging_repository_impl.dart` - Implémentation
9. `lib/presentation/viewmodels/chat/chat_viewmodel.dart` - Logique complète
10. `lib/presentation/widgets/chat/message_bubble.dart` - Avatar et support audio
11. `lib/presentation/widgets/chat/message_input_field.dart` - Bouton vocal
12. `lib/presentation/views/chat/chat_view.dart` - Intégration streams
13. `lib/main.dart` - Initialisation cache
14. `lib/core/constants.dart` - URLs pour Android

---

## 10. Points d'Attention et Améliorations Futures

### Points d'Attention

1. **Permissions** : Vérifier que les permissions sont bien demandées
2. **Format audio** : Le format M4A est utilisé (compatible iOS/Android)
3. **Taille des fichiers** : Pas de limite de taille côté client (gérée par le backend)
4. **Cache** : Les fichiers sont stockés localement (peut prendre de l'espace)

### Améliorations Futures Possibles

1. **Compression audio** : Réduire la taille des fichiers
2. **Waveform** : Affichage de la forme d'onde audio
3. **Vitesse de lecture** : Option pour accélérer/ralentir
4. **Recherche vocale** : Transcription des messages vocaux
5. **Notifications** : Notification lors de la réception
6. **Statistiques** : Durée totale des messages vocaux

---

## 11. Commandes Utiles

### Génération du code Hive

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Vérification des erreurs

```bash
flutter analyze
```

### Test sur téléphone

```bash
flutter run
```

### Nettoyage du cache

Le cache est automatiquement nettoyé après 30 jours (configurable dans `VoiceMessageHiveDataSource.cleanupOldCache()`).

---

## 12. Conclusion

L'implémentation des messages vocaux suit les principes de Clean Architecture et MVVM, avec une séparation claire des responsabilités. La fonctionnalité est complète et prête pour la production, avec :

- ✅ Enregistrement et envoi fonctionnels
- ✅ Réception et affichage corrects
- ✅ Lecture avec contrôles
- ✅ Cache local pour accès hors ligne
- ✅ Gestion d'erreurs robuste
- ✅ Expérience utilisateur optimale avec avatars

**Dernière mise à jour :** Documentation complète de l'implémentation des messages vocaux

