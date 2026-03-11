import 'package:flutter/material.dart';
import 'package:medigo_delivery/main.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RequestsTab extends StatefulWidget {
  const RequestsTab({super.key});

  @override
  State<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends State<RequestsTab> {
  String? _userPlace;
  bool _isOnline = false;
  Map<int, String> _shopLocations = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final profileData = await supabase.from('delivery_profiles').select('registered_place, is_online').eq('id', userId).single();
      final shopsData = await supabase.from('shops').select('id, place');
      
      if (mounted) {
        setState(() {
          _userPlace = profileData['registered_place'];
          _isOnline = profileData['is_online'] ?? false;
          _shopLocations = { for (var s in shopsData) s['id'] as int : (s['place'] as String?) ?? '' };
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (!_isOnline) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(color: const Color(0xFFE0F2F1), shape: BoxShape.circle),
                child: const Icon(Icons.power_settings_new, size: 60, color: Color(0xFF00897B)),
              ),
              const SizedBox(height: 24),
              const Text("You are Offline", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              const Text("Go to your Profile and toggle 'Online'\nto start receiving medicine orders.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loadInitialData, 
                child: const Text("Refresh Status")
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("New Requests", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Row(children: [
              const Icon(Icons.my_location, size: 12, color: Color(0xFF00897B)), 
              const SizedBox(width: 4), 
              Text("Zone: ${_userPlace ?? "Unknown"}", style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))
            ])
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadInitialData)
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: supabase.from('orders').stream(primaryKey: ['id']).order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allOrders = snapshot.data!;
          final orders = allOrders.where((o) {
            final status = o['status'] ?? '';
            final isShopAccepted = (status == 'Confirmed' || status == 'Accepted' || status == 'Preparing' || status == 'Processing' || status == 'Ready for Delivery');
            final isNotTaken = o['delivery_boy_id'] == null;
            final shopId = o['shop_id'] as int?;
            String orderPlace = (o['shop_place'] as String?) ?? _shopLocations[shopId] ?? '';
            return isShopAccepted && isNotTaken && (orderPlace.trim().toLowerCase() == (_userPlace ?? '').trim().toLowerCase());
          }).toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.health_and_safety, size: 80, color: Color(0xFFB2DFDB)),
                  const SizedBox(height: 16),
                  const Text("Looking for orders...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  const SizedBox(height: 8),
                  Text("You are online in $_userPlace", style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00897B)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return OrderCard(order: orders[index], shopLocations: _shopLocations);
            },
          );
        },
      ),
    );
  }
}

// --- ORDER CARD WIDGET ---
class OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;
  final Map<int, String> shopLocations;

  const OrderCard({super.key, required this.order, required this.shopLocations});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  String _customerName = "Customer";
  
  @override
  void initState() {
    super.initState();
    _fetchCustomerName();
  }

  Future<void> _fetchCustomerName() async {
    final userId = widget.order['user_id'];
    if (userId != null) {
      final data = await supabase.from('profiles').select('first_name, last_name').eq('id', userId).maybeSingle();
      if (mounted && data != null) {
        setState(() {
          _customerName = "${data['first_name']} ${data['last_name']}".trim();
          if (_customerName.isEmpty) _customerName = "Valued Customer";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final shopId = order['shop_id'] as int?;
    final shopPlace = (order['shop_place'] as String?) ?? widget.shopLocations[shopId] ?? 'Unknown';
    double earnings = (order['total_amount'] ?? 0) * 0.1;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        // SOFT SHADOW EFFECT
        boxShadow: [BoxShadow(color: const Color(0xFF0F172A).withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 8))]
      ),
      child: Column(
        children: [
          // HEADER WITH BADGE
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(8)),
                  child: Text("ORDER #${order['id']}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00796B))),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("EST. EARNING", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
                    Text("₹${earnings.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF00897B), fontSize: 18)),
                  ],
                )
              ],
            ),
          ),
          
          Divider(height: 1, color: Colors.grey.shade100),

          // BODY - VISUAL TIMELINE
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _locationRow(Icons.storefront_rounded, order['shop_name'] ?? "Medical Shop", shopPlace, isPickup: true),
                Container(
                  margin: const EdgeInsets.only(left: 14), // Align with icon center
                  height: 30,
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade300],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 0.5] // Dashed effect simulator
                    )
                  ),
                ),
                _locationRow(Icons.person_rounded, _customerName, order['delivery_address'] ?? "Address", isPickup: false),
              ],
            ),
          ),

          // BUTTON
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _acceptOrder(order['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00897B),
                  elevation: 4,
                  shadowColor: const Color(0x4000897B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("ACCEPT DELIVERY", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }

  Widget _locationRow(IconData icon, String title, String subtitle, {required bool isPickup}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPickup ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2F1), // Orange-tint vs Teal-tint
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: isPickup ? const Color(0xFFF97316) : const Color(0xFF00897B), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isPickup ? "PICKUP POINT" : "DROP LOCATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade400, letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        )
      ],
    );
  }

  Future<void> _acceptOrder(int orderId) async {
    try {
      final myId = supabase.auth.currentUser!.id;
      await supabase.from('orders').update({'delivery_boy_id': myId, 'status': 'Order Accepted'}).eq('id', orderId);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order Accepted!"), backgroundColor: Color(0xFF00897B)));
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to accept."), backgroundColor: Colors.red));
    }
  }
}