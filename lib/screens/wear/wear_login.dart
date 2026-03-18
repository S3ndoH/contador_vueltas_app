import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;
import '../../theme.dart';
import 'wear_home.dart';

/// Almacenamiento persistente para los controladores de autenticación.
/// Esto evita que el texto se pierda si la pantalla se reconstruye por el teclado.
class _AuthStorage {
  static final emailController = TextEditingController();
  static final passwordController = TextEditingController();
}

/// Pintor que genera ruido visual microscópico para forzar el redibujado de la GPU.
class _ChaosPainter extends CustomPainter {
  final double pulse;
  _ChaosPainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color.fromARGB(1, math.Random().nextInt(255), 0, 0); // 1/255 de opacidad
    canvas.drawRect(const Rect.fromLTWH(0, 0, 1, 1), paint);
  }

  @override
  bool shouldRepaint(_ChaosPainter oldDelegate) => true;
}

class WearLoginScreen extends StatefulWidget {
  const WearLoginScreen({super.key});

  @override
  State<WearLoginScreen> createState() => _WearLoginScreenState();
}

class _WearLoginScreenState extends State<WearLoginScreen> with SingleTickerProviderStateMixin {
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  late AnimationController _frameController;
  bool _tremor = false; // El activador del temblor de layout

  @override
  void initState() {
    super.initState();
    // FRAME FORCER v9: 60fps + Temblor de Layout
    _frameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();

    _AuthStorage.emailController.addListener(_onTextChanged);
    _AuthStorage.passwordController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {
        _tremor = !_tremor; // Cambiamos el padding de toda la pantalla
      });

      // Forzado de físicas de scroll (mucho más agresivo que jumpTo)
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.offset + (_tremor ? 0.5 : -0.5),
          duration: const Duration(milliseconds: 1),
          curve: Curves.linear,
        );
      }
    }
  }

  @override
  void dispose() {
    _AuthStorage.emailController.removeListener(_onTextChanged);
    _AuthStorage.passwordController.removeListener(_onTextChanged);
    _frameController.dispose();
    _scrollController.dispose();
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
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 10),
        // TEMBLOR: El cambio de padding en la raíz obliga a recalcular TODO el layout
        padding: EdgeInsets.only(top: _tremor ? 0.5 : 0),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _frameController,
                builder: (context, _) => CustomPaint(
                  painter: _ChaosPainter(_frameController.value),
                ),
              ),
            ),
            
            SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.shieldAlert, color: AppColors.primary, size: 16),
                    const SizedBox(height: 2),
                    
                    // ESPEJO EMAIL
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        key: ValueKey('m_email_${_AuthStorage.emailController.text.length}_$_tremor'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _AuthStorage.emailController.text.isEmpty ? 'EMAIL...' : _AuthStorage.emailController.text,
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    TextField(
                      controller: _AuthStorage.emailController,
                      focusNode: _emailFocus,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      cursorColor: AppColors.primary,
                      showCursor: true,
                      cursorWidth: 3,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ESPEJO PASSWORD
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 50),
                      child: Container(
                        key: ValueKey('m_pass_${_AuthStorage.passwordController.text.length}_$_tremor'),
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _AuthStorage.passwordController.text.isEmpty ? 'PASS...' : '*' * _AuthStorage.passwordController.text.length,
                          style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    TextField(
                      controller: _AuthStorage.passwordController,
                      focusNode: _passwordFocus,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      cursorColor: AppColors.primary,
                      showCursor: true,
                      cursorWidth: 3,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              child: const Text('INGRESAR', style: TextStyle(fontSize: 10)),
                            ),
                          ),
                    const SizedBox(height: 100), // Más espacio para scroll
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
