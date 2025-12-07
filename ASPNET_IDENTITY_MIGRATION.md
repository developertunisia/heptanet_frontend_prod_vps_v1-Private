# Migration ASP.NET Identity Roles - Branch Develop

## ✅ État de la Migration

Tous les changements de migration vers ASP.NET Identity Roles ont été appliqués avec succès sur la branche `develop`.

---

## 📋 Résumé des Changements Effectués

### 1. **Modèles de Données (Domain Models)** ✅

#### `UserResponseDto` (`lib/domain/models/user_response_dto.dart`)
- ✅ Ajout de `List<String> roles` - Liste des rôles ASP.NET Identity
- ✅ `int? roleId` marqué comme `@Deprecated` et rendu nullable
- ✅ Ajout du getter `roleName` qui retourne le rôle principal
- ✅ `fromJson()` gère les rôles avec fallback sur liste vide

#### `RegisterUserDto` (`lib/domain/models/register_user_dto.dart`)
- ✅ Remplacement de `int roleId` par `String? roleName`
- ✅ `roleName` est optionnel (le backend assigne "Utilisateur" par défaut)
- ✅ `toJson()` n'ajoute `roleName` que s'il est spécifié

#### `User` (`lib/domain/models/auth_model.dart`)
- ✅ Ajout de `List<String> roles`
- ✅ Ajout du getter `roleName` qui retourne le rôle principal
- ✅ `fromJson()` parse robustement les rôles
- ✅ `toJson()` inclut les rôles

---

### 2. **Constantes et Helpers (Core)** ✅

#### `AppRoles` (`lib/core/constants.dart`)

**Constantes de rôles:**
```dart
static const String superAdmin = 'SuperAdmin';
static const String admin = 'Admin';
static const String utilisateur = 'Utilisateur';
```

**Helpers pour UserResponseDto:**
- `isSuperAdmin(UserResponseDto user)`
- `isAdmin(UserResponseDto user)`
- `isUtilisateur(UserResponseDto user)`
- `hasRole(UserResponseDto user, String role)`
- `hasAnyRole(UserResponseDto user, List<String> roles)`
- `hasAllRoles(UserResponseDto user, List<String> roles)`
- `isAdministrator(UserResponseDto user)` - SuperAdmin ou Admin
- `getPrimaryRole(UserResponseDto user)`

**Helpers pour User (Auth Model):**
- `isSuperAdminAuth(User user)`
- `isAdminAuth(User user)`
- `isUtilisateurAuth(User user)`
- `hasRoleAuth(User user, String role)`
- `hasAnyRoleAuth(User user, List<String> roles)`
- `hasAllRolesAuth(User user, List<String> roles)`
- `isAdministratorAuth(User user)`
- `getPrimaryRoleAuth(User user)`

---

### 3. **ViewModels** ✅

#### `RegisterUserViewModel` (`lib/presentation/viewmodels/register_user_viewmodel.dart`)
- ✅ Paramètre `String? roleName` au lieu de `int roleId`
- ✅ `roleName` est optionnel dans la méthode `registerUser()`

#### `AuthorizedEmailViewModel` (`lib/presentation/viewmodels/authorized_email_viewmodel.dart`)
- ✅ Gère la liste des emails autorisés
- ✅ Recherche en temps réel
- ✅ Opérations CRUD complètes
- ✅ Rechargement automatique après modifications

---

### 4. **Vues et Navigation** ✅

#### `RegisterUserScreen` (`lib/presentation/views/register_user_screen.dart`)
- ✅ Suppression de `_selectedRoleId`
- ✅ N'envoie plus de `roleName` (backend assigne "Utilisateur")

#### `HomeScreen` (`lib/presentation/views/home_screen.dart`)
- ✅ Charge l'utilisateur depuis le storage via `checkAuthStatus()`
- ✅ Affiche les logs de debug pour vérifier les rôles
- ✅ Système de navigation par tabs avec dashboard

