import 'package:flutter/material.dart';
import 'package:gowayanad/services/auth_services.dart';
import 'package:gowayanad/admin_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
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

  final Color _primaryPurple = const Color(0xFF673AB7);
  final Color _accentPurple = const Color(0xFF9575CD);

  @override
  void initState() {
    super.initState();
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
    await AuthService().loginAndRoute(phone, password, context);
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
      _showError("Please enter a valid phone number");
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
      await AuthService().signUpWithPhone(name, phone, password, _selectedRole);
      if (mounted) {
        _showSuccess("Account created successfully! Logging you in...");
        // Auto-login after signup
        await AuthService().loginAndRoute(phone, password, context);
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isSignUpLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _primaryPurple.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.bolt_rounded, size: 60, color: _primaryPurple),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "GO WAYANAD",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _primaryPurple,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: _primaryPurple,
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: "Login"),
                      Tab(text: "Sign Up"),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 500, // Fixed height for tab views
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildLoginForm(),
                      _buildSignUpForm(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildAdminButton(),
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
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _loginPasswordController,
          label: "Password",
          icon: Icons.lock_outline,
          isPassword: true,
          obscureText: !_isLoginPasswordVisible,
          onToggleVisibility: () {
            setState(() => _isLoginPasswordVisible = !_isLoginPasswordVisible);
          },
        ),
        const SizedBox(height: 32),
        _buildPrimaryButton(
          text: "LOGIN",
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
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpPhoneController,
            label: "Phone Number",
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _signUpPasswordController,
            label: "Password",
            icon: Icons.lock_outline,
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
            icon: Icons.lock_clock_outlined,
            isPassword: true,
            obscureText: !_isSignUpConfirmPasswordVisible,
            onToggleVisibility: () {
              setState(() => _isSignUpConfirmPasswordVisible = !_isSignUpConfirmPasswordVisible);
            },
          ),
          const SizedBox(height: 16),
          _buildRoleSelection(),
          const SizedBox(height: 32),
          _buildPrimaryButton(
            text: "CREATE ACCOUNT",
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: _accentPurple),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey,
                ),
                onPressed: onToggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: _primaryPurple, width: 2),
        ),
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("I am a:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildRoleCard('rider', 'User', Icons.person_outline),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildRoleCard('driver', 'Driver', Icons.drive_eta_outlined),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _primaryPurple : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 2,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildAdminButton() {
    return Center(
      child: TextButton(
        onPressed: _showAdminPasscodeDialog,
        child: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
        ),
      ),
    );
  }

  void _showAdminPasscodeDialog() {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Admin Access"),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            hintText: "Enter secret passcode",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (passController.text == "112233") {
                Navigator.pop(context); // close dialog
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminPanel(),
                  ),
                );
              } else {
                Navigator.pop(context); // close dialog
                _showError("Access Denied");
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }
}
