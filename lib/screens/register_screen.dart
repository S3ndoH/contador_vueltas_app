import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {'full_name': _fullNameController.text.trim()},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful! Check your email for verification.',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to login
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message), backgroundColor: Colors.red),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unexpected error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -size.height * 0.2,
            left: -size.width * 0.2,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: size.width * 0.8,
                height: size.height * 0.6,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: size.width * 0.6,
                height: size.height * 0.4,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // Main Scrollable Content
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image Section
                Stack(
                  children: [
                    Container(
                      height: size.height * 0.35,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(
                            'https://rwxsccdnidvihkjbapld.supabase.co/storage/v1/object/sign/Imag_LAPCOUNTER/Patin_carrera.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV9lMDgyNmE1OC0yMmVmLTQ2MTYtYTE5Ny0wNDBlMzQ5NDg4ZGUiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJJbWFnX0xBUENPVU5URVIvUGF0aW5fY2FycmVyYS5wbmciLCJpYXQiOjE3NzI1MDg0NDEsImV4cCI6MjA1NjMzMjQ0MX0.FlFUXPoPqC0sBrsWMPX_rU1_A9RHx4Wjq82Kp1OJlDk',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    // Gradients
                    Container(
                      height: size.height * 0.35,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.backgroundDark.withOpacity(0.3),
                            AppColors.backgroundDark.withOpacity(0.6),
                            AppColors.backgroundDark,
                          ],
                        ),
                      ),
                    ),
                    Container(
                      height: size.height * 0.35,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            AppColors.backgroundDark,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.5],
                        ),
                      ),
                    ),
                    // Branding
                    Positioned(
                      top: 48,
                      left: 24,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.fitness_center,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'LAPCOUNTER',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Content Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Transform.translate(
                    offset: const Offset(0, -48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Join the movement,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const Text(
                          'Athlete.',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create your training account.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Form
                        const Text(
                          'Full Name',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            hintText: 'Juan Perez',
                            suffixIcon: Icon(
                              Icons.person_outline,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Email Address',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'athlete@lapcounter.com',
                            suffixIcon: Icon(
                              Icons.mail_outline,
                              color: AppColors.textMuted.withOpacity(0.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'Password',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            hintText: '••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: AppColors.textMuted.withOpacity(0.5),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Text(
                                        'Sign Up',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: const [
                            Expanded(
                              child: Divider(color: AppColors.surfaceDark),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: AppColors.surfaceDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Social Buttons
                        Row(
                          children: [
                            Expanded(
                              child: _SocialButton(
                                label: 'Google',
                                iconUrl:
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDDteqkUrPqzgg5ImUnbpemCrBQaMQ89HQVElnupGHH896U9VsXjcs8kHAJPqLrSuquLsKyaECtGv3hE28xlalzapmq0W3QjyNFQGze_GT49P-wNavC5sewMYSTUfvfWeJWL-QxNjLoo0c-GqCBBwBn2fx1I1Jk-Ya-aOSm3CAsPjJ4V9NxYk4iXoxVk4z9kaBgU5SajYFYDMUVQP24FX7aBviDkWNpmvA1cUwF5MsBtMqAVmiYr1MMj2F2rBzaIakukpPeRB1HpsJh',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _SocialButton(
                                label: 'Apple',
                                iconUrl:
                                    'https://lh3.googleusercontent.com/aida-public/AB6AXuCgg-rIhaqvyu4KLIokG8rsU4kWIvJxHnmmRWwSfLiKoF32f4_tDv_bDd5NKCTa47uSYjQIV2dpbUX8tZPQXvG25jS2RxbA3O_ZY_ZLKp-KGVP6cGWzA21eX-12GH3p8w9jhHKFs-5C94EKi7ckb_hzfu1RBBUSwMcuH7bzVDH-tMTGDxvj1Mg4jYWIdb1UPi0V5KmOl96t_vt7jV_XIkQJVulyBqiEsp1VVtiZFJO_RwhE1wZxwCkqfFTqGtkqMDD7bcr9vWMwEKj3',
                                invertIcon: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Footer
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final String iconUrl;
  final bool invertIcon;

  const _SocialButton({
    required this.label,
    required this.iconUrl,
    this.invertIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColorFiltered(
                colorFilter: ColorFilter.mode(
                  invertIcon ? Colors.white : Colors.transparent,
                  BlendMode.srcIn,
                ),
                child: Image.network(iconUrl, width: 20, height: 20),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
