import 'package:flutter/material.dart';
import 'package:medigo_delivery/main.dart';

class BankDetailsPage extends StatefulWidget {
  const BankDetailsPage({super.key});

  @override
  State<BankDetailsPage> createState() => _BankDetailsPageState();
}

class _BankDetailsPageState extends State<BankDetailsPage> {
  final _bankCtrl = TextEditingController();
  final _accCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await supabase.from('delivery_profiles').select().eq('id', supabase.auth.currentUser!.id).single();
      _bankCtrl.text = data['bank_name'] ?? '';
      _accCtrl.text = data['account_number'] ?? '';
      _ifscCtrl.text = data['ifsc_code'] ?? '';
    } catch(e) {/* ignore */}
    setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await supabase.from('delivery_profiles').update({
        'bank_name': _bankCtrl.text,
        'account_number': _accCtrl.text,
        'ifsc_code': _ifscCtrl.text,
      }).eq('id', supabase.auth.currentUser!.id);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bank details updated!"), backgroundColor: Colors.green));
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update"), backgroundColor: Colors.red));
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bank Details")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.account_balance, size: 60, color: Colors.grey),
                const SizedBox(height: 24),
                _field("Bank Name", _bankCtrl, Icons.business),
                const SizedBox(height: 16),
                _field("Account Number", _accCtrl, Icons.numbers),
                const SizedBox(height: 16),
                _field("IFSC Code", _ifscCtrl, Icons.qr_code),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save, 
                    child: const Text("SAVE DETAILS")
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}