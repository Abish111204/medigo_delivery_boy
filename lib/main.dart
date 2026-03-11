import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://hybropgyoprztvxcvsjo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh5YnJvcGd5b3ByenR2eGN2c2pvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2Njg0MDMsImV4cCI6MjA4MDI0NDQwM30.UqJqRET_V9tgkp9lVdqcSEgjJbf1xwt22vnyDbjSj9s', 
  );

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGo Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // PROFESSIONAL COLOR PALETTE (Emerald & Slate)
        primaryColor: const Color(0xFF00897B), 
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Ultra-light Slate Grey
        cardColor: Colors.white,
        
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF00897B),
          secondary: const Color(0xFF26A69A),
          surface: Colors.white,
          error: const Color(0xFFEF4444),
          onPrimary: Colors.white,
        ),

        // MODERN TEXT THEME
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF1E293B), letterSpacing: -0.5),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          bodyLarge: TextStyle(fontSize: 16, color: Color(0xFF334155), height: 1.5),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
        ),

        // MODERN BUTTON STYLE
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00897B),
            foregroundColor: Colors.white,
            elevation: 0, // Flat is modern
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
          ),
        ),
        
        // CLEAN APP BAR
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        ),
        
        // INPUT FIELDS
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00897B), width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        useMaterial3: true,
      ),
      home: supabase.auth.currentUser == null ? const LoginPage() : const HomePage(),
    );
  }
}