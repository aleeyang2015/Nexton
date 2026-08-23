import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/generated/app_localizations.dart';

/// 404 Not Found Page
class NotFoundPage extends StatelessWidget {
  final Exception? error;

  const NotFoundPage({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pageNotFoundTitle),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pageNotFoundHeading,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.pageNotFoundMessage,
              textAlign: TextAlign.center,
            ),
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(
                l10n.errorDetailsLabel(error.toString()),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text(l10n.goHome),
            ),
          ],
        ),
      ),
    );
  }
}