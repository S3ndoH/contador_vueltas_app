import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme.dart';
import 'wear_home.dart';

/// Almacenamiento persistente para los controladores de autenticación.
/// Esto evita que el texto se pierda si la pantalla se reconstruye por el teclado.
class _AuthStorage {
  static final emailController = TextEditingController();
  static final passwordController = TextEditingController();
}

class WearLoginScreen extends StatefulWidget {
  const WearLoginScreen({super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreenState();
}

class _WearLoginScreenState extends State<WearLoginScreen> {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _AuthStorage.emailController.text.trim(),
        password: _AuthStorage.passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WearHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // PREVENIR RESIZE QUE MATA EL TECLADO
      body: Container(
        width: double.infinity,
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Icon(LucideIcons.shieldCheck, color: AppColors.primary, size: 20),
            const SizedBox(height: 2),
            const Text(
              'VINCULAR CUENTA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            
            // EMAIL FIELD con ValueListenableBuilder para refresco ATÓMICO
            ValueListenableBuilder(
              valueListenable: _AuthStorage.emailController,
              builder: (context, value, _) {
                return TextField(
                  controller: _AuthStorage.emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    _emailFocus.unfocus();
                    FocusScope.of(context).requestFocus(_passwordFocus);
                  },
                );
              },
            ),
            
            const SizedBox(height: 4),
            
            // PASSWORD FIELD con ValueListenableBuilder para refresco ATÓMICO
            ValueListenableBuilder(
              valueListenable: _AuthStorage.passwordController,
              builder: (context, value, _) {
                return TextField(
                  controller: _AuthStorage.passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: 'Contraseña',
                    hintStyle: TextStyle(color: Colors.white24),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 6),
            _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: const Size(0, 32),
                      ),
                      child: const Text('INGRESAR', style: TextStyle(fontSize: 11)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
