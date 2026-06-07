import 'package:flutter/material.dart';
import '../services/error_handler.dart';

/// Dialog professionnel pour afficher les erreurs
class ErrorDialog extends StatelessWidget {
  final AppError error;
  final VoidCallback? onRetry;
  final VoidCallback? onSettings;
  final VoidCallback? onDismiss;

  const ErrorDialog({
    super.key,
    required this.error,
    this.onRetry,
    this.onSettings,
    this.onDismiss,
  });

  /// Affiche le dialog d'erreur
  static Future<void> show(
    BuildContext context,
    AppError error, {
    VoidCallback? onRetry,
    VoidCallback? onSettings,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ErrorDialog(
        error: error,
        onRetry: onRetry,
        onSettings: onSettings,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: error.color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  error.icon,
                  color: error.color,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Message principal
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),

            // Description
            if (error.description != null) ...[
              const SizedBox(height: 8),
              Text(
                error.description!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],

            const SizedBox(height: 24),

            // Boutons d'action
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouton Réessayer
                if (onRetry != null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onRetry!();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Réessayer'),
                      style: FilledButton.styleFrom(
                        backgroundColor: error.color,
                      ),
                    ),
                  ),

                // Bouton Paramètres
                if (onSettings != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onSettings!();
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Paramètres'),
                    ),
                  ),
                ],

                // Bouton Fermer (toujours présent)
                if (onRetry == null && onSettings == null)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.grey.shade400,
                      ),
                      child: const Text('OK'),
                    ),
                  )
                else if (onRetry == null || onSettings == null)
                  const SizedBox(height: 12),

                // Bouton d'annulation optionnel
                if (onRetry != null || onSettings != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour afficher une erreur en banner (plus léger)
class ErrorBanner extends StatelessWidget {
  final AppError error;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.color.withValues(alpha: 0.15),
        border: Border.all(color: error.color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(error.icon, color: error.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error.message,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: error.color,
                  ),
                ),
                if (error.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    error.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded),
              iconSize: 20,
              constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
