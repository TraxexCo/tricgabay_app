import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/booking_model.dart';
import '../../../core/utils/app_translations.dart';

class TouristProfileScreen extends StatelessWidget {
  const TouristProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: PrototypeSession.isFilipino,
    builder: (context, isFilipino, _) => Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 106),
          children: [
            Row(
              children: [
                Text(
                  context.tr('Your account', 'Ang iyong account'),
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.push('/tourist/profile/edit'),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
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
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: PrototypeSession.currentUserName,
                          builder: (context, name, _) => Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          'maria@example.com',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: Color(0xFFFFD166),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              context.tr(
                                'Verified tourist',
                                'Na-verify na turista',
                              ),
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            ValueListenableBuilder<List<dynamic>>(
              valueListenable: PrototypeSession.bookings,
              builder: (ctx, bookingList, _) {
                return ValueListenableBuilder<Set<String>>(
                  valueListenable: PrototypeSession.favorites,
                  builder: (ctx2, favSet, _) {
                    final tripCount = bookingList
                        .where((b) => b.status == BookingStatus.completed)
                        .length;
                    final savedCount = favSet.length;
                    return Row(
                      children: [
                        _stat('$tripCount', context.tr('Trips', 'Biyahe')),
                        const SizedBox(width: 10),
                        _stat('$savedCount', context.tr('Saved', 'Naka-save')),
                        const SizedBox(width: 10),
                        _stat('4.9', context.tr('Rating', 'Rating')),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 25),
            Text(
              context.tr('Your travel', 'Ang iyong paglalakbay'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _tile(
              context,
              Icons.receipt_long_outlined,
              context.tr('Booking history', 'Kasaysayan ng Booking'),
              context.tr(
                'Your rides and receipts',
                'Iyong mga sakay at resibo',
              ),
              '/tourist/bookings',
            ),
            _tile(
              context,
              Icons.favorite_outline_rounded,
              context.tr('Saved places', 'Mga Paborito'),
              context.tr(
                'Destinations you love',
                'Mga destinasyon na gusto mo',
              ),
              '/tourist/favorites',
            ),
            _tile(
              context,
              Icons.tour_outlined,
              context.tr('Tour packages', 'Mga Tour Package'),
              context.tr('Ready-made days out', 'Handang mga biyahe'),
              '/tourist/tour-packages',
            ),
            const SizedBox(height: 19),
            Text(
              context.tr('Support & settings', 'Suporta at setting'),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _tile(
              context,
              Icons.notifications_none_rounded,
              context.tr('Notifications', 'Mga Notification'),
              context.tr(
                'Ride and booking updates',
                'Mga update sa sakay at booking',
              ),
              '/tourist/notifications',
            ),
            _tile(
              context,
              Icons.sos_outlined,
              context.tr('Emergency help', 'Tulong sa Emergency'),
              context.tr(
                'Local contacts and SOS',
                'Mga lokal na contact at SOS',
              ),
              '/tourist/emergency',
              color: AppColors.danger,
            ),
            _tile(
              context,
              Icons.chat_bubble_outline_rounded,
              context.tr('Send feedback', 'Magpadala ng feedback'),
              context.tr(
                'Tell us what to improve',
                'Sabihin kung ano ang dapat pagandahin',
              ),
              '/tourist/feedback',
            ),
            _tile(
              context,
              Icons.language_rounded,
              context.tr('Language', 'Wika'),
              isFilipino ? 'Filipino' : 'English',
              '',
              onTap: () => _languageSheet(context),
            ),
            const SizedBox(height: 15),
            TextButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.tr('Log Out?', 'Mag-log Out?')),
                    content: Text(
                      context.tr(
                        'Are you sure you want to log out of Tric Gabay?',
                        'Sigurado ka bang gusto mong mag-log out sa Tric Gabay?',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.tr('Cancel', 'Kanselahin')),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text(
                          context.tr('Log Out', 'Mag-log Out'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await PrototypeSession.signOut();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppColors.danger),
              label: Text(
                context.tr('Log out', 'Mag-log Out'),
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Attraction and fare information is synchronized with Tric-Gabay.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );

  Widget _stat(String value, String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            label,
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
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
            ],
          ),
        ),
      ),
    ),
  );
  void _languageSheet(BuildContext context) => showModalBottomSheet(
    context: context,
    builder: (sheet) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('English'),
            onTap: () {
              PrototypeSession.isFilipino.value = false;
              Navigator.pop(sheet);
            },
          ),
          ListTile(
            title: const Text('Filipino'),
            onTap: () {
              PrototypeSession.isFilipino.value = true;
              Navigator.pop(sheet);
            },
          ),
        ],
      ),
    ),
  );
}
