import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/leave_type.dart';
import '../providers/leave_types_notifier.dart';
import '../widgets/leave_copy.dart';

/// What the route accepts as `extra`: the id to tick, and whether to offer an
/// "All" row that clears the selection (the history filter wants it, the
/// request form does not).
typedef LeaveTypePickerArgs = ({String? selectedTypeId, bool allowClear});

/// Full-screen leave-type chooser opened from the request form's "Leave type"
/// card and the history tab's filter. Renders the session-cached
/// `GET /leave/types` list ([leaveTypesNotifierProvider]) with a client-side
/// search box, and pops with the chosen [LeaveType.id] — or an empty string
/// from the "All" row when [allowClear] is set. Backing out pops with nothing
/// and leaves the caller's current selection untouched.
///
/// The filtering here is pure presentation — trimming an already-loaded list —
/// so it stays in the page rather than the notifier.
class LeaveTypePickerPage extends ConsumerStatefulWidget {
  const LeaveTypePickerPage({
    super.key,
    this.selectedTypeId,
    this.allowClear = false,
  });

  /// The type currently chosen by the caller, ticked in the list. `null` when
  /// nothing is selected yet.
  final String? selectedTypeId;

  /// When true, an "All" row sits above the list and pops with `''`.
  final bool allowClear;

  @override
  ConsumerState<LeaveTypePickerPage> createState() =>
      _LeaveTypePickerPageState();
}

class _LeaveTypePickerPageState extends ConsumerState<LeaveTypePickerPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Case-insensitive match on the display name, the Lao name and the code, so
  /// search works whichever language the list is shown in.
  List<LeaveType> _filter(List<LeaveType> types) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return types;
    return [
      for (final type in types)
        if (type.name.toLowerCase().contains(q) ||
            (type.nameLo ?? '').toLowerCase().contains(q) ||
            type.code.toLowerCase().contains(q))
          type,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typesAsync = ref.watch(leaveTypesNotifierProvider);

    return Container(
      color: Colors.white,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            leading: GestureDetector(
              onTap: () => context.pop(),
              child: const Padding(
                padding: EdgeInsets.only(left: 10),
                child: Icon(Icons.arrow_back_ios, color: AppColors.primary),
              ),
            ),
            title: customText(
              l10n.leaveTypePickerTitle,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              fontSize: 20,
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 12, 15, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: inputDecoration(l10n.leaveTypeSearchHint).copyWith(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.subTitle,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: typesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Center(
                    child: customText(
                      l10n.leaveTypeLoadFailed,
                      color: AppColors.subTitle,
                      fontSize: 13,
                    ),
                  ),
                  data: (types) {
                    final filtered = _filter(types);
                    if (filtered.isEmpty && !widget.allowClear) {
                      return Center(
                        child: customText(
                          l10n.leaveTypeSearchEmpty,
                          color: AppColors.subTitle,
                          fontSize: 13,
                        ),
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(15, 4, 15, 24),
                      children: [
                        if (widget.allowClear) ...[
                          _LeaveTypeRow(
                            label: l10n.leaveFilterAll,
                            selected: widget.selectedTypeId == null,
                            onTap: () => context.pop(''),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                        ],
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: customText(
                              l10n.leaveTypeSearchEmpty,
                              color: AppColors.subTitle,
                              fontSize: 13,
                              alight: TextAlign.center,
                            ),
                          )
                        else
                          for (var i = 0; i < filtered.length; i++) ...[
                            if (i > 0)
                              const Divider(
                                height: 1,
                                color: AppColors.border,
                              ),
                            _LeaveTypeRow(
                              label: LeaveCopy.leaveTypeLabel(l10n, filtered[i]),
                              selected: filtered[i].id == widget.selectedTypeId,
                              onTap: () => context.pop(filtered[i].id),
                            ),
                          ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveTypeRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LeaveTypeRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: customText(
                label,
                fontSize: 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
