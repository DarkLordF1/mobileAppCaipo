import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/gradient_scaffold.dart';
import 'auth_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool isLoading = false;
  bool rememberMe = false;
  bool isPasswordVisible = false;
  bool isHoveringLogin = false;
  String? emailError;
  String? passwordError;
  
  // Map to track hover states for different elements
  final Map<String, bool> _hoveredItems = {};
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    _animationController = AnimationController(
      vsync: this,
      duration: themeProvider.animationDurationLong,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    
    _animationController.forward();
  }
  
  Future<void> handleLogin() async {
    // Clear previous errors
    setState(() {
      emailError = null;
      passwordError = null;
    });
    
    // Validate the form
    if (_formKey.currentState!.validate()) {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      setState(() => isLoading = true);
      
      try {
        // Simulate login API call
        await Future.delayed(const Duration(seconds: 1));
        
        // Check credentials (this would be replaced with actual auth logic)
        if (email == 'test@example.com' && password == 'password') {
          if (!mounted) return;
          
          // Save remember me state if needed
          if (rememberMe) {
            // Would use SharedPreferences to store email 
            // (never store passwords directly)
          }
          
          // Navigate to home page on success
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Show error message for invalid credentials
          setState(() {
            passwordError = 'Invalid email or password. Try test@example.com / password';
          });
        }
      } catch (e) {
        // Handle any errors during login
        setState(() {
          passwordError = 'An error occurred. Please try again.';
        });
      } finally {
        // Reset loading state
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return GradientScaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // App logo with animation
                  _buildAnimatedLogo(themeProvider),
                  const SizedBox(height: 16),
                  
                  // App title with shine effect
                  Center(child: _buildAppTitle(themeProvider)),
                  Center(child: Text(
                    'by FLOMAD',
                    style: themeProvider.titleMedium.copyWith(
                      color: themeProvider.secondaryTextColor,
                    ),
                  )),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Voice Recording & Transcription',
                      style: themeProvider.bodyMedium.copyWith(
                        color: themeProvider.secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form with email and password
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: emailController,
                          hintText: 'Email address',
                          icon: Icons.email,
                          errorText: emailError,
                          themeProvider: themeProvider,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        _buildInputField(
                          controller: passwordController,
                          hintText: 'Password',
                          icon: Icons.lock,
                          errorText: passwordError,
                          obscureText: !isPasswordVisible,
                          themeProvider: themeProvider,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible 
                                  ? Icons.visibility_off 
                                  : Icons.visibility,
                              color: themeProvider.secondaryIconColor,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  _buildRememberMeRow(themeProvider),
                  const SizedBox(height: 24),
                  
                  // Login button
                  _buildLoginButton(themeProvider),
                  const SizedBox(height: 16),
                  
                  // Get Started button
                  _buildSignUpOption(themeProvider),
                  const SizedBox(height: 24),
                  
                  // Social login section
                  _buildSocialLoginSection(themeProvider),
                  
                  const SizedBox(height: 24),
                  
                  // Footer links
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () {
                          // TODO: Implement privacy policy
                        },
                        child: Text(
                          'Privacy',
                          style: themeProvider.bodyMedium.copyWith(
                            color: themeProvider.accentColor,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: themeProvider.bodyMedium.copyWith(
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement terms
                        },
                        child: Text(
                          'Terms',
                          style: themeProvider.bodyMedium.copyWith(
                            color: themeProvider.accentColor,
                          ),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: themeProvider.bodyMedium.copyWith(
                          color: themeProvider.secondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Implement help
                        },
                        child: Text(
                          'Help',
                          style: themeProvider.bodyMedium.copyWith(
                            color: themeProvider.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAnimatedLogo(ThemeProvider themeProvider) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Hero(
        tag: 'app_logo',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: themeProvider.accentColor.withOpacity(0.3),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset('assets/logo.png', height: 100),
        ),
      ),
    );
  }
  
  Widget _buildAppTitle(ThemeProvider themeProvider) {
    return ShaderMask(
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            themeProvider.accentColor.withOpacity(0.7),
            Colors.white,
            themeProvider.accentColor.withOpacity(0.7),
          ],
          stops: const [0.0, 0.5, 1.0],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          tileMode: TileMode.clamp,
        ).createShader(bounds);
      },
      child: Text(
        'CAIPO',
        style: themeProvider.displayMedium.copyWith(
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildLoginButton(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        onEnter: (_) => setState(() => isHoveringLogin = true),
        onExit: (_) => setState(() => isHoveringLogin = false),
        child: AnimatedContainer(
          duration: themeProvider.animationDurationShort,
          transform: isHoveringLogin 
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          child: ElevatedButton(
            onPressed: isLoading ? null : handleLogin,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: themeProvider.accentColor,
              foregroundColor: Colors.white,
              elevation: isHoveringLogin ? 8 : 4,
              shadowColor: themeProvider.accentColor.withOpacity(isHoveringLogin ? 0.6 : 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              ),
            ),
            child: isLoading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'LOG IN',
                    style: themeProvider.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSignUpOption(ThemeProvider themeProvider) {
    return SizedBox(
      width: double.infinity,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hoveredItems['signup'] = true),
        onExit: (_) => setState(() => _hoveredItems['signup'] = false),
        child: AnimatedContainer(
          duration: themeProvider.animationDurationShort,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(themeProvider.borderRadius),
            border: Border.all(
              color: _hoveredItems['signup'] == true
                  ? themeProvider.accentColor
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const AuthScreen(signUpMode: true),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOutCubic))
                            .animate(animation),
                        child: child,
                      ),
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 500),
                ),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              ),
              foregroundColor: _hoveredItems['signup'] == true
                  ? themeProvider.accentColor
                  : themeProvider.accentColor.withOpacity(0.8),
            ),
            child: Text(
              'Get Started',
              style: themeProvider.titleMedium.copyWith(
                color: themeProvider.accentColor,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required ThemeProvider themeProvider,
    bool obscureText = false,
    String? errorText,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    final String fieldKey = hintText.toLowerCase().replaceAll(' ', '_');
    final bool isHovered = _hoveredItems[fieldKey] ?? false;
    
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hoveredItems[fieldKey] = true),
          onExit: (_) => setState(() => _hoveredItems[fieldKey] = false),
          child: AnimatedContainer(
            duration: themeProvider.animationDurationShort,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(themeProvider.borderRadius),
              boxShadow: isHovered ? [
                BoxShadow(
                  color: themeProvider.accentColor.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              style: themeProvider.bodyLarge.copyWith(
                color: Colors.white,
              ),
              validator: validator,
              decoration: InputDecoration(
                filled: true,
                fillColor: isHovered ? Colors.white.withOpacity(0.3) : Colors.white24,
                hintText: hintText,
                hintStyle: themeProvider.bodyMedium.copyWith(
                  color: Colors.white54,
                ),
                prefixIcon: Icon(icon, color: isHovered ? Colors.white : Colors.white70),
                suffixIcon: suffixIcon,
                errorText: errorText,
                errorStyle: themeProvider.bodySmall.copyWith(
                  color: themeProvider.errorColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  borderSide: BorderSide(color: themeProvider.accentColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  borderSide: BorderSide(color: themeProvider.errorColor, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(themeProvider.borderRadius),
                  borderSide: BorderSide(color: themeProvider.errorColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onFieldSubmitted: (_) {
                if (_formKey.currentState!.validate()) {
                  handleLogin();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRememberMeRow(ThemeProvider themeProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Row(
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                checkboxTheme: CheckboxThemeData(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              child: Checkbox(
                value: rememberMe,
                onChanged: (value) {
                  setState(() => rememberMe = value ?? false);
                },
                activeColor: themeProvider.accentColor,
                checkColor: Colors.white,
              ),
            ),
            Text(
              "Remember Me",
              style: themeProvider.bodyMedium.copyWith(
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const Spacer(),
            MouseRegion(
              onEnter: (_) => setState(() => _hoveredItems['forgot'] = true),
              onExit: (_) => setState(() => _hoveredItems['forgot'] = false),
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset functionality coming soon'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: themeProvider.accentColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: AnimatedDefaultTextStyle(
                  duration: themeProvider.animationDurationShort,
                  style: themeProvider.bodyMedium.copyWith(
                    color: themeProvider.accentColor,
                    fontWeight: _hoveredItems['forgot'] == true ? FontWeight.bold : FontWeight.w600,
                    decoration: _hoveredItems['forgot'] == true ? TextDecoration.underline : TextDecoration.none,
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required String label,
    required ThemeProvider themeProvider,
    required VoidCallback onPressed,
  }) {
    final String buttonKey = 'social_${label.toLowerCase()}';
    
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hoveredItems[buttonKey] = true),
      onExit: (_) => setState(() => _hoveredItems[buttonKey] = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: _hoveredItems[buttonKey] == true ? 1.1 : 1.0,
        ),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: themeProvider.cardBackground.withOpacity(0.3),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _hoveredItems[buttonKey] == true
                    ? color.withOpacity(0.3)
                    : Colors.black.withOpacity(0.1),
                blurRadius: _hoveredItems[buttonKey] == true ? 8 : 4,
                spreadRadius: _hoveredItems[buttonKey] == true ? 1 : 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              hoverColor: color.withOpacity(0.2),
              splashColor: color.withOpacity(0.3),
              highlightColor: color.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: FaIcon(
                  icon, 
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginSection(ThemeProvider themeProvider) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Text(
              'Or sign in with',
              style: themeProvider.bodyMedium.copyWith(
                color: themeProvider.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSocialButton(
                  icon: FontAwesomeIcons.google,
                  color: Colors.red,
                  label: 'Google',
                  themeProvider: themeProvider,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google sign-in coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: FontAwesomeIcons.apple,
                  color: Colors.white,
                  label: 'Apple',
                  themeProvider: themeProvider,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apple sign-in coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: FontAwesomeIcons.facebook,
                  color: Colors.blue.shade600,
                  label: 'Facebook',
                  themeProvider: themeProvider,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Facebook sign-in coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                _buildSocialButton(
                  icon: FontAwesomeIcons.linkedin,
                  color: Colors.blue,
                  label: 'LinkedIn',
                  themeProvider: themeProvider,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('LinkedIn sign-in coming soon'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}