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

  Future<void> _onTokenReceived(Map<String, String> tokens) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final accessToken = tokens['accessToken'];
    final refreshToken = tokens['refreshToken'];
    
    debugPrint("WearLoginScreen: Procesando tokens v7...");
    debugPrint("WearLoginScreen: RefreshToken length = ${refreshToken?.length}");
    
    try {
      if (refreshToken != null) {
        // En v7 usamos setSession con el refreshToken directamente
        // setSession en Supabase 2.x restaura la sesión usando el token.
        await Supabase.instance.client.auth.setSession(refreshToken);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Sincronización Exitosa!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            )
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WearHomeScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("WearLoginScreen: Error en setSession: $e");
      if (mounted) {
        // Mostramos el error exacto para diagnóstico
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error v7: $e'),
            backgroundColor: Colors.redAccent,
          )
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ESPERANDO TELÉFONO',
                          style: TextStyle(
                            color: AppColors.primary, 
                            fontSize: 9, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Toca abajo para forzar la búsqueda si el celular ya está listo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 8),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {
                         // This actually already happens in native onCreate, 
                         // but we can add a native method to re-check if needed.
                         // For now, re-initializing the service listener.
                         WearSyncService().init();
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(content: Text('Buscando señal...', style: TextStyle(fontSize: 10)), duration: Duration(seconds: 1))
                         );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('BUSCAR AHORA', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                      ),
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
                  : Column(
                      children: [
                        SizedBox(
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
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const WearHomeScreen()),
                              );
                            },
                            child: const Text(
                              'CONTINUAR SIN CUENTA',
                              style: TextStyle(color: Colors.white54, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
              
              const SizedBox(height: 40), // Extra space for scrolling
            ],
          ),
        ),
      ),
    );
  }
}
