import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';

/// Opens the PDF page of [payslipId] from a button, once: taps while that
/// page is open, or before it has opened, do nothing. So a double tap opens
/// one page, not two.
///
/// [builder] draws the button with the tap handler to give it.
class PayslipPdfOpener extends StatefulWidget {
  final String payslipId;
  final Widget Function(BuildContext context, VoidCallback open) builder;

  const PayslipPdfOpener({
    super.key,
    required this.payslipId,
    required this.builder,
  });

  @override
  State<PayslipPdfOpener> createState() => _PayslipPdfOpenerState();
}

class _PayslipPdfOpenerState extends State<PayslipPdfOpener> {
  bool _open = false;

  Future<void> _openPage() async {
    if (_open) return;
    _open = true;
    try {
      await context.push<void>(AppRoutes.payslipPdf(widget.payslipId));
    } finally {
      _open = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _openPage);
}
