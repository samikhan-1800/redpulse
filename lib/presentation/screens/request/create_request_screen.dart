import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/common_widgets.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? requestType;

  const CreateRequestScreen({super.key, this.requestType});

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
    if (widget.requestType != null) {
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
        throw Exception('User not authenticated');
      }

      double lat, lng;
      String address;

      if (_useCurrentLocation && locationState.position != null) {
        lat = locationState.position!.latitude;
        lng = locationState.position!.longitude;
        address = locationState.address ?? _addressController.text.trim();
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
          throw Exception('Could not find location for the given address');
        }
      }

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

      if (mounted) {
        final dialog = SuccessDialog(
          title: AppStrings.requestCreated,
          message:
              'Your blood request has been created successfully. Nearby donors will be notified.',
        );
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => dialog,
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
          _requestType == 'sos'
              ? AppStrings.sosAlert
              : AppStrings.createRequest,
        ),
      ),
      body: SingleChildScrollView(
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
                  _buildTypeChip('emergency', 'Emergency', Icons.priority_high),
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
                CustomTextField(
                  controller: _addressController,
                  label: AppStrings.hospitalAddress,
                  hint: 'Enter hospital address',
                  prefixIcon: Icon(Icons.location_on),
                  maxLines: 2,
                  validator: _useCurrentLocation
                      ? null
                      : Validators.validateRequired,
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
                      text: AppStrings.createRequest,
                      onPressed: _createRequest,
                      isLoading: _isLoading,
                    ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _requestType == type;
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
          padding: EdgeInsets.symmetric(vertical: 12.h),
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
            children: [
              Icon(icon, color: isSelected ? color : AppColors.textHint),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isSelected ? color : AppColors.textHint,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
