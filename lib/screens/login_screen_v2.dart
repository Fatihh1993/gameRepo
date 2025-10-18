import 'package:flutter/material.dart';
import '../services/auth_service_v2.dart';
import '../utils/theme_manager.dart';
import '../utils/language_manager.dart';
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
      _showMessage(widget.languageManager.isTurkish 
        ? 'Lütfen email/kullanıcı adı ve şifre girin' 
        : 'Please enter email/username and password', isError: true);
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
            builder: (_) => HomeScreen(
              themeManager: widget.themeManager,
              languageManager: widget.languageManager,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isTr = widget.languageManager.isTurkish;
        String errorMsg = isTr ? 'Giriş başarısız' : 'Login failed';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('user-not-found')) {
          errorMsg = isTr ? 'Bu email ile kayıtlı kullanıcı bulunamadı' : 'No user found with this email';
        } else if (errorStr.contains('kullanıcı adı bulunamadı')) {
          errorMsg = isTr ? 'Kullanıcı adı bulunamadı. Email ile giriş yapmayı deneyin.' : 'Username not found. Try logging in with email.';
        } else if (errorStr.contains('wrong-password') || 
                   errorStr.contains('invalid-credential')) {
          errorMsg = isTr ? 'Yanlış şifre veya kullanıcı bilgisi' : 'Wrong password or credentials';
        } else if (errorStr.contains('invalid-email')) {
          errorMsg = isTr ? 'Geçersiz email formatı' : 'Invalid email format';
        } else if (errorStr.contains('too-many-requests')) {
          errorMsg = isTr ? 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin.' : 'Too many attempts. Please try again later.';
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
      _showMessage(widget.languageManager.isTurkish 
        ? 'Lütfen tüm alanları doldurun' 
        : 'Please fill all fields', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showMessage(widget.languageManager.isTurkish 
        ? 'Şifre en az 6 karakter olmalıdır' 
        : 'Password must be at least 6 characters', isError: true);
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
            builder: (_) => HomeScreen(
              themeManager: widget.themeManager,
              languageManager: widget.languageManager,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final isTr = widget.languageManager.isTurkish;
        String errorMsg = isTr ? 'Kayıt başarısız' : 'Registration failed';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('email-already-in-use')) {
          errorMsg = isTr ? 'Bu email zaten kullanılıyor' : 'This email is already in use';
        } else if (errorStr.contains('kullanıcı adı zaten kullanılıyor')) {
          errorMsg = isTr ? 'Bu kullanıcı adı zaten alınmış. Başka bir kullanıcı adı deneyin.' : 'This username is already taken. Try another username.';
        } else if (errorStr.contains('invalid-email')) {
          errorMsg = isTr ? 'Geçersiz email formatı' : 'Invalid email format';
        } else if (errorStr.contains('weak-password')) {
          errorMsg = isTr ? 'Şifre çok zayıf. Daha güçlü bir şifre kullanın.' : 'Password is too weak. Use a stronger password.';
        } else if (errorStr.contains('profil oluşturulamadı')) {
          errorMsg = isTr ? 'Profil oluşturulamadı. Lütfen tekrar deneyin.' : 'Failed to create profile. Please try again.';
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
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.resetPassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.languageManager.isTurkish 
              ? 'Email adresinizi girin:' 
              : 'Enter your email address:'),
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
            onPressed: () => Navigator.pop(context),
            child: Text(widget.languageManager.isTurkish ? 'İptal' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isEmpty) {
                Navigator.pop(context);
                _showMessage(widget.languageManager.isTurkish 
                  ? 'Lütfen email girin' 
                  : 'Please enter email', isError: true);
                return;
              }

              try {
                await _authService.resetPassword(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showMessage(widget.languageManager.isTurkish 
                    ? 'Şifre sıfırlama linki email adresinize gönderildi!' 
                    : 'Password reset link sent to your email!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showMessage('${widget.languageManager.isTurkish ? 'Hata' : 'Error'}: ${e.toString()}', isError: true);
                }
              }
            },
            child: Text(widget.languageManager.isTurkish ? 'Gönder' : 'Send'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations(widget.languageManager.currentLanguage);
    
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
          child: Column(
            children: [
              // Üst Alan - Dil ve Tema Butonları
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Dil Değiştirme Butonu - ÇOK BÜYÜK VE BELİRGİN
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            setState(() {
                              widget.languageManager.setLanguage(
                                widget.languageManager.isTurkish ? 'en' : 'tr'
                              );
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.languageManager.isTurkish ? '🇹🇷' : '🇬🇧',
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.languageManager.isTurkish ? 'Türkçe' : 'English',
                                  style: const TextStyle(
                                    color: Color(0xFF6C63FF),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tema Değiştirme Butonu
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          widget.themeManager.toggleTheme();
                        },
                        icon: Icon(
                          widget.themeManager.themeMode == ThemeMode.dark
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color: const Color(0xFF6C63FF),
                          size: 32,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Ana İçerik - Genişletilmiş
              Expanded(
                child: Center(
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
                        loc.welcome,
                        style: const TextStyle(
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
                                          loc.login,
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
                                          loc.register,
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

                              // Email veya Username Field
                              TextField(
                                controller: _emailController,
                                keyboardType: _isRegisterMode 
                                    ? TextInputType.emailAddress 
                                    : TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: _isRegisterMode ? loc.email : '${loc.email} / ${loc.username}',
                                  hintText: _isRegisterMode 
                                      ? 'example@email.com' 
                                      : '${loc.email} / ${loc.username}',
                                  prefixIcon: Icon(
                                    _isRegisterMode 
                                        ? Icons.email_outlined 
                                        : Icons.account_circle_outlined,
                                  ),
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
                                    labelText: loc.username,
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
                                  labelText: loc.password,
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
                                    child: Text('${loc.forgotPassword}?'),
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
                                          _isRegisterMode ? loc.register : loc.login,
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
              ), // Expanded kapatma
            ],
          ),
        ),
      ),
    );
  }
}