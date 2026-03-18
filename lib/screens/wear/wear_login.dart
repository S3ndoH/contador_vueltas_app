import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter/services.dart';
import '../../theme.dart';
import 'wear_home.dart';

class WearLoginScreen extends StatefulWidget {
  const WearLoginScreen({super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreenState();
}

class _WearLoginScreenState extends State<WearLoginScreen> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  // GLOBAL KEYS: Para mantener la conexión con el teclado (IME) a pesar de destruir el árbol
  final _emailKey = GlobalKey(debugLabel: 'email_field');
  final _passwordKey = GlobalKey(debugLabel: 'password_field');
  
  bool _isLoading = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      // VIBRACIÓN FUERTE: Despierta el kernel
      HapticFeedback.vibrate();
      setState(() {
        _charCount = _emailController.text.length + _passwordController.text.length;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
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
    // CAMBIO DE IDENTIDAD TOTAL: La key del body cambia en cada letra
    // Esto obliga a Flutter a hacer 'dispose' y 'init' de toda la rama
    final bodyKey = ValueKey('nuclear_v12_$_charCount');

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, 
      body: Container(
        key: bodyKey,
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 16),
                const SizedBox(height: 4),
                
                // ESPEJO DINÁMICO (Forzado por la Key del padre)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: Text(
                    _emailController.text.isEmpty ? 'E-MAIL...' : _emailController.text,
                    style: const TextStyle(
                      color: Colors.white, 
                      fontSize: 11, 
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 12),

                // TEXT FIELDS CON GLOBAL KEYS
                TextField(
                  key: _emailKey,
                  controller: _emailController,
                  focusNode: _emailFocus,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  cursorColor: AppColors.primary,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 10),

                TextField(
                  key: _passwordKey,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  cursorColor: AppColors.primary,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'Clave',
                    isDense: true,
                    contentPadding: EdgeInsets.all(12),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 14),

                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text('INGRESAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                
                const SizedBox(height: 150),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
