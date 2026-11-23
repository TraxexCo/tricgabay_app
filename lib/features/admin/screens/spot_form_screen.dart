import 'package:tricgabay_app/core/l10n/app_l10n.dart';
import '../../../core/services/error_messages.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/session/app_session.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/l10n/record_labels.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/map_coordinate_validator.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/place_search_service.dart';
import '../widgets/opening_hours_field.dart';
import 'admin_location_picker_screen.dart';

class SpotFormScreen extends ConsumerStatefulWidget {
  final TouristSpotModel? spot;

  const SpotFormScreen({super.key, this.spot});

  @override
  ConsumerState<SpotFormScreen> createState() => _SpotFormScreenState();
}

class _SpotFormScreenState extends ConsumerState<SpotFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _addressController;
  late TextEditingController _entranceFeeController;
  late TextEditingController _openingHoursController;
  late TextEditingController _historyController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  Uint8List? _imageBytes;
  bool _saving = false;

  SpotCategory _category = SpotCategory.heritage;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.spot?.name ?? '');
    _descController = TextEditingController(
      text: widget.spot?.description ?? '',
    );
    _addressController = TextEditingController(
      text: widget.spot?.address ?? '',
    );
    _entranceFeeController = TextEditingController(
      text: widget.spot?.entranceFee ?? '',
    );
    _openingHoursController = TextEditingController(
      text: widget.spot?.openingHours ?? '',
    );
    _historyController = TextEditingController(
      text: widget.spot?.history ?? '',
    );
    _latitudeController = TextEditingController(
      text: widget.spot?.latitude.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.spot?.longitude.toString() ?? '',
    );

    if (widget.spot != null) {
      _category = widget.spot!.category;
      _isActive = widget.spot!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _entranceFeeController.dispose();
    _openingHoursController.dispose();
    _historyController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 2200,
    );
    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  /// A plain amount gets the peso sign; words like "Free" stay as typed.
  String _entranceFee() {
    final text = _entranceFeeController.text.trim();
    if (text.isEmpty) return '';
    return double.tryParse(text.replaceAll(',', '')) != null ? '₱$text' : text;
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<PlaceHit>(
      MaterialPageRoute(
        builder: (_) => AdminLocationPickerScreen(
          latitude: double.tryParse(_latitudeController.text),
          longitude: double.tryParse(_longitudeController.text),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _latitudeController.text = picked.latitude.toStringAsFixed(7);
      _longitudeController.text = picked.longitude.toStringAsFixed(7);
      if (picked.address.isNotEmpty) _addressController.text = picked.address;
      if (_nameController.text.trim().isEmpty && picked.name.isNotEmpty) {
        _nameController.text = picked.name;
      }
    });
  }

  Future<void> _saveSpot() async {
    if (_openingHoursController.text.trim().isEmpty) {
      AppSnackbar.showError(context, context.l10n.hoursPickDays);
      return;
    }
    if (_formKey.currentState!.validate()) {
      if (!BackendConfig.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.serverSetupIsIncompleteTheAttractionWasNotSaved,
            ),
          ),
        );
        return;
      }
      setState(() => _saving = true);
      final isNew = widget.spot == null;
      final spotId = isNew ? 'spot-${const Uuid().v4()}' : widget.spot!.id;

      final updatedSpot = TouristSpotModel(
        id: spotId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        history: _historyController.text.trim(),
        latitude: double.parse(_latitudeController.text),
        longitude: double.parse(_longitudeController.text),
        category: _category,
        imageUrls: widget.spot?.imageUrls ?? const [],
        address: _addressController.text.trim(),
        openingHours: _openingHoursController.text.trim(),
        entranceFee: _entranceFee(),
        tips: widget.spot?.tips ?? const [],
        isActive: _isActive,
        availabilityStatus: widget.spot?.availabilityStatus ?? 'open',
        closedUntil: widget.spot?.closedUntil,
        closureReason: widget.spot?.closureReason,
      );

      try {
        await BackendRepository.upsertSpot(
          spot: updatedSpot,
          address: _addressController.text,
          imageBytes: _imageBytes,
        );
        await AppSession.syncRemoteState();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.message(
                isNew
                    ? MessageCode.touristSpotCreated
                    : MessageCode.touristSpotUpdated,
              ),
            ),
          ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.message(
            widget.spot == null
                ? MessageCode.addTouristSpot
                : MessageCode.editTouristSpot,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _saving ? null : _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imageBytes != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        )
                      : widget.spot != null && widget.spot!.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SafeAppImage(
                            path: widget.spot!.imageUrls.first,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              context.l10n.uploadImage,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: context.l10n.spotName,
                hint: context.l10n.eGMinasaFestivalGrounds,
                controller: _nameController,
                maxLength: 120,
                validator: (v) =>
                    Validators.required(v, fieldName: MessageCode.spotName) ??
                    Validators.maxLength(
                      v,
                      120,
                      fieldName: MessageCode.spotName,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.category,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: SpotCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(spotCategoryLabel(context, cat)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.description,
                hint: context.l10n.enterDescription,
                maxLines: 4,
                maxLength: 2000,
                controller: _descController,
                validator: (v) =>
                    Validators.required(
                      v,
                      fieldName: MessageCode.description,
                    ) ??
                    Validators.maxLength(
                      v,
                      2000,
                      fieldName: MessageCode.description,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.spotLocation,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _saving ? null : _pickOnMap,
                icon: const Icon(Icons.map_outlined),
                label: Text(context.l10n.pickOnMap),
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: context.l10n.address,
                hint: context.l10n.enterAddress,
                controller: _addressController,
                maxLines: 2,
                maxLength: 300,
                validator: (v) =>
                    Validators.required(v, fieldName: MessageCode.address),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: context.l10n.latitude,
                      hint: '14.9500',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        final number = MapCoordinateValidator.finiteNumber(
                          value,
                        );
                        return number == null || number < -90 || number > 90
                            ? MessageCode.invalidLatitude
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: context.l10n.longitude,
                      hint: '120.9200',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        final number = MapCoordinateValidator.finiteNumber(
                          value,
                        );
                        return number == null || number < -180 || number > 180
                            ? MessageCode.invalidLongitude
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.history,
                hint: context.l10n.enterHistory,
                maxLines: 8,
                maxLength: 3000,
                controller: _historyController,
              ),
              const SizedBox(height: 16),
              OpeningHoursField(
                initial: widget.spot?.openingHours ?? '',
                onChanged: (value) => _openingHoursController.text = value,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: context.l10n.entranceFee,
                hint: context.l10n.entranceFeeHint,
                controller: _entranceFeeController,
                maxLength: 120,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: Text(context.l10n.visibleToTourists),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: context.l10n.saveSpot,
                  isLoading: _saving,
                  onPressed: _saveSpot,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
