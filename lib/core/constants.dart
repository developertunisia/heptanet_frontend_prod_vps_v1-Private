import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../domain/models/user_response_dto.dart';
import '../domain/models/auth_model.dart';

class AppColors {
  static const primary = Colors.blue;
  static const accent = Colors.orange;
}

class ApiConstants {
  // Base URL pour les APIs (utilisée par certains clients API)
  // Configuration pour le serveur VPS de production
  static String get baseUrl {
    // Utilisation de l'URL du serveur VPS pour tous les environnements
    return 'http://51.83.72.29';
  }
  static const String checkEmailEndpoint = '/api/AuthorizedEmail/check';

  static const String otpSendEndpoint = '/api/auth/otp/send';
  static const String otpVerifyEndpoint = '/api/auth/otp/verify';
  static const String otpStatusEndpoint = '/api/auth/otp/status';
  static const String registerUserEndpoint = '/api/Users/register';
  static const String authorizedEmailsEndpoint = '/api/AuthorizedEmail';
  
  // Messaging endpoints
  static const String conversationsEndpoint = '/api/conversations';
  static const String messagesEndpoint = '/api/messages';
  
  // SignalR Hub URL
  // Configuration pour le serveur VPS de production
  static String get signalRHubUrl {
    // Utilisation de l'URL du serveur VPS pour tous les environnements
    return 'http://51.83.72.29/hubs/chat';
  }
}

// ===== ASP.NET Identity Roles =====

class AppRoles {
  // Constantes de rôles
  static const String superAdmin = 'SuperAdmin';
  static const String admin = 'Admin';
  static const String utilisateur = 'Utilisateur';

  // Liste de tous les rôles disponibles
  static const List<String> allRoles = [
    superAdmin,
    admin,
    utilisateur,
  ];

  // Helpers pour vérifier les permissions
  static bool isSuperAdmin(UserResponseDto user) {
    return user.roles.contains(superAdmin);
  }

  static bool isAdmin(UserResponseDto user) {
    return user.roles.contains(admin);
  }

  static bool isUtilisateur(UserResponseDto user) {
    return user.roles.contains(utilisateur);
  }

  static bool hasRole(UserResponseDto user, String role) {
    return user.roles.contains(role);
  }

  static bool hasAnyRole(UserResponseDto user, List<String> roles) {
    return user.roles.any((role) => roles.contains(role));
  }

  static bool hasAllRoles(UserResponseDto user, List<String> roles) {
    return roles.every((role) => user.roles.contains(role));
  }

  // Vérifier si l'utilisateur a des privilèges administratifs
  static bool isAdministrator(UserResponseDto user) {
    return isSuperAdmin(user) || isAdmin(user);
  }

  // Obtenir le rôle principal (le premier de la liste)
  static String getPrimaryRole(UserResponseDto user) {
    return user.roles.isNotEmpty ? user.roles.first : utilisateur;
  }

  // ===== Helpers pour le modèle User (auth_model.dart) =====

  static bool isSuperAdminAuth(User user) {
    return user.roles.contains(superAdmin);
  }

  static bool isAdminAuth(User user) {
    return user.roles.contains(admin);
  }

  static bool isUtilisateurAuth(User user) {
    return user.roles.contains(utilisateur);
  }

  static bool hasRoleAuth(User user, String role) {
    return user.roles.contains(role);
  }

  static bool hasAnyRoleAuth(User user, List<String> roles) {
    return user.roles.any((role) => roles.contains(role));
  }

  static bool hasAllRolesAuth(User user, List<String> roles) {
    return roles.every((role) => user.roles.contains(role));
  }

  static bool isAdministratorAuth(User user) {
    return isSuperAdminAuth(user) || isAdminAuth(user);
  }

  static String getPrimaryRoleAuth(User user) {
    return user.roles.isNotEmpty ? user.roles.first : utilisateur;
  }
}

// ===== Migré depuis core/utils/app_config.dart =====

class AppConfig {
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String verifyTokenEndpoint = '/auth/verify';

  static const String tokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user_data';
  static const String savedEmailKey = 'saved_email';

  static String get baseUrl {
    // Configuration pour le serveur VPS de production
    // Utilisation de l'URL du serveur VPS pour tous les environnements
    return 'http://51.83.72.29/api';
  }
}
