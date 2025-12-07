# Configuration du Débogage Wireless et Connexion Android

Ce document explique comment configurer le débogage wireless pour connecter un téléphone Android à l'application Flutter et les modifications nécessaires pour que l'application communique avec le backend .NET.

## 📱 Table des matières

1. [Configuration du Débogage Wireless](#configuration-du-débogage-wireless)
2. [Connexion du Téléphone](#connexion-du-téléphone)
3. [Configuration des Adresses IP](#configuration-des-adresses-ip)
4. [Vérification et Test](#vérification-et-test)
5. [Dépannage](#dépannage)

---

## 🔧 Configuration du Débogage Wireless

### Prérequis

- Téléphone Android avec Android 11+ (API 30+)
- Ordinateur et téléphone sur le même réseau Wi-Fi
- ADB installé sur l'ordinateur (inclus avec Android Studio)
- Flutter installé et configuré

### Étape 1 : Activer les Options Développeur

1. Sur votre téléphone Android, allez dans **Paramètres** → **À propos du téléphone**
2. Appuyez 7 fois sur **Numéro de build** jusqu'à voir le message "Vous êtes maintenant développeur"
3. Retournez aux **Paramètres** → **Système** → **Options développeur**

### Étape 2 : Activer le Débogage USB (première fois uniquement)

1. Dans **Options développeur**, activez **Débogage USB**
2. Connectez votre téléphone à l'ordinateur via USB
3. Sur le téléphone, acceptez l'invite "Autoriser le débogage USB" et cochez **Toujours autoriser depuis cet ordinateur**

### Étape 3 : Activer le Débogage sans fil

1. Dans **Options développeur**, activez **Débogage sans fil**
2. Notez l'adresse IP et le port affichés (ex: `192.168.100.212:39687`)

---

## 📲 Connexion du Téléphone

### Étape 1 : Appariement (Pairing)

Ouvrez PowerShell ou Terminal et exécutez :

```powershell
adb pair [IP_DU_TELEPHONE]:[PORT]
```

**Exemple :**
```powershell
adb pair 192.168.100.212:39687
```

Vous serez invité à entrer le code d'appariement affiché sur votre téléphone.

**Résultat attendu :**
```
Successfully paired to 192.168.100.212:39687 [guid=adb-10ADAT0U58001GJ-raBpbs]
```

### Étape 2 : Connexion

Après l'appariement, une nouvelle adresse IP:PORT est générée pour la connexion réelle. 

1. Sur votre téléphone, dans **Options développeur** → **Débogage sans fil**, regardez la section **Adresses IP** ou **IP address & Port**
2. Notez la nouvelle adresse (différente du port d'appariement)

Connectez-vous avec cette nouvelle adresse :

```powershell
adb connect [NOUVELLE_IP]:[NOUVEAU_PORT]
```

**Note :** Si vous ne voyez pas de nouvelle adresse, essayez de redémarrer le débogage sans fil sur le téléphone.

### Étape 3 : Vérification

Vérifiez que le téléphone est bien connecté :

```powershell
adb devices
```

**Résultat attendu :**
```
List of devices attached
192.168.100.212:XXXXX    device
```

### Étape 4 : Vérification avec Flutter

Vérifiez que Flutter détecte votre téléphone :

```powershell
flutter devices
```

**Résultat attendu :**
```
Found 1 wirelessly connected device:
  V2317 (wireless) (mobile) • adb-10ADAT0U58001GJ-raBpbs._adb-tls-connect._tcp • android-arm64 • Android 15 (API 35)
```

### Étape 5 : Lancer l'Application

Lancez l'application sur le téléphone :

```powershell
flutter run
```

Ou spécifiez explicitement le device :

```powershell
flutter run -d V2317
```

---

## 🌐 Configuration des Adresses IP

### Problème Identifié

Par défaut, Flutter utilise `localhost` ou `10.0.2.2` (pour émulateur Android) pour se connecter au backend. Sur un téléphone réel connecté en Wi-Fi, ces adresses ne fonctionnent pas. Il faut utiliser l'adresse IP réelle de l'ordinateur sur le réseau Wi-Fi.

### Étape 1 : Trouver l'IP de l'Ordinateur

Exécutez dans PowerShell :

```powershell
ipconfig
```

Cherchez la section **Carte réseau sans fil Wi‑Fi** ou **Wireless LAN adapter Wi-Fi** et notez l'**Adresse IPv4**.

**Exemple :**
```
Adresse IPv4. . . . . . . . . . . . . .: 192.168.100.242
```

### Étape 2 : Modifications dans le Code

#### Fichier : `lib/core/constants.dart`

##### 1. `AppConfig.baseUrl` (pour l'authentification et les APIs principales)

**Avant :**
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5106/api';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:5106/api';  // ❌ Ne fonctionne que pour émulateur
    // ...
  }
}
```

**Après :**
```dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:5106/api';
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://192.168.100.242:5106/api';  // ✅ IP de l'ordinateur
    // ...
  }
}
```

##### 2. `ApiConstants.baseUrl` (pour certaines APIs)

**Avant :**
```dart
class ApiConstants {
  static const String baseUrl = 'http://localhost:5106';
  // ...
}
```

**Après :**
```dart
class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5106';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://192.168.100.242:5106';
      default:
        return 'http://localhost:5106';
    }
  }
  // ...
}
```

##### 3. `ApiConstants.signalRHubUrl` (pour SignalR)

**Avant :**
```dart
static String get signalRHubUrl {
  // ...
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:5106/hubs/chat';  // ❌
    // ...
  }
}
```

**Après :**
```dart
static String get signalRHubUrl {
  // ...
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://192.168.100.242:5106/hubs/chat';  // ✅
    // ...
  }
}
```

#### Fichier : `lib/data/datasources/signalr_service.dart`

##### `_hubUrl` (pour SignalR)

**Avant :**
```dart
String get _hubUrl {
  // ...
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:5106/hubs/chat';  // ❌
    // ...
  }
}
```

**Après :**
```dart
String get _hubUrl {
  // ...
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://192.168.100.242:5106/hubs/chat';  // ✅
    // ...
  }
}
```

### Étape 3 : Configuration du Backend

Assurez-vous que le backend .NET écoute sur toutes les interfaces réseau, pas seulement `localhost`.

#### Fichier : `HeptaNet.API/Properties/launchSettings.json`

**Configuration recommandée :**
```json
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": false,
      "applicationUrl": "http://0.0.0.0:5106",  // ✅ Écoute sur toutes les interfaces
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
```

**Important :** `0.0.0.0` permet au backend d'écouter sur toutes les interfaces réseau, permettant ainsi aux appareils sur le même réseau Wi-Fi de s'y connecter.

#### Démarrer le Backend

```powershell
cd "C:\Users\tunav\Documents\Aziz\HeptaNET\dev_mode\heptanet-backend\HeptaNet.API"
dotnet run --launch-profile http
```

---

## ✅ Vérification et Test

### 1. Vérifier la Connexion ADB

```powershell
adb devices
```

Le téléphone doit apparaître comme `device` (pas `offline`).

### 2. Vérifier la Détection Flutter

```powershell
flutter devices
```

Le téléphone doit apparaître dans la liste des appareils connectés.

### 3. Tester l'Application

```powershell
flutter run
```

L'application doit s'installer et se lancer sur le téléphone.

### 4. Tester le Login

1. Ouvrez l'application sur le téléphone
2. Entrez vos identifiants
3. Le login doit fonctionner sans erreur "Connection refused"

---

## 🔍 Dépannage

### Problème : "Device is offline"

**Solution :**
1. Redémarrez le débogage sans fil sur le téléphone
2. Réappariez le téléphone si nécessaire
3. Vérifiez que le téléphone et l'ordinateur sont sur le même réseau Wi-Fi

### Problème : "Connection refused" lors du login

**Causes possibles :**

1. **Mauvaise IP dans le code Flutter**
   - Vérifiez que l'IP dans `constants.dart` correspond à l'IP de votre ordinateur
   - Exécutez `ipconfig` pour vérifier votre IP actuelle

2. **Backend non démarré**
   - Assurez-vous que le backend est en cours d'exécution
   - Vérifiez qu'il écoute sur `0.0.0.0:5106` (toutes les interfaces)

3. **Firewall Windows**
   - Le firewall peut bloquer les connexions entrantes
   - Ajoutez une exception pour le port 5106 ou désactivez temporairement le firewall pour tester

4. **Réseau différent**
   - Vérifiez que le téléphone et l'ordinateur sont sur le même réseau Wi-Fi

### Problème : Flutter ne détecte pas le téléphone

**Solution :**
1. Vérifiez avec `adb devices` que le téléphone est bien connecté
2. Redémarrez le service ADB : `adb kill-server` puis `adb start-server`
3. Réessayez `flutter devices`

### Problème : L'IP change à chaque connexion Wi-Fi

**Solution :**
- Configurez une IP statique pour votre ordinateur dans les paramètres du routeur
- Ou utilisez une variable d'environnement dans Flutter pour faciliter le changement

---

## 📝 Notes Importantes

1. **IP Dynamique :** Si votre IP change fréquemment, vous devrez mettre à jour les fichiers de configuration à chaque fois.

2. **Sécurité :** Le débogage wireless est pratique mais moins sécurisé que USB. Désactivez-le quand vous ne l'utilisez pas.

3. **Performance :** Le débogage wireless peut être légèrement plus lent que USB, mais reste très utilisable.

4. **Port Backend :** Assurez-vous que le port 5106 n'est pas utilisé par un autre service.

---

## 🔄 Reconnexion Rapide

Si vous devez vous reconnecter plus tard :

1. Activez **Débogage sans fil** sur le téléphone
2. Notez l'adresse IP:PORT affichée
3. Connectez-vous : `adb connect [IP]:[PORT]`
4. Vérifiez : `adb devices`
5. Lancez : `flutter run`

---

## 📚 Ressources

- [Documentation Flutter - Débogage](https://docs.flutter.dev/tools/devtools)
- [Documentation ADB - Débogage Wireless](https://developer.android.com/studio/command-line/adb#wireless)
- [Documentation .NET - Configuration Kestrel](https://learn.microsoft.com/en-us/aspnet/core/fundamentals/servers/kestrel)

---

**Dernière mise à jour :** Configuration effectuée avec succès pour le développement sur téléphone Android V2317 (Android 15, API 35).

**IP de l'ordinateur utilisée :** `192.168.100.242`  
**Port backend :** `5106`  
**Téléphone :** V2317 (10ADAT0U58001GJ)

