import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import '../../widgets/common_widgets.dart';
import '../../../data/models/blood_request_model.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? requestType;
  final BloodRequest? requestToEdit;

  const CreateRequestScreen({super.key, this.requestType, this.requestToEdit});

  @override
  ConsumerState<CreateRequestScreen> createState() =>
      _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _addressController = TextEditingController();
  final _unitsController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  String _requestType = 'normal';
  String _urgencyLevel = 'medium';
  bool _useCurrentLocation = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // If editing, pre-fill form fields
    if (widget.requestToEdit != null) {
      final request = widget.requestToEdit!;
      _patientNameController.text = request.patientName;
      _hospitalController.text = request.hospitalName;
      _addressController.text = request.hospitalAddress;
      _unitsController.text = request.unitsRequired.toString();
      _notesController.text = request.additionalNotes ?? '';
      _selectedBloodGroup = request.bloodGroup;
      _requestType = request.requestType;
      _urgencyLevel = request.urgencyLevel;
      _useCurrentLocation = false; // Use saved location when editing
    } else if (widget.requestType != null) {
      _requestType = widget.requestType!;
      if (_requestType == 'sos') {
        _urgencyLevel = 'critical';
      } else if (_requestType == 'emergency') {
        _urgencyLevel = 'high';
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNotifierProvider.notifier).getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalController.dispose();
    _addressController.dispose();
    _unitsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate units (max 10)
    final units = int.tryParse(_unitsController.text) ?? 0;
    if (units < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 1 unit'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (units > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 units allowed per request'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final locationState = ref.read(locationNotifierProvider);
    if (_useCurrentLocation && locationState.position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable location services')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = ref.read(currentUserIdProvider);
      final user = ref.read(currentUserProfileProvider).value;

      if (userId == null || user == null) {
        if (mounted) {
          setState(() => _isLoading = false);
          await showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Authentication Error'),
              content: const Text(
                'Unable to verify your account. Please try logging out and logging back in.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      double lat, lng;
      String address;

      if (_useCurrentLocation && locationState.position != null) {
        lat = locationState.position!.latitude;
        lng = locationState.position!.longitude;
        address = locationState.address ?? _addressController.text.trim();
      } else {
        // Use existing coordinates when editing, or get new ones
        if (widget.requestToEdit != null && !_useCurrentLocation) {
          lat = widget.requestToEdit!.latitude;
          lng = widget.requestToEdit!.longitude;
          address = _addressController.text.trim();
        } else {
          final locationService = ref.read(locationServiceProvider);
          final coords = await locationService.getCoordinatesFromAddress(
            _addressController.text.trim(),
          );
          if (coords != null) {
            lat = coords.latitude;
            lng = coords.longitude;
            address = _addressController.text.trim();
          } else {
            // Show error dialog for invalid address
            if (mounted) {
              setState(() => _isLoading = false);
              await showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Address Not Found'),
                  content: const Text(
                    'The address you entered could not be found on the map. Please check the address and try again, or use your current location.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }
            return; // Stop request creation
          }
        }
      }

      if (widget.requestToEdit != null) {
        // Update existing request
        await ref
            .read(bloodRequestNotifierProvider.notifier)
            .updateRequest(
              requestId: widget.requestToEdit!.id,
              bloodGroup: _selectedBloodGroup,
              unitsRequired: int.tryParse(_unitsController.text) ?? 1,
              requestType: _requestType,
              urgencyLevel: _urgencyLevel,
              patientName: _patientNameController.text.trim(),
              hospitalName: _hospitalController.text.trim(),
              hospitalAddress: address,
              latitude: lat,
              longitude: lng,
              additionalNotes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      } else {
        // Create new request
        await ref
            .read(bloodRequestNotifierProvider.notifier)
            .createRequest(
              bloodGroup: _selectedBloodGroup,
              unitsRequired: int.tryParse(_unitsController.text) ?? 1,
              requestType: _requestType,
              urgencyLevel: _urgencyLevel,
              patientName: _patientNameController.text.trim(),
              hospitalName: _hospitalController.text.trim(),
              hospitalAddress: address,
              latitude: lat,
              longitude: lng,
              requiredBy: DateTime.now().add(const Duration(days: 1)),
              additionalNotes: _notesController.text.trim().isNotEmpty
                  ? _notesController.text.trim()
                  : null,
            );
      }

      // Stop loading before showing dialog
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  widget.requestToEdit != null
                      ? 'Request Updated!'
                      : 'Request Created!',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8.h),
                Text(
                  widget.requestToEdit != null
                      ? 'Your blood request has been updated successfully.'
                      : 'Your blood request has been created successfully. Nearby donors will be notified.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );

        // Pop the create request screen after dialog is dismissed
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
      return; // Early return to skip finally block's setState
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Error'),
            content: Text(
              'Failed to ${widget.requestToEdit != null ? 'update' : 'create'} request: ${e.toString()}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationNotifierProvider);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          widget.requestToEdit != null
              ? 'Edit Request'
              : (_requestType == 'sos'
                    ? AppStrings.sosAlert
                    : AppStrings.createRequest),
        ),
      ),
      body: RepaintBoundary(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_requestType == 'sos')
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.emergency.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.emergency),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.emergency),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'This is an emergency request. All nearby donors will be immediately notified.',
                            style: TextStyle(
                              color: AppColors.emergency,
                              fontSize: 12.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16.h),
                const SectionHeader(title: AppStrings.requestType),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    _buildTypeChip('normal', 'Normal', Icons.water_drop),
                    SizedBox(width: 8.w),
                    _buildTypeChip(
                      'emergency',
                      'Emergency',
                      Icons.priority_high,
                    ),
                    SizedBox(width: 8.w),
                    _buildTypeChip('sos', 'SOS', Icons.emergency),
                  ],
                ),
                SizedBox(height: 24.h),
                const SectionHeader(title: AppStrings.bloodGroup),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: AppConstants.bloodGroups.map((group) {
                    final isSelected = group == _selectedBloodGroup;
                    return FilterChip(
                      label: Text(group),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedBloodGroup = group);
                      },
                      selectedColor: AppColors.getBloodGroupColor(
                        group,
                      ).withValues(alpha: 0.2),
                      checkmarkColor: AppColors.getBloodGroupColor(group),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.getBloodGroupColor(group)
                            : AppColors.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 24.h),
                CustomTextField(
                  controller: _patientNameController,
                  label: AppStrings.patientName,
                  hint: 'Enter patient name',
                  prefixIcon: Icon(Icons.person),
                  validator: Validators.validateName,
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _hospitalController,
                  label: AppStrings.hospitalName,
                  hint: 'Enter hospital name',
                  prefixIcon: Icon(Icons.local_hospital),
                  validator: Validators.validateRequired,
                ),
                SizedBox(height: 16.h),
                Card(
                  child: SwitchListTile(
                    title: Text(AppStrings.useCurrentLocation),
                    subtitle: Text(
                      _useCurrentLocation
                          ? (locationState.address ?? 'Getting location...')
                          : 'Enter address manually',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    secondary: Icon(
                      _useCurrentLocation
                          ? Icons.my_location
                          : Icons.edit_location,
                      color: AppColors.primary,
                    ),
                    value: _useCurrentLocation,
                    onChanged: (value) {
                      setState(() => _useCurrentLocation = value);
                    },
                  ),
                ),
                if (!_useCurrentLocation) ...[
                  SizedBox(height: 16.h),
                  TypeAheadField<String>(
                    controller: _addressController,
                    debounceDuration: const Duration(milliseconds: 500),
                    builder: (context, controller, focusNode) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          labelText: AppStrings.hospitalAddress,
                          hintText: 'Start typing address...',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(
                              color: AppColors.textHint.withValues(alpha: 0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                      );
                    },
                    decorationBuilder: (context, child) {
                      return Material(
                        type: MaterialType.card,
                        elevation: 4,
                        borderRadius: BorderRadius.circular(8.r),
                        child: child,
                      );
                    },
                    constraints: BoxConstraints(maxHeight: 200.h),
                    direction: VerticalDirection.up,
                    suggestionsCallback: (pattern) async {
                      if (pattern.length < 3) return [];

                      try {
                        // Get location suggestions from geocoding
                        final locations = await locationFromAddress(pattern);

                        // Convert locations to readable addresses
                        final suggestions = <String>[];
                        for (var location in locations.take(5)) {
                          try {
                            final placemarks = await placemarkFromCoordinates(
                              location.latitude,
                              location.longitude,
                            );
                            if (placemarks.isNotEmpty) {
                              final place = placemarks.first;
                              // Build readable address from placemark
                              final addressParts = <String>[];

                              // Add name if it's meaningful (not a code)
                              if (place.name != null &&
                                  place.name!.isNotEmpty &&
                                  place.name!.length > 3 &&
                                  !place.name!.contains(
                                    RegExp(r'^[A-Z0-9]{1,4}$'),
                                  )) {
                                addressParts.add(place.name!);
                              }

                              // Add thoroughfare (street name)
                              if (place.thoroughfare != null &&
                                  place.thoroughfare!.isNotEmpty) {
                                addressParts.add(place.thoroughfare!);
                              }

                              // Add sub-thoroughfare (street number)
                              if (place.subThoroughfare != null &&
                                  place.subThoroughfare!.isNotEmpty) {
                                if (addressParts.isEmpty) {
                                  addressParts.add(place.subThoroughfare!);
                                }
                              }

                              // Add subLocality
                              if (place.subLocality != null &&
                                  place.subLocality!.isNotEmpty) {
                                addressParts.add(place.subLocality!);
                              }

                              // Add locality (city)
                              if (place.locality != null &&
                                  place.locality!.isNotEmpty) {
                                addressParts.add(place.locality!);
                              }

                              // Add administrative area (state)
                              if (place.administrativeArea != null &&
                                  place.administrativeArea!.isNotEmpty) {
                                addressParts.add(place.administrativeArea!);
                              }

                              // Add postal code if available
                              if (place.postalCode != null &&
                                  place.postalCode!.isNotEmpty) {
                                addressParts.add(place.postalCode!);
                              }

                              if (addressParts.isNotEmpty) {
                                suggestions.add(addressParts.join(', '));
                              } else if (pattern.isNotEmpty) {
                                // Fallback to the search pattern if no parts found
                                suggestions.add(pattern);
                              }
                            }
                          } catch (e) {
                            // Skip this location if reverse geocoding fails
                          }
                        }

                        // Remove duplicates
                        final uniqueSuggestions = suggestions.toSet().toList();

                        return uniqueSuggestions.isEmpty
                            ? ['No results found']
                            : uniqueSuggestions;
                      } catch (e) {
                        return ['No results found'];
                      }
                    },
                    itemBuilder: (context, suggestion) {
                      if (suggestion == 'No results found') {
                        return Padding(
                          padding: EdgeInsets.all(16.w),
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        );
                      }
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        title: Text(
                          suggestion,
                          style: TextStyle(fontSize: 13.sp),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        dense: true,
                      );
                    },
                    onSelected: (suggestion) {
                      if (suggestion != 'No results found') {
                        _addressController.text = suggestion;
                      }
                    },
                    emptyBuilder: (context) => Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Text(
                        'Type at least 3 characters to search',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    hideOnEmpty: true,
                    hideOnLoading: false,
                    hideKeyboardOnDrag: false,
                  ),
                ],
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _unitsController,
                  label: AppStrings.unitsRequired,
                  hint: 'Enter number of units',
                  prefixIcon: Icon(Icons.water_drop),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter units required';
                    }
                    final units = int.tryParse(value);
                    if (units == null || units < 1 || units > 10) {
                      return 'Enter a valid number (1-10)';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16.h),
                CustomTextField(
                  controller: _notesController,
                  label: AppStrings.additionalNotes,
                  hint: 'Any additional information (optional)',
                  prefixIcon: Icon(Icons.note),
                  maxLines: 3,
                ),
                SizedBox(height: 32.h),
                _requestType == 'sos'
                    ? SOSButton(
                        onPressed: _isLoading ? null : _createRequest,
                        isLoading: _isLoading,
                      )
                    : PrimaryButton(
                        text: widget.requestToEdit != null
                            ? 'Update Request'
                            : AppStrings.createRequest,
                        onPressed: _createRequest,
                        isLoading: _isLoading,
                      ),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _requestType == type;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    Color color;
    switch (type) {
      case 'emergency':
        color = AppColors.warning;
        break;
      case 'sos':
        color = AppColors.emergency;
        break;
      default:
        color = AppColors.primary;
    }

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _requestType = type;
            if (type == 'sos') {
              _urgencyLevel = 'critical';
            } else if (type == 'emergency') {
              _urgencyLevel = 'high';
            } else {
              _urgencyLevel = 'medium';
            }
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isLandscape ? 8.h : 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? color : AppColors.textHint,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? color : AppColors.textHint,
                size: isLandscape ? 20.sp : 24.sp,
              ),
              SizedBox(height: 4.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isLandscape ? 10.sp : 12.sp,
                    color: isSelected ? color : AppColors.textHint,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
