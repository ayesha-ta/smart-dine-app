import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'menu_screen.dart';
import 'dart:async';

class TablePinScreen extends StatefulWidget {
  const TablePinScreen({super.key});

  @override
  State<TablePinScreen> createState() => _TablePinScreenState();
}

class _TablePinScreenState extends State<TablePinScreen> {
  static const Color _primaryOrange = Color(0xFFF08A5D);
  static const String _correctPin = '1234';
  static const int _maxAttempts = 3;
  static const int _lockoutSeconds = 55;

  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  int _attemptCount = 0;
  bool _showError = false;
  bool _isLockedOut = false;
  int _remainingSeconds = _lockoutSeconds;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    for (final c in _pinControllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _lockoutTimer?.cancel();
    super.dispose();
  }

  String get _currentPin =>
      _pinControllers.map((c) => c.text).join();

  void _onPinDigitChanged(int index, String value) {
    if (value.length == 1 && index < 3) {
      _focusNodes[index + 1].requestFocus();
    }

    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when all 4 digits entered
    if (_currentPin.length == 4) {
      _verifyPin();
    }
  }

  void _verifyPin() {
    final pin = _currentPin;
    if (pin.length != 4) return;

    if (pin == _correctPin) {
      // Success
      Provider.of<UserProvider>(context, listen: false).verifyPin(pin);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } else {
      // Wrong PIN
      _attemptCount++;
      if (_attemptCount >= _maxAttempts) {
        _startLockout();
      } else {
        setState(() {
          _showError = true;
        });
        _clearPinFields();
      }
    }
  }

  void _clearPinFields() {
    for (final c in _pinControllers) {
      c.clear();
    }
    if (mounted) {
      _focusNodes[0].requestFocus();
    }
  }

  void _startLockout() {
    setState(() {
      _isLockedOut = true;
      _remainingSeconds = _lockoutSeconds;
      _showError = false;
    });
    _clearPinFields();

    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _isLockedOut = false;
          _attemptCount = 0;
          _remainingSeconds = _lockoutSeconds;
        });
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '$minutes : ${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tableNumber =
        Provider.of<UserProvider>(context).tableNumber;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(tableNumber),
            Expanded(
              child: _isLockedOut
                  ? _buildLockoutBody()
                  : _buildNormalBody(),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  HEADER
  // ──────────────────────────────────────────────
  Widget _buildHeader(dynamic tableNumber) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _primaryOrange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Smart Dine',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Spice Garden • Table $tableNumber',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  NORMAL / ERROR BODY
  // ──────────────────────────────────────────────
  Widget _buildNormalBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        children: [
          // Padlock icon in peach box
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3EE),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: const Text(
              '🔒',
              style: TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Text(
            'Enter Table PIN',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Ask your waiter for the 4-digit PIN',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Error warning box
          if (_showError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _primaryOrange.withOpacity(0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: _primaryOrange,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Incorrect PIN. Please try again. (Attempt $_attemptCount/$_maxAttempts)',
                      style: const TextStyle(
                        color: _primaryOrange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // PIN input boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              return Container(
                width: 60,
                height: 60,
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 10,
                  right: index == 3 ? 0 : 10,
                ),
                child: TextField(
                  controller: _pinControllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  obscureText: true,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _showError
                            ? Colors.red
                            : Colors.grey.shade300,
                        width: _showError ? 1.8 : 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: _showError ? Colors.red : _primaryOrange,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) =>
                      _onPinDigitChanged(index, value),
                ),
              );
            }),
          ),
          const SizedBox(height: 32),

          // Unlock Menu button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _verifyPin,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
                textStyle: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              child: const Text('Unlock Menu'),
            ),
          ),
          const SizedBox(height: 24),

          // Help text
          Text(
            "Don't have a PIN? Ask Restaurant Staff",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  LOCKOUT BODY
  // ──────────────────────────────────────────────
  Widget _buildLockoutBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Padlock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3EE),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_outline_rounded,
                color: _primaryOrange,
                size: 42,
              ),
            ),
            const SizedBox(height: 24),

            // Title
            const Text(
              'Too many Attempts',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            const Text(
              'Please wait before trying again',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 32),

            // Countdown timer box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _primaryOrange.withOpacity(0.85),
                    _primaryOrange,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _primaryOrange.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'seconds remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // Help text
            const Text(
              'Contact your waiter if you need help',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
