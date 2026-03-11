import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medigo_delivery/main.dart';
import 'package:medigo_delivery/order_detail_page.dart';

class RideHistoryPage extends StatefulWidget {
  const RideHistoryPage({super.key});

  @override
  State<RideHistoryPage> createState() => _RideHistoryPageState();
}

class _RideHistoryPageState extends State<RideHistoryPage> {
  // We use a Future to fetch data once, instead of keeping a stream open
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _fetchHistory();
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    final myId = supabase.auth.currentUser!.id;
    final data = await supabase
        .from('orders')
        .select() // Use .select() for standard fetching
        .eq('delivery_boy_id', myId)
        .eq('status', 'Delivered')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ride History")),
      // Switched to FutureBuilder (Better for static history data)
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
             return Center(child: Text("Error: ${snapshot.error}"));
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("No completed rides yet.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final dateStr = order['created_at'];
              // Handle date formatting safely
              String date = "Unknown Date";
              if (dateStr != null) {
                date = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.parse(dateStr).toLocal());
              }
              
              final earn = (order['total_amount'] ?? 0) * 0.1;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.shade50,
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text("Order #${order['id']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(date, style: const TextStyle(fontSize: 12)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("+ ₹${earn.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                      const Text("Earned", style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}