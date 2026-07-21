# Flutter Project Rules

## Architecture

- Feature First
- Clean Architecture

Every feature contains

- presentation
- domain
- data

## State Management

Riverpod only

Use Notifier/AsyncNotifier

## Navigation

GoRouter

## Networking

Dio

## Rules

- Don't change architecture without approval.
- Don't introduce new packages unless requested.
- Reuse existing code whenever possible.
- Keep widgets small.
- No business logic inside widgets.
- Repository returns Result<T>.
- Always explain architectural decisions.
- Implement only the requested task.