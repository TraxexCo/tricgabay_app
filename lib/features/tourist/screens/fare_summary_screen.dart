import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/constants/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import '../../../models/booking_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/config/tour_schedule.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../payment/outstanding_fare_banner.dart';

class FareSummaryScreen extends StatefulWidget {
  const FareSummaryScreen({super.key});
  @override
  State<FareSummaryScreen> createState() => _FareSummaryScreenState();
}

class _FareSummaryScreenState extends State<FareSummaryScreen> {
  bool _busy = false;
  bool _agreed = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  int _passengerCount = AppSession.draft.passengerCount;
  // Tours run on a chosen day from the tourism office; the tourist picks the
  // day and a start time inside office hours (see TourSchedule).
  late List<DateTime> _days = TourSchedule.bookableDays();
  DateTime? _day;
  DateTime? _scheduledAt;
  late final TextEditingController _luggageNotes;
  late final TextEditingController _accessibilityNeeds;
  @override
  void initState() {
    super.initState();
    _luggageNotes = TextEditingController(text: AppSession.draft.luggageNotes);
    _accessibilityNeeds = TextEditingController(
      text: AppSession.draft.accessibilityNeeds,
    );
    AppSession.farePolicy.addListener(_priceChanged);
    _restoreSchedule();
    _checkOnlineDrivers();
  }

  /// Keeps a still-valid earlier choice; otherwise picks the first open
  /// start time.
  void _restoreSchedule() {
    _days = TourSchedule.bookableDays();
    final previous = AppSession.draft.scheduledAt;
    if (previous != null) {
      final local = ServerClock.manila(previous);
      final day = _days
          .where(
            (d) =>
                d.year == local.year &&
                d.month == local.month &&
                d.day == local.day,
          )
          .firstOrNull;
      if (day != null && TourSchedule.startTimes(day).contains(previous)) {
        _day = day;
        _scheduledAt = previous;
        return;
      }
    }
    _day = _days.firstOrNull;
    _scheduledAt = _day == null
        ? null
        : TourSchedule.startTimes(_day!).firstOrNull;
  }

  void _pickDay(DateTime day) {
    final times = TourSchedule.startTimes(day);
    setState(() {
      _day = day;
      // Keep the same hour on the new day when it is offered.
      final hour = _scheduledAt == null
          ? null
          : ServerClock.manila(_scheduledAt!).hour;
      _scheduledAt =
          times.where((t) => ServerClock.manila(t).hour == hour).firstOrNull ??
          times.firstOrNull;
      _agreed = false;
    });
  }

