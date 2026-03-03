import 'package:flutter/material.dart';
import '../theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        _buildFeaturedSection(),
                        _buildStickyFilter(),
                        _buildUpcomingSection(),
                        const SizedBox(height: 100), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hola, Javier 👋',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to crush your goals today?',
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1D21),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
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

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Featured Classes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {},
                child: Row(
                  children: const [
                    Text('See All', style: TextStyle(color: AppColors.primary)),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 360,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildFeaturedCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuB6Fc-f51JX3lW_STvey0uNu6Ft29MdcnFCU6b3batWN2hFQMtW09B9-TzYuQT6ZCiSnvqUxUBiXGRbgnHJZacmFE7i02axM0Kbc9q4ECaC3Ed6clRMgmPP5JP_2yRiiDgl-DqLL70pB4_2wMHZyNaoEKQpx-EBtTKJDoG-3ovJyNLNUTwePapQEu6Vcgd7Exm58JAuhFlgWtzOo36pdwu__XFeiEy_WLQ0TzJLTgLbKFwqKQHTfioQpdIwO4PTVwe4hrYTdCBQzUX_',
                title: 'CrossFit WOD',
                tag: 'High Intensity',
                time: '18:00',
                duration: '60 min',
                spots: '4 Spots',
                isFull: false,
              ),
              const SizedBox(width: 16),
              _buildFeaturedCard(
                imageUrl:
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDWwsMz0WJzF92gYYIDCTW_A7i8EZ-kIK82PBuQrGe17TDb_ED4AcjJWTpQ9xFC_9CBOiIaf-ftqHZOn8OETvkqf69eEKRTXWB71wObTPsZMxGmC07nYMYtOuZd7m2S2TvoTGYPH1r8beEFog_k_kIMRVT6OqbiE2hK2V5HvShyltniUfQP3PNWAr5UubW-iPaYxgtEp6938R3jqQ4khTA2yQb5W_8rj7mzJcUUoMMkiDqRwUbnBxbsu-YDUSBzylhxkr_hUdGguIdl',
                title: 'Power Yoga',
                tag: 'Flexibility',
                time: '07:00',
                duration: '45 min',
                spots: 'Full',
                isFull: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard({
    required String imageUrl,
    required String title,
    required String tag,
    required String time,
    required String duration,
    required String spots,
    bool isFull = false,
  }) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isFull)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF78CC33),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (!isFull) const SizedBox(width: 6),
                    Text(
                      spots,
                      style: TextStyle(
                        color: isFull ? Colors.redAccent : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(
                tag.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white54, size: 16),
                const SizedBox(width: 4),
                Text(
                  time,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isFull ? null : () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isFull
                    ? const Color(0xFF1A1D21)
                    : AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isFull ? 'Join Waitlist' : 'Reservar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            _buildFilterChip('All Classes', isActive: true),
            _buildFilterChip('Cardio'),
            _buildFilterChip('Strength'),
            _buildFilterChip('Morning'),
            _buildFilterChip('Evening'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text(label),
        onPressed: () {},
        backgroundColor: isActive ? AppColors.primary : Colors.transparent,
        labelStyle: TextStyle(
          color: isActive ? Colors.white : AppColors.textMuted,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isActive ? Colors.transparent : Colors.white.withOpacity(0.1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUpcomingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Upcoming Classes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1D21),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '3',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildUpcomingItem(
            day: 'Today',
            time: '19:00',
            title: 'HIIT Advanced',
            subtitle: 'Coach Sarah',
            duration: '45m',
            status: 'Confirmed',
            statusColor: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildUpcomingItem(
            day: 'Tmrw',
            time: '08:00',
            title: 'Spin Cycle',
            subtitle: 'Coach Mike',
            duration: '60m',
            status: 'Waitlist',
            statusColor: Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildUpcomingItem(
            day: 'Fri',
            time: '12:00',
            title: 'Open Gym',
            subtitle: 'Main Floor',
            duration: '',
            status: 'Past',
            statusColor: Colors.grey,
            isPast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingItem({
    required String day,
    required String time,
    required String title,
    required String subtitle,
    required String duration,
    required String status,
    required Color statusColor,
    bool isPast = false,
  }) {
    return Opacity(
      opacity: isPast ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D21),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Text(
                    day.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        isPast ? Icons.location_on : Icons.person_outline,
                        color: AppColors.primary,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      if (duration.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.timer_outlined,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          duration,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF121416).withOpacity(0.95),
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_filled, 'Home', isActive: true),
            _buildNavItem(Icons.calendar_today_outlined, 'Schedule'),
            _buildNavItem(Icons.person_outline, 'Profile'),
            _buildNavItem(Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 26,
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
    );
  }
}
