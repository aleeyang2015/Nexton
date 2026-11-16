import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure.dart';
import '../../../../core/l10n/failure_localizer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/datasources/punch_location_source.dart';
import '../../domain/entities/offsite_method.dart';
import 'offsite_copy.dart';

BoxDecoration _tintBox() => BoxDecoration(
  color: AppColors.primaryTint,
  borderRadius: BorderRadius.circular(12),
);

/// Which punch the scan stands in for: clock-in or clock-out, side by side.
class OffsiteMethodSelector extends StatelessWidget {
  final OffsiteMethod selected;
  final ValueChanged<OffsiteMethod> onSelect;

  const OffsiteMethodSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final method in OffsiteMethod.values) ...[
          if (method != OffsiteMethod.values.first) widthBx(w: 8),
          Expanded(
            child: _MethodButton(
              method: method,
              selected: method == selected,
              onTap: () => onSelect(method),
            ),
          ),
        ],
      ],
    );
  }
}

class _MethodButton extends StatelessWidget {
  final OffsiteMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = selected ? Colors.white : AppColors.textPrimary;

    return Material(
      color: selected ? AppColors.primaryVariant : AppColors.primaryTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(OffsiteCopy.methodIcon(method), size: 18, color: color),
              widthBx(w: 6),
              Flexible(
                child: customText(
                  OffsiteCopy.methodLabel(l10n, method),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Where the scan is being filed from: the fix while it is being read, the
/// coordinates once it lands, or why there isn't one — with a retry, since
/// every reason the source gives (services off, permission denied, no fix in
/// time) is something the user can go and change.
class OffsiteLocationCard extends StatelessWidget {
  final AsyncValue<PunchLocationReading> location;
  final VoidCallback onRetry;

  const OffsiteLocationCard({
    super.key,
    required this.location,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // A retry after a failed read is still an [AsyncLoading] carrying the old
    // error; while it runs the card reads as "working", not as "broken".
    final failure = location.isLoading ? null : location.error;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _tintBox(),
      child: Row(
        children: [
          _Badge(loading: location.isLoading, failed: failure != null),
          widthBx(w: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                customText(
                  _title(l10n, failure),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: failure == null
                      ? AppColors.textPrimary
                      : AppColors.danger,
                  maxLine: 3,
                ),
                heightBx(h: 2),
                customText(
                  _subtitle(l10n),
                  fontSize: 13,
                  color: AppColors.secondaryTxt,
                ),
              ],
            ),
          ),
          if (!location.isLoading) ...[
            widthBx(w: 8),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onRetry,
                borderRadius: BorderRadius.circular(10),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.refresh, color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The coordinates, the reason there are none, or the "reading…" line.
  String _title(AppLocalizations l10n, Object? failure) {
    if (location.isLoading) return l10n.offsiteLocating;
    if (failure != null) {
      return failure is Failure
          ? failure.localize(l10n)
          : l10n.locationUnavailable;
    }
    return OffsiteCopy.coordinates(location.valueOrNull) ??
        l10n.locationUnavailable;
  }

  /// How good the fix is, falling back to naming the field — the title already
  /// says what is going on, so this never repeats it.
  String _subtitle(AppLocalizations l10n) =>
      OffsiteCopy.accuracy(l10n, location.valueOrNull) ??
      l10n.offsiteLocationLabel;
}

class _Badge extends StatelessWidget {
  final bool loading;
  final bool failed;

  const _Badge({required this.loading, required this.failed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: (failed ? AppColors.danger : AppColors.primary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: loading
          ? const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryVariant,
              ),
            )
          : Icon(
              failed ? Icons.location_disabled : Icons.my_location,
              color: failed ? AppColors.danger : AppColors.primaryVariant,
            ),
    );
  }
}
