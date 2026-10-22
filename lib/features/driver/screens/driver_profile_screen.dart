import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';

class DriverProfileScreen extends StatelessWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F8FB),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 106),
        children: [
          Row(
            children: [
              Text(
                'Driver account',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.push('/driver/profile/edit'),
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF1B6CA8)],
              ),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    const CircleAvatar(
                      radius: 31,
                      backgroundColor: Color(0x33FFFFFF),
                      child: Icon(
                        Icons.person_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<String>(
                        valueListenable: PrototypeSession.currentDriverName,
                        builder: (context, name, _) => Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        'ABC 1234 • Accredited driver',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: .25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'VERIFIED',
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              ValueListenableBuilder(
                valueListenable: PrototypeSession.bookings,
                builder: (context, bookings, _) => _stat(
                  PrototypeSession.driverTripsCompleted.toString(),
                  'Trips',
                  Icons.route_outlined,
                ),
              ),
              const SizedBox(width: 10),
              _stat('4.9', 'Rating', Icons.star_rounded),
              const SizedBox(width: 10),
              _stat('1 yr', 'Member', Icons.calendar_today_outlined),
            ],
          ),
          const SizedBox(height: 25),
          Text(
            'Driver tools',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _tile(
            context,
            Icons.person_outline_rounded,
            'Personal information',
            'Update your driver details',
            '/driver/profile/edit',
          ),
          _tile(
            context,
            Icons.receipt_long_outlined,
            'Trip history',
            'Completed and active bookings',
            '/driver/bookings',
          ),
          _tile(
            context,
            Icons.verified_user_outlined,
            'Verification status',
            'Accreditation verified',
            '',
            trailing: const Text(
              'Verified',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your accreditation is verified')),
            ),
          ),
          _tile(
            context,
            Icons.notifications_none_rounded,
            'Notifications',
            'Booking and system updates',
            '/driver/notifications',
          ),
          const SizedBox(height: 19),
          Text(
            'Safety & support',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _tile(
            context,
            Icons.sos_outlined,
            'Emergency help',
            'Local contacts and SOS',
            '/driver/emergency',
            color: AppColors.danger,
          ),
          _tile(
            context,
            Icons.help_outline_rounded,
            'Help & support',
            'Send a support message',
            '',
            onTap: () => context.push('/tourist/feedback'),
          ),
          const SizedBox(height: 15),
          TextButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log out'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        context.pop();
                        await PrototypeSession.signOut();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text(
                        'Log out',
                        style: TextStyle(color: AppColors.danger),
                      ),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
            label: const Text(
              'Log out',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stat(String value, String label, IconData icon) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    String route, {
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap ?? () => context.push(route),
        borderRadius: BorderRadius.circular(17),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (color ?? AppColors.primary).withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color ?? AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child:
                    trailing ??
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
