import 'package:flutter/material.dart';

/// Type d'erreur spécifique
enum ErrorType {
  /// Pas de connexion internet
  noInternet,

  /// Serveur ne répond pas (timeout)
  serverTimeout,

  /// Serveur introuvable
  serverNotFound,

  /// Image invalide ou trop grande
  invalidImage,

  /// Erreur de parsing JSON
  parseError,

  /// Erreur serveur 500
  serverError,

  /// Erreur serveur 5xx
  unavailable,

  /// Clé API invalide
  invalidApiKey,

  /// Erreur inconnue
  unknown,
}

/// Classe pour représenter une erreur applicative
class AppError implements Exception {
  final ErrorType type;
  final String message;
  final String? description;
  final IconData icon;
  final Color color;
  final String? actionLabel;

  AppError({
    required this.type,
    required this.message,
    this.description,
    required this.icon,
    required this.color,
    this.actionLabel,
  });

  @override
  String toString() => message;
}

/// Convertit une exception en AppError
AppError handleException(Object error) {
  final text = error.toString().toLowerCase();

  // Timeout
  if (text.contains('timeout') || text.contains('timeoutexception')) {
    return AppError(
      type: ErrorType.serverTimeout,
      message: 'Le serveur met trop de temps à répondre',
      description: 'Vérifiez que le serveur est allumé et réessayez.',
      icon: Icons.hourglass_bottom_rounded,
      color: Colors.orange,
      actionLabel: 'Réessayer',
    );
  }

  // Connexion impossible
  if (text.contains('socket') ||
      text.contains('connection refused') ||
      text.contains('failed host lookup') ||
      text.contains('network is unreachable')) {
    return AppError(
      type: ErrorType.serverNotFound,
      message: 'Impossible de joindre le serveur',
      description: 'Vérifiez l\'adresse API et votre connexion réseau.',
      icon: Icons.cloud_off_rounded,
      color: Colors.red,
      actionLabel: 'Paramètres',
    );
  }

  // Pas de connexion internet
  if (text.contains('no internet') || text.contains('network error')) {
    return AppError(
      type: ErrorType.noInternet,
      message: 'Pas de connexion internet',
      description: 'Vérifiez votre connexion WiFi ou données mobiles.',
      icon: Icons.wifi_off_rounded,
      color: Colors.red,
      actionLabel: 'Réessayer',
    );
  }

  // Erreur par défaut
  return AppError(
    type: ErrorType.unknown,
    message: 'Une erreur s\'est produite',
    description: 'Réessayez dans quelques instants.',
    icon: Icons.error_outline_rounded,
    color: Colors.red,
    actionLabel: 'Réessayer',
  );
}

/// Traite les réponses HTTP et retourne une AppError
AppError handleHttpError(int statusCode, String? responseBody) {
  switch (statusCode) {
    case 400:
      // Image invalide ou mauvaise requête
      return AppError(
        type: ErrorType.invalidImage,
        message: 'Image invalide ou trop grande',
        description: 'Essayez une autre photo de meilleure qualité.',
        icon: Icons.image_not_supported_rounded,
        color: Colors.red,
        actionLabel: 'Choisir image',
      );

    case 401 || 403:
      // Clé API invalide
      return AppError(
        type: ErrorType.invalidApiKey,
        message: 'Accès refusé',
        description: 'La clé API est invalide. Vérifiez les paramètres.',
        icon: Icons.lock_outline_rounded,
        color: Colors.red,
        actionLabel: 'Paramètres',
      );

    case 404:
      return AppError(
        type: ErrorType.serverError,
        message: 'Endpoint API non trouvé',
        description: 'Vérifiez l\'adresse du serveur.',
        icon: Icons.search_off_rounded,
        color: Colors.red,
        actionLabel: 'Paramètres',
      );

    case 500 || 502 || 503:
      return AppError(
        type: ErrorType.unavailable,
        message: 'Serveur indisponible',
        description: 'Le serveur est en maintenance. Réessayez plus tard.',
        icon: Icons.construction_rounded,
        color: Colors.orange,
        actionLabel: 'Réessayer',
      );

    default:
      return AppError(
        type: ErrorType.serverError,
        message: 'Erreur serveur ($statusCode)',
        description: 'Réessayez dans quelques instants.',
        icon: Icons.warning_amber_rounded,
        color: Colors.orange,
        actionLabel: 'Réessayer',
      );
  }
}

/// Traite les erreurs de parsing JSON
AppError handleParseError() {
  return AppError(
    type: ErrorType.parseError,
    message: 'Réponse serveur invalide',
    description: 'Le serveur a envoyé une réponse inattendue.',
    icon: Icons.data_usage_rounded,
    color: Colors.red,
    actionLabel: 'Réessayer',
  );
}

/// Valide une image et retourne une AppError si invalide
AppError? validateImage(int? fileSize) {
  // Limite : 10 MB
  if (fileSize != null && fileSize > 10 * 1024 * 1024) {
    return AppError(
      type: ErrorType.invalidImage,
      message: 'Image trop grande',
      description: 'Choisissez une image de moins de 10 MB.',
      icon: Icons.image_rounded,
      color: Colors.red,
      actionLabel: 'Autre image',
    );
  }
  return null;
}
