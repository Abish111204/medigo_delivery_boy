import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medigo_delivery/main.dart';

class EarningsPage extends StatefulWidget {
  const EarningsPage({super.key});

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  String _selectedFilter = 'Today'; 
  double _totalEarnings = 0.0;
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEarnings();
  }

  Future<void> _fetchEarnings() async {
    setState(() => _isLoading = true);
    try {
      final myId = supabase.auth.currentUser!.id;
      final now = DateTime.now();
      DateTime? startDate;
      
      // LOGIC: Based on DELIVERY DATE
      if (_selectedFilter == 'Today') {
        startDate = DateTime(now.year, now.month, now.day);
      } else if (_selectedFilter == 'This Week') {
        final daysToSubtract = now.weekday - 1; 
        startDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysToSubtract));
      } else if (_selectedFilter == 'This Month') {
        startDate = DateTime(now.year, now.month, 1);
      }

      var query = supabase.from('orders').select().eq('delivery_boy_id', myId).eq('status', 'Delivered');
      if (startDate != null) query = query.gte('delivered_at', startDate.toUtc().toIso8601String());

      final data = await query.order('delivered_at', ascending: false);

      double total = 0.0;
      final List<Map<String, dynamic>> orders = List<Map<String, dynamic>>.from(data);
      for (var o in orders) {
        final rawAmount = o['total_amount'];
        double amount = (rawAmount is int) ? rawAmount.toDouble() : (rawAmount as double? ?? 0.0);
        total += amount * 0.10; 
      }

      if (mounted) setState(() { _orders = orders; _totalEarnings = total; _isLoading = false; });
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Earnings Dashboard"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. MODERN GRADIENT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF004D40), Color(0xFF00897B)], // Deep Teal Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Color(0x4000897B), blurRadius: 20, offset: Offset(0, 10))]
            ),
            child: Column(
              children: [
                // Filter Chips (Glassmorphism)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _glassChip("Today"),
                      _glassChip("This Week"),
                      _glassChip("This Month"),
                      _glassChip("All Time"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                // Revenue Display
                Text("TOTAL REVENUE", style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("₹", style: TextStyle(color: Colors.white70, fontSize: 32, fontWeight: FontWeight.bold, height: 1.5)),
                    Text(_totalEarnings.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Mini Stat
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Text("${_orders.length} Deliveries Completed", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              ],
            ),
          ),

          // 2. TRANSACTION LIST
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _orders.isEmpty 
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _orders.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final dateStr = order['delivered_at'] ?? order['created_at'];
                        String dateDisplay = dateStr != null 
                            ? DateFormat('MMM dd, hh:mm a').format(DateTime.parse(dateStr).toLocal())
                            : "Unknown";
                        
                        final rawTotal = order['total_amount'];
                        double totalAmt = (rawTotal is int) ? rawTotal.toDouble() : (rawTotal as double? ?? 0.0);
                        final earn = totalAmt * 0.1;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: const Color(0xFFE0F2F1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF00897B)),
                            ),
                            title: Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            subtitle: Text(dateDisplay, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("+ ₹${earn.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF00897B))),
                                Text("Credit", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
          )
        ],
      ),
    );
  }

  Widget _glassChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () { setState(() => _selectedFilter = label); _fetchEarnings(); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          color: isSelected ? const Color(0xFF004D40) : Colors.white,
          fontWeight: FontWeight.w600, fontSize: 13
        )),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text("No earnings found", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontSize: 16)),
        Text("in $_selectedFilter", style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
      ],
    );
  }
}