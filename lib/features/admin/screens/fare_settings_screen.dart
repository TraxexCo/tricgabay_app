import '../../../core/constants/app_colors.dart';
import 'package:tricgabay_app/core/utils/formatters.dart';
import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'package:flutter/material.dart';
import '../../../core/session/app_session.dart';
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
  late final List<TourPackageModel> _packages;
  bool _saving = false;
  bool _savingPolicy = false;
  @override
  void initState() {
    super.initState();
    final policy = AppSession.farePolicy.value;
    _revision = policy.revision;
    final cancellation = AppSession.cancellationPolicy.value;
    _policyVersion = cancellation.version;
    _graceMinutes.text = '${cancellation.freeCancellationMinutes}';
    _lateFeePercent.text = '${cancellation.acceptedTripFeePercent}';
    _waitMinutes.text = '${cancellation.driverWaitMinutes}';
    _noShowPercent.text = '${cancellation.noShowFeePercent}';
    _policyTerms.text = cancellation.terms;
    _packages = List.of(AppSession.tourPackages.value);
    for (final p in _packages) {
      final cents = policy.packageFares[p.id];
      _prices[p.id] = TextEditingController(
        text: cents == null ? '' : AppFormatters.decimalInput(cents / 100),
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
        label: MessageCode.freeCancellation,
      );
      final lateFee = CancellationPolicy.parseBounded(
        _lateFeePercent.text,
        minimum: 0,
        maximum: 100,
        label: MessageCode.lateCancellationFee,
      );
      final wait = CancellationPolicy.parseBounded(
        _waitMinutes.text,
        minimum: 1,
        maximum: 120,
        label: MessageCode.pickupWait,
      );
      final noShow = CancellationPolicy.parseBounded(
        _noShowPercent.text,
        minimum: 0,
        maximum: 100,
        label: MessageCode.noShowFee,
      );
      if (_policyTerms.text.trim().length < 20) {
        throw const FormatException(
          MessageCode.explainThePolicyInAtLeast20Characters,
        );
      }
      if (_policyReason.text.trim().length < 5) {
        throw const FormatException(MessageCode.enterAClearReasonForThisChange);
      }
      final approved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.publishCancellationPolicy),
          content: Text(
            context.l10n
                .freeCancellationMinutesLateTouristCancellationVerifiedPickupWaitMinutesTouristNoShowValue(
                  context.message((grace).toString()),
                  context.message((lateFee).toString()),
                  context.message((wait).toString()),
                  context.message((noShow).toString()),
                ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.keepEditing),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.publishPolicy),
            ),
          ],
        ),
      );
      if (approved != true || !mounted) return;
      setState(() => _savingPolicy = true);
      await AppSession.saveCancellationPolicy(
        expectedVersion: _policyVersion,
        freeCancellationMinutes: grace,
        acceptedTripFeePercent: lateFee,
        driverWaitMinutes: wait,
        noShowFeePercent: noShow,
        terms: _policyTerms.text.trim(),
        reason: _policyReason.text.trim(),
      );
      _policyVersion = AppSession.cancellationPolicy.value.version;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.policyPublishedExistingBookingsAreUnchanged,
            ),
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
      if (mounted) setState(() => _savingPolicy = false);
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    // Custom tours were removed; the stored custom rate is kept unchanged.
    final custom = AppSession.farePolicy.value.customFareCents;
    final packages = {
      ...AppSession.farePolicy.value.packageFares,
      for (final p in _packages)
        p.id: FarePolicy.parsePrice(_prices[p.id]!.text),
    };
    final approved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.publishTheseFixedFares),
        content: Text(
          context.l10n.newBookingsUseTheseFaresValue(
            _packages
                .map(
                  (p) =>
                      "${p.name}: ₱${AppFormatters.amount((packages[p.id]! / 100))}",
                )
                .join("\n"),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.keepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.publish),
          ),
        ],
      ),
    );
    if (approved != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await AppSession.saveFares(
        customCents: custom,
        packages: packages,
        expectedRevision: _revision,
        reason: _reason.text,
      );
      _revision = AppSession.farePolicy.value.revision;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.fixedFaresSavedExistingBookingPricesAreUnchanged,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.message(ErrorMessages.forError(e)))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.fixedFares)),
    body: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            context.l10n.onePriceForTheBookedRoute,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(context.l10n.setAFixedFareForEachTourPackage),
          const SizedBox(height: 24),
          ..._packages.map((p) => _field(p.id, p.name)),
          TextFormField(
            controller: _reason,
            enabled: !_saving,
            maxLength: 300,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.reasonForPriceChange,
              hintText: context.l10n.exampleUpdatedOperatingCostApprovedByAdmin,
            ),
            validator: localizeValidator(
              context,
              (value) => (value ?? '').trim().length < 5
                  ? MessageCode.enterAClearReasonForTheAuditHistory
                  : null,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            scrollPadding: const EdgeInsets.all(96),
          ),
          const SizedBox(height: 12),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.price_check),
            label: Text(
              context.message(
                _saving
                    ? MessageCode.saving
                    : MessageCode.reviewAndPublishFares,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.cancellationAndPaymentPolicy,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(context.message(TripRules.policyText)),
          const SizedBox(height: 16),
          Text(
            context.l10n.policyVersionValue(
              context.message((_policyVersion).toString()),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _policyField(
                  _graceMinutes,
                  MessageCode.freeCancellation,
                  'minutes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _policyField(
                  _lateFeePercent,
                  MessageCode.lateCancellation,
                  '%',
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _policyField(
                  _waitMinutes,
                  MessageCode.pickupWait,
                  'minutes',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _policyField(_noShowPercent, MessageCode.noShowFee, '%'),
              ),
            ],
          ),
          TextField(
            controller: _policyTerms,
            enabled: !_savingPolicy,
            maxLength: 1000,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: context.l10n.touristAndDriverPolicyTerms,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            scrollPadding: const EdgeInsets.all(96),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _policyReason,
            enabled: !_savingPolicy,
            maxLength: 300,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: context.l10n.reasonForPolicyChange,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            scrollPadding: const EdgeInsets.all(96),
          ),
          FilledButton.icon(
            onPressed: _savingPolicy ? null : _savePolicy,
            icon: const Icon(Icons.policy_outlined),
            label: Text(
              context.message(
                _savingPolicy
                    ? MessageCode.publishing
                    : MessageCode.reviewAndPublishPolicy,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.l10n.priceHistoryCurrentVersionValue(
              context.message((_revision).toString()),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ...AppSession.farePolicy.value.history.reversed.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(context.message(entry)),
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
        labelText: context.message(label),
        prefixText: '₱ ',
        prefixStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      validator: localizeValidator(context, (value) {
        try {
          FarePolicy.parsePrice(value ?? '');
          return null;
        } catch (e) {
          return e is FormatException
              ? e.message
              : MessageCode.enterAValidPrice;
        }
      }),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      scrollPadding: const EdgeInsets.all(96),
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
        labelText: context.message(label),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      scrollPadding: const EdgeInsets.all(96),
    ),
  );
}
