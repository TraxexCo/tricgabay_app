import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/trip_rules.dart';
import '../../../core/services/backend_repository.dart';
import '../../../core/config/backend_config.dart';
import '../../../models/booking_model.dart';
import 'package:url_launcher/url_launcher.dart';

class FareSummaryScreen extends StatefulWidget {
  const FareSummaryScreen({super.key});
  @override
  State<FareSummaryScreen> createState() => _FareSummaryScreenState();
}

class _FareSummaryScreenState extends State<FareSummaryScreen> {
  bool _busy = false;
  bool _agreed = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  int _passengerCount = PrototypeSession.passengerCount;
  DateTime? _scheduledAt = PrototypeSession.scheduledAt;
  late final TextEditingController _luggageNotes;
  late final TextEditingController _accessibilityNeeds;
  @override
  void initState() {
    super.initState();
    _luggageNotes = TextEditingController(
      text: PrototypeSession.luggageNotes,
    );
    _accessibilityNeeds = TextEditingController(
      text: PrototypeSession.accessibilityNeeds,
    );
    PrototypeSession.farePolicy.addListener(_priceChanged);
  }

  void _priceChanged() {
    if (mounted) setState(() => _agreed = false);
  }

  String _scheduleLabel(BuildContext context) {
    final value = _scheduledAt;
    if (value == null) return 'Request a driver now';
    final local = value.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(local)} at ${material.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  Future<void> _chooseSchedule() async {
    final now = DateTime.now();
    final initial = _scheduledAt ?? now.add(const Duration(hours: 2));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'Choose pickup date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
      helpText: 'Choose pickup time',
    );
    if (time == null || !mounted) return;
    final chosen = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (chosen.isBefore(DateTime.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule pickup at least 1 hour from now.')),
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
    PrototypeSession.farePolicy.removeListener(_priceChanged);
    _luggageNotes.dispose();
    _accessibilityNeeds.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      PrototypeSession.farePolicy,
      PrototypeSession.itinerary,
      PrototypeSession.customPickupAddress,
    ]),
    builder: (context, _) {
      final revision = PrototypeSession.farePolicy.value.revision;
      final spots = PrototypeSession.itinerary.value;
      final package = PrototypeSession.activePackage;
      final fare = PrototypeSession.estimatedFare;
      return Scaffold(
        appBar: AppBar(title: const Text('Review your booking')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              package?.name ?? 'Custom tour',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Fixed fare for this route'),
                subtitle: const Text(
                  'No distance, waiting or surge additions. Entrance fees and purchases are separate.',
                ),
                trailing: Text(
                  '₱${fare.toStringAsFixed(2)}',
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
                title: const Text('Pickup point'),
                subtitle: Text(
                  PrototypeSession.customPickupAddress.value ??
                      (PrototypeSession.userLatitude.value == null
                          ? 'Choose an exact pickup point before booking'
                          : 'Current GPS location'),
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
                      _scheduledAt == null ? 'Book now' : 'Scheduled pickup',
                    ),
                    subtitle: Text(_scheduleLabel(context)),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _busy ? null : _chooseSchedule,
                  ),
                  if (_scheduledAt != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Driver matching begins 30 minutes before pickup.',
                            ),
                          ),
                          TextButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() {
                                    _scheduledAt = null;
                                    _agreed = false;
                                  }),
                            child: const Text('Use now'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Included stops',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            if (spots.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Select at least one destination first.'),
              ),
            ...spots.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(entry.value.name),
              ),
            ),
            const Divider(height: 32),
            const Text(
              'Passenger requirements',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _passengerCount,
              decoration: const InputDecoration(
                labelText: 'Passengers',
                helperText: 'Maximum capacity is checked before offering the booking.',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('1 passenger')),
                DropdownMenuItem(value: 2, child: Text('2 passengers')),
                DropdownMenuItem(value: 3, child: Text('3 passengers')),
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
              decoration: const InputDecoration(
                labelText: 'Luggage or bulky items',
                hintText: 'Example: two backpacks and one folding stroller',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accessibilityNeeds,
              enabled: !_busy,
              maxLength: 300,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Accessibility or assistance needs',
                hintText: 'Example: senior passenger needs extra boarding time',
                border: OutlineInputBorder(),
              ),
            ),
            const Divider(height: 32),
            SegmentedButton<PaymentMethod>(
              segments: [
                const ButtonSegment(
                  value: PaymentMethod.cash,
                  icon: Icon(Icons.payments_outlined),
                  label: Text('Cash'),
                ),
                ButtonSegment(
                  value: PaymentMethod.online,
                  icon: const Icon(Icons.account_balance_wallet_outlined),
                  label: Text(
                    BackendConfig.isConfigured
                        ? 'PayMongo'
                        : 'PayMongo unavailable',
                  ),
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
              _paymentMethod == PaymentMethod.cash
                  ? 'Pay the final amount after the trip. Tourist and driver must both confirm the cash handover.'
                  : 'You will be sent to PayMongo test checkout. Payment is confirmed only after the secure webhook reaches Tric-Gabay.',
            ),
            const SizedBox(height: 12),
            const Text(
              'If plans change',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(TripRules.policyText),
            const SizedBox(height: 12),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _agreed,
              onChanged: _busy
                  ? null
                  : (v) => setState(() => _agreed = v ?? false),
              title: const Text(
                'I agree to the fixed fare and cancellation/payment policy.',
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
                        PrototypeSession.passengerCount = _passengerCount;
                        PrototypeSession.luggageNotes = _luggageNotes.text.trim();
                        PrototypeSession.accessibilityNeeds =
                            _accessibilityNeeds.text.trim();
                        PrototypeSession.scheduledAt = _scheduledAt;
                        final booking = await PrototypeSession.createBooking(
                          paymentMethod: _paymentMethod,
                          expectedFareRevision: revision,
                        );
                        if (_paymentMethod == PaymentMethod.online) {
                          final checkoutUrl =
                              await BackendRepository.createCheckout(
                                booking.id,
                              );
                          final opened = await launchUrl(
                            Uri.parse(checkoutUrl),
                            mode: LaunchMode.externalApplication,
                          );
                          if (!opened) {
                            throw StateError(
                              'Could not open the secure PayMongo checkout.',
                            );
                          }
                        }
                        if (context.mounted) {
                          context.pushReplacement(
                            '/tourist/booking-confirmation',
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() => _agreed = false);
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: Text(
                _busy
                    ? 'Saving booking…'
                    : 'Book for ₱${fare.toStringAsFixed(2)}',
              ),
            ),
          ),
        ),
      );
    },
  );
}
