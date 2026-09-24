import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> orderedItems;
  final Map<String, int> itemQuantities;
  const PaymentScreen({
    super.key,
    required this.totalAmount,
    required this.orderedItems,
    required this.itemQuantities,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  static const _orange = Color(0xFFF08A5D);

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isProcessing = false;

  // Success overlay state
  bool _showSuccess = false;
  int _coinsEarned = 0;
  late AnimationController _scaleCtrl;
  late AnimationController _fadeCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _scaleAnim = CurvedAnimation(parent: _scaleCtrl, curve: Curves.elasticOut);
    _fadeAnim  = CurvedAnimation(parent: _fadeCtrl,  curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _fadeCtrl.dispose();
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Validation ───────────────────────────────────────────────────────────
  bool _validate() {
    final card = _cardNumberCtrl.text.replaceAll(' ', '');
    if (card.length < 16) {
      _snack('Enter a valid 16-digit card number');
      return false;
    }
    if (_expiryCtrl.text.length < 5) {
      _snack('Enter a valid expiry date (MM/YY)');
      return false;
    }
    if (_cvvCtrl.text.length < 3) {
      _snack('Enter a valid 3-digit CVV');
      return false;
    }
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Enter the cardholder name');
      return false;
    }
    return true;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Payment Processing ───────────────────────────────────────────────────
  Future<void> _processPayment() async {
    if (!_validate()) return;
    setState(() => _isProcessing = true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Place the order & deduct inventory
    userProvider.placeOrderWithInventory(
      userProvider.tableNumber,
      widget.totalAmount,
      widget.itemQuantities,
    );

    // Calculate & award coins
    int earned = 0;
    if (userProvider.isRegisteredUser) {
      // +50 for every online payment
      userProvider.addCoins(50, 'Online Payment Bonus', 'Paid via Card');
      earned += 50;

      // +100 Big Spender bonus if order > PKR 2000
      if (widget.totalAmount > 2000) {
        userProvider.addCoins(100, 'Big Spender Bonus', 'Order over PKR 2,000');
        earned += 100;
      }
    }

    // Clear cart
    Provider.of<CartProvider>(context, listen: false).clear();

    setState(() {
      _isProcessing = false;
      _coinsEarned = earned;
      _showSuccess = true;
    });

    // Animate success overlay in
    _fadeCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _scaleCtrl.forward();
  }

  // ─── Navigate to tracking ─────────────────────────────────────────────────
  void _goToTracking() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderTrackingScreen(
          orderedItems: widget.orderedItems,
          coinsEarned: _coinsEarned,
        ),
      ),
      (r) => false,
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Secure Payment',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── Payment Form ──
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF08A5D), Color(0xFFE07040)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Amount',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(
                        'PKR ${widget.totalAmount.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Coins preview badge
                      Builder(builder: (ctx) {
                        final user = Provider.of<UserProvider>(ctx, listen: false);
                        if (!user.isRegisteredUser) return const SizedBox.shrink();
                        int preview = 50;
                        if (widget.totalAmount > 2000) preview += 100;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '🪙 You will earn +$preview loyalty coins',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const Text('Card Details',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),

                // Card Number
                _label('Card Number'),
                _field(
                  controller: _cardNumberCtrl,
                  hint: '4242  4242  4242  4242',
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  maxLength: 19,
                  onChanged: (v) {
                    // Auto-format with spaces
                    final digits = v.replaceAll(' ', '');
                    final formatted = StringBuffer();
                    for (int i = 0; i < digits.length && i < 16; i++) {
                      if (i > 0 && i % 4 == 0) formatted.write(' ');
                      formatted.write(digits[i]);
                    }
                    final newVal = formatted.toString();
                    if (newVal != v) {
                      _cardNumberCtrl.value = TextEditingValue(
                        text: newVal,
                        selection:
                            TextSelection.collapsed(offset: newVal.length),
                      );
                    }
                  },
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Expiry Date'),
                          _field(
                            controller: _expiryCtrl,
                            hint: 'MM/YY',
                            icon: Icons.calendar_today,
                            keyboardType: TextInputType.number,
                            maxLength: 5,
                            onChanged: (v) {
                              if (v.length == 2 && !v.contains('/')) {
                                _expiryCtrl.text = '$v/';
                                _expiryCtrl.selection =
                                    TextSelection.collapsed(
                                        offset: _expiryCtrl.text.length);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('CVV'),
                          _field(
                            controller: _cvvCtrl,
                            hint: '•••',
                            icon: Icons.lock_outline,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                _label('Cardholder Name'),
                _field(
                  controller: _nameCtrl,
                  hint: 'Name on card',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),

                const SizedBox(height: 10),
                // Security badge
                Row(
                  children: [
                    Icon(Icons.lock, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    Text('256-bit SSL Encrypted · Powered by Stripe',
                        style: TextStyle(
                            color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),

                const SizedBox(height: 28),
                // Pay button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      disabledBackgroundColor: _orange.withValues(alpha: 0.6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isProcessing
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Processing Payment...',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Text(
                            'Pay PKR ${widget.totalAmount.toInt()}',
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel and go back to Checkout',
                        style: TextStyle(color: Colors.grey, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Success Overlay ──
          if (_showSuccess)
            FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: _buildSuccessCard(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Success Card ─────────────────────────────────────────────────────────
  Widget _buildSuccessCard() {
    final hasCoins = _coinsEarned > 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Green checkmark circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green.shade200, width: 2),
            ),
            child: Icon(Icons.check_circle_rounded,
                color: Colors.green.shade500, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Payment Successful!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            'PKR ${widget.totalAmount.toInt()} paid via Card',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // Coins breakdown (only if logged in and coins earned)
          if (hasCoins) ...[
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade50, Colors.orange.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🪙',
                          style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Loyalty Coins Earned!',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87)),
                            const SizedBox(height: 4),
                            if (widget.totalAmount > 2000) ...[
                              _coinRow('+50', 'Online Payment Bonus'),
                              _coinRow('+100', 'Big Spender Bonus (>PKR 2,000)'),
                            ] else
                              _coinRow('+50', 'Online Payment Bonus'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Coins Earned',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$_coinsEarned coins',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '= PKR ${(_coinsEarned * 0.5).toStringAsFixed(0)} redeemable value',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // No coins message for guests
          if (!hasCoins) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Register an account to earn loyalty coins on every order!',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Track Order button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _goToTracking,
              icon: const Icon(Icons.track_changes_rounded),
              label: const Text('Track My Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _coinRow(String amount, String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Text(amount,
              style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          const SizedBox(width: 6),
          Text(label,
              style:
                  TextStyle(color: Colors.grey.shade700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style:
                const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    void Function(String)? onChanged,
  }) =>
      TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: _orange, size: 20),
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orange, width: 1.5),
          ),
        ),
      );
}
