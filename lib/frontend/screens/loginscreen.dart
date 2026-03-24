import 'package:flutter/material.dart';
import 'package:gowayanad/backend/services/auth_services.dart';
import 'package:gowayanad/frontend/admin/admin_panel.dart';
import 'package:gowayanad/backend/utils/design_system.dart';

class LoginScreen extends StatefulWidget {
  final AuthService? authService;
  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late TabController _tabController;
  
  // Login Controllers
  final _loginPhoneController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _isLoginPasswordVisible = false;
  bool _isLoginLoading = false;

  // Sign Up Controllers
  final _signUpNameController = TextEditingController();
  final _signUpPhoneController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmPasswordController = TextEditingController();
  String _selectedRole = 'rider'; // 'rider' or 'driver'
  bool _isSignUpPasswordVisible = false;
  bool _isSignUpConfirmPasswordVisible = false;
  bool _isSignUpLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneController.dispose();
    _loginPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpPhoneController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final phone = _loginPhoneController.text.trim();
    final password = _loginPasswordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    setState(() => _isLoginLoading = true);
    await _authService.loginAndRoute(phone, password, context);
    if (mounted) setState(() => _isLoginLoading = false);
  }

  void _handleSignUp() async {
    final name = _signUpNameController.text.trim();
    final phone = _signUpPhoneController.text.trim();
    final password = _signUpPasswordController.text.trim();
    final confirmPassword = _signUpConfirmPasswordController.text.trim();

    if (name.isEmpty || phone.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _showError("Please fill in all fields");
      return;
    }

    if (phone.length < 10) {
      _showError("Please enter a valid 10-digit phone number");
      return;
    }

    if (password.length < 6) {
      _showError("Password must be at least 6 characters");
      return;
    }

    if (password != confirmPassword) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isSignUpLoading = true);
    try {
      await _authService.signUpWithPhone(name, phone, password, _selectedRole);
      if (mounted) {
        _showSuccess("Account created successfully!");
        // Auto-login after signup
        await _authService.loginAndRoute(phone, password, context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSignUpLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    "GO WAYANAD",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Container(
                  height: 54,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(27),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(23),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(text: "Login"),
                      Tab(text: "Sign Up"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 480,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignUpForm(),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: _showAdminPasscodeDialog,
                    child: Text(
                      "Admin Dashboard",
                      style: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _loginPhoneController,
          label: "Phone Number",
          icon: Icons.phone_android_rounded,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _loginPasswordController,
          label: "Password",
          icon: Icons.lock_outline_rounded,
          isPassword: true,
          obscureText: !_isLoginPasswordVisible,
          onToggleVisibility: () {
            setState(() => _isLoginPasswordVisible = !_isLoginPasswordVisible);
          },
        ),
        const SizedBox(height: 40),
        CustomButton(
          label: "LOGIN",
          onPressed: _handleLogin,
          isLoading: _isLoginLoading,
        ),
      ],
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            controller: _signUpNameController,
            label: "Full Name",
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpPhoneController,
            label: "Phone Number",
            icon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpPasswordController,
            label: "Password",
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            obscureText: !_isSignUpPasswordVisible,
            onToggleVisibility: () {
              setState(() => _isSignUpPasswordVisible = !_isSignUpPasswordVisible);
            },
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpConfirmPasswordController,
            label: "Confirm Password",
            icon: Icons.lock_reset_rounded,
            isPassword: true,
            obscureText: !_isSignUpConfirmPasswordVisible,
            onToggleVisibility: () {
              setState(() => _isSignUpConfirmPasswordVisible = !_isSignUpConfirmPasswordVisible);
            },
          ),
          const SizedBox(height: 20),
          _buildRoleSelection(),
          const SizedBox(height: 32),
          CustomButton(
            label: "CREATE ACCOUNT",
            onPressed: _handleSignUp,
            isLoading: _isSignUpLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.secondary, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "I AM A:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildRoleCard('rider', 'Rider', Icons.person_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildRoleCard('driver', 'Driver', Icons.drive_eta_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.secondary,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdminPasscodeDialog() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Admin Access", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter secret passcode for admin dashboard.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Passcode",
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (passController.text == "112233") {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPanel(authService: _authService)),
                );
              } else {
                Navigator.pop(context);
                _showError("Access Denied");
              }
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
