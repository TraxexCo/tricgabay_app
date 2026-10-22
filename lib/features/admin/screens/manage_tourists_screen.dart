import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';

class ManageTouristsScreen extends StatelessWidget {
  const ManageTouristsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Manage Tourists',
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: PrototypeSession.adminTourists,
        builder: (context, tourists, _) {
          if (tourists.isEmpty) {
            return const EmptyStateWidget(
              title: 'No Tourists Found',
              subtitle: 'There are no registered tourists yet.',
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tourists.length,
            itemBuilder: (context, index) {
              final tourist = tourists[index];
              final isActive = tourist['status'] == 'active';

              return AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                        tourist['name'][0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tourist['name'],
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tourist['email'],
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Trips: ${tourist['trips']}',
                            style: GoogleFonts.poppins(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatusBadge(
                            label: isActive ? 'Active' : 'Suspended',
                            color: isActive
                                ? AppColors.success
                                : AppColors.danger,
                            textColor: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle_outline,
                        color: isActive ? AppColors.danger : AppColors.success,
                      ),
                      onPressed: () {
                        PrototypeSession.toggleTouristStatus(tourist['id']);
                      },
                      tooltip: isActive
                          ? 'Suspend Tourist'
                          : 'Activate Tourist',
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
