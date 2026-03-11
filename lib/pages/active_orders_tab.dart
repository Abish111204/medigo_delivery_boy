import 'package:flutter/material.dart';
import 'package:medigo_delivery/main.dart';
import 'package:medigo_delivery/order_detail_page.dart';

class ActiveOrdersTab extends StatelessWidget {
  const ActiveOrdersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text("My Schedule", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          backgroundColor: Colors.white,
          elevation: 1,
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "ONGOING"),
              Tab(text: "HISTORY"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _OrdersList(showActive: true),
            _OrdersList(showActive: false),
          ],
        ),
      ),
    );
  }
}

class _OrdersList extends StatelessWidget {
  final bool showActive;
  const _OrdersList({required this.showActive});

  @override
  Widget build(BuildContext context) {
    final myId = supabase.auth.currentUser!.id;
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase.from('orders').stream(primaryKey: ['id']).order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final allMyOrders = snapshot.data!.where((o) => o['delivery_boy_id'] == myId).toList();
        
        final filteredOrders = allMyOrders.where((o) {
          final isDelivered = o['status'] == 'Delivered';
          return showActive ? !isDelivered : isDelivered;
        }).toList();

        if (filteredOrders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(showActive ? Icons.moped : Icons.history, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(showActive ? "No active deliveries" : "No delivery history", style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: showActive ? Colors.orange.shade100 : Colors.grey.shade200,
                  child: Icon(
                    showActive ? Icons.store : Icons.check, // Changed icon to Store
                    color: showActive ? Colors.orange : Colors.grey
                  ),
                ),
                title: Text(order['shop_name'] ?? "Unknown Shop", style: const TextStyle(fontWeight: FontWeight.bold)), // <--- SHOWS SHOP NAME
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text("To: ${order['delivery_address'] ?? 'Unknown'}", maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(order['status'].toString().toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)));
                },
              ),
            );
          },
        );
      },
    );
  }
}