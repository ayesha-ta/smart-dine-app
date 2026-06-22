import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'feedback_screen.dart';
import 'coin_wallet_screen.dart';

class OrderTrackingScreen extends StatefulWidget {
  final List<Map<String, dynamic>> orderedItems;
  const OrderTrackingScreen({super.key, this.orderedItems = const []});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xFFF08A5D);
  static const _peach = Color(0xFFFFF3EE);

  // Phase: false = Order Placed view, true = Tracking view
  bool _showTracking = false;

  int _currentStep = 0; // 0=Received, 1=Preparing, 2=Ready, 3=Served
  final List<String> _steps = ['Received', 'Preparing', 'Ready', 'Served'];
  final List<IconData> _stepIcons = [
    Icons.receipt_long,
    Icons.soup_kitchen,
    Icons.restaurant,
    Icons.check_circle,
  ];

  late List<Map<String, dynamic>> _orderItems;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _orderItems = List<Map<String, dynamic>>.from(widget.orderedItems);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startTracking() {
    setState(() => _showTracking = true);
    _simulateProgress();
  }

  void _simulateProgress() async {
    for (int i = 1; i < 4; i++) {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return;
      setState(() {
        _currentStep = i;
        // Update item statuses as progress moves
        if (i >= 2) {
          for (var item in _orderItems) {
            item['status'] = 'Ready';
          }
        } else if (i >= 1) {
          for (var item in _orderItems) {
            if (item['status'] == 'Pending') {
              item['status'] = 'Preparing';
            }
          }
        }
      });
    }
    // After reaching Served, navigate to Feedback
    if (mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FeedbackScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _showTracking ? _buildTrackingView() : _buildOrderPlacedView();
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PHASE 1: Order Placed Confirmation
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildOrderPlacedView() {
    final user = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),

                    // ── Checkmark circle ──
                    Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Title ──
                    const Text(
                      'Order Placed',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Order #SD-2847 • Table 4',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Loyalty coins earned box ──
                    if (user.isLoggedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(text: '+26 loyalty coins earned!!\n', style: TextStyle(color: Color(0xFFF08A5D), fontWeight: FontWeight.bold, fontSize: 14, height: 1.5)),
                                    TextSpan(text: 'New balance: ${user.loyaltyCoins} coins', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 32),

                    // ── Order Status section ──
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Order Status',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── 4 status rows ──
                          _buildStatusRow('Order received', 0),
                          _buildStatusRow('Preparing', 1),
                          _buildStatusRow('Ready to Serve', 2),
                          _buildStatusRow('Served', 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Track Order button ──
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _startTracking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Track Order',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single status row for the Order Placed view
  Widget _buildStatusRow(String label, int index) {
    // Only step 0 is active initially
    final bool isActive = index == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? _orange : Colors.transparent,
              border: Border.all(
                color: isActive ? _orange : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: isActive
                ? const Icon(Icons.circle, size: 8, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: isActive ? Colors.black87 : Colors.grey.shade400,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  PHASE 2: Live Tracking View
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTrackingView() {
    final user = Provider.of<UserProvider>(context);

    // Dynamic header subtitle & cooking label
    final String statusLabel;
    final String estimateLabel;
    final IconData centerIcon;
    switch (_currentStep) {
      case 0:
        statusLabel = 'Order Received';
        estimateLabel = 'Est. 20-25 minutes';
        centerIcon = Icons.receipt_long;
        break;
      case 1:
        statusLabel = 'Being Prepared';
        estimateLabel = 'Est. 15-20 minutes';
        centerIcon = Icons.soup_kitchen;
        break;
      case 2:
        statusLabel = 'Ready to Serve';
        estimateLabel = 'Your order is ready!';
        centerIcon = Icons.restaurant;
        break;
      case 3:
        statusLabel = 'Served';
        estimateLabel = 'Enjoy your meal!';
        centerIcon = Icons.check_circle;
        break;
      default:
        statusLabel = 'Being Prepared';
        estimateLabel = 'Est. 15-20 minutes';
        centerIcon = Icons.soup_kitchen;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false, // let the orange header extend behind status bar
        child: Column(
          children: [
            // ── Orange header ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 8,
                right: 8,
                bottom: 20,
              ),
              decoration: const BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _showTracking = false),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order #SD-2847',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Table 4 • ${_orderItems.length} items',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (user.isLoggedIn)
                    IconButton(
                      icon: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CoinWalletScreen(),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Body ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // ── Centre status icon ──
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final scale = 1.0 + (_pulseController.value * 0.06);
                        return Transform.scale(scale: scale, child: child);
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: _peach,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(centerIcon, size: 52, color: _orange),
                      ),
                    ),

                    const SizedBox(height: 14),
                    Text(
                      statusLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estimateLabel,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Horizontal timeline ──
                    _buildHorizontalTimeline(),

                    const SizedBox(height: 32),

                    // ── Your Items card ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Items',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._orderItems.map((item) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['name']!,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                    _buildItemBadge(item['status']!),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Loyalty coins earned info ──
                    if (user.isLoggedIn)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(text: '+26 loyalty coins earned!!\n', style: TextStyle(color: Color(0xFFF08A5D), fontWeight: FontWeight.bold, fontSize: 13, height: 1.5)),
                                    TextSpan(text: 'New balance: ${user.loyaltyCoins} coins', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Badge for item status (Preparing / Pending / Ready)
  Widget _buildItemBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Preparing':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        break;
      case 'Ready':
        bgColor = const Color(0xFFE8F5E9);
        textColor = Colors.green;
        break;
      default: // Pending
        bgColor = Colors.orange.shade800;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Horizontal 4-step timeline with dots and connecting lines
  Widget _buildHorizontalTimeline() {
    return Row(
      children: List.generate(_steps.length, (index) {
        final isCompleted = index < _currentStep;
        final isActive = index == _currentStep;
        final isLast = index == _steps.length - 1;
        final isFirst = index == 0;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  // Left connecting line
                  if (!isFirst)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isCompleted || isActive
                              ? _orange
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                  // Dot
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    width: isActive ? 32 : 26,
                    height: isActive ? 32 : 26,
                    decoration: BoxDecoration(
                      color: isCompleted || isActive
                          ? _orange
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: _orange.withOpacity(0.35),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check
                          : _stepIcons[index],
                      color: Colors.white,
                      size: isActive ? 16 : 13,
                    ),
                  ),

                  // Right connecting line
                  if (!isLast)
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        height: 3,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? _orange
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _steps[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive || isCompleted
                      ? _orange
                      : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Animated builder that passes animation value to child builder
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder2(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

/// Inner implementation using AnimatedWidget pattern
class AnimatedBuilder2 extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder2({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
