import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import 'auth_api_service.dart';
import 'demo_account.dart';
import 'login_screen.dart';

const _registerNavy = Color(0xFF061A2F);
const _registerNavyTop = Color(0xFF051428);
const _registerNavyBottom = Color(0xFF071E38);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authApiService = AuthApiService();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_isSubmitting) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final contactNumber = _contactController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (username.isEmpty ||
        email.isEmpty ||
        contactNumber.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Complete all registration fields.');
      return;
    }

    if (!DemoAccount.usernamePattern.hasMatch(username)) {
      setState(
        () => _errorMessage =
            'Username can only use letters, numbers, dot, dash, or underscore.',
      );
      return;
    }

    if (username.length > DemoAccount.maxUsernameLength) {
      setState(() => _errorMessage = 'Username cannot exceed 25 characters.');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Enter a valid email address.');
      return;
    }

    if (!DemoAccount.contactNumberPattern.hasMatch(contactNumber)) {
      setState(
        () => _errorMessage = 'Contact number must contain digits only.',
      );
      return;
    }

    if (contactNumber.length > DemoAccount.maxContactNumberLength) {
      setState(() => _errorMessage = 'Contact number cannot exceed 11 digits.');
      return;
    }

    if (contactNumber.length < 10) {
      setState(() => _errorMessage = 'Enter a valid contact number.');
      return;
    }

    if (!DemoAccount.passwordPattern.hasMatch(password) ||
        !DemoAccount.passwordPattern.hasMatch(confirmPassword)) {
      setState(
        () => _errorMessage = 'Password contains unsupported characters.',
      );
      return;
    }

    if (password.length > DemoAccount.maxPasswordLength) {
      setState(() => _errorMessage = 'Password cannot exceed 15 characters.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isSubmitting = true;
    });

    try {
      final user = await _authApiService.register(
        username: username,
        email: email,
        contactNumber: contactNumber,
        password: password,
      );

      DemoAccount.updateFromApi(
        username: user.username,
        email: user.email,
        contactNumber: user.contactNumber,
        password: password,
      );
      await DemoAccount.save();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isSubmitting = false;
        });
      }
      return;
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const LoginScreen(
          message: 'Account created. Login with your new credentials.',
        ),
      ),
    );
  }

  void _openLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: _registerNavy,
        systemNavigationBarDividerColor: _registerNavy,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _registerNavy,
        body: ClipRect(
          child: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_registerNavyTop, _registerNavy, _registerNavyBottom],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  clipBehavior: Clip.hardEdge,
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _RegisterBrand(),
                        const SizedBox(height: 26),
                        const Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 25,
                            height: 1.1,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Create your FoodPulse account to order, track riders, and manage checkout preferences.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFAAB8CA),
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        _RegisterField(
                          key: const Key('register_username'),
                          controller: _usernameController,
                          hintText: 'Username',
                          icon: Icons.person_outline_rounded,
                          maxLength: DemoAccount.maxUsernameLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9._-]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RegisterField(
                          key: const Key('register_email'),
                          controller: _emailController,
                          hintText: 'Email address',
                          icon: Icons.mail_outline_rounded,
                          keyboardType: TextInputType.emailAddress,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9@._-]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RegisterField(
                          key: const Key('register_contact_number'),
                          controller: _contactController,
                          hintText: 'Contact number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          maxLength: DemoAccount.maxContactNumberLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RegisterField(
                          key: const Key('register_password'),
                          controller: _passwordController,
                          hintText: 'Password',
                          icon: Icons.lock_outline_rounded,
                          obscureText: true,
                          maxLength: DemoAccount.maxPasswordLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
                            ),
                          ],
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 14),
                        _RegisterField(
                          key: const Key('register_confirm_password'),
                          controller: _confirmPasswordController,
                          hintText: 'Confirm password',
                          icon: Icons.verified_user_outlined,
                          obscureText: true,
                          maxLength: DemoAccount.maxPasswordLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
                            ),
                          ],
                          onSubmitted: (_) => _register(),
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          _AuthMessage(
                            message: _errorMessage!,
                            color: AppColors.tangerine,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _RegisterSubmitButton(
                          label: _isSubmitting
                              ? 'Creating Account...'
                              : 'Register',
                          onPressed: _register,
                        ),
                        const SizedBox(height: 22),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            const Text(
                              'Already have an account?',
                              style: TextStyle(
                                color: AppColors.silver,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextButton(
                              onPressed: _openLogin,
                              child: const Text(
                                'Login',
                                style: TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterBrand extends StatelessWidget {
  const _RegisterBrand();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 210,
        height: 250,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: 920,
            maxHeight: 736,
            child: Transform.translate(
              offset: const Offset(-110, -98),
              child: Image.asset(
                'assets/images/auth/eagle.png',
                width: 920,
                height: 736,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  const _RegisterField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(
        color: const Color(0xFF41607D).withAlpha(118),
        width: 1.2,
      ),
    );

    return SizedBox(
      height: 58,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        obscureText: obscureText,
        maxLength: maxLength,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF142E48),
          hintText: hintText,
          counterText: '',
          hintStyle: const TextStyle(
            color: Color(0xFF9EABC1),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9EABC1), size: 23),
          contentPadding: const EdgeInsets.symmetric(horizontal: 18),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.orange, width: 1.4),
          ),
        ),
      ),
    );
  }
}

class _RegisterSubmitButton extends StatelessWidget {
  const _RegisterSubmitButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB21B), Color(0xFFFFA30A)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onPressed,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.prussian,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthMessage extends StatelessWidget {
  const _AuthMessage({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(32),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
