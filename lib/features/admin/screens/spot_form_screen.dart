import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../core/prototype/prototype_session.dart';
import '../../../models/tourist_spot_model.dart';
import '../../../core/config/backend_config.dart';
import '../../../core/services/backend_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

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
      text: widget.spot?.tips.firstOrNull ?? '',
    );
    _entranceFeeController = TextEditingController(
      text: widget.spot?.entranceFee.replaceAll('₱', '').trim() ?? '0',
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

  Future<void> _saveSpot() async {
    if (_formKey.currentState!.validate()) {
      if (!BackendConfig.isConfigured) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Server setup is incomplete. The attraction was not saved.',
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
        openingHours: _openingHoursController.text.trim(),
        entranceFee: '₱${_entranceFeeController.text.trim()}',
        tips: widget.spot?.tips ?? [_addressController.text.trim()],
        isActive: _isActive,
        availabilityStatus:
            widget.spot?.availabilityStatus ?? 'open',
        closedUntil: widget.spot?.closedUntil,
        closureReason: widget.spot?.closureReason,
      );

      try {
        await BackendRepository.upsertSpot(
          spot: updatedSpot,
          address: _addressController.text,
          imageBytes: _imageBytes,
        );
        await PrototypeSession.syncRemoteState();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isNew ? 'Tourist spot created' : 'Tourist spot updated',
            ),
          ),
        );
        context.pop();
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
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
          widget.spot == null ? 'Add Tourist Spot' : 'Edit Tourist Spot',
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
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Upload Image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Spot Name',
                hint: 'e.g. Minasa Festival Grounds',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: SpotCategory.values.map((cat) {
                  final isSelected = _category == cat;
                  return ChoiceChip(
                    label: Text(cat.name.toUpperCase()),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _category = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Enter description...',
                maxLines: 4,
                controller: _descController,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Address',
                hint: 'Enter address...',
                controller: _addressController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Latitude',
                      hint: '14.9500',
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        final number = double.tryParse(value ?? '');
                        return number == null || number < -90 || number > 90
                            ? 'Invalid latitude'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Longitude',
                      hint: '120.9200',
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      validator: (value) {
                        final number = double.tryParse(value ?? '');
                        return number == null || number < -180 || number > 180
                            ? 'Invalid longitude'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'History',
                hint: 'Enter history...',
                maxLines: 3,
                controller: _historyController,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Opening Hours',
                      hint: '8:00 AM - 5:00 PM',
                      controller: _openingHoursController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      label: 'Entrance Fee',
                      hint: '0.00',
                      keyboardType: TextInputType.number,
                      controller: _entranceFeeController,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Visible to Tourists'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: 'Save Spot',
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
