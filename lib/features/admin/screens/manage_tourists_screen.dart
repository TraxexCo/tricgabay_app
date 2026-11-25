import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/widgets/remote_page_controls.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import '../../../core/motion/motion_widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';

class ManageTouristsScreen extends StatefulWidget {
  const ManageTouristsScreen({super.key, this.onToggleStatus});

  /// Suspends or reactivates a tourist. Defaults to the server action;
  /// tests pass their own.
  final Future<void> Function(String id, {required String reason})?
  onToggleStatus;

  @override
  State<ManageTouristsScreen> createState() => _ManageTouristsScreenState();
}

class _ManageTouristsScreenState extends State<ManageTouristsScreen> {
  final Set<String> _pending = {};

  Future<void> _toggle(Map<String, dynamic> tourist) async {
    final id = tourist['id'] as String;
    if (_pending.contains(id)) return;
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          context.message(
            tourist['status'] == 'active'
                ? MessageCode.suspendTourist
                : MessageCode.restoreTourist,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: context.l10n.reasonAtLeast5Characters,
          ),
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          scrollPadding: const EdgeInsets.all(96),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().length >= 5) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: Text(context.l10n.confirmChange),
          ),
        ],
      ),
    );
    // The dialog's route disposes after its closing animation.
    if (reason == null || !mounted) return;
    setState(() => _pending.add(id));
    try {
      await (widget.onToggleStatus ?? AppSession.toggleTouristStatus)(
        id,
        reason: reason,
      );
      if (!mounted) return;
      final activated = tourist['status'] != 'active';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.message(
              activated
                  ? MessageCode.touristAccountActivated
                  : MessageCode.touristAccountSuspended,
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.message(ErrorMessages.forError(error))),
          action: SnackBarAction(
            label: context.l10n.refresh,
            onPressed: () => AppSession.syncRemoteState(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _pending.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const RemotePageControls(directory: true),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.l10n.manageTourists,
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
        valueListenable: AppSession.adminTourists,
        builder: (context, tourists, _) {
          if (tourists.isEmpty) {
            return EmptyStateWidget(
              title: context.l10n.noTouristsFound,
              subtitle: context.l10n.thereAreNoRegisteredTouristsYet,
              icon: Icons.people_outline,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tourists.length,
            itemBuilder: (context, index) => FadeSlideIn.staggered(
              index: index,
              child: Builder(
                builder: (context) {
                  final tourist = tourists[index];
                  final isActive = tourist['status'] == 'active';
                  final pending = _pending.contains(tourist['id']);

                  return AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            context.message(tourist['name'][0]).toUpperCase(),
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
                                context.message(tourist['name']),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.message(tourist['email']),
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.l10n.tripsValue(
                                  context.message('${tourist['trips'] ?? 0}'),
                                ),
                                style: GoogleFonts.poppins(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatusBadge(
                                label: isActive
                                    ? MessageCode.active
                                    : MessageCode.suspended,
                                color: isActive
                                    ? AppColors.success
                                    : AppColors.danger,
                                textColor: Colors.white,
                              ),
                            ],
                          ),
                        ),
                        Semantics(
                          label: context.message(
                            isActive
                                ? MessageCode.suspendValue(
                                    (tourist['name']).toString(),
                                  )
                                : MessageCode.activateValue(
                                    (tourist['name']).toString(),
                                  ),
                          ),
                          button: true,
                          enabled: !pending,
                          child: IconButton(
                            icon: pending
                                ? const SizedBox.square(
                                    dimension: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    isActive
                                        ? Icons.block
                                        : Icons.check_circle_outline,
                                    color: isActive
                                        ? AppColors.danger
                                        : AppColors.success,
                                  ),
                            onPressed: pending ? null : () => _toggle(tourist),
                            tooltip: context.message(
                              isActive
                                  ? MessageCode.suspendTouristLabel
                                  : MessageCode.activateTourist,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
