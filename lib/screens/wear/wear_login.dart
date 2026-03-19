import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import '../../services/wear_sync_service.dart';
import 'wear_home.dart';
import 'dart:async';

class WearLoginScreen extends StatefulWidget {
  const WearLoginScreen({super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreenState();
}

class _WearLoginScreenState extends State<WearLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  bool _isLoading = false;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for silent sync from phone
    _syncSubscription = WearSyncService().onTokenReceived.listen(_onTokenReceived);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _syncSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onTokenReceived(String token) async {
    setState(() => _isLoading = true);
    try {
      // Sign in using the token received from the phone
      await Supabase.instance.client.auth.setSession(token);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WearHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync Error: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WearHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
              const SizedBox(height: 8),
              const Text(
                'LAPCOUNTER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              
              // SYNC STATUS / WAITING MESSAGE
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Esperando al teléfono...',
                      style: TextStyle(color: Colors.white70, fontSize: 9),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // EMAIL FIELD
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: AppColors.primary,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Email',
                  hintStyle: const TextStyle(color: Colors.white30),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // PASSWORD FIELD
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                obscureText: true,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                cursorColor: AppColors.primary,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _signIn(),
                decoration: InputDecoration(
                  hintText: 'Clave',
                  hintStyle: const TextStyle(color: Colors.white30),
                  isDense: true,
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              _isLoading
                  ? const CircularProgressIndicator(color: AppColors.primary)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _signIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: const Text('INGRESAR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ),
              
              const SizedBox(height: 40), // Extra space for scrolling
            ],
          ),
        ),
      ),
    );
  }
}
