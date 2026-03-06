import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../services/database_service.dart';
import '../models/training_summary.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _databaseService = DatabaseService();
  final _supabase = Supabase.instance.client;
  User? get _user => _supabase.auth.currentUser;

  List<TrainingSummary> _allTrainings = [];
  bool _isLoading = true;
  String? _username;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    // Fetch profile data (alias)
    try {
      if (_user != null) {
        final profileData = await _supabase
            .from('profiles')
            .select('username, avatar_url')
            .eq('id', _user!.id)
            .maybeSingle();
        if (profileData != null) {
          setState(() {
            _username = profileData['username'];
            _avatarUrl = profileData['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading username: $e');
    }

    // Fetch a large number to calculate aggregate stats for now
    final trainings = await _databaseService.getRecentTrainings(limit: 100);
    if (mounted) {
      setState(() {
        _allTrainings = trainings;
        _isLoading = false;
      });
    }
  }

  double get _totalDistance {
    return _allTrainings.fold(
      0.0,
      (sum, t) => sum + (t.totalLaps * 0.2),
    ); // Assuming 200m track
  }

  double get _avgSpeed {
    if (_allTrainings.isEmpty) return 0.0;
    final sum = _allTrainings.fold(0.0, (sum, t) => sum + t.sessionAvgSpeed);
    return double.parse((sum / _allTrainings.length).toStringAsFixed(2));
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cerrar Sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Estás seguro de que quieres salir?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        title: const Text(
          'Perfil',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildUserHeader(),
                    const SizedBox(height: 32),
                    _buildStatsGrid(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserHeader() {
    final fullName = _user?.userMetadata?['full_name'] ?? 'Patinador';
    final email = _user?.email ?? '';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'P';

    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: (_avatarUrl != null && _avatarUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: _avatarUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(
          fullName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (_username != null && _username!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '@$_username',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Text(email, style: const TextStyle(color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              'Sesiones',
              _allTrainings.length.toString(),
              LucideIcons.calendar,
              AppColors.primary,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Vueltas Totales',
              _allTrainings.fold(0, (sum, t) => sum + t.totalLaps).toString(),
              LucideIcons.rotateCcw,
              AppColors.warning,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildStatCard(
              'Distancia Total',
              '${_totalDistance.toStringAsFixed(1)} km',
              LucideIcons.mapPin,
              AppColors.success,
            ),
            const SizedBox(width: 16),
            _buildStatCard(
              'Vel. Promedio',
              '$_avgSpeed km/h',
              LucideIcons.zap,
              AppColors
                  .intensityHigh, // Use intensityHigh (violet) as requested in guidelines
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildListButton('Editar Perfil', LucideIcons.user, () async {
          final result = await Navigator.pushNamed(context, '/edit_profile');
          if (result == true) {
            _loadProfileData();
          }
        }),
        const SizedBox(height: 12),
        _buildListButton('Configuración', LucideIcons.settings, () {}),
        const SizedBox(height: 12),
        _buildListButton(
          'Cerrar Sesión',
          LucideIcons.logOut,
          _handleLogout,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildListButton(
    String label,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDestructive ? AppColors.error : Colors.white,
              ),
            ),
            const Spacer(),
            Icon(
              LucideIcons.chevronRight,
              color: AppColors.textMuted.withValues(alpha: 0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
