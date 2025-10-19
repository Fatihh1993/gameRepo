import 'package:flutter/material.dart';

import '../services/auth_service_v2.dart';
import '../utils/app_colors.dart';
import '../utils/language_manager.dart';
import '../utils/theme_manager.dart';
import 'home_screen.dart';

class LoginScreenV2 extends StatefulWidget {
  final ThemeManager themeManager;
  final LanguageManager languageManager;

  const LoginScreenV2({
    super.key,
    required this.themeManager,
    required this.languageManager,
  });

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  final AuthServiceV2 _authService = AuthServiceV2();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleLogin() async {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage(loc.loginMissingCredentials, isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            themeManager: widget.themeManager,
            languageManager: widget.languageManager,
          ),
        ),
      );
    } catch (error) {
      final errorMessage = _mapAuthErrorToMessage(error);
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      _showMessage(loc.registerMissingFields, isError: true);
      return;
    }

    if (_passwordController.text.trim().length < 6) {
      _showMessage(loc.passwordTooShort(6), isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            themeManager: widget.themeManager,
            languageManager: widget.languageManager,
          ),
        ),
      );
    } catch (error) {
      final errorMessage = _mapAuthErrorToMessage(error);
      _showMessage(errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapAuthErrorToMessage(Object error) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final message = error.toString().toLowerCase();

    if (message.contains('user-not-found')) {
      return loc.emailNotFound;
    }
    if (message.contains('username')) {
      return loc.usernameNotFound;
    }
    if (message.contains('wrong-password') ||
        message.contains('invalid-credential')) {
      return loc.wrongCredentials;
    }
    if (message.contains('invalid-email')) {
      return loc.invalidEmail;
    }
    if (message.contains('too-many-requests')) {
      return loc.tooManyRequests;
    }
    if (message.contains('already-in-use')) {
      return loc.emailAlreadyUsed;
    }
    return loc.loginFailed;
  }

  Future<void> _showForgotPasswordDialog() async {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.resetPassword),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(loc.enterEmailHint),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: loc.email,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  Navigator.of(context).pop();
                  _showMessage(loc.loginMissingCredentials, isError: true);
                  return;
                }

                try {
                  await _authService.resetPassword(controller.text.trim());
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _showMessage(loc.passwordResetSent);
                } catch (_) {
                  if (!mounted) return;
                  Navigator.of(context).pop();
                  _showMessage(loc.loginFailed, isError: true);
                }
              },
              child: Text(loc.send),
            ),
          ],
        );
      },
    );
  }

  void _toggleLanguage() {
    final newLang = widget.languageManager.isTurkish ? 'en' : 'tr';
    widget.languageManager.setLanguage(newLang);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _LanguageToggleButton(
                      isTurkish: widget.languageManager.isTurkish,
                      onTap: _toggleLanguage,
                      loc: loc,
                    ),
                    const SizedBox(width: 12),
                    _ThemeToggleButton(themeManager: widget.themeManager),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.code_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          loc.appName,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc.homeGreeting,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _buildAuthCard(loc),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard(AppLocalizations loc) {
    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _AuthToggleChip(
                    label: loc.login,
                    isActive: !_isRegisterMode,
                    onTap: () {
                      setState(() {
                        _isRegisterMode = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _AuthToggleChip(
                    label: loc.register,
                    isActive: _isRegisterMode,
                    onTap: () {
                      setState(() {
                        _isRegisterMode = true;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _isRegisterMode ? _emailController : _emailController,
              keyboardType: _isRegisterMode
                  ? TextInputType.emailAddress
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: _isRegisterMode ? loc.email : loc.emailOrUsername,
                hintText:
                    _isRegisterMode ? 'example@email.com' : loc.emailOrUsername,
                prefixIcon: Icon(
                  _isRegisterMode ? Icons.mail_outline : Icons.person_outline,
                ),
              ),
            ),
            if (_isRegisterMode) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: loc.username,
                  prefixIcon: const Icon(Icons.tag_faces_outlined),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: loc.password,
                prefixIcon: const Icon(Icons.lock_outline),
              ),
              onSubmitted: (_) =>
                  _isRegisterMode ? _handleRegister() : _handleLogin(),
            ),
            if (!_isRegisterMode) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  child: Text('${loc.forgotPassword}?'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isRegisterMode ? _handleRegister : _handleLogin),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _isRegisterMode ? loc.register : loc.login,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() {
                  _isRegisterMode = !_isRegisterMode;
                });
              },
              child: Text(
                _isRegisterMode ? loc.alreadyHaveAccount : loc.dontHaveAccount,
              ),          
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final ThemeManager themeManager;

  const _ThemeToggleButton({required this.themeManager});

  @override
  Widget build(BuildContext context) {
    final isDark = themeManager.isDark;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),                
        ],
      ),
      child: IconButton(
        icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
        color: AppColors.primary,
        onPressed: themeManager.toggleTheme,
      ),
    );
  }
}

class _LanguageToggleButton extends StatelessWidget {
  final bool isTurkish;
  final VoidCallback onTap;
  final AppLocalizations loc;

  const _LanguageToggleButton({
    required this.isTurkish,
    required this.onTap,
    required this.loc,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isTurkish ? '🇹🇷' : '🇬🇧',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                isTurkish ? loc.turkish : loc.english,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthToggleChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _AuthToggleChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
