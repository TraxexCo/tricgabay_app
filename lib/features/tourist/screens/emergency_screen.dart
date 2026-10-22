import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_card.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text(
          'Emergency',
          style: GoogleFonts.poppins(
            color: AppColors.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.danger),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_controller.value * 0.1),
                  child: GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Call emergency services?'),
                          content: const Text(
                            'This opens your phone dialer with 911. You must press Call to contact emergency services.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.danger,
                              ),
                              onPressed: () async {
                                Navigator.pop(ctx);
                                final uri = Uri(scheme: 'tel', path: '911');
                                final launched = await launchUrl(uri);
                                if (!mounted) return;
                                if (!launched) {
                                  ScaffoldMessenger.of(
                                    this.context,
                                  ).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not open the phone dialer. Call 911 manually.',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'OPEN DIALER',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.danger.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'SOS',
                          style: GoogleFonts.poppins(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'For immediate danger, call 911. Tric-Gabay does not replace emergency services.',
              style: GoogleFonts.poppins(
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Emergency Contacts',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildContact(
              'National Emergency Hotline',
              '911',
              Icons.emergency_outlined,
            ),
            const SizedBox(height: 24),
            Text(
              'Official emergency numbers from municipality portal.',
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(String name, String number, IconData icon) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.danger.withValues(alpha: 0.1),
          child: Icon(icon, color: AppColors.danger),
        ),
        title: Text(
          name,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          number,
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.call, color: AppColors.success),
          onPressed: () async {
            final uri = Uri(scheme: 'tel', path: number);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open phone dialer.')),
                );
              }
            }
          },
        ),
      ),
    );
  }
}
