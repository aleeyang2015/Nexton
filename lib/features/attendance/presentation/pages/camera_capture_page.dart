import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/global_widgets.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../time_off/domain/entities/local_file.dart';
import '../providers/camera_capture_notifier.dart';

/// Full-screen camera for the time-correction form's "ຖ່າຍຮູບ" button: a live
/// preview with a shutter, then a review of the shot with "retake" / "use
/// photo". Pops with the accepted [LocalFile], or null when closed.
///
/// The camera itself lives in [cameraCaptureNotifierProvider]; this page only
/// shows it and remembers which shot is under review.
class CameraCapturePage extends ConsumerStatefulWidget {
  const CameraCapturePage({super.key});

  @override
  ConsumerState<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends ConsumerState<CameraCapturePage>
    with WidgetsBindingObserver {
  LocalFile? _shot;
  bool _taking = false;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The OS may take the camera away while the app is backgrounded, so it is
  /// reopened on return. Only a real pause counts — the permission prompt
  /// makes the app `inactive` too, and reopening then would re-prompt.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      ref.invalidate(cameraCaptureNotifierProvider);
    }
  }

  Future<void> _takePicture() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _taking = true);
    final shot = await ref
        .read(cameraCaptureNotifierProvider.notifier)
        .takePicture();
    if (!mounted) return;
    setState(() {
      _taking = false;
      _shot = shot;
    });
    if (shot == null) AppToast.error(l10n.cameraCaptureFailed);
  }

  @override
  Widget build(BuildContext context) {
    final camera = ref.watch(cameraCaptureNotifierProvider);
    final shot = _shot;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: shot != null
            ? _ReviewView(
                shot: shot,
                onRetake: () => setState(() => _shot = null),
                onUse: () => context.pop(shot),
              )
            : camera.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                error: (error, _) => _CameraMessage(
                  reason: error is CameraCaptureFailure
                      ? error.reason
                      : CameraCaptureError.failed,
                ),
                data: (controller) => _PreviewView(
                  controller: controller,
                  taking: _taking,
                  onShutter: _takePicture,
                ),
              ),
      ),
    );
  }
}

class _PreviewView extends StatelessWidget {
  final CameraController controller;
  final bool taking;
  final VoidCallback onShutter;

  const _PreviewView({
    required this.controller,
    required this.taking,
    required this.onShutter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _CloseRow(),
        Expanded(child: Center(child: CameraPreview(controller))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _ShutterButton(busy: taking, onTap: onShutter),
        ),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _ShutterButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: busy ? Colors.white54 : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _ReviewView extends StatelessWidget {
  final LocalFile shot;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  const _ReviewView({
    required this.shot,
    required this.onRetake,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Image.file(File(shot.path), fit: BoxFit.contain),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRetake,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.cameraRetake),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              widthBx(w: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUse,
                  icon: const Icon(Icons.check),
                  label: Text(l10n.cameraUsePhoto),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryVariant,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the preview when the camera can't open.
class _CameraMessage extends StatelessWidget {
  final CameraCaptureError reason;

  const _CameraMessage({required this.reason});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (reason) {
      CameraCaptureError.unavailable => l10n.cameraUnavailable,
      CameraCaptureError.permissionDenied => l10n.cameraPermissionDenied,
      CameraCaptureError.failed => l10n.cameraCaptureFailed,
    };

    return Column(
      children: [
        const _CloseRow(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Center(
              child: customText(
                message,
                fontSize: 16,
                color: Colors.white,
                maxLine: 4,
                alight: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CloseRow extends StatelessWidget {
  const _CloseRow();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(Icons.close, color: Colors.white, size: 28),
      ),
    );
  }
}
