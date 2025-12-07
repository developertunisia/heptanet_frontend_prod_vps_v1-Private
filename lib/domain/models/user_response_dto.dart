import 'package:hive/hive.dart';

part 'user_response_dto.g.dart';

@HiveType(typeId: 0)
class UserResponseDto extends HiveObject {
  @HiveField(0)
  final int id;
  
  @HiveField(1)
  final String firstName;
  
  @HiveField(2)
  final String lastName;
  
  @HiveField(3)
  final String email;
  
  @HiveField(4)
  final String whatsAppNumber;
  
  @HiveField(5)
  @Deprecated('Use roles instead. roleId is deprecated with ASP.NET Identity migration.')
  final int? roleId; // Nullable pour compatibilité avec ancien système
  
  @HiveField(6)
  final List<String> roles; // Liste des rôles ASP.NET Identity
  
  @HiveField(7)
  final DateTime createdAt;
  
  @HiveField(8)
  final DateTime? lastLogin;
  
  @HiveField(9)
  final bool isBlacklisted;
  
  @HiveField(10)
  final DateTime cachedAt; // For cache management

  UserResponseDto({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.whatsAppNumber,
    this.roleId, // Optionnel maintenant
    required this.roles,
    required this.createdAt,
    this.lastLogin,
    this.isBlacklisted = false,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  // Getter pour obtenir le rôle principal (premier de la liste)
  String get roleName => roles.isNotEmpty ? roles.first : 'Utilisateur';

  // Getter pour obtenir le nom complet
  String get fullName => '$firstName $lastName'.trim();

  // Getter pour obtenir les initiales (premières lettres du prénom et nom)
  String get initials {
    final firstInitial = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final lastInitial = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return (firstInitial + lastInitial).isEmpty ? '?' : (firstInitial + lastInitial);
  }

  factory UserResponseDto.fromJson(Map<String, dynamic> json) {
    List<String> parseRoles(dynamic value) {
      if (value is List) {
        return value
            .map((item) => item?.toString())
            .whereType<String>()
            .where((role) => role.isNotEmpty)
            .toList();
      }
      return [];
    }

    final roles = parseRoles(json['roles'] ?? json['Roles'] ?? []);
    final roleName = json['roleName'] ?? json['RoleName'] ?? (roles.isNotEmpty ? roles.first : 'Utilisateur');

    // Parse createdAt avec gestion de null
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    // Parse lastLogin avec gestion de null
    DateTime? parseLastLogin(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return UserResponseDto(
      id: json['id'] as int,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      whatsAppNumber: json['whatsAppNumber'] as String? ?? '',
      roleId: json['roleId'] as int?, // Peut être null
      roles: roles, // Utiliser la fonction parseRoles qui gère déjà tous les cas
      createdAt: parseCreatedAt(json['createdAt']),
      lastLogin: parseLastLogin(json['lastLogin']),
      isBlacklisted: json['isBlacklisted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'whatsAppNumber': whatsAppNumber,
      'roleId': roleId,
      'roles': roles,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isBlacklisted': isBlacklisted,
    };
  }
  
  // CopyWith method for cache updates
  UserResponseDto copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? whatsAppNumber,
    int? roleId,
    List<String>? roles,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isBlacklisted,
    DateTime? cachedAt,
  }) {
    return UserResponseDto(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      whatsAppNumber: whatsAppNumber ?? this.whatsAppNumber,
      roleId: roleId ?? this.roleId,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isBlacklisted: isBlacklisted ?? this.isBlacklisted,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}