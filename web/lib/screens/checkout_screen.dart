import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';
import 'payment_screen.dart';
import 'order_tracking_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String _paymentMethod = 'Cash on Table';
  bool _useLoyaltyCoins = false;

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final user = Provider.of<UserProvider>(context);
    final subtotal = cart.totalAmount;
    final tax = subtotal * 0.05;
    double total = subtotal + tax;

    if (_useLoyaltyCoins && user.isLoggedIn) {
      total = (total - user.loyaltyCoins).clamp(0, double.infinity);
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${cart.itemCount} items', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFFF08A5D),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
              child: const Text('Table 4', style: TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),

                  // Cash option
                  _paymentTile(
                    icon: Icons.attach_money,
                    title: 'Cash on Table',
                    subtitle: 'Pay when served',
                    value: 'Cash on Table',
                  ),
                  const SizedBox(height: 10),
                  // Online option
                  _paymentTile(
                    icon: Icons.credit_card,
                    title: 'Online Payment',
                    subtitle: 'Visa, Mastercard via Stripe',
                    value: 'Online Payment',
                    highlight: true,
                  ),

                  const SizedBox(height: 20),

                  // Loyalty Coins
                  if (user.isLoggedIn)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Loyalty Coins', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                  'Balance: ${user.loyaltyCoins} coins = PKR ${user.loyaltyCoins}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text('Redeem', style: TextStyle(color: const Color(0xFFF08A5D), fontSize: 13, fontWeight: FontWeight.bold)),
                              Checkbox(
                                value: _useLoyaltyCoins,
                                activeColor: const Color(0xFFF08A5D),
                                onChanged: (val) => setState(() => _useLoyaltyCoins = val ?? false),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 12),
                  _summaryRow('Subtotal', 'PKR ${subtotal.toInt()}'),
                  const SizedBox(height: 8),
                  _summaryRow('Tax (5%)', 'PKR ${tax.toInt()}'),
                  if (_useLoyaltyCoins && user.isLoggedIn) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Coins Discount', '- PKR ${user.loyaltyCoins}', accent: true),
                  ],
                  const Divider(height: 24),
                  _summaryRow('Total', 'PKR ${total.toInt()}', bold: true),
                ],
              ),
            ),
          ),

          // Bottom CTA
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final orderedItems = cart.items.values.map((item) => {
                    'name': '${item.menuItem.name} x ${item.quantity}',
                    'status': 'Pending'
                  }).toList();

                  if (_paymentMethod == 'Online Payment') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentScreen(totalAmount: total, orderedItems: orderedItems)));
                  } else {
                    if (_useLoyaltyCoins && user.isLoggedIn) {
                      Provider.of<UserProvider>(context, listen: false).deductCoins(user.loyaltyCoins, 'Discount Applied', 'Redeemed at checkout');
                    }
                    if (total > 2000 && user.isLoggedIn) {
                      Provider.of<UserProvider>(context, listen: false).addCoins(100, 'Big Spender Bonus', 'Order over PKR 2000');
                    }
                    Provider.of<CartProvider>(context, listen: false).clear();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderedItems: orderedItems)), (r) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF08A5D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _paymentMethod == 'Online Payment' ? 'Place order & Pay Online' : 'Place order',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentTile({required IconData icon, required String title, required String subtitle, required String value, bool highlight = false}) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFFF08A5D) : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: isSelected ? const Color(0xFFFFF3EE) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: isSelected ? const Color(0xFFF08A5D) : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFF08A5D) : Colors.black)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _paymentMethod,
              activeColor: const Color(0xFFF08A5D),
              onChanged: (val) => setState(() => _paymentMethod = val!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false, bool accent = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: bold ? Colors.black : Colors.grey, fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 14)),
        Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 17 : 14, color: accent ? Colors.orange : (bold ? const Color(0xFFF08A5D) : Colors.black))),
      ],
    );
  }
}
