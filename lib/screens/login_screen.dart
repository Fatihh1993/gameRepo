import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/theme_manager.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  final ThemeManager themeManager;
  
  const LoginScreen({super.key, required this.themeManager});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isRegisterMode = false; // Kayıt/Giriş modu
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      print('🔐 Giriş denemesi: ${_usernameController.text.trim()}');
      
      final usernameOrEmail = _usernameController.text.trim();
      
      // Email formatı mı kontrol et
      if (usernameOrEmail.contains('@')) {
        // Email ile direkt giriş
        print('📧 Email ile giriş yapılıyor...');
        await _authService.login(usernameOrEmail, _passwordController.text);
      } else {
        // Username ile giriş
        await _authService.loginWithUsername(
          username: usernameOrEmail,
          password: _passwordController.text,
        );
      }
      
      print('✅ Giriş başarılı!');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(themeManager: widget.themeManager)),
        );
      }
    } catch (e) {
      print('❌ Giriş hatası: $e');
      if (mounted) {
        String errorMessage = 'Giriş başarısız';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Kullanıcı bulunamadı';
        } else if (e.toString().contains('wrong-password')) {
          errorMessage = 'Yanlış şifre';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Geçersiz email formatı';
        } else if (e.toString().contains('Kullanıcı bulunamadı')) {
          errorMessage = 'Bu kullanıcı adı kayıtlı değil.\nEmail adresiniz ile giriş yapmayı deneyin.';
        } else {
          errorMessage = 'Giriş başarısız: ${e.toString()}';
        }
        
        _showError(errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _register() async {
    if (_usernameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır');
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      // Firebase Auth ile kayıt
      await _authService.registerWithUsername(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomeScreen(themeManager: widget.themeManager)),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Kayıt başarısız: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
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
            const Text('Kullanıcı adınızı veya email adresinizi girin.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Kullanıcı Adı veya Email',
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
                _showError('Lütfen kullanıcı adı veya email girin');
                return;
              }
              
              try {
                await _authService.resetPassword(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  _showSuccess('Şifre sıfırlama linki email adresinize gönderildi!');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showError('Hata: ${e.toString()}');
                }
              }
            },
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(isSelected ? 1.0 : 0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF6C63FF) : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
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
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
              Theme.of(context).colorScheme.tertiary,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo ve Başlık
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.code,
                        size: 80,
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Code Quiz',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kodlama Bilginizi Test Edin!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Giriş/Kayıt Formu
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Giriş/Kayıt Toggle
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
                                            : Colors.transparent,
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
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isRegisterMode = true),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isRegisterMode 
                                            ? const Color(0xFF6C63FF) 
                                            : Colors.transparent,
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
                            
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Kullanıcı Adı veya Email',
                                hintText: 'kullanici veya email@mail.com',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            
                            // Email (sadece kayıt modunda)
                            if (_isRegisterMode) ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              onSubmitted: (_) => _isRegisterMode ? _register() : _login(),
                            ),
                            
                            // Şifremi Unuttum (sadece giriş modunda)
                            if (!_isRegisterMode) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    'Şifremi Unuttum?',
                                    style: TextStyle(
                                      color: Color(0xFF6C63FF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading 
                                    ? null 
                                    : (_isRegisterMode ? _register : _login),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
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
                    const SizedBox(height: 24),
                    
                    // Tema Seçimi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '🎨 Tema Seçimi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildThemeButton(
                                icon: Icons.light_mode,
                                label: 'Aydınlık',
                                isSelected: widget.themeManager.themeMode == ThemeMode.light,
                                onTap: () => widget.themeManager.setTheme(ThemeMode.light),
                              ),
                              const SizedBox(width: 16),
                              _buildThemeButton(
                                icon: Icons.dark_mode,
                                label: 'Karanlık',
                                isSelected: widget.themeManager.themeMode == ThemeMode.dark,
                                onTap: () => widget.themeManager.setTheme(ThemeMode.dark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Demo/Test bilgisi
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            '💡 Test Kullanıcısı',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text(
                                  'Test Hesabı:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Email: test@codequiz.com\nŞifre: test123456',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.95),
                                    fontSize: 13,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    _usernameController.text = 'test@codequiz.com';
                                    _passwordController.text = 'test123456';
                                    setState(() => _isRegisterMode = false);
                                    _showSuccess('Test hesabı bilgileri dolduruldu!');
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text('Formu Doldur'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF6C63FF),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'veya',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Yeni demo kullanıcı bilgilerini formlara doldur
                              final timestamp = DateTime.now().millisecondsSinceEpoch;
                              _usernameController.text = 'user_$timestamp';
                              _emailController.text = 'user$timestamp@test.com';
                              _passwordController.text = 'pass123456';
                              setState(() => _isRegisterMode = true);
                              _showSuccess('Yeni hesap bilgileri dolduruldu! "Kayıt Ol" butonuna basın.');
                            },
                            icon: const Icon(Icons.person_add),
                            label: const Text('Yeni Hesap Oluştur'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Şifrenizi unuttunuz mu?\n"Şifremi Unuttum" butonunu kullanın!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
