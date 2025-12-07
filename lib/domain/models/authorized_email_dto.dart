import 'package:hive/hive.dart';

part 'authorized_email_dto.g.dart';

@HiveType(typeId: 1)
class AuthorizedEmailDto extends HiveObject {
  @HiveField(0)
  final int syncId;
  
  @HiveField(1)
  final String email;
  
  @HiveField(2)
  final bool isImported;
  
  @HiveField(3)
  final DateTime? syncDate;
  
  @HiveField(4)
  final DateTime cachedAt; // For cache management

  AuthorizedEmailDto({
    required this.syncId,
    required this.email,
    this.isImported = false,
    this.syncDate,
    DateTime? cachedAt,
  }) : cachedAt = cachedAt ?? DateTime.now();

  factory AuthorizedEmailDto.fromJson(Map<String, dynamic> json) {
    return AuthorizedEmailDto(
      syncId: json['syncId'] ?? 0,
      email: json['email'] ?? '',
      isImported: json['isImported'] ?? false,
      syncDate: json['syncDate'] != null 
          ? DateTime.parse(json['syncDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'syncId': syncId,
      'email': email,
      'isImported': isImported,
      'syncDate': syncDate?.toIso8601String(),
    };
  }
  
  // CopyWith method for cache updates
  AuthorizedEmailDto copyWith({
    int? syncId,
    String? email,
    bool? isImported,
    DateTime? syncDate,
    DateTime? cachedAt,
  }) {
    return AuthorizedEmailDto(
      syncId: syncId ?? this.syncId,
      email: email ?? this.email,
      isImported: isImported ?? this.isImported,
      syncDate: syncDate ?? this.syncDate,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}

class AddAuthorizedEmailDto {
  final String email;
  final bool isImported;

  AddAuthorizedEmailDto({
    required this.email,
    this.isImported = false, // Par défaut true quand ajouté depuis l'interface
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'isImported': isImported,
    };
  }
}

class UpdateEmailStatusDto {
  final String email;

  UpdateEmailStatusDto({
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}

