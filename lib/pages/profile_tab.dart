import 'package:flutter/material.dart';
import 'package:medigo_delivery/main.dart';
import 'package:medigo_delivery/login_page.dart';
import 'package:medigo_delivery/pages/ride_history_page.dart';
import 'package:medigo_delivery/pages/performance_page.dart';
import 'package:medigo_delivery/pages/bank_details_page.dart';
import 'package:medigo_delivery/pages/earnings_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _isOnline = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfileStatus();
  }

  Future<void> _fetchProfileStatus() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase.from('delivery_profiles').select('is_online').eq('id', userId).single();
      if (mounted) {
        setState(() {
          _isOnline = data['is_online'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleOnlineStatus(bool value) async {
    setState(() => _isOnline = value);
    try {
      await supabase.from('delivery_profiles').update({'is_online': value}).eq('id', supabase.auth.currentUser!.id);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value ? "You are ONLINE" : "You are OFFLINE"), backgroundColor: value ? Colors.green : Colors.grey));
      }
    } catch (e) {
      setState(() => _isOnline = !value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: supabase.from('delivery_profiles').select().eq('id', supabase.auth.currentUser!.id).single(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || _isLoading) return const Center(child: CircularProgressIndicator());
        
        final profile = snapshot.data as Map<String, dynamic>;
        
        return Scaffold(
          appBar: AppBar(title: const Text("My Profile"), automaticallyImplyLeading: false),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // 1. HEADER CARD
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 30, backgroundColor: Colors.orange.shade50, child: Text(profile['name']?[0] ?? "D", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange))),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile['name'] ?? "Driver", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text("ID: ${profile['id'].toString().substring(0,8).toUpperCase()}", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),

                // 2. STATUS TOGGLE
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _isOnline ? Colors.green.shade200 : Colors.red.shade200)
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_isOnline ? "YOU ARE ONLINE" : "YOU ARE OFFLINE", style: TextStyle(fontWeight: FontWeight.bold, color: _isOnline ? Colors.green[800] : Colors.red[800])),
                      Switch(value: _isOnline, activeColor: Colors.green, onChanged: _toggleOnlineStatus),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. MENU OPTIONS (Functioning)
               
                _buildMenuItem(Icons.history, "Ride History", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideHistoryPage()))),
                _buildMenuItem(Icons.currency_rupee, "My Earnings", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EarningsPage()))),
                _buildMenuItem(Icons.star_outline, "Performance", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PerformancePage()))),
                _buildMenuItem(Icons.account_balance, "Bank Details", () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BankDetailsPage()))),
                
                const SizedBox(height: 24),
                
                // 4. LOGOUT
                TextButton.icon(
                  onPressed: () async {
                    await supabase.auth.signOut();
                    if(context.mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Log Out", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: Colors.black87),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}