import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Email controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Phone controllers
  final phoneController = TextEditingController();
  final otpController = TextEditingController();
  final phoneNameController = TextEditingController();
  final phoneEmailController = TextEditingController();
  
  bool isSignUp = false;
  bool isPhoneOtpSent = false;
  String? error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    otpController.dispose();
    phoneNameController.dispose();
    phoneEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    if (auth.user != null) {
      Future.microtask(() => context.go('/'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 
                           MediaQuery.of(context).padding.top - 
                           MediaQuery.of(context).padding.bottom - 32,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo and Title
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.location_city, color: Colors.white, size: 48),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'UrbanVoice',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Report civic issues in your community',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 48),

                // Tab Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: const Color(0xFF6B7280),
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Email'),
                      Tab(text: 'Google'),
                      Tab(text: 'Phone'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Tab Content
                SizedBox(
                  height: 400, // Fixed height for tab content
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmailTab(auth),
                      _buildGoogleTab(auth),
                      _buildPhoneTab(auth),
                    ],
                  ),
                ),

                // Error Message
                if (auth.error != null || error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.1),
                          Colors.red.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            auth.error ?? error!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16), // Bottom padding
              ],
            ),
          ),
        ),
      ),
      )
    );
  }

  Widget _buildEmailTab(AuthProvider auth) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Demo Login Button for Hackathon
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF5B041), Color(0xFFD4AC0D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF5B041).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _demoLogin,
                  icon: const Icon(Icons.flash_on, size: 20),
                  label: const Text('DEMO LOGIN (Hackathon)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.transparent,
                  ),
                ),
              ),
              Container(
                height: 1,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFF8E44AD).withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Text(
                isSignUp ? 'Create Account' : 'Sign In',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              
              if (isSignUp) ...[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    labelText: 'Full Name',
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  labelText: 'Password',
                ),
              ),
              
              if (isSignUp) ...[
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                    labelText: 'Confirm Password',
                  ),
                ),
              ],
              
              const SizedBox(height: 20),
              
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: auth.loading ? null : () => _handleEmailAuth(auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.transparent,
                  ),
                  child: auth.loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isSignUp ? 'Sign Up' : 'Sign In'),
                ),
              ),
              
              const SizedBox(height: 12),
              
              TextButton(
                onPressed: () {
                  setState(() {
                    isSignUp = !isSignUp;
                    error = null;
                  });
                  auth.clearError();
                },
                child: Text(
                  isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Sign Up',
                ),
              ),
              
              if (!isSignUp) ...[
                TextButton(
                  onPressed: () => _handlePasswordReset(auth),
                  child: const Text('Forgot Password?'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleTab(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.g_mobiledata, size: 48, color: Color(0xFF1E3A8A)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use your Google account to sign in quickly and securely',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: auth.loading ? null : () => _handleGoogleSignIn(auth),
                icon: auth.loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  shadowColor: Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneTab(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: !isPhoneOtpSent
            ? _buildPhoneForm(auth)
            : _buildOtpForm(auth),
      ),
    );
  }

  Widget _buildPhoneForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Phone Verification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            labelText: 'Phone Number',
            hintText: '+91 9876543210',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneNameController,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
            labelText: 'Full Name',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: phoneEmailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
            labelText: 'Email (Optional)',
          ),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: auth.loading ? null : () => _handlePhoneAuth(auth),
            icon: auth.loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send),
            label: const Text('Send OTP'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter OTP',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'OTP sent to ${phoneController.text}',
          style: const TextStyle(color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: otpController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
            labelText: 'Enter 6-digit OTP',
          ),
          maxLength: 6,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            OutlinedButton(
              onPressed: auth.loading
                  ? null
                  : () {
                      setState(() {
                        isPhoneOtpSent = false;
                        otpController.clear();
                        error = null;
                      });
                      auth.clearError();
                    },
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: auth.loading ? null : () => _handleOtpVerification(auth),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    shadowColor: Colors.transparent,
                  ),
                  child: auth.loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Verify'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _handleEmailAuth(AuthProvider auth) async {
    setState(() => error = null);
    auth.clearError();

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => error = 'Please fill in all required fields');
      return;
    }

    if (isSignUp && name.isEmpty) {
      setState(() => error = 'Please enter your name');
      return;
    }

    if (isSignUp && password != confirmPasswordController.text.trim()) {
      setState(() => error = 'Passwords do not match');
      return;
    }

    bool success;
    if (isSignUp) {
      success = await auth.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
    } else {
      success = await auth.signInWithEmail(
        email: email,
        password: password,
      );
    }

    if (mounted) {
      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Authentication failed')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn(AuthProvider auth) async {
    setState(() => error = null);
    auth.clearError();

    final success = await auth.signInWithGoogle();
    if (mounted) {
      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Google sign-in failed')),
        );
      }
    }
  }

  Future<void> _handlePhoneAuth(AuthProvider auth) async {
    setState(() => error = null);
    auth.clearError();

    final phone = phoneController.text.trim();
    final name = phoneNameController.text.trim();

    if (phone.isEmpty || name.isEmpty) {
      setState(() => error = 'Please fill in all required fields');
      return;
    }

    final success = await auth.sendPhoneVerification(phone);
    if (success) {
      setState(() => isPhoneOtpSent = true);
    }
  }

  Future<void> _handleOtpVerification(AuthProvider auth) async {
    setState(() => error = null);
    auth.clearError();

    final otp = otpController.text.trim();
    final name = phoneNameController.text.trim();
    final email = phoneEmailController.text.trim();

    if (otp.length != 6) {
      setState(() => error = 'Please enter a valid 6-digit OTP');
      return;
    }

    final success = await auth.verifyPhoneOTP(
      otp: otp,
      name: name,
      email: email.isNotEmpty ? email : null,
    );

    if (success && mounted) {
      context.go('/');
    }
  }

  void _demoLogin() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    // Create a demo user for hackathon testing
    final demoUser = CivicUser(
      id: 'demo_user_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Demo User',
      email: 'demo@urbanvoice.app',
      phone: '+91 9876543210',
      role: UserRole.citizen,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    // Bypass Firebase authentication for demo
    auth.setUser(demoUser);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demo login successful! Ready for hackathon testing.'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/');
    }
  }

  Future<void> _handlePasswordReset(AuthProvider auth) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() => error = 'Please enter your email address');
      return;
    }

    final success = await auth.resetPassword(email);
    if (mounted) {
      if (success) {
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Authentication failed')),
        );
      }
    }
  }
}
