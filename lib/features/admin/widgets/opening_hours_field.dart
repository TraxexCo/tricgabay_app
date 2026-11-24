import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/opening_hours.dart';

export '../../../core/utils/opening_hours.dart';

/// Opening hours set with day chips and time pickers instead of free text.
class OpeningHoursField extends StatefulWidget {
  const OpeningHoursField({
    super.key,
    required this.initial,
    required this.onChanged,
  });

  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<OpeningHoursField> createState() => _OpeningHoursFieldState();
}

class _OpeningHoursFieldState extends State<OpeningHoursField> {
  late bool _allDay = widget.initial == OpeningHoursText.open24;
  late final List<HoursBlock>? _parsed = OpeningHoursText.parse(widget.initial);

  /// Old free text (e.g. "Check locally") is kept until the admin sets hours.
  late bool _keepOld =
      !_allDay && _parsed == null && widget.initial.trim().isNotEmpty;
  late final List<HoursBlock> _blocks =
      _parsed ??
      [
        HoursBlock(
          {1, 2, 3, 4, 5},
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 17, minute: 0),
        ),
      ];

  @override
  void initState() {
    super.initState();
    // A new place starts with the default hours filled in.
    if (widget.initial.trim().isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
    }
  }

  void _emit() =>
      widget.onChanged(OpeningHoursText.format(_blocks, allDay: _allDay));

  void _update(VoidCallback change) {
    setState(() {
      _keepOld = false;
      change();
    });
    _emit();
  }

  Future<void> _pickTime(HoursBlock block, bool opening) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? block.opens : block.closes,
      helpText: opening
          ? context.l10n.hoursOpensAt
          : context.l10n.hoursClosesAt,
    );
    if (picked == null || !mounted) return;
    // A place can't close before it opens.
    final minutes = picked.hour * 60 + picked.minute;
    final other = opening
        ? block.closes.hour * 60 + block.closes.minute
        : block.opens.hour * 60 + block.opens.minute;
    if (opening ? minutes >= other : minutes <= other) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.hoursCloseAfterOpen)));
      return;
    }
    _update(() {
      if (opening) {
        block.opens = picked;
      } else {
        block.closes = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final localeDays = DateFormat.E(Localizations.localeOf(context).toString());
    String dayLabel(int day) =>
        localeDays.format(DateTime(2024, 1, day)); // 1 Jan 2024 is a Monday.
    final summary = _keepOld
        ? l.hoursCurrentValue(widget.initial)
        : OpeningHoursText.format(_blocks, allDay: _allDay);
    return Material(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l.openingHours,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.hoursOpen24),
              value: _allDay,
              onChanged: (value) => _update(() => _allDay = value),
            ),
            if (!_allDay) ...[
              for (final (index, block) in _blocks.indexed) ...[
                if (index > 0) const Divider(height: 24),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var day = 1; day <= 7; day++)
                      FilterChip(
                        showCheckmark: false,
                        label: Text(dayLabel(day)),
                        selected: block.days.contains(day),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: block.days.contains(day)
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        onSelected: (on) => _update(() {
                          if (on) {
                            block.days.add(day);
                          } else {
                            block.days.remove(day);
                          }
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _timeButton(
                        l.hoursOpensAt,
                        block.opens,
                        () => _pickTime(block, true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _timeButton(
                        l.hoursClosesAt,
                        block.closes,
                        () => _pickTime(block, false),
                      ),
                    ),
                    if (_blocks.length > 1)
                      IconButton(
                        tooltip: l.hoursRemoveSchedule,
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.danger,
                        ),
                        onPressed: () => _update(() => _blocks.removeAt(index)),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _update(
                    () => _blocks.add(
                      HoursBlock(
                        {6, 7},
                        const TimeOfDay(hour: 8, minute: 0),
                        const TimeOfDay(hour: 17, minute: 0),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l.hoursAddSchedule),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                summary.isEmpty ? l.hoursPickDays : context.message(summary),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: summary.isEmpty
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeButton(
    String label,
    TimeOfDay time,
    VoidCallback onTap,
  ) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      alignment: Alignment.centerLeft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        Text(
          time.format(context),
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
