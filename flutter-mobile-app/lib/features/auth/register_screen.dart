import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/network/api_exception.dart';
import '../../shared/widgets/foodpulse_logo.dart';
import '../../shared/widgets/primary_button.dart';
import 'auth_api_service.dart';
import 'demo_account.dart';
import 'login_screen.dart';

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
      setState(() => _errorMessage = 'Contact number must contain digits only.');
      return;
    }

    if (contactNumber.length > DemoAccount.maxContactNumberLength) {
      setState(
        () => _errorMessage = 'Contact number cannot exceed 11 digits.',
      );
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
      setState(
        () => _errorMessage = 'Password must be at least 6 characters.',
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.prussian,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FoodPulseLogo(),
                  const SizedBox(height: 18),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create your FoodPulse account to order, track riders, and manage checkout preferences.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.silver,
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    key: const Key('register_username'),
                    controller: _usernameController,
                    style: const TextStyle(color: AppColors.white),
                    maxLength: DemoAccount.maxUsernameLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9._-]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      counterText: '',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_email'),
                    controller: _emailController,
                    style: const TextStyle(color: AppColors.white),
                    keyboardType: TextInputType.emailAddress,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9@._-]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_contact_number'),
                    controller: _contactController,
                    style: const TextStyle(color: AppColors.white),
                    keyboardType: TextInputType.phone,
                    maxLength: DemoAccount.maxContactNumberLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Contact number',
                      counterText: '',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_password'),
                    controller: _passwordController,
                    style: const TextStyle(color: AppColors.white),
                    obscureText: true,
                    maxLength: DemoAccount.maxPasswordLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
                      ),
                    ],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      counterText: '',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('register_confirm_password'),
                    controller: _confirmPasswordController,
                    style: const TextStyle(color: AppColors.white),
                    obscureText: true,
                    maxLength: DemoAccount.maxPasswordLength,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
                      ),
                    ],
                    onSubmitted: (_) => _register(),
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      counterText: '',
                      prefixIcon: Icon(Icons.verified_user_outlined),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _AuthMessage(
                      message: _errorMessage!,
                      color: AppColors.tangerine,
                    ),
                  ],
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: _isSubmitting ? 'Creating Account...' : 'Register',
                    onPressed: _register,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account?',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
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