#### `NavigationViewModel` (`lib/presentation/viewmodels/dashboard/navigation_viewmodel.dart`)
- ✅ Utilise `user.roleName` pour filtrer les navigation items
- ✅ **SuperAdmin** → Accès à toutes les sections (Messages, Membres, Diffusion, **Gestion**)
- ✅ **Admin** → Accès à Messages, Membres, Diffusion
- ✅ **Utilisateur** → Accès à Messages, Membres
- ✅ Fallback sur `roleId` pour compatibilité

#### `ManagementView` (`lib/presentation/views/dashboard/management_view.dart`) ⭐ **FUSIONNÉ**
- ✅ Vérifie si l'utilisateur est SuperAdmin avec `AppRoles.isSuperAdminAuth(user)`
- ✅ **Affiche directement la gestion des emails autorisés pour SuperAdmin** (plus de navigation séparée)
- ✅ Interface fusionnée : settings + gestion des emails dans la même page
- ✅ Barre de recherche en temps réel
- ✅ Bouton "Ajouter un email autorisé"
- ✅ Liste complète des emails avec actions (Activer/Désactiver/Supprimer)
- ✅ Design moderne avec cards et responsive
- ✅ ScrollView pour éviter les pixel overflow

---

### 5. **API et Repositories** ✅

#### `AuthorizedEmailApiClient` (`lib/data/datasources/authorized_email_api_client.dart`)
- ✅ Utilise `FlutterSecureStorage` pour récupérer le token JWT
- ✅ Méthode `_getHeaders()` ajoute automatiquement `Authorization: Bearer <token>`
- ✅ Toutes les requêtes HTTP incluent le token d'authentification
- ✅ Gestion robuste des réponses vides ou non-JSON

#### `AuthorizedEmailDto` (`lib/domain/models/authorized_email_dto.dart`)
- ✅ `fromJson()` robuste avec valeurs par défaut
- ✅ `AddAuthorizedEmailDto` inclut `isImported: true` par défaut
- ✅ Plus d'erreur "type null is not subtype"

---

## 🎯 Comment Utiliser

### Vérification des Permissions

```dart
// Avec User (Auth Model)
if (AppRoles.isSuperAdminAuth(user)) {
  // L'utilisateur est SuperAdmin
}

if (AppRoles.isAdministratorAuth(user)) {
  // L'utilisateur est SuperAdmin ou Admin
}

// Avec UserResponseDto
if (AppRoles.isAdministrator(userResponse)) {
  // L'utilisateur est un administrateur
}
```

### Enregistrement d'un Utilisateur

```dart
// Simple utilisateur (rôle par défaut "Utilisateur")
await registerUserViewModel.registerUser(
  firstName: 'John',
  lastName: 'Doe',
  email: 'john@example.com',
  whatsAppNumber: '+1234567890',
  password: 'password123',
  // roleName omis = backend assigne "Utilisateur"
);

// Admin ou SuperAdmin
await registerUserViewModel.registerUser(
  firstName: 'Admin',
  lastName: 'User',
  email: 'admin@example.com',
  whatsAppNumber: '+1234567890',
  password: 'password123',
  roleName: AppRoles.admin, // ou AppRoles.superAdmin
);
```

### Accès à la Gestion des Emails Autorisés

Pour les **SuperAdmins uniquement**:
1. Connectez-vous avec un compte SuperAdmin
2. Allez dans l'onglet **"Gestion"** (4ème onglet en bas)
3. La section "Gestion des Emails Autorisés" est **directement affichée** sur la même page
4. Recherchez, ajoutez, activez/désactivez ou supprimez des emails autorisés

---

## 🔄 Structure de la Réponse Backend Attendue

