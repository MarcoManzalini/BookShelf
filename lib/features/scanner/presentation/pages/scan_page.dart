import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/utils/l10n_extension.dart';
import '../cubit/isbn_scan_cubit.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/scan_result_panel.dart';

/// Full-screen camera that reads a book's ISBN barcode and finds the book.
class ScanPage extends StatelessWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<IsbnScanCubit>(),
      child: const ScanView(),
    );
  }
}

class ScanView extends StatefulWidget {
  const ScanView({super.key});

  @override
  State<ScanView> createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> {
  // Book barcodes are EAN-13; asking only for that makes detection faster.
  final _camera = MobileScannerController(formats: const [BarcodeFormat.ean13]);

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onStateChanged(BuildContext context, IsbnScanState state) {
    switch (state.status) {
      case ScanStatus.scanning:
        _camera.start();
      case ScanStatus.lookingUp:
        break;
      case ScanStatus.found:
        HapticFeedback.mediumImpact();
        _camera.stop();
      case ScanStatus.notFound:
      case ScanStatus.failure:
        _camera.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<IsbnScanCubit>();
    return BlocListener<IsbnScanCubit, IsbnScanState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: _onStateChanged,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _camera,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  cubit.onDetected(barcode.rawValue);
                }
              },
              errorBuilder: (context, error) => _CameraError(error: error),
            ),
            BlocSelector<IsbnScanCubit, IsbnScanState, bool>(
              selector: (state) => state.status == ScanStatus.scanning,
              builder: (context, scanning) => ScanOverlay(active: scanning),
            ),
            SafeArea(
              child: Column(
                children: [
                  _TopBar(camera: _camera, title: l10n.scanTitle),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: BlocBuilder<IsbnScanCubit, IsbnScanState>(
                      builder: (context, state) => ScanResultPanel(
                        state: state,
                        onRescan: cubit.rescan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.camera, required this.title});

  final MobileScannerController camera;
  final String title;

  @override
  Widget build(BuildContext context) {
    const white = IconThemeData(color: Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: IconTheme(
        data: white,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: camera,
              builder: (context, state, _) {
                final on = state.torchState == TorchState.on;
                return IconButton(
                  tooltip: context.l10n.scanTorch,
                  icon: Icon(
                    on ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: Colors.white,
                  ),
                  // Not every device (or the front camera) has a torch.
                  onPressed: state.torchState == TorchState.unavailable
                      ? null
                      : camera.toggleTorch,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.error});

  final MobileScannerException error;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final denied = error.errorCode == MobileScannerErrorCode.permissionDenied;
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                denied ? l10n.scanCameraDenied : l10n.scanCameraError,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
