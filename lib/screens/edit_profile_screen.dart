import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../services/storage_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _storageService = StorageService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _aliasController = TextEditingController();
  bool _isSaving = false;
  bool _isUploading = false;
  String _initialEmail = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    _nameController.text = user?.userMetadata?['full_name'] ?? '';
    _emailController.text = user?.email ?? '';
    _initialEmail = user?.email ?? '';
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final data = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          if (data['username'] != null) {
            _aliasController.text = data['username'];
          }
          _avatarUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final imageFile = await _storageService.pickImage();
    if (imageFile == null) return;

    setState(() => _isUploading = true);
    try {
      final url = await _storageService.uploadAvatar(imageFile);
      if (url != null) {
        setState(() => _avatarUrl = url);
        if (mounted) {
          _showSnackBar('Foto subida correctamente', isError: false);
        }
      } else {
        if (mounted) {
          _showSnackBar('Error al subir la foto');
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();
    final newAlias = _aliasController.text.trim().toLowerCase();

    if (newName.isEmpty) {
      _showSnackBar('El nombre no puede estar vacío');
      return;
    }

    if (newEmail.isEmpty || !newEmail.contains('@')) {
      _showSnackBar('Por favor, ingresa un correo válido');
      return;
    }

    if (newAlias.isNotEmpty && newAlias.length < 3) {
      _showSnackBar('El alias debe tener al menos 3 caracteres');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _supabase.auth.currentUser;
      final emailChanged = newEmail != _initialEmail;

      // Fetch current alias to check for changes if needed for logging/logic
      final currentAliasData = await _supabase
          .from('profiles')
          .select('username')
          .eq('id', user!.id)
          .maybeSingle();
      // ignore: unused_local_variable
      final currentAlias = currentAliasData?['username'] ?? '';

      // Update Auth Metadata & Email
      await _supabase.auth.updateUser(
        UserAttributes(
          email: emailChanged ? newEmail : null,
          data: {'full_name': newName},
        ),
      );

      // Update Public Profile (Trigger usually handles creation, we handle update here)
      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': newAlias.isEmpty ? null : newAlias,
        'full_name': newName,
        'avatar_url': _avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        String message = 'Perfil actualizado correctamente';
        if (emailChanged) {
          message +=
              '. Se ha enviado un enlace de confirmación a tu nuevo correo.';
        }

        _showSnackBar(message, isError: false);
        Navigator.pop(context, true);
      }
    } catch (e) {
      String errorMessage = 'Error al actualizar: ${e.toString()}';
      if (e.toString().contains('unique constraint') ||
          e.toString().contains('profiles_username_key')) {
        errorMessage =
            'El alias "$newAlias" ya está en uso por otro patinador.';
      }

      if (mounted) {
        _showSnackBar(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        duration: Duration(seconds: isError ? 3 : 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _isUploading
                        ? const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: _avatarUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Icon(
                              LucideIcons.user,
                              size: 60,
                              color: AppColors.textMuted,
                            ),
                          )
                        : const Icon(
                            LucideIcons.user,
                            size: 60,
                            color: AppColors.textMuted,
                          ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploading ? null : _pickAndUploadAvatar,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.camera,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Información Personal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Actualiza tu identidad para que otros patinadores puedan encontrarte.',
              style: TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              label: 'Nombre Completo',
              controller: _nameController,
              icon: LucideIcons.user,
              hint: 'Ej: Juan Pérez',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Alias Único (Opcional)',
              controller: _aliasController,
              icon: LucideIcons.atSign,
              hint: 'Ej: skater_pro',
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: 'Correo Electrónico',
              controller: _emailController,
              icon: LucideIcons.mail,
              hint: 'correo@ejemplo.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
