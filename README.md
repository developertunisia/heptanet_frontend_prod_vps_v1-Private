# Heptagon Network Frontend

Application mobile Flutter pour Heptagon Network.

## 🚀 Installation et configuration

### Prérequis
- Flutter SDK (^3.9.2)
- Dart SDK
- Android Studio / Xcode (pour le développement mobile)

### Installation

1. **Cloner le repository**
```bash
git clone <votre-repo-url>
cd heptanet-frontend
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Lancer l'application**
```bash
flutter run
```

## 📱 Configuration de l'icône de l'application

L'icône de l'application est configurée avec le package `flutter_launcher_icons`.

### Régénérer les icônes (si vous modifiez le logo)

Si vous modifiez le logo source (`assets/image/heptanetlogo.png`), vous devez régénérer les icônes :

```bash
# Installer/mettre à jour les dépendances
flutter pub get

# Générer les icônes pour Android et iOS
dart run flutter_launcher_icons
```

**Note :** Les icônes générées sont déjà incluses dans le repository. Vous n'avez besoin de les régénérer que si vous modifiez le logo source.

### Taille recommandée du logo
- Format : PNG
- Taille : 1024x1024 pixels
- Emplacement : `assets/image/heptanetlogo.png`

## 🏗️ Structure du projet

```
lib/
├── core/              # Configuration, routes et constantes
│   ├── constants.dart
│   └── routes.dart
├── data/              # Datasources et repositories
│   ├── datasources/
│   └── repositories/
├── domain/            # Modèles et interfaces
│   ├── models/
│   └── repositories/
└── presentation/      # UI (views, viewmodels, widgets)
    ├── views/
    ├── viewmodels/
    └── widgets/
```

## 📦 Dépendances principales

- **provider** (^6.1.5) - State management
- **dio** (^5.7.0) - HTTP client
- **flutter_secure_storage** (^9.2.2) - Stockage sécurisé
- **jwt_decoder** (^2.0.1) - Décodage JWT
- **http** (^1.2.2) - HTTP requests

### Dev Dependencies
- **flutter_lints** (^5.0.0) - Linting rules
- **flutter_launcher_icons** (^0.13.1) - Génération d'icônes

## 🛠️ Développement

### Lancer en mode debug
```bash
flutter run --debug
```

### Lancer sur un appareil spécifique
```bash
# Lister les appareils disponibles
flutter devices

# Lancer sur un appareil spécifique
flutter run -d <device-id>
```

### Clean et rebuild
```bash
flutter clean
flutter pub get
flutter run
```

### Construire pour production

**Android (APK) :**
```bash
flutter build apk --release
```

**Android (App Bundle) :**
```bash
flutter build appbundle --release
```

**iOS :**
```bash
flutter build ios --release
```

## 🔐 Configuration

L'application utilise un stockage sécurisé pour gérer les tokens d'authentification. Les constantes de configuration sont définies dans `lib/core/constants.dart`.

## 🧪 Tests

Pour exécuter les tests :

```bash
flutter test
```

## 📝 Fonctionnalités

- ✅ Authentification (Login/Register)
- ✅ Vérification d'email
- ✅ Validation OTP
- ✅ Récupération de mot de passe
- ✅ Écran d'accueil
- ✅ Gestion de session sécurisée

## 🎨 UI/UX

L'application suit les principes Material Design avec une interface moderne et intuitive.

## 👥 Équipe

Développé par l'équipe Heptagon Network.

## 📄 License

Propriétaire - Tous droits réservés.
