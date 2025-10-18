import 'package:flutter/material.dart';
import '../services/auth_service_v2.dart';
import '../utils/theme_manager.dart';
import 'home_screen.dart';

class LoginScreenV2 extends StatefulWidget {
  final ThemeManager themeManager;
  
  const LoginScreenV2({super.key, required this.themeManager});

  @override
  State<LoginScreenV2> createState() => _LoginScreenV2State();
}

class _LoginScreenV2State extends State<LoginScreenV2> {
  final _authService = AuthServiceV2();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showMessage('Lütfen email ve şifre girin', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(themeManager: widget.themeManager),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Giriş başarısız';
        if (e.toString().contains('user-not-found')) {
          errorMsg = 'Kullanıcı bulunamadı';
        } else if (e.toString().contains('wrong-password') || 
                   e.toString().contains('invalid-credential')) {
          errorMsg = 'Yanlış şifre';
        }
        _showMessage(errorMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleRegister() async {
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      _showMessage('Lütfen tüm alanları doldurun', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage('Şifre en az 6 karakter olmalıdır', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => HomeScreen(themeManager: widget.themeManager),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Kayıt başarısız';
        if (e.toString().contains('email-already-in-use')) {
          errorMsg = 'Bu email zaten kullanılıyor';
        } else if (e.toString().contains('invalid-email')) {
          errorMsg = 'Geçersiz email formatı';
        }
        _showMessage(errorMsg, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Email adresinizi girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                Navigator.pop(context);
                _showMessage('Lütfen email girin', isError: true);
                return;
              }

              try {
                await _authService.resetPassword(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showMessage('Şifre sıfırlama linki email adresinize gönderildi!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showMessage('Hata: ${e.toString()}', isError: true);
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF),
              const Color(0xFF5A52D5),
              Colors.purple.shade400,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Tema Değiştirme Butonu (Sağ Üst)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  onPressed: () {
                    widget.themeManager.toggleTheme();
                  },
                  icon: Icon(
                    widget.themeManager.themeMode == ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    color: Colors.white,
                    size: 28,
                  ),
                  tooltip: widget.themeManager.themeMode == ThemeMode.dark
                      ? 'Aydınlık Tema'
                      : 'Karanlık Tema',
                ),
              ),
              
              // Ana İçerik
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Title
                      const Icon(
                        Icons.code,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Code Quiz Game',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Kodlama bilginizi test edin!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form Card
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Toggle: Giriş / Kayıt
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isRegisterMode = false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: !_isRegisterMode 
                                              ? const Color(0xFF6C63FF) 
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Giriş Yap',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: !_isRegisterMode ? Colors.white : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isRegisterMode = true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _isRegisterMode 
                                              ? const Color(0xFF6C63FF) 
                                              : Colors.grey[200],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Kayıt Ol',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _isRegisterMode ? Colors.white : Colors.grey,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Email Field
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Username (sadece kayıt modunda)
                              if (_isRegisterMode) ...[
                                TextField(
                                  controller: _usernameController,
                                  decoration: InputDecoration(
                                    labelText: 'Kullanıcı Adı',
                                    prefixIcon: const Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  labelText: 'Şifre',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSubmitted: (_) => _isRegisterMode 
                                    ? _handleRegister() 
                                    : _handleLogin(),
                              ),

                              // Şifremi Unuttum (sadece giriş modunda)
                              if (!_isRegisterMode) ...[
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showForgotPasswordDialog,
                                    child: const Text('Şifremi Unuttum?'),
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading 
                                      ? null 
                                      : (_isRegisterMode ? _handleRegister : _handleLogin),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6C63FF),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          _isRegisterMode ? 'Kayıt Ol' : 'Giriş Yap',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
