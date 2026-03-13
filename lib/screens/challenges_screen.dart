import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme.dart';
import '../services/database_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final _databaseService = DatabaseService();
  bool _isLoading = true;
  
  int _totalTrainings = 0;
  double _totalDistance = 0.0;
  int _totalLaps = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Fetch an arbitrary large number to calculate total stats. 
    // In a real large app, you'd use a specific RPC or aggregate query.
    final trainings = await _databaseService.getRecentTrainings(limit: 1000);
    
    int tempTotalLaps = 0;
    double tempTotalDistance = 0.0;
    
    for (var t in trainings) {
      tempTotalLaps += t.totalLaps;
      // We assume a 200m track for history if not strictly recorded, or we'd ideally get it from DB.
      // For this challenges calculation, we'll use a standard 200m or assume we don't have per-training track length here,
      // but if we *really* need it, we should use the getTrainingStats logic or aggregate.
      // Since TrainingSummary lacks track_length_meters, we'll approximate with 0.2km.
      tempTotalDistance += (t.totalLaps * 0.2); 
    }

    if (mounted) {
      setState(() {
        _totalTrainings = trainings.length;
        _totalLaps = tempTotalLaps;
        _totalDistance = double.parse(tempTotalDistance.toStringAsFixed(1));
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    _buildAppBar(),
                    _buildHeroSection(),
                    _buildChallengesList(),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
            ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/training');
        },
        backgroundColor: AppColors.primary,
        child: const Icon(LucideIcons.play, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildAppBar() {
    return SliverPadding(
      padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: 8.0),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            const Icon(LucideIcons.trophy, color: AppColors.warning, size: 28),
            const SizedBox(width: 12),
            Text(
              'Desafíos',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    // Determine level based on total trainings
    int level = (_totalTrainings / 5).floor() + 1;
    if (level > 20) level = 20; // Cap at 20 just as an example
    
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)], // Violet gradient
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Nivel Actual',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Nivel $level',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 36),
              ),
              const SizedBox(height: 12),
              Text(
                '¡Has completado $_totalTrainings entrenamientos!',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengesList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const SizedBox(height: 8),
          const Text(
            'Tus Metas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildChallengeCard(
            title: 'Constancia',
            description: 'Completa 10 entrenamientos. ¡Sigue así!',
            icon: LucideIcons.flame,
            iconColor: AppColors.error,
            currentValue: _totalTrainings.toDouble(),
            targetValue: 10.0,
            unit: 'sesiones',
          ),
          const SizedBox(height: 16),
          _buildChallengeCard(
            title: 'Maratonista',
            description: 'Acumula 42 km recorridos en total.',
            icon: LucideIcons.mapPin,
            iconColor: AppColors.success,
            currentValue: _totalDistance,
            targetValue: 42.0,
            unit: 'km',
          ),
          const SizedBox(height: 16),
          _buildChallengeCard(
            title: 'Centurión',
            description: 'Supera las 100 vueltas en el patinódromo.',
            icon: LucideIcons.rotateCcw,
            iconColor: AppColors.warning,
            currentValue: _totalLaps.toDouble(),
            targetValue: 100.0,
            unit: 'vueltas',
          ),
          const SizedBox(height: 16),
          _buildChallengeCard(
            title: 'Maestro de la Pista',
            description: 'Realiza 50 entrenamientos en total.',
            icon: LucideIcons.star,
            iconColor: AppColors.primary,
            currentValue: _totalTrainings.toDouble(),
            targetValue: 50.0,
            unit: 'sesiones',
          ),
        ]),
      ),
    );
  }

  Widget _buildChallengeCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required double currentValue,
    required double targetValue,
    required String unit,
  }) {
    double progress = currentValue / targetValue;
    if (progress > 1.0) progress = 1.0;
    final isCompleted = progress >= 1.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCompleted ? iconColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
          width: isCompleted ? 2 : 1,
        ),
        boxShadow: isCompleted 
            ? [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? iconColor.withValues(alpha: 0.2) : AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.check, color: Colors.white, size: 16),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progreso: ${currentValue.toStringAsFixed(unit == 'km' ? 1 : 0)} / ${targetValue.toInt()} $unit',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: isCompleted ? AppColors.success : AppColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.backgroundDark,
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.success : iconColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: AppColors.surfaceDark,
      padding: EdgeInsets.zero,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(LucideIcons.home, 'Inicio', false, () {
              Navigator.pushReplacementNamed(context, '/home');
            }),
            _buildNavItem(LucideIcons.calendar, 'Calendario', false, () {
              Navigator.pushNamed(context, '/calendar');
            }),
            const SizedBox(width: 40), // Space for FAB
            _buildNavItem(LucideIcons.trophy, 'Desafíos', true, () {}),
            _buildNavItem(LucideIcons.user, 'Perfil', false, () {
              Navigator.pushNamed(context, '/profile');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textMuted,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
