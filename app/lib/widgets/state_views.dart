import 'package:material_ui/material_ui.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/palette.dart';

/// Shared empty / loading / error states so every page shows them the same way.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
  });

  final IconData icon;
  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final palette = Palette.of(context);
    final text = Theme.of(context).textTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: palette.secondaryText),
            const SizedBox(height: 12),
            Text(title, style: text.titleMedium, textAlign: TextAlign.center),
            if (body case final body?) ...[
              const SizedBox(height: 8),
              Text(
                body,
                style: text.bodyMedium?.copyWith(color: palette.secondaryText),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      label: AppLocalizations.of(context).stateLoading,
      child: const CircularProgressIndicator(),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, this.title, this.message, this.onRetry});

  /// Defaults to a generic "something went wrong".
  final String? title;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final palette = Palette.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 40, color: palette.error),
            const SizedBox(height: 12),
            Text(
              title ?? l10n.stateErrorTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message case final message?) ...[
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: Text(l10n.actionRetry)),
            ],
          ],
        ),
      ),
    );
  }
}
