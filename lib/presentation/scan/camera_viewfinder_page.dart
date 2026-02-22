import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'scan_camera_page.dart';

/// Custom camera screen with a smooth square viewfinder overlay.
/// Captured image is sent to [ScanCameraPage] for analysis.
class CameraViewfinderPage extends StatefulWidget {
  const CameraViewfinderPage({Key? key}) : super(key: key);

  @override
  State<CameraViewfinderPage> createState() => _CameraViewfinderPageState();
}

class _CameraViewfinderPageState extends State<CameraViewfinderPage> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found';
        });
        return;
      }
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Camera error: $e';
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _captureAndContinue() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      final String path = file.path;
      if (path.isEmpty) {
        setState(() => _isCapturing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save photo')),
          );
        }
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ScanCameraPage(imagePath: path),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              )
            else if (!_isInitialized || _controller == null)
              const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              )
            else
              _buildCameraWithOverlay(),
            // App bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const Expanded(
                        child: Text(
                          'Position food in frame',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraWithOverlay() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera preview
        FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.previewSize?.height ?? 1,
            height: _controller!.value.previewSize?.width ?? 1,
            child: CameraPreview(_controller!),
          ),
        ),
        // Smooth square viewfinder overlay (darkened area with rounded square cutout)
        LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.maxWidth < constraints.maxHeight
                ? constraints.maxWidth * 0.85
                : constraints.maxHeight * 0.85;
            final left = (constraints.maxWidth - side) / 2;
            final top = (constraints.maxHeight - side) / 2;
            return CustomPaint(
              painter: _ViewfinderOverlayPainter(
                viewfinderRect: RRect.fromRectAndRadius(
                  Rect.fromLTWH(left, top, side, side),
                  const Radius.circular(24),
                ),
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            );
          },
        ),
        // Capture button at bottom
        Positioned(
          left: 0,
          right: 0,
          bottom: MediaQuery.of(context).padding.bottom + 32,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isCapturing ? null : _captureAndContinue,
                customBorder: const CircleBorder(),
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    color: _isCapturing
                        ? Colors.white24
                        : Colors.white.withOpacity(0.2),
                  ),
                  child: _isCapturing
                      ? const Padding(
                          padding: EdgeInsets.all(22),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.camera_alt, color: Colors.white, size: 36),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a semi-transparent overlay with a smooth rounded-square "hole" (viewfinder).
class _ViewfinderOverlayPainter extends CustomPainter {
  final RRect viewfinderRect;

  _ViewfinderOverlayPainter({required this.viewfinderRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()..addRRect(viewfinderRect);
    final combined = Path.combine(PathOperation.difference, path, hole);
    canvas.drawPath(combined, overlay);

    // Optional: thin border around viewfinder for clarity
    final border = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(viewfinderRect, border);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderOverlayPainter oldDelegate) {
    return oldDelegate.viewfinderRect != viewfinderRect;
  }
}
