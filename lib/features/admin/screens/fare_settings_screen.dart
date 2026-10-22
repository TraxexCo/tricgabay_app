import 'package:flutter/material.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../core/services/fare_policy.dart';
import '../../../core/services/cancellation_policy.dart';
import '../../../core/services/trip_rules.dart';
import '../../../models/tourist_spot_model.dart';

class FareSettingsScreen extends StatefulWidget {
  const FareSettingsScreen({super.key});
  @override
  State<FareSettingsScreen> createState() => _FareSettingsScreenState();
}

class _FareSettingsScreenState extends State<FareSettingsScreen> {
  final _form = GlobalKey<FormState>();
  final _prices = <String, TextEditingController>{};
  final _reason = TextEditingController();
  final _policyReason = TextEditingController();
  final _policyTerms = TextEditingController();
  final _graceMinutes = TextEditingController();
  final _lateFeePercent = TextEditingController();
  final _waitMinutes = TextEditingController();
  final _noShowPercent = TextEditingController();
  late int _revision;
  late int _policyVersion;
  bool _saving = false;
  bool _savingPolicy = false;
  @override
  void initState() {
    super.initState();
    final policy = PrototypeSession.farePolicy.value;
    _revision = policy.revision;
    final cancellation = PrototypeSession.cancellationPolicy.value;
    _policyVersion = cancellation.version;
    _graceMinutes.text = '${cancellation.freeCancellationMinutes}';
    _lateFeePercent.text = '${cancellation.acceptedTripFeePercent}';
    _waitMinutes.text = '${cancellation.driverWaitMinutes}';
    _noShowPercent.text = '${cancellation.noShowFeePercent}';
    _policyTerms.text = cancellation.terms;
    _prices['custom'] = TextEditingController(
      text: (policy.customFareCents / 100).toStringAsFixed(2),
    );
    for (final p in TourPackageModel.catalog) {
      _prices[p.id] = TextEditingController(
        text: (policy.quote(p.id) / 100).toStringAsFixed(2),
      );
    }
  }

  @override
  void dispose() {
    for (final c in _prices.values) {
      c.dispose();
    }
    _reason.dispose();
    _policyReason.dispose();
    _policyTerms.dispose();
    _graceMinutes.dispose();
    _lateFeePercent.dispose();
    _waitMinutes.dispose();
    _noShowPercent.dispose();
    super.dispose();
  }

  Future<void> _savePolicy() async {
    if (_savingPolicy) return;
    try {
      final grace = CancellationPolicy.parseBounded(
        _graceMinutes.text,
        minimum: 0,
        maximum: 120,
        label: 'Free cancellation',
      );
      final lateFee = CancellationPolicy.parseBounded(
        _lateFeePercent.text,
        minimum: 0,
        maximum: 100,
        label: 'Late cancellation fee',
      );
      final wait = CancellationPolicy.parseBounded(
        _waitMinutes.text,
        minimum: 1,
        maximum: 120,
        label: 'Pickup wait',
      );
      final noShow = CancellationPolicy.parseBounded(
        _noShowPercent.text,
        minimum: 0,
        maximum: 100,
        label: 'No-show fee',
      );
      if (_policyTerms.text.trim().length < 20) {
        throw const FormatException(
          'Explain the policy in at least 20 characters.',
        );
      }
      if (_policyReason.text.trim().length < 5) {
        throw const FormatException('Enter a clear reason for this change.');
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Publish cancellation policy?'),
          content: Text(
            'Free cancellation: $grace minutes\nLate tourist cancellation: $lateFee%\nVerified pickup wait: $wait minutes\nTourist no-show fee: $noShow%\n\nExisting bookings keep their original policy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Publish policy'),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
      setState(() => _savingPolicy = true);
      await PrototypeSession.saveCancellationPolicy(
        expectedVersion: _policyVersion,
        freeCancellationMinutes: grace,
        acceptedTripFeePercent: lateFee,
        driverWaitMinutes: wait,
        noShowFeePercent: noShow,
        terms: _policyTerms.text.trim(),
        reason: _policyReason.text.trim(),
      );
      _policyVersion = PrototypeSession.cancellationPolicy.value.version;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Policy published. Existing bookings are unchanged.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _savingPolicy = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final custom = FarePolicy.parsePrice(_prices['custom']!.text);
    final packages = {
      for (final p in TourPackageModel.catalog)
        p.id: FarePolicy.parsePrice(_prices[p.id]!.text),
    };
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish these fixed fares?'),
        content: Text(
          'Custom tour: ₱${(custom / 100).toStringAsFixed(2)}\n${TourPackageModel.catalog.map((p) => "${p.name}: ₱${(packages[p.id]! / 100).toStringAsFixed(2)}").join("\n")}\n\nNew bookings use these rates. Existing bookings keep their agreed fare.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await PrototypeSession.saveFares(
        customCents: custom,
        packages: packages,
        expectedRevision: _revision,
        reason: _reason.text,
      );
      _revision = PrototypeSession.farePolicy.value.revision;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fixed fares saved. Existing booking prices are unchanged.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Fixed fares')),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'One price for the booked route',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a flat custom-tour fare and a fixed fare for each package. No automatic per-stop, distance, waiting-time or surge additions. Entrance fees are paid separately.',
          ),
          const SizedBox(height: 24),
          _field('custom', 'Custom tour (1–12 selected stops)'),
          ...TourPackageModel.catalog.map((p) => _field(p.id, p.name)),
          TextFormField(
            controller: _reason,
            enabled: !_saving,
            maxLength: 300,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason for price change',
              hintText: 'Example: Updated operating cost approved by admin',
              border: OutlineInputBorder(),
            ),
            validator: (value) => (value ?? '').trim().length < 5
                ? 'Enter a clear reason for the audit history'
                : null,
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.price_check),
            label: Text(_saving ? 'Saving…' : 'Review and publish fares'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Cancellation and payment policy',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(TripRules.policyText),
          const SizedBox(height: 16),
          Text(
            'Policy version $_policyVersion',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _policyField(
                  _graceMinutes,
                  'Free cancellation',
                  'minutes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _policyField(_lateFeePercent, 'Late cancellation', '%'),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _policyField(_waitMinutes, 'Pickup wait', 'minutes'),
              ),
              const SizedBox(width: 12),
              Expanded(child: _policyField(_noShowPercent, 'No-show fee', '%')),
            ],
          ),
          TextField(
            controller: _policyTerms,
            enabled: !_savingPolicy,
            maxLength: 1000,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Tourist and driver policy terms',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _policyReason,
            enabled: !_savingPolicy,
            maxLength: 300,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Reason for policy change',
              border: OutlineInputBorder(),
            ),
          ),
          FilledButton.icon(
            onPressed: _savingPolicy ? null : _savePolicy,
            icon: const Icon(Icons.policy_outlined),
            label: Text(
              _savingPolicy ? 'Publishing...' : 'Review and publish policy',
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Price history · current version $_revision',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...PrototypeSession.farePolicy.value.history.reversed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(entry),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    ),
  );
  Widget _field(String id, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: _prices[id],
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixText: '₱ ',
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        try {
          FarePolicy.parsePrice(value ?? '');
          return null;
        } catch (e) {
          return e is FormatException ? e.message : 'Enter a valid price';
        }
      },
    ),
  );

  Widget _policyField(
    TextEditingController controller,
    String label,
    String suffix,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      enabled: !_savingPolicy,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
