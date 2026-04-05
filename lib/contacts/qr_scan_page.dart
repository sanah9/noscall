import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:noscall/core/navigation/app_navigator_scope.dart';
import 'package:noscall/utils/snackbar_helper.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  MobileScannerController? _controller;
  final TextEditingController _manualController = TextEditingController();

  bool _hasScanned = false;

  late ThemeData theme;
  Color get onSurface => theme.colorScheme.onSurface;

  /// [mobile_scanner] only registers iOS, Android, and macOS native targets.
  bool get _supportsMobileScanner {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    if (_supportsMobileScanner) {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        facing: CameraFacing.back,
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(context),
      extendBodyBehindAppBar: _supportsMobileScanner,
      body: _supportsMobileScanner
          ? _buildScannerView(context)
          : _buildManualEntry(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_supportsMobileScanner) {
      return AppBar(
        title: const Text('Scan QR Code'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppNavigatorScope.requireOf(context).pop(context),
        ),
      );
    }
    return AppBar(
      title: const Text('Enter QR / npub'),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => AppNavigatorScope.requireOf(context).pop(context),
      ),
    );
  }

  Widget _buildManualEntry(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Camera scanning is not available on this platform. Paste an nprofile, npub, or other scanned text below.',
              style: theme.textTheme.bodyMedium?.copyWith(color: onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _manualController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'nprofile1… or npub1…',
              ),
              minLines: 2,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitManual(context),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _submitManual(context),
              child: const Text('Use text'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitManual(BuildContext context) {
    final trimmed = _manualController.text.trim();
    if (trimmed.isEmpty) {
      AppSnackBar.warning(context, 'Please enter a value.');
      return;
    }
    context.pop<String>(trimmed);
  }

  Widget _buildScannerView(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }
    return Stack(
      children: [
        MobileScanner(
          controller: controller,
          onDetect: _onQRCodeDetected,
        ),
        Positioned.fill(
          child: _buildOverlay(context),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: SafeArea(child: _buildInstructions(context)),
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    const scanArea = 250.0;
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        scanArea: scanArea,
        cornerLength: 20,
        cornerWidth: 4,
        cornerColor: Colors.white,
      ),
    );
  }

  Widget _buildInstructions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        'Position the QR code within the frame',
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }

  void _onQRCodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final raw = barcode.rawValue;
    if (raw == null || raw.isEmpty) return;

    _hasScanned = true;
    context.pop<String>(raw);
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final double scanArea;
  final double cornerLength;
  final double cornerWidth;
  final Color cornerColor;

  _ScannerOverlayPainter({
    required this.scanArea,
    required this.cornerLength,
    required this.cornerWidth,
    required this.cornerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final scanRect = Path()
      ..addRRect(
        RRect.fromRectAndCorners(Rect.fromCenter(
          center: Offset(size.width / 2, size.height / 2),
          width: scanArea,
          height: scanArea,
        )),
      );

    final cutout = Path.combine(
      PathOperation.difference,
      path,
      scanRect,
    );

    canvas.drawPath(cutout, paint);

    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final topLeft = Offset(
      (size.width - scanArea) / 2,
      (size.height - scanArea) / 2,
    );

    canvas.drawLine(
      topLeft,
      Offset(topLeft.dx + cornerLength, topLeft.dy),
      cornerPaint,
    );
    canvas.drawLine(
      topLeft,
      Offset(topLeft.dx, topLeft.dy + cornerLength),
      cornerPaint,
    );

    final topRight = Offset(
      (size.width + scanArea) / 2,
      (size.height - scanArea) / 2,
    );
    canvas.drawLine(
      topRight,
      Offset(topRight.dx - cornerLength, topRight.dy),
      cornerPaint,
    );
    canvas.drawLine(
      topRight,
      Offset(topRight.dx, topRight.dy + cornerLength),
      cornerPaint,
    );

    final bottomLeft = Offset(
      (size.width - scanArea) / 2,
      (size.height + scanArea) / 2,
    );
    canvas.drawLine(
      bottomLeft,
      Offset(bottomLeft.dx + cornerLength, bottomLeft.dy),
      cornerPaint,
    );
    canvas.drawLine(
      bottomLeft,
      Offset(bottomLeft.dx, bottomLeft.dy - cornerLength),
      cornerPaint,
    );

    final bottomRight = Offset(
      (size.width + scanArea) / 2,
      (size.height + scanArea) / 2,
    );
    canvas.drawLine(
      bottomRight,
      Offset(bottomRight.dx - cornerLength, bottomRight.dy),
      cornerPaint,
    );
    canvas.drawLine(
      bottomRight,
      Offset(bottomRight.dx, bottomRight.dy - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