### Login Response
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": null,
  "user": {
    "id": 1,
    "email": "admin@example.com",
    "firstName": "Admin",
    "lastName": "User",
    "isBlacklisted": false,
    "roles": ["SuperAdmin"]  // ✅ IMPORTANT !
  }
}
```

### Register Response
```json
{
  "id": 1,
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "whatsAppNumber": "+1234567890",
  "roleId": null,  // Peut être null
  "roles": ["Utilisateur"],  // ✅ IMPORTANT !
  "createdAt": "2025-01-01T00:00:00Z",
  "isBlacklisted": false
}
```

---

## 🧪 Tests Recommandés

1. ✅ **Connexion avec SuperAdmin** → Vérifier que l'onglet "Gestion" est visible
2. ✅ **Connexion avec Admin** → Vérifier que l'onglet "Gestion" n'est PAS visible
3. ✅ **Connexion avec Utilisateur** → Vérifier accès limité (Messages + Membres)
4. ✅ **Enregistrement sans spécifier de rôle** → Doit recevoir "Utilisateur"
5. ✅ **Navigation vers Gestion emails** → Depuis l'onglet Gestion (SuperAdmin)
6. ✅ **Ajout d'email autorisé** → Avec `isImported: true`
7. ✅ **Toggle statut actif/inactif** → Doit fonctionner
8. ✅ **Suppression d'email** → Avec confirmation
9. ✅ **Recherche d'email** → En temps réel

---

## 📝 Points Importants

### 1. Backward Compatibility
- Le champ `roleId` est marqué `@Deprecated` mais reste présent
- Le `NavigationViewModel` utilise `roleName` en priorité et fallback sur `roleId`
- Permet une migration progressive

### 2. Stockage Local
- Les rôles sont sauvegardés dans `flutter_secure_storage`
- **Important**: Déconnexion/reconnexion nécessaire après mise à jour du backend
- Le token JWT est automatiquement inclus dans toutes les requêtes API

### 3. Sécurité
- Vérifications côté client ET serveur
- Token JWT requis pour la gestion des emails autorisés
- Seuls les SuperAdmins peuvent accéder à la gestion

### 4. UX
- Interface moderne et intuitive
- Boutons contextuels selon le rôle
- Feedback visuel pour toutes les actions
- Messages d'erreur clairs

---

## 🐛 Troubleshooting

### Problème: Bouton "Gestion" non visible pour SuperAdmin

**Solution:**
1. Déconnectez-vous
2. Videz le cache du site (F12 → Application → Clear site data)
3. Reconnectez-vous

Le backend doit renvoyer `"roles": ["SuperAdmin"]` dans la réponse de login.

### Problème: Erreur 401 Unauthorized sur les APIs

**Solution:**
Le token JWT n'est pas inclus. Vérifiez que:
1. Vous êtes bien connecté
2. Le token est sauvegardé dans `flutter_secure_storage`
3. `AuthorizedEmailApiClient` utilise `_getHeaders()` qui inclut le token

### Problème: "type null is not subtype"

**Solution:**
Le backend renvoie un format de réponse différent. Les modèles actuels gèrent déjà les valeurs null avec fallback.

---

## 📦 Fichiers Modifiés

### Domain Layer
- `lib/domain/models/user_response_dto.dart` ✅
- `lib/domain/models/register_user_dto.dart` ✅
- `lib/domain/models/auth_model.dart` ✅
- `lib/domain/models/authorized_email_dto.dart` ✅
- `lib/domain/repositories/authorized_email_repository.dart` ✅

### Data Layer
- `lib/data/datasources/authorized_email_api_client.dart` ✅
- `lib/data/repositories/authorized_email_repository_impl.dart` ✅

### Presentation Layer
- `lib/presentation/viewmodels/register_user_viewmodel.dart` ✅
- `lib/presentation/viewmodels/authorized_email_viewmodel.dart` ✅
- `lib/presentation/viewmodels/dashboard/navigation_viewmodel.dart` ✅
- `lib/presentation/views/register_user_screen.dart` ✅
- `lib/presentation/views/home_screen.dart` ✅
- `lib/presentation/views/dashboard/management_view.dart` ✅ **NOUVEAU**

### Core Layer
- `lib/core/constants.dart` ✅ (AppRoles ajouté)
- `lib/core/routes.dart` ✅
- `lib/main.dart` ✅ (Providers)

---

## ✨ Résultat Final

- ✅ Migration complète vers ASP.NET Identity Roles
- ✅ Support des rôles : SuperAdmin, Admin, Utilisateur
- ✅ Navigation contextuelle selon le rôle
- ✅ Interface de gestion des emails autorisés (SuperAdmin uniquement)
- ✅ Authentification JWT automatique
- ✅ Gestion robuste des erreurs
- ✅ UX moderne et intuitive

**La migration est complète et fonctionnelle !** 🎉

