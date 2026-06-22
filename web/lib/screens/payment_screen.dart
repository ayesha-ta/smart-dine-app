import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'order_tracking_screen.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final List<Map<String, dynamic>> orderedItems;
  const PaymentScreen({super.key, required this.totalAmount, required this.orderedItems});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _showFailure = false;

  bool _hasFailedOnce = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (!_hasFailedOnce) {
      setState(() {
        _isProcessing = false;
        _showFailure = true;
        _hasFailedOnce = true;
      });
      return;
    }

    setState(() { _isProcessing = false; _showFailure = false; });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      userProvider.addCoins(50, 'Online Payment', 'Stripe Transaction');
      if (widget.totalAmount > 2000) {
        userProvider.addCoins(100, 'Big Spender Bonus', 'Order over PKR 2000');
      }
    }
    Provider.of<CartProvider>(context, listen: false).clear();
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderedItems: widget.orderedItems)), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showFailure) return _buildFailureScreen();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text('PKR ${widget.totalAmount.toInt()}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                  const Text('Table - 4', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text('Card Number', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: '4242   4242   4242   4242',
                hintStyle: const TextStyle(letterSpacing: 1.5, color: Colors.black87),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Expiry', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'MM/YY',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CVV', style: TextStyle(color: Colors.grey, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: '•••',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Cardholder Name', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                hintText: 'Name on card',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
            ),
            const Spacer(),
            _isProcessing
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFF08A5D)))
                : SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _processPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF08A5D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Pay PKR ${widget.totalAmount.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel and return to Checkout', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(color: Color(0xFFFBE9E7), shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.black87, size: 40),
              ),
              const SizedBox(height: 24),
              const Text('Payment Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Your card was declined by the Bank', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              const Text('Error: Insufficient balance!!!', style: TextStyle(color: Color(0xFFF08A5D))),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => setState(() => _showFailure = false),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF08A5D), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50), side: const BorderSide(color: Color(0xFFF08A5D)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Switch to Cash on Table', style: TextStyle(color: Color(0xFFF08A5D), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text('Need help? Contact your waiter', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
