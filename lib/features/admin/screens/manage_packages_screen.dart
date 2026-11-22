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

/// The tours tourists can book. Admins add, edit and delete them here; each
/// package is a fixed route of tourist spots with one price.
class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});

  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.packageDeletedValue(package.name)),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleting = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.tourPackages)),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => context.push(AppRoutes.packageForm),
      icon: const Icon(Icons.add_rounded),
      label: Text(context.l10n.newPackage),
    ),
    body: ValueListenableBuilder<List<TourPackageModel>>(
      valueListenable: AppSession.tourPackages,
      builder: (context, packages, _) {
        if (packages.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.tour_outlined,
            title: context.l10n.noTourPackagesYet,
            subtitle: context.l10n.noTourPackagesYetBody,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
          itemCount: packages.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _PackageTile(
            package: packages[index],
            busy: _deleting == packages[index].id,
            onEdit: () =>
                context.push(AppRoutes.packageForm, extra: packages[index]),
            onDelete: () => _delete(packages[index]),
          ),
        );
      },
    ),
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
    final names = {for (final s in AppSession.allSpots.value) s.id: s.name};
    final route = package.spotIds.map((id) => names[id] ?? id).join('  ›  ');
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: SafeAppImage(
                    path: AppSession.packageImage(package),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.message(package.name),
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₱${AppFormatters.integer(AppSession.packageFare(package))} · ${context.l10n.stopsValue(package.spotIds.length.toString())}',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (busy)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<String>(
                  tooltip: context.l10n.packageOptions,
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: const Icon(Icons.edit_outlined),
                        title: Text(context.l10n.editPackage),
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
                          context.l10n.deletePackage,
                          style: const TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
