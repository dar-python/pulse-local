import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_colors.dart';
import '../home/home_screen.dart';
import 'auth_api_service.dart';
import 'demo_account.dart';
import 'register_screen.dart';

const _loginNavy = Color(0xFF061A2F);
const _loginNavyTop = Color(0xFF051428);
const _loginNavyBottom = Color(0xFF071E38);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.message, this.authApiService});

  final String? message;
  final AuthApiService? authApiService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthApiService _authApiService;
  String? _errorMessage;
  String? _successMessage;
  Timer? _successMessageTimer;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _authApiService = widget.authApiService ?? AuthApiService();
    _successMessage = widget.message;

    if (_successMessage != null) {
      _successMessageTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    }
  }

  @override
  void dispose() {
    _successMessageTimer?.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isSubmitting) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.length > DemoAccount.maxUsernameLength) {
      setState(() => _errorMessage = 'Username cannot exceed 25 characters.');
      return;
    }

    if (password.length > DemoAccount.maxPasswordLength) {
      setState(() => _errorMessage = 'Password cannot exceed 15 characters.');
      return;
    }

    if (username.isNotEmpty &&
        !DemoAccount.usernamePattern.hasMatch(username)) {
      setState(
        () => _errorMessage =
            'Username can only use letters, numbers, dot, dash, or underscore.',
      );
      return;
    }

    if (password.isNotEmpty &&
        !DemoAccount.passwordPattern.hasMatch(password)) {
      setState(
        () => _errorMessage = 'Password contains unsupported characters.',
      );
      return;
    }

    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isSubmitting = true;
    });

    try {
      final user = await _authApiService.login(
        username: username,
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
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  void _openRegister() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: _loginNavy,
        systemNavigationBarDividerColor: _loginNavy,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _loginNavy,
        body: ClipRect(
          child: ColoredBox(
            color: _loginNavy,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(child: _LoginBackdrop()),
                SafeArea(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.hardEdge,
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 4),
                            const _LoginHero(),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                              ),
                              child: _LoginPanel(
                                usernameController: _usernameController,
                                passwordController: _passwordController,
                                obscurePassword: _obscurePassword,
                                isSubmitting: _isSubmitting,
                                successMessage: _successMessage,
                                errorMessage: _errorMessage,
                                onTogglePassword: () {
                                  setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  );
                                },
                                onLogin: _login,
                                onRegister: _openRegister,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHero extends StatelessWidget {
  const _LoginHero();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final heroHeight = (constraints.maxWidth * 0.76).clamp(260.0, 410.0);

        return ColoredBox(
          color: _loginNavy,
          child: SizedBox(
            height: heroHeight,
            child: ClipRect(
              child: Image.asset(
                'assets/images/auth/eagle.png',
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.usernameController,
    required this.passwordController,
    required this.obscurePassword,
    required this.isSubmitting,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onRegister,
    this.successMessage,
    this.errorMessage,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final Future<void> Function() onLogin;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0C2A43).withAlpha(238),
                const Color(0xFF051D31).withAlpha(246),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF5E7FA4).withAlpha(82)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Log in to your account',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 25,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Nice to see you again! 👋',
                style: TextStyle(
                  color: AppColors.alabaster,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (successMessage != null) ...[
                const SizedBox(height: 16),
                _AuthMessage(message: successMessage!, color: AppColors.green),
              ],
              const SizedBox(height: 24),
              _LoginField(
                keyValue: const Key('login_username'),
                controller: usernameController,
                hintText: 'Enter your username',
                icon: Icons.person_outline_rounded,
                maxLength: DemoAccount.maxUsernameLength,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._-]')),
                ],
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _LoginField(
                keyValue: const Key('login_password'),
                controller: passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline_rounded,
                obscureText: obscurePassword,
                maxLength: DemoAccount.maxPasswordLength,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[A-Za-z0-9!@#$%^&*._-]'),
                  ),
                ],
                onSubmitted: (_) => onLogin(),
                suffixIcon: IconButton(
                  onPressed: onTogglePassword,
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF9EABC1),
                    size: 26,
                  ),
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                _AuthMessage(
                  message: errorMessage!,
                  color: AppColors.tangerine,
                ),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: AppColors.orange,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _LoginSubmitButton(
                label: isSubmitting ? 'Logging in...' : 'Log in',
                onPressed: () => onLogin(),
              ),
              const SizedBox(height: 26),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: AppColors.silver,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: onRegister,
                    child: const Text(
                      'Register',
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
    );
  }
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyValue,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.textInputAction,
    this.onSubmitted,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final Key? keyValue;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: const Color(0xFF6D86A8).withAlpha(118),
        width: 1.5,
      ),
    );

    return SizedBox(
      height: 58,
      child: TextField(
        key: keyValue,
        controller: controller,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        obscureText: obscureText,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFF08263D).withAlpha(188),
          hintText: hintText,
          counterText: '',
          hintStyle: const TextStyle(
            color: Color(0xFF9EABC1),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppColors.orange, size: 26),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _LoginSubmitButton extends StatelessWidget {
  const _LoginSubmitButton({required this.label, required this.onPressed});

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
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
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

class _LoginBackdrop extends StatelessWidget {
  const _LoginBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_loginNavyTop, _loginNavy, _loginNavyBottom],
        ),
      ),
      child: CustomPaint(painter: _Clouds()),
    );
  }
}

class _Clouds extends CustomPainter {
  const _Clouds();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.white.withAlpha(10);
    _cloud(canvas, paint, Offset(size.width * 0.06, size.height * 0.11), 0.72);
    _cloud(canvas, paint, Offset(size.width * 0.37, size.height * 0.09), 0.66);
    _cloud(canvas, paint, Offset(size.width * 0.72, size.height * 0.09), 0.86);
  }

  void _cloud(Canvas canvas, Paint paint, Offset origin, double scale) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    canvas.drawCircle(const Offset(22, 6), 18, paint);
    canvas.drawCircle(const Offset(44, 0), 24, paint);
    canvas.drawCircle(const Offset(70, 9), 16, paint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 16, 96, 16),
        const Radius.circular(10),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
