import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/image_helper.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/location_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();

  String _selectedBloodGroup = 'A+';
  String _selectedGender = 'male';
  DateTime _selectedDate = DateTime.now().subtract(const Duration(days: 6570));
  String? _profileImageUrl;
  File? _selectedImageFile;
  bool _isLoading = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final user = ref.read(currentUserProfileProvider).value;
    if (user != null) {
      _nameController.text = user.name;
      _phoneController.text = user.phone;
      _bioController.text = user.bio ?? '';
      _cityController.text = user.city ?? '';
      _selectedBloodGroup = user.bloodGroup;
      // Normalize gender to lowercase to match dropdown values
      _selectedGender = user.gender.isNotEmpty
          ? user.gender.toLowerCase()
          : 'male';
      _selectedDate = user.dateOfBirth;
      _profileImageUrl = user.profileImageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );

    if (source == null) return;

    final image = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (image == null) return;

    try {
      // Read the image as bytes and create a new file
      final bytes = await image.readAsBytes();
      final tempFile = File(image.path);

      // Verify we can read the file
      if (bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected image is empty')),
          );
        }
        return;
      }

      setState(() {
        _selectedImageFile = tempFile;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load image: $e')));
      }
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1940),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)),
    );

    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoading = true);

    try {
      await ref.read(locationNotifierProvider.notifier).getCurrentLocation();
      final locationState = ref.read(locationNotifierProvider);

      if (locationState.position != null && locationState.address != null) {
        setState(() {
          _cityController.text = locationState.address!;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            bloodGroup: _selectedBloodGroup,
            gender: _selectedGender,
            dateOfBirth: _selectedDate,
            bio: _bioController.text.trim().isNotEmpty
                ? _bioController.text.trim()
                : null,
            city: _cityController.text.trim().isNotEmpty
                ? _cityController.text.trim()
                : null,
            profileImage: _selectedImageFile,
          );

      // Update location if available
      final locationState = ref.read(locationNotifierProvider);
      if (locationState.position != null) {
        await ref
            .read(userProfileNotifierProvider.notifier)
            .updateLocation(
              locationState.position!.latitude,
              locationState.position!.longitude,
            );
      }

      // Refresh the profile to show updated image
      ref.invalidate(currentUserProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Profile image
              Stack(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _selectedImageFile != null
                        ? CircleAvatar(
                            radius: 60.r,
                            backgroundImage: FileImage(_selectedImageFile!),
                          )
                        : ImageHelper.buildProfileImage(
                            imageUrl: _profileImageUrl,
                            size: 120.r,
                          ),
                  ),
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withOpacity(0.5),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              // Name
              CustomTextField(
                controller: _nameController,
                label: AppStrings.fullName,
                hint: 'Enter your full name',
                prefixIcon: Icon(Icons.person, size: 20.sp),
                validator: Validators.validateName,
              ),
              SizedBox(height: 16.h),
              // Phone
              CustomTextField(
                controller: _phoneController,
                label: AppStrings.phoneNumber,
                hint: 'Enter your phone number',
                prefixIcon: Icon(Icons.phone, size: 20.sp),
                keyboardType: TextInputType.phone,
                validator: Validators.validatePhoneNumber,
              ),
              SizedBox(height: 16.h),
              // Blood group
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
                    ).withOpacity(0.2),
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
              SizedBox(height: 16.h),
              // Gender
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: InputDecoration(
                  labelText: AppStrings.gender,
                  prefixIcon: const Icon(Icons.wc),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedGender = value);
                  }
                },
              ),
              SizedBox(height: 16.h),
              // Date of birth
              GestureDetector(
                onTap: _selectDate,
                child: AbsorbPointer(
                  child: CustomTextField(
                    controller: TextEditingController(
                      text:
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                    label: AppStrings.dateOfBirth,
                    hint: 'Select date of birth',
                    prefixIcon: Icon(Icons.calendar_today, size: 20.sp),
                    readOnly: true,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              // City
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: AppStrings.city,
                      hint: 'Enter your city',
                      prefixIcon: Icon(Icons.location_city, size: 20.sp),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: _updateLocation,
                    icon: const Icon(Icons.my_location),
                    color: AppColors.primary,
                    tooltip: 'Use current location',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              // Bio
              CustomTextField(
                controller: _bioController,
                label: AppStrings.bio,
                hint: 'Tell something about yourself (optional)',
                prefixIcon: Icon(Icons.info, size: 20.sp),
                maxLines: 3,
              ),
              SizedBox(height: 32.h),
              // Save button
              PrimaryButton(
                text: AppStrings.saveChanges,
                onPressed: _saveProfile,
                isLoading: _isLoading,
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
