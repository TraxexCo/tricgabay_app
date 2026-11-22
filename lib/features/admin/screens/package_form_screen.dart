import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/error_messages.dart';
import '../../../core/services/fare_policy.dart';
import '../../../core/session/app_session.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../models/tourist_spot_model.dart';

/// Creates a tour package, or edits one when [package] is given: its name,
/// description, fixed price and the ordered stops the driver follows.
class PackageFormScreen extends StatefulWidget {
  const PackageFormScreen({super.key, this.package});

  final TourPackageModel? package;

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.package?.name);
  late final _description = TextEditingController(
    text: widget.package?.description,
  );
  late final _price = TextEditingController(
    text: widget.package == null
        ? ''
        : AppFormatters.decimalInput(AppSession.packageFare(widget.package!)),
  );
  late final List<String> _stops = List.of(widget.package?.spotIds ?? []);
  bool _saving = false;

  bool get _editing => widget.package != null;

  Map<String, TouristSpotModel> get _spots => {
    for (final spot in AppSession.allSpots.value) spot.id: spot,
  };

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _addStops() async {
    final available = AppSession.allSpots.value
        .where((spot) => spot.isActive && !_stops.contains(spot.id))
        .toList();
    final picked = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _StopPicker(spots: available),
    );
    if (picked == null || picked.isEmpty || !mounted) return;
    setState(() => _stops.addAll(picked));
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    if (_stops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.chooseTwoToTwelveDifferentStops)),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await AppSession.saveTourPackage(
        packageId: widget.package?.id,
        name: _name.text,
        description: _description.text,
        fareCents: FarePolicy.parsePrice(_price.text),
        spotIds: _stops,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.packageSavedValue(_name.text))),
      );
      context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.message(ErrorMessages.forError(error))),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spots = _spots;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editing ? context.l10n.editPackage : context.l10n.newPackage,
        ),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AppTextField(
              label: context.l10n.packageName,
              controller: _name,
              prefixIcon: Icons.tour_outlined,
              maxLength: 60,
              enabled: !_saving,
              validator: (value) => (value ?? '').trim().length < 3
                  ? context.l10n.enterAPackageNameOf3To60Characters
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.l10n.packagePrice,
              hint: '700',
              controller: _price,
              prefixIcon: Icons.payments_outlined,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_saving,
              validator: (value) {
                try {
                  final cents = FarePolicy.parsePrice(value ?? '');
                  return cents < 100 || cents > 10000000
                      ? context.l10n.enterAPriceBetween1And100000Pesos
                      : null;
                } catch (_) {
                  return context.l10n.enterAPriceBetween1And100000Pesos;
                }
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              label: context.l10n.packageDescriptionOptional,
              controller: _description,
              maxLines: 3,
              maxLength: 500,
              enabled: !_saving,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.stopsInOrder,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${_stops.length}/12',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ],
            ),
            Text(
              context.l10n.dragToReorderStops,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              onReorderItem: (from, to) => setState(() {
                _stops.insert(to, _stops.removeAt(from));
              }),
              children: [
                for (final (index, id) in _stops.indexed)
                  Container(
                    key: ValueKey(id),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        radius: 15,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(spots[id]?.name ?? id),
                      subtitle: spots[id] == null
                          ? null
                          : Text(context.message(spots[id]!.categoryLabel)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.l10n.removeStop,
                            icon: const Icon(Icons.close_rounded),
                            onPressed: _saving
                                ? null
                                : () => setState(() => _stops.remove(id)),
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.drag_handle_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            OutlinedButton.icon(
              onPressed: _saving || _stops.length >= 12 ? null : _addStops,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(context.l10n.addStops),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      _editing
                          ? context.l10n.saveChanges
                          : context.l10n.createPackage,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.packagePriceChangeNote,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select list of tourist spots that aren't in the package yet.
class _StopPicker extends StatefulWidget {
  const _StopPicker({required this.spots});

  final List<TouristSpotModel> spots;

  @override
  State<_StopPicker> createState() => _StopPickerState();
}

class _StopPickerState extends State<_StopPicker> {
  final _picked = <String>[];

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.addStops,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            FilledButton(
              onPressed: _picked.isEmpty
                  ? null
                  : () => Navigator.pop(context, _picked),
              child: Text(context.l10n.addCountValue(_picked.length)),
            ),
          ],
        ),
      ),
      Expanded(
        child: widget.spots.isEmpty
            ? Center(child: Text(context.l10n.everySpotIsAlreadyInThisPackage))
            : ListView(
                children: [
                  for (final spot in widget.spots)
                    CheckboxListTile(
                      value: _picked.contains(spot.id),
                      title: Text(spot.name),
                      subtitle: Text(context.message(spot.categoryLabel)),
                      onChanged: (checked) => setState(
                        () => checked == true
                            ? _picked.add(spot.id)
                            : _picked.remove(spot.id),
                      ),
                    ),
                ],
              ),
      ),
    ],
  );
}
