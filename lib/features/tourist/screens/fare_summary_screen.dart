import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/server_clock.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../core/config/backend_config.dart';
import '../../../models/booking_model.dart';
import '../../../core/constants/app_colors.dart';
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
  DateTime? _scheduledAt = AppSession.draft.scheduledAt;
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
  }

  void _priceChanged() {
    if (mounted) setState(() => _agreed = false);
  }

  String _scheduleLabel(BuildContext context) {
    final value = _scheduledAt;
    if (value == null) return MessageCode.requestADriverNow;
    return ServerClock.formatManila(value);
  }

  Future<void> _chooseSchedule() async {
    final now = ServerClock.manila(ServerClock.now());
    final initial = _scheduledAt == null
        ? now.add(const Duration(hours: 2))
        : ServerClock.manila(_scheduledAt!);
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: context.l10n.choosePickupDate,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: context.l10n.choosePickupTime,
    );
    if (time == null || !mounted) return;
    final chosen = ServerClock.fromManila(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (chosen.isBefore(ServerClock.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.schedulePickupAtLeast1HourFromNow)),
      );
      return;
    }
    setState(() {
      _scheduledAt = chosen;
      _agreed = false;
    });
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
    listenable: Listenable.merge([
      AppSession.farePolicy,
      AppSession.itinerary,
      AppSession.draft.pickupAddress,
    ]),
    builder: (context, _) {
      final revision = AppSession.farePolicy.value.revision;
      final spots = AppSession.itinerary.value;
      final package = AppSession.activePackage;
      final fare = AppSession.estimatedFare;
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.reviewYourBooking)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const OutstandingFareBanner(),
            Text(
              context.message(package?.name ?? MessageCode.customTour),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: Text(context.l10n.fixedFareForThisRoute),
                subtitle: Text(
                  context
                      .l10n
                      .noDistanceWaitingOrSurgeAdditionsEntranceFeesAndPurchasesAreSeparate,
                ),
                trailing: Text(
                  context.message('₱${AppFormatters.amount(fare)}'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(context.l10n.pickupPoint),
                subtitle: Text(
                  context.message(
                    AppSession.draft.pickupAddress.value ??
                        (AppSession.userLatitude.value == null
                            ? MessageCode.chooseAnExactPickupPointBeforeBooking
                            : MessageCode.currentGpsLocation),
                  ),
                ),
                trailing: const Icon(Icons.edit_location_alt_outlined),
                onTap: () async {
                  await context.push('/tourist/location-picker');
                  if (mounted) setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _scheduledAt == null
                          ? Icons.bolt_rounded
                          : Icons.event_available_outlined,
                    ),
                    title: Text(
                      context.message(
                        _scheduledAt == null
                            ? MessageCode.bookNow
                            : MessageCode.scheduledPickup,
                      ),
                    ),
                    subtitle: Text(context.message(_scheduleLabel(context))),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _busy ? null : _chooseSchedule,
                  ),
                  if (_scheduledAt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              context
                                  .l10n
                                  .driverMatchingBegins30MinutesBeforePickup,
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _scheduledAt = null;
                                    _agreed = false;
                                  }),
                            child: Text(context.l10n.useNow),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
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
                border: OutlineInputBorder(),
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
            const SizedBox(height: 12),
            TextField(
              controller: _luggageNotes,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: context.l10n.luggageOrBulkyItems,
                hintText: context.l10n.exampleTwoBackpacksAndOneFoldingStroller,
                border: OutlineInputBorder(),
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
                border: OutlineInputBorder(),
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
              style: const ButtonStyle(
                foregroundColor: WidgetStatePropertyAll(Color(0xFF1A1A2E)),
                textStyle: WidgetStatePropertyAll(
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
            child: FilledButton(
              onPressed: _busy || !_agreed || spots.isEmpty
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
          ),
        ),
      );
    },
  );
}
