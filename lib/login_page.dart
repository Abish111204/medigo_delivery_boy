import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'home_page.dart';
import 'main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscured = true;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (res.user != null) {
        // Check if user is a valid delivery partner
        final profile = await supabase
            .from('delivery_profiles')
            .select()
            .eq('id', res.user!.id)
            .maybeSingle();

        if (profile != null) {
          if (mounted) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          }
        } else {
          await supabase.auth.signOut();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Access Denied: Not a Delivery Partner."), backgroundColor: Colors.red)
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login Failed: ${e.toString()}"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF00897B); // Medical Teal

    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE WITH OVERLAY
          Positioned.fill(
            child: Image.network(
              // Professional medical/logistics background
              'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?q=80&w=2030&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(color: const Color(0xFF004D40)), // Fallback color
            ),
          ),
          // Dark Teal Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF004D40).withOpacity(0.8), // Dark Green/Teal
                    const Color(0xFF00897B).withOpacity(0.9), // Lighter Teal
                  ],
                ),
              ),
            ),
          ),

          // 2. CONTENT
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- LOGO SECTION ---
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))
                      ]
                    ),
                    child: const Icon(Icons.health_and_safety_rounded, size: 64, color: primaryColor),
                  ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  // --- APP TITLE ---
                  const Text(
                    "MediGo Delivery",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                  ).animate().fadeIn().slideY(begin: 0.3, end: 0),
                  
                  const Text(
                    "Partner Portal",
                    style: TextStyle(color: Colors.white70, fontSize: 16, letterSpacing: 2),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 40),

                  // --- LOGIN CARD ---
                  Card(
                    elevation: 8,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            "Welcome Back",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3436)),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Sign in to start your shift",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          const SizedBox(height: 30),

                          // Email Input
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: "Email Address",
                              prefixIcon: const Icon(Icons.email_outlined, color: primaryColor),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password Input
                          TextFormField(
                            controller: _passCtrl,
                            obscureText: _isObscured,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(Icons.lock_outline, color: primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(_isObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                onPressed: () => setState(() => _isObscured = !_isObscured),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                            ),
                          ),
                          const SizedBox(height: 30),
                          
                          // Login Button
                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shadowColor: primaryColor.withOpacity(0.4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: _isLoading 
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("SECURE LOGIN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                      SizedBox(width: 10),
                                      Icon(Icons.arrow_forward_rounded, size: 20),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 40),
                  
                  Text(
                    "© 2026 MediGo Logistics",
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}