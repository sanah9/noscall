import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanPage extends StatefulWidget {
  const QRScanPage({super.key});

  @override
  State<QRScanPage> createState() => _QRScanPageState();
}

class _QRScanPageState extends State<QRScanPage> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
  );

  bool _hasScanned = false;

  late ThemeData theme;
  ColorScheme get colorScheme => theme.colorScheme;
  Color get surface => theme.colorScheme.surface;
  Color get onSurface => theme.colorScheme.onSurface;
  Color get primary => theme.colorScheme.primary;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);
    return Scaffold(
      appBar: _buildAppBar(context),
      extendBodyBehindAppBar: true,
      body: _buildScannerView(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Scan QR Code'),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildScannerView(BuildContext context) {
    return Stack(
      children: [
        // Camera scanner
        MobileScanner(
          controller: _controller,
          onDetect: _onQRCodeDetected,
        ),
        // Overlay with scanning frame
        Positioned.fill(
          child: _buildOverlay(context),
        ),
        // Instructions
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
    if (barcode.rawValue == null) return;

    _hasScanned = true;

    // Return the scanned value to previous page
    context.pop(barcode.rawValue);
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
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2, size.height / 2),
            width: scanArea,
            height: scanArea,
          ),
          const Radius.circular(16),
        ),
      );

    final cutout = Path.combine(
      PathOperation.difference,
      path,
      scanRect,
    );

    canvas.drawPath(cutout, paint);

    // Draw corner indicators
    final cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final topLeft = Offset(
      (size.width - scanArea) / 2,
      (size.height - scanArea) / 2,
    );

    // Top-left corner
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

    // Top-right corner
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

    // Bottom-left corner
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

    // Bottom-right corner
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