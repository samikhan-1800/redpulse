import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import '../../widgets/dialogs.dart';
import '../main/main_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedBloodGroup;
  String? _selectedGender;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  Future<void> _selectBloodGroup() async {
    final selected = await BloodGroupSelectionDialog.show(
      context,
      selectedBloodGroup: _selectedBloodGroup,
    );
    if (selected != null) {
      setState(() {
        _selectedBloodGroup = selected;
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your blood group'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your gender'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate age (must be between 18 and 65)
    final now = DateTime.now();
    final age = now.year - _dateOfBirth!.year;
    final hasHadBirthdayThisYear =
        now.month > _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day >= _dateOfBirth!.day);
    final actualAge = hasHadBirthdayThisYear ? age : age - 1;

    if (actualAge < 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You must be at least 18 years old to register as a blood donor',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (actualAge > 65) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Blood donation is restricted to people under 65 years of age',
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .signUp(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          phone: _phoneController.text,
          bloodGroup: _selectedBloodGroup!,
          gender: _selectedGender!,
          dateOfBirth: _dateOfBirth!,
        );

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (authState.hasValue) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text(AppStrings.signUp)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.createAccount,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Join RedPulse and start saving lives',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32.h),
                // Name field
                CustomTextField(
                  controller: _nameController,
                  label: AppStrings.fullName,
                  hint: 'Enter your full name',
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateName,
                  prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                ),
                SizedBox(height: 16.h),
                // Email field
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  prefixIcon: Icon(Icons.email_outlined, size: 20.sp),
                ),
                SizedBox(height: 16.h),
                // Phone field
                CustomTextField(
                  controller: _phoneController,
                  label: AppStrings.phoneNumber,
                  hint: 'Enter your phone number',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePhoneNumber,
                  prefixIcon: Icon(Icons.phone_outlined, size: 20.sp),
                ),
                SizedBox(height: 16.h),
                // Blood group and Gender row
                Row(
                  children: [
                    // Blood group selector
                    Expanded(
                      child: GestureDetector(
                        onTap: _selectBloodGroup,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.divider),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bloodtype_outlined,
                                size: 20.sp,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  _selectedBloodGroup ?? AppStrings.bloodGroup,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: _selectedBloodGroup != null
                                        ? AppColors.textPrimary
                                        : AppColors.textHint,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    // Gender selector
                    Expanded(
                      child: CustomDropdownField<String>(
                        value: _selectedGender,
                        items: const [
                          AppStrings.male,
                          AppStrings.female,
                          AppStrings.other,
                        ],
                        label: AppStrings.gender,
                        itemLabel: (item) => item,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                        prefixIcon: Icon(Icons.person_outline, size: 20.sp),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Date of birth selector
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cake_outlined,
                          size: 20.sp,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            _dateOfBirth != null
                                ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                                : AppStrings.dateOfBirth,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: _dateOfBirth != null
                                  ? AppColors.textPrimary
                                  : AppColors.textHint,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.calendar_today,
                          size: 20.sp,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Password field
                PasswordTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: 'Create a password',
                  textInputAction: TextInputAction.next,
                  validator: Validators.validatePassword,
                ),
                SizedBox(height: 16.h),
                // Confirm password field
                PasswordTextField(
                  controller: _confirmPasswordController,
                  label: AppStrings.confirmPassword,
                  hint: 'Confirm your password',
                  textInputAction: TextInputAction.done,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                SizedBox(height: 8.h),
                // Age requirement note
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20.sp,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'You must be between ${AppConstants.minAge} and ${AppConstants.maxAge} years old to donate blood.',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                // Register button
                PrimaryButton(
                  text: AppStrings.signUp,
                  onPressed: _register,
                  isLoading: isLoading,
                ),
                SizedBox(height: 24.h),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.alreadyHaveAccount,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.login),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
