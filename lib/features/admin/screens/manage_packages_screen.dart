import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/session/app_session.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/tourist_spot_model.dart';
import '../widgets/admin_ui.dart';

/// The tours tourists can book. Admins add, edit and delete them here; each
/// package is a fixed route of tourist spots with one price.
class ManagePackagesScreen extends StatelessWidget {
  const ManagePackagesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tourPackages)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push(AppRoutes.packageForm),
      icon: const Icon(Icons.add_rounded),
      label: Text(context.l10n.newPackage),
    ),
    body: const TourPackagesAdminList(),
  );
}

/// The package list, also shown on the Places tab.
class TourPackagesAdminList extends StatefulWidget {
  const TourPackagesAdminList({super.key});

  @override
  State<TourPackagesAdminList> createState() => _TourPackagesAdminListState();
}

class _TourPackagesAdminListState extends State<TourPackagesAdminList> {
  String? _deleting;

  Future<void> _delete(TourPackageModel package) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.deletePackageValue(package.name)),
        content: Text(context.l10n.deletePackageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.l10n.keepPackage),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.l10n.deletePackage),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = package.id);
    try {
      await AppSession.deleteTourPackage(package.id);
      if (mounted) {
        showAdminToast(context, context.l10n.packageDeletedValue(package.name));
      }
    } catch (error) {
      if (mounted) {
        showAdminToast(context, ErrorMessages.forError(error), error: true);
      }
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<List<TourPackageModel>>(
        valueListenable: AppSession.tourPackages,
        builder: (context, packages, _) {
          if (packages.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.tour_outlined,
              title: context.l10n.noTourPackagesYet,
              subtitle: context.l10n.noTourPackagesYetBody,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 104),
            itemCount: packages.length,
            itemBuilder: (context, index) => _PackageTile(
              package: packages[index],
              busy: _deleting == packages[index].id,
              onEdit: () =>
                  context.push(AppRoutes.packageForm, extra: packages[index]),
              onDelete: () => _delete(packages[index]),
            ),
          );
        },
      );
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.package,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  final TourPackageModel package;
  final bool busy;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final names = {for (final s in AppSession.allSpots.value) s.id: s.name};
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: busy ? null : onEdit,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SafeAppImage(
                      path: AppSession.packageImage(package),
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC001F5C)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 60,
                      bottom: 12,
                      child: Text(
                        context.message(package.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '₱${AppFormatters.integer(AppSession.packageFare(package))}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textOnSecondary,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: busy
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : Material(
                              color: Colors.black.withValues(alpha: .35),
                              shape: const CircleBorder(),
                              child: PopupMenuButton<String>(
                                tooltip: l.packageOptions,
                                iconColor: Colors.white,
                                onSelected: (value) =>
                                    value == 'edit' ? onEdit() : onDelete(),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: ListTile(
                                      leading: const Icon(Icons.edit_outlined),
                                      title: Text(l.editPackage),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.danger,
                                      ),
                                      title: Text(
                                        l.deletePackage,
                                        style: const TextStyle(
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.stopsValue(package.spotIds.length.toString()),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final (i, id) in package.spotIds.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: AppColors.surfaceVariant,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                names[id] ?? id,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
