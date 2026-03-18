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
  bool _isLoading = false;
  late AnimationController _nuclearController;

  @override
  void initState() {
    super.initState();
    // NUCLEAR TICKER: 60fps perpetuos para invalidar cualquier cache de frames del OS
    _nuclearController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _emailController.addListener(_onTextChanged);
    _passwordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      // VIBRACIÓN NUCLEAR: Despierta el kernel de Android
      HapticFeedback.vibrate();
    }
  }

  @override
  void dispose() {
    _nuclearController.dispose();
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
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false, 
      // RECONSTRUCTOR NUCLEAR: Obliga a Flutter a Re-construir TODO en cada frame
      body: AnimatedBuilder(
        animation: Listenable.merge([_nuclearController, _emailController, _passwordController]),
        builder: (context, child) {
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.lock, color: AppColors.primary, size: 16),
                      const SizedBox(height: 2),
                      
                      // ESPEJO NUCLEAR (Rebuild 60fps)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                          // Añadimos una sombra sutil que cambia para asegurar que el compositor detecte cambios
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              blurRadius: _nuclearController.value * 5,
                            )
                          ],
                        ),
                        child: Text(
                          _emailController.text.isEmpty ? 'Escribiendo...' : _emailController.text,
                          style: const TextStyle(
                            color: AppColors.primary, 
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        cursorWidth: 3,
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
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        cursorWidth: 3,
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

                      const SizedBox(height: 12),

                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _signIn,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text('ENTRAR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                      
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
