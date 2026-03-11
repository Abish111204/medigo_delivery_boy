import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;
  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late String _status;
  bool _isLoading = false;
  
  // Data to fetch
  String? _customerName;
  String? _customerPhone;
  List<Map<String, dynamic>> _orderItems = [];
  bool _loadingItems = true;

  @override
  void initState() {
    super.initState();
    _status = widget.order['status'];
    _fetchCustomerDetails();
    _fetchOrderItems();
  }

  // 1. Fetch Name & Phone
  Future<void> _fetchCustomerDetails() async {
    try {
      final userId = widget.order['user_id'];
      if (userId == null) return;

      final data = await supabase
          .from('profiles')
          .select('first_name, last_name, phone_number')
          .eq('id', userId)
          .maybeSingle();

      if (mounted && data != null) {
        setState(() {
          _customerName = "${data['first_name'] ?? ''} ${data['last_name'] ?? ''}".trim();
          if (_customerName!.isEmpty) _customerName = "Valued Customer";
          _customerPhone = data['phone_number'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching customer: $e");
    }
  }

  // 2. Fetch Products/Medicines in this order
  Future<void> _fetchOrderItems() async {
    try {
      final data = await supabase
          .from('order_items')
          .select('product_name, quantity, price')
          .eq('order_id', widget.order['id']);
      
      if (mounted) {
        setState(() {
          _orderItems = List<Map<String, dynamic>>.from(data);
          _loadingItems = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingItems = false);
    }
  }

  Future<void> _processDelivery() async {
    final isCOD = widget.order['payment_method'] == 'COD';
    final isPending = widget.order['payment_status'] == 'Pending';

    if (_status != 'Out for Delivery') {
      _updateStatus('Out for Delivery');
      return;
    }

    // Cash Collection Check
    if (isCOD && isPending) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("💰 Collect Cash"),
          content: Text("Please collect ₹${widget.order['total_amount']} from customer."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text("Cash Collected")
            ),
          ],
        )
      );
      
      if (confirm != true) return;
      await supabase.from('orders').update({'payment_status': 'Paid'}).eq('id', widget.order['id']);
    }

    _updateStatus('Delivered');
  }

// Find this function inside lib/order_detail_page.dart
Future<void> _updateStatus(String newStatus) async {
  setState(() => _isLoading = true);
  
  try {
    Map<String, dynamic> updates = {'status': newStatus};

    // NEW: If marking as delivered, save the current time!
    if (newStatus == 'Delivered') {
      updates['delivered_at'] = DateTime.now().toUtc().toIso8601String();
    }

    await supabase.from('orders').update(updates).eq('id', widget.order['id']);

    setState(() { _status = newStatus; _isLoading = false; });
    if (newStatus == 'Delivered' && mounted) Navigator.pop(context);
    
  } catch (e) {
    if(mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _launchMap(String? address) async {
    if (address == null) return;
    final uri = Uri.parse("https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}");
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (e) {/*ignore*/}
  }

  Future<void> _launchCall(String? phone) async {
    if (phone == null) return;
    try { await launchUrl(Uri(scheme: 'tel', path: phone)); } catch (e) {/*ignore*/}
  }

  @override
  Widget build(BuildContext context) {
    bool isCompleted = _status == 'Delivered';
    bool isCOD = widget.order['payment_method'] == 'COD';
    String date = DateFormat('dd MMM, hh:mm a').format(DateTime.parse(widget.order['created_at']));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Order Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text("Order #${widget.order['id']} • $date", style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 1. CASH BANNER
          if (isCOD && _status != 'Delivered')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red.shade600,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wallet, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "COLLECT CASH: ₹${widget.order['total_amount']}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CUSTOMER CARD
                  _buildCustomerCard(),
                  const SizedBox(height: 16),
                  
                  // ITEMS LIST
                  _buildItemsList(),
                  const SizedBox(height: 16),

                  // PAYMENT SUMMARY
                  _buildPaymentSummary(isCOD),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // SLIDER BUTTON
          if (!isCompleted)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _status == 'Out for Delivery' ? Colors.green : Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    onPressed: _isLoading ? null : _processDelivery,
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _status == 'Out for Delivery' ? "COMPLETE DELIVERY" : "SWIPE TO START", 
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)
                        ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue.shade50, child: const Icon(Icons.person, color: Colors.blue)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_customerName ?? "Loading...", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text("Customer", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              const Spacer(),
              _iconBtn(Icons.call, Colors.green, () => _launchCall(_customerPhone)),
              const SizedBox(width: 8),
              _iconBtn(Icons.directions, Colors.blue, () => _launchMap(widget.order['delivery_address'])),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.order['delivery_address'] ?? "No address", style: const TextStyle(height: 1.4, fontSize: 14)),
              ),
            ],
          ),
          if (widget.order['description'] != null && widget.order['description'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.yellow.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.yellow.shade200)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(child: Text("Note: ${widget.order['description']}", style: TextStyle(color: Colors.orange[800], fontSize: 13))),
                ],
              ),
            )
          ]
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("ORDER SUMMARY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 16),
          if (_loadingItems)
            const Center(child: LinearProgressIndicator())
          else if (_orderItems.isEmpty)
            const Text("No items details available.")
          else
            ..._orderItems.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                    child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item['product_name'], style: const TextStyle(fontSize: 15))),
                  Text("₹${item['price']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(bool isCOD) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _row("Item Total", "₹${widget.order['total_amount']}"),
          const SizedBox(height: 8),
          _row("Delivery Fee", "₹0.00", color: Colors.green),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Grand Total", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("₹${widget.order['total_amount']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCOD ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(8)
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isCOD ? Icons.money : Icons.check_circle, size: 16, color: isCOD ? Colors.orange[800] : Colors.green[800]),
                const SizedBox(width: 8),
                Text(
                  isCOD ? "Payment: Cash on Delivery" : "Payment: Paid Online", 
                  style: TextStyle(color: isCOD ? Colors.orange[800] : Colors.green[800], fontWeight: FontWeight.bold)
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: color)),
      ],
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }
}