import 'package:flutter/material.dart';
import 'package:medigo_delivery/main.dart';

class PerformancePage extends StatelessWidget {
  const PerformancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Performance")),
      body: FutureBuilder(
        future: supabase.from('delivery_profiles').select().eq('id', supabase.auth.currentUser!.id).single(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final profile = snapshot.data as Map<String, dynamic>;
          final rating = (profile['rating'] ?? 5.0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // RATING CARD
                Container(
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))]
                  ),
                  child: Column(
                    children: [
                      const Text("Current Rating", style: TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          const Icon(Icons.star, color: Colors.yellow, size: 40),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text("Excellent Work! Keep it up.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // METRICS GRID
                Row(
                  children: [
                    _metricCard("On-Time", "98%", Icons.timer, Colors.blue),
                    const SizedBox(width: 16),
                    _metricCard("Acceptance", "100%", Icons.check_circle, Colors.green),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
