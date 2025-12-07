class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class LoginResponse {
  final bool success;
  final String message;
  final User user;
  final String? accessToken;
  final String? refreshToken;

  LoginResponse({
    required this.success,
    required this.message,
    required this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'] ?? json['user'] ?? json;
    final Map<String, dynamic> data = rawData is Map<String, dynamic>
        ? rawData
        : <String, dynamic>{};

    return LoginResponse(
      success: json['success'] ?? true,
      message: json['message'] ?? '',
      user: data.containsKey('user')
          ? User.fromJson(data['user'] as Map<String, dynamic>)
          : User.fromJson(data),
      accessToken:
          data['accessToken'] ??
          json['accessToken'] ??
          data['access_token'] ??
          json['access_token'],
      refreshToken:
          data['refreshToken'] ??
          json['refreshToken'] ??
          data['refresh_token'] ??
          json['refresh_token'],
    );
  }
}

class User {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isBlacklisted;
  final List<String> roles; // Liste des rôles ASP.NET Identity

  User({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.isBlacklisted = false,
    this.roles = const [], // Par défaut liste vide
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final effectiveJson = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return null;
    }

    final id =
        parseInt(
          effectiveJson['id'] ??
              effectiveJson['userId'] ??
              effectiveJson['UserId'] ??
              effectiveJson['Id'],
        ) ??
        0;

    List<String> parseRoles(dynamic value) {
      if (value is List) {
        return value
            .map((item) => item?.toString())
            .whereType<String>()
            .where((role) => role.isNotEmpty)
            .toList(growable: false);
      }
      return const [];
    }

    final roles = parseRoles(effectiveJson['roles'] ?? effectiveJson['Roles']);
    String? roleName =
        effectiveJson['roleName'] ?? effectiveJson['RoleName'] as String?;
    if ((roleName == null || roleName.isEmpty) && roles.isNotEmpty) {
      roleName = roles.first;
    }

    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      isBlacklisted: json['isBlacklisted'] ?? false,
      roles: json['roles'] != null 
          ? List<String>.from(json['roles'] as List)
          : [], // Si roles n'existe pas, liste vide
    );
  }

  String get fullName {
    final hasFirst = (firstName ?? '').isNotEmpty;
    final hasLast = (lastName ?? '').isNotEmpty;
    if (hasFirst && hasLast) {
      return '${firstName!} ${lastName!}';
    }
    if (hasFirst) return firstName!;
    if (hasLast) return lastName!;
    return email;
  }

  // Getter pour obtenir les initiales de l'utilisateur
String get initials {
  final first = (firstName ?? '').trim();
  final last = (lastName ?? '').trim();
  
  if (first.isNotEmpty && last.isNotEmpty) {
    return '${first[0]}${last[0]}'.toUpperCase();
  }
  if (first.isNotEmpty) {
    return first[0].toUpperCase();
  }
  if (last.isNotEmpty) {
    return last[0].toUpperCase();
  }
  // Fallback sur la première lettre de l'email
  return email.isNotEmpty ? email[0].toUpperCase() : '?';
}

  // Getter pour obtenir le rôle principal (premier de la liste)
  String get roleName => roles.isNotEmpty ? roles.first : 'Utilisateur';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isBlacklisted': isBlacklisted,
      'roles': roles,
    };
  }
}



