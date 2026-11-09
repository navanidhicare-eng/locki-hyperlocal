import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'order_tracking_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  final ApiService _api = ApiService();
  List<OrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  void _loadOrders() async {
    setState(() => _loading = true);
    final list = await _api.fetchMyOrders();
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundLight,
      appBar: AppBar(
        title: const Text('My Bookings & Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppConstants.secondary,
        elevation: 0.5,
        actions: [
          IconButton(onPressed: _loadOrders, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No bookings found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Book plumbers, mechanics, delivery boys from home', style: TextStyle(color: AppConstants.textDim, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (ctx, idx) {
                    final o = _orders[idx];
                    bool isCompleted = o.orderStatus == 'COMPLETED';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OrderTrackingScreen(order: o)),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  o.id,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppConstants.primary),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: (isCompleted
                                            ? AppConstants.accentEmerald
                                            : (o.orderStatus.toUpperCase() == 'CANCELLED'
                                                ? Colors.red
                                                : AppConstants.accentGold))
                                        .withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    o.orderStatus,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: isCompleted
                                          ? AppConstants.accentEmerald
                                          : (o.orderStatus.toUpperCase() == 'CANCELLED'
                                              ? const Color(0xFFDC2626)
                                              : AppConstants.accentGold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              o.serviceName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.secondary),
                            ),
                            const SizedBox(height: 4),
                            Text('Specialist: ${o.providerName}', style: const TextStyle(fontSize: 13, color: AppConstants.textMuted)),
                            if (o.orderStatus.toUpperCase() != 'CANCELLED') ...[
                              const SizedBox(height: 12),
                              Text(
                                'OTP PIN: ${o.otp}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.accentGold, fontSize: 13),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