  String _dayLabel(BuildContext context, DateTime day) {
    final today = ServerClock.manila(ServerClock.now());
    final diff = DateTime(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime(today.year, today.month, today.day)).inDays;
    return switch (diff) {
      0 => context.l10n.today,
      1 => context.l10n.tomorrow,
      _ => AppFormatters.weekdayShort(day),
    };
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${TourSchedule.meetingPointLat},${TourSchedule.meetingPointLng}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Null until known, or when the count can't be loaded (then no warning).
  int? _onlineDrivers;

  Future<void> _checkOnlineDrivers() async {
    if (!BackendConfig.isConfigured) return;
    try {
      final count = await BackendRepository.countOnlineDrivers();
      if (mounted) setState(() => _onlineDrivers = count);
    } catch (_) {
      // Informational only; booking still works without it.
    }
  }

  void _priceChanged() {
    if (mounted) setState(() => _agreed = false);
  }

  @override
  void dispose() {
    AppSession.farePolicy.removeListener(_priceChanged);
    _luggageNotes.dispose();
    _accessibilityNeeds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([AppSession.farePolicy, AppSession.itinerary]),
    builder: (context, _) {
      final revision = AppSession.farePolicy.value.revision;
      final spots = AppSession.itinerary.value;
      final package = AppSession.activePackage;
      final fare = AppSession.estimatedFare;
      // Only tour packages can be booked.
      if (package == null) {
        return Scaffold(
          appBar: AppBar(title: Text(context.l10n.reviewYourBooking)),
          body: EmptyStateWidget(
            icon: Icons.tour_outlined,
            title: context.l10n.chooseATourPackage,
            subtitle: context.l10n.chooseATourPackageBody,
            actionLabel: context.l10n.seeTours,
            onAction: () => context.go(AppRoutes.tourPackages),
          ),
        );
      }
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.reviewYourBooking)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const OutstandingFareBanner(),
            // The fare is what the tourist is agreeing to; lead with it.
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.message(package.name),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        context.message('₱${AppFormatters.amount(fare)}'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 15,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                context.l10n.fixedFareForThisRoute,
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context
                        .l10n
                        .noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .85),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MeetingPointCard(onDirections: _openDirections),
            const SizedBox(height: 22),
            Text(
              context.l10n.chooseYourTourDay,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.tourHoursNote,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (_days.isEmpty)
              Text(context.l10n.noTourDaysAvailable)
            else
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _days.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final day = _days[i];
                    final selected = day == _day;
                    return _DayChip(
                      label: _dayLabel(context, day),
                      date: AppFormatters.monthDayShort(day),
                      selected: selected,
                      onTap: _busy ? null : () => _pickDay(day),
                    );
                  },
                ),
              ),
            if (_day != null) ...[
              const SizedBox(height: 16),
              Text(
                context.l10n.startTime,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final start in TourSchedule.startTimes(_day!))
                    ChoiceChip(
                      label: Text(
                        AppFormatters.time(ServerClock.manila(start)),
                      ),
                      selected: start == _scheduledAt,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: start == _scheduledAt
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: start == _scheduledAt
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                      onSelected: _busy
                          ? null
                          : (_) => setState(() {
                              _scheduledAt = start;
                              _agreed = false;
                            }),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.driverMatchingBegins30MinutesBeforePickup,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (_day == _days.firstOrNull &&
                _dayLabel(context, _day ?? DateTime(0)) == context.l10n.today &&
                _onlineDrivers == 0) ...[
              const SizedBox(height: 12),
              _NoticeBox(
                icon: Icons.wifi_tethering_off_rounded,
                color: AppColors.warning,
                background: AppColors.warningLight,
                title: context.l10n.noDriversOnlineRightNow,
                body: context.l10n.noDriversForTodayBody,
              ),
            ],
            const SizedBox(height: 20),
            Text(
              context.l10n.includedStops,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (spots.isEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(context.l10n.selectAtLeastOneDestinationFirst),
              ),
            ...spots.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Text(context.message('${entry.key + 1}')),
                ),
                title: Text(context.message(entry.value.name)),
              ),
            ),
            const Divider(height: 32),
            Text(
              context.l10n.passengerRequirements,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _passengerCount,
              decoration: InputDecoration(
                labelText: context.l10n.passengers,
                helperText: context
                    .l10n
                    .maximumCapacityIsCheckedBeforeOfferingTheBooking,
                helperMaxLines: 2,
              ),
              items: [
                DropdownMenuItem(
                  value: 1,
                  child: Text(context.l10n.onePassenger),
                ),
                DropdownMenuItem(
                  value: 2,
                  child: Text(context.l10n.twoPassengers),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text(context.l10n.threePassengers),
                ),
              ],
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _passengerCount = value ?? 1),
            ),
            const SizedBox(height: 10),
            _NoticeBox(
              icon: Icons.groups_2_outlined,
              color: AppColors.primary,
              background: AppColors.surfaceVariant,
              title: context.l10n.groupOfFourOrMore,
              body: context.l10n.groupOfFourOrMoreBody,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _luggageNotes,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.luggageOrBulkyItems,
                hintText: context.l10n.exampleTwoBackpacksAndOneFoldingStroller,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              scrollPadding: const EdgeInsets.all(96),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessibilityNeeds,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.accessibilityOrAssistanceNeeds,
                hintText:
                    context.l10n.exampleSeniorPassengerNeedsExtraBoardingTime,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              scrollPadding: const EdgeInsets.all(96),
            ),
            const Divider(height: 32),
            SegmentedButton<PaymentMethod>(
              direction: MediaQuery.sizeOf(context).width < 460
                  ? Axis.vertical
                  : Axis.horizontal,
              style: ButtonStyle(
                foregroundColor: const WidgetStatePropertyAll(
                  Color(0xFF1A1A2E),
                ),
                // Poppins like the rest of the app; a bare TextStyle fell
                // back to the platform font.
                textStyle: WidgetStatePropertyAll(
                  GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: PaymentMethod.cash,
                  icon: Icon(Icons.payments_outlined),
                  label: Text(context.l10n.cash),
                ),
                ButtonSegment(
                  value: PaymentMethod.gcashDirect,
                  icon: const Icon(Icons.phone_android_outlined),
                  label: Text(context.l10n.gcashSendToDriver),
                  enabled: BackendConfig.isConfigured,
                ),
              ],
              selected: {_paymentMethod},
              onSelectionChanged: _busy
                  ? null
                  : (selection) =>
                        setState(() => _paymentMethod = selection.first),
            ),
            const SizedBox(height: 10),
            Text(
              context.message(switch (_paymentMethod) {
                PaymentMethod.gcashDirect => context.l10n.gcashAfterTrip,
                _ =>
                  MessageCode
                      .payTheFinalAmountAfterTheTripTouristAndDriverMustBothConfirm,
              }),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.ifPlansChange,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  context.message(TripRules.policyText),
                  // Bold keeps it readable on the tinted box (the
                  // accessibility contrast check failed at regular weight).
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreed,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _agreed = v ?? false),
              title: Text(
                context.l10n.iAgreeToTheFixedFareAndCancellationPaymentPolicy,
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The agreement box is at the end of a long page; say why
                // the button is disabled instead of leaving it grey.
                if (!_agreed && !_busy) ...[
                  Text(
                    context.l10n.tickTheAgreementToBook,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed:
                      _busy || !_agreed || spots.isEmpty || _scheduledAt == null
                      ? null
                      : () async {
                          setState(() => _busy = true);
                          try {
                            AppSession.draft.passengerCount = _passengerCount;
                            AppSession.draft.luggageNotes = _luggageNotes.text
                                .trim();
                            AppSession.draft.accessibilityNeeds =
                                _accessibilityNeeds.text.trim();
                            AppSession.draft.scheduledAt = _scheduledAt;
                            await AppSession.createBooking(
                              paymentMethod: _paymentMethod,
                              expectedFareRevision: revision,
                            );
                            if (context.mounted) {
                              context.pushReplacement(
                                '/tourist/booking-confirmation',
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              setState(() => _agreed = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    context.message(ErrorMessages.forError(e)),
                                  ),
                                ),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(
                    context.message(
                      _busy
                          ? MessageCode.savingBooking
                          : MessageCode.bookForValue(
                              (AppFormatters.amount(fare)).toString(),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// A tinted note with an icon, a short title and an explanation.
class _NoticeBox extends StatelessWidget {
  const _NoticeBox({
    required this.icon,
    required this.color,
    required this.background,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color, background;
  final String title, body;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Where every tour starts and ends: the Bustos tourism office.
class _MeetingPointCard extends StatelessWidget {
  const _MeetingPointCard({required this.onDirections});
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.account_balance_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.meetingPoint,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    context.l10n.bustosTourismOffice,
                    style: GoogleFonts.poppins(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.bustosTourismOfficeAddress,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.loop_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.l10n.meetingPointExplainer,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded),
            label: Text(context.l10n.getDirections),
          ),
        ),
      ],
    ),
  );
}

/// One day in the tour-day picker: "Today" / "Tomorrow" / weekday + date.
class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final String label, date;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.primary : AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: selected
                      ? Colors.white.withValues(alpha: .9)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
