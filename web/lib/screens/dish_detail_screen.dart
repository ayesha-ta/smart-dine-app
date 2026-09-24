import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../providers/user_provider.dart';

class DishDetailScreen extends StatefulWidget {
  final MenuItem menuItem;
  const DishDetailScreen({super.key, required this.menuItem});

  @override
  State<DishDetailScreen> createState() => _DishDetailScreenState();
}

class _DishDetailScreenState extends State<DishDetailScreen> {
  int _quantity = 1;
  bool _isInit = false;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final maxQty = userProvider.getMaxAvailableQuantity(widget.menuItem);

    if (!_isInit) {
      _quantity = maxQty > 0 ? 1 : 0;
      _isInit = true;
    }

    final totalPrice = (widget.menuItem.price * _quantity).toInt();
    final isOutOfStock = maxQty <= 0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Hero image with back button overlay
          Stack(
            children: [
              SizedBox(
                height: 280,
                width: double.infinity,
                child: Image.network(
                  widget.menuItem.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 280,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, size: 80, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                top: 50,
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black45,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.menuItem.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(widget.menuItem.category, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                  if (widget.menuItem.isSpicy) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                                      child: const Text('Spicy', style: TextStyle(color: Colors.red, fontSize: 11)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        Text('PKR $totalPrice', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFF08A5D))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(widget.menuItem.description, style: TextStyle(color: Colors.grey.shade600, height: 1.6, fontSize: 14)),
                    const SizedBox(height: 24),

                    // Inventory & Quantity Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Quantity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOutOfStock ? Colors.red.shade50 : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isOutOfStock 
                                ? 'Out of Stock' 
                                : 'Kitchen stock allows: 0 to $maxQty items',
                            style: TextStyle(
                              color: isOutOfStock ? Colors.red.shade700 : const Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (isOutOfStock)
                      Text(
                        'This item is currently unavailable due to insufficient kitchen ingredients.',
                        style: TextStyle(color: Colors.red.shade400, fontSize: 13, fontStyle: FontStyle.italic),
                      )
                    else
                      Row(
                        children: [
                          _qtyButton(Icons.remove, () {
                            if (_quantity > 1) setState(() => _quantity--);
                          }),
                          const SizedBox(width: 20),
                          Text('$_quantity', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 20),
                          _qtyButton(Icons.add, () {
                            if (_quantity < maxQty) {
                              setState(() => _quantity++);
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Cannot order more than $maxQty items based on current kitchen ingredients!'),
                                  backgroundColor: Colors.orangeAccent,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          }),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Special Instructions
                    const Text('Special Instructions (optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _instructionsController,
                      maxLines: 3,
                      enabled: !isOutOfStock,
                      decoration: InputDecoration(
                        hintText: isOutOfStock ? 'Item is out of stock' : 'e.g. extra spicy, no onions...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Add to Cart button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isOutOfStock
                    ? null
                    : () {
                        Provider.of<CartProvider>(context, listen: false)
                            .addItem(widget.menuItem, _quantity, _instructionsController.text);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${widget.menuItem.name} added to cart!'),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOutOfStock ? Colors.grey.shade300 : const Color(0xFFF08A5D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isOutOfStock 
                      ? 'Out of Stock' 
                      : 'Add to Cart • PKR $totalPrice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF08A5D)),
      ),
    );
  }
}
