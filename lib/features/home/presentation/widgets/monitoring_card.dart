import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';

/// One attendance figure inside [MonitoringCard]
class MonitoringStat {
  final String value;
  final String label;

  const MonitoringStat(this.value, this.label);
}

/// Attendance summary card: title row, date, and the stat columns
class MonitoringCard extends StatelessWidget {
  final List<MonitoringStat> stats;
  final DateTime date;

  const MonitoringCard({super.key, required this.stats, required this.date});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      alignment: const Alignment(0, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.primaryVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              customText(l10n.monitoring, color: Colors.white),
              assetImg("assets/icon/scan.png", width: 25, height: 25),
            ],
          ),
          heightBx(h: 15),
          customText(
            DateFormat(
              'EEE, dd MMM yyyy',
              Localizations.localeOf(context).toString(),
            ).format(date),
            color: Colors.white,
            fontSize: 16,
          ),
          heightBx(h: 20),
          Row(children: _statsWithDividers()),
        ],
      ),
    );
  }

  /// Stat columns separated by a vertical rule, matching the original layout
  List<Widget> _statsWithDividers() {
    final children = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) children.add(const _StatDivider());
      children.add(_StatColumn(stat: stats[i]));
    }
    return children;
  }
}

class _StatColumn extends StatelessWidget {
  final MonitoringStat stat;

  const _StatColumn({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          customText(
            stat.value,
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
          customText(stat.label, color: Colors.white),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
    );
  }
}
