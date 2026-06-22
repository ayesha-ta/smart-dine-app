import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'table_pin_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen>
    with SingleTickerProviderStateMixin {
  // 0 = scanning, 1 = detected
  int _scanStep = 0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color _primaryOrange = Color(0xFFF08A5D);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-advance from scanning to detected after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _scanStep = 1;
        });
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ───────────────────────── Header ─────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: _primaryOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Text(
            'Scan QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          const Text('⚡', style: TextStyle(fontSize: 22)),
        ],
      ),
    );
  }

  // ───────────────────────── Info Bar ────────────────────────
  Widget _buildInfoBar() {
    final bool isDetected = _scanStep == 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDetected ? const Color(0xFFE8F5E9) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDetected ? const Color(0xFF66BB6A) : const Color(0xFFE0E0E0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isDetected ? Icons.check_circle_rounded : Icons.camera_alt_rounded,
            color: isDetected ? const Color(0xFF43A047) : _primaryOrange,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isDetected
                  ? 'QR code detected successfully!!'
                  : 'Point your camera at the table QR Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDetected
                    ? const Color(0xFF2E7D32)
                    : const Color(0xFF424242),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── Scanner Viewfinder ─────────────────────
  Widget _buildScannerBox() {
    const double boxSize = 240;

    return SizedBox(
      width: boxSize,
      height: boxSize,
      child: Stack(
        children: [
          // Background
          Container(
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              color: _scanStep == 0
                  ? const Color(0xFFEEEEEE)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: _scanStep == 1
                ? const Center(
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF43A047),
                      size: 100,
                    ),
                  )
                : Center(
                    child: ScaleTransition(
                      scale: _pulseAnimation,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
          ),

          // Corner markers — top-left
          _buildCorner(Alignment.topLeft),
          // Corner markers — top-right
          _buildCorner(Alignment.topRight),
          // Corner markers — bottom-left
          _buildCorner(Alignment.bottomLeft),
          // Corner markers — bottom-right
          _buildCorner(Alignment.bottomRight),
        ],
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    final Color cornerColor =
        _scanStep == 1 ? const Color(0xFF43A047) : _primaryOrange;

    const double length = 36;
    const double thickness = 4.5;
    const double radius = 20;

    // Determine border radii & positioning
    BorderRadius borderRadius;
    if (alignment == Alignment.topLeft) {
      borderRadius = const BorderRadius.only(topLeft: Radius.circular(radius));
    } else if (alignment == Alignment.topRight) {
      borderRadius = const BorderRadius.only(topRight: Radius.circular(radius));
    } else if (alignment == Alignment.bottomLeft) {
      borderRadius =
          const BorderRadius.only(bottomLeft: Radius.circular(radius));
    } else {
      borderRadius =
          const BorderRadius.only(bottomRight: Radius.circular(radius));
    }

    return Align(
      alignment: alignment,
      child: SizedBox(
        width: length,
        height: length,
        child: CustomPaint(
          painter: _CornerPainter(
            color: cornerColor,
            strokeWidth: thickness,
            alignment: alignment,
            radius: radius,
          ),
        ),
      ),
    );
  }

  // ───────────── Scanning Chip / Status Pill ────────────────
  Widget _buildStatusPill() {
    if (_scanStep != 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: _primaryOrange,
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('⏳', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Text(
            'Scanning...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ────────────── Table Info Card (Step 2) ───────────────────
  Widget _buildTableInfoCard() {
    if (_scanStep != 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: const Column(
        children: [
          Text(
            'You are seated at',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Table 4',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF212121),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Spice Garden',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF9E9E9E),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── Enter PIN Button (Step 2) ──────────────────
  Widget _buildEnterPinButton() {
    if (_scanStep != 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {
            Provider.of<UserProvider>(context, listen: false)
                .setTableData('Table 4');
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TablePinScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryOrange,
            foregroundColor: Colors.white,
            elevation: 4,
            shadowColor: _primaryOrange.withOpacity(0.45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Enter PIN',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────── Bottom Hints (Step 1) ───────────────────────
  Widget _buildBottomHints() {
    if (_scanStep != 0) return const SizedBox.shrink();

    return const Column(
      children: [
        SizedBox(height: 28),
        Text(
          'Find QR Code sticker on your Table',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF616161),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Hold Your Phone steady to scan !!!',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }

  // ═════════════════════ BUILD ══════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Orange Header
            _buildHeader(),

            // Info / success bar
            _buildInfoBar(),

            const Spacer(),

            // Scanner viewfinder
            _buildScannerBox(),

            // Status pill (step 0) or nothing (step 1)
            _buildStatusPill(),

            // Table info card (step 1 only)
            _buildTableInfoCard(),

            // Enter PIN button (step 1 only)
            _buildEnterPinButton(),

            // Bottom hints (step 0 only)
            _buildBottomHints(),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════ Corner Painter ═════════════════════════
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final Alignment alignment;
  final double radius;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.alignment,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (alignment == Alignment.topLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, radius);
      path.quadraticBezierTo(0, 0, radius, 0);
      path.lineTo(size.width, 0);
    } else if (alignment == Alignment.topRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width - radius, 0);
      path.quadraticBezierTo(size.width, 0, size.width, radius);
      path.lineTo(size.width, size.height);
    } else if (alignment == Alignment.bottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height - radius);
      path.quadraticBezierTo(0, size.height, radius, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height - radius);
      path.quadraticBezierTo(
          size.width, size.height, size.width - radius, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.color != color;
}
