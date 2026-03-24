import 'package:flutter/material.dart';
import 'package:gowayanad/frontend/screens/auth_screen.dart';
import 'package:gowayanad/frontend/admin/admin_panel.dart';
import 'package:gowayanad/backend/utils/design_system.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background Image Illustration
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.55,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/welcome_bg.png'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha((0.05 * 255).round()),
                    BlendMode.darken,
                  ),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.white.withAlpha((0.8 * 255).round()),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Content Overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  // Small Logo Icon at the top
                  const SizedBox(height: 80),

                  const Spacer(),

                  // Branding
                  const Text(
                    "Go Wayanad",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  const SizedBox(height: 64),

                  // Actions Container
                  Column(
                    children: [
                      // Login Button
                      CustomButton(
                        label: "LOGIN",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(isLogin: true),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Signup Link
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthScreen(isLogin: false),
                              ),
                            );
                          },
                          child: const Text(
                            "CREATE ACCOUNT",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Admin Dashboard (More professional entry)
                  Center(
                    child: InkWell(
                      onTap: () => _showAdminPasscodeDialog(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.admin_panel_settings_outlined,
                              size: 18,
                              color: AppColors.textSecondary.withAlpha((0.5 * 255).round()),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Admin Dashboard",
                              style: TextStyle(
                                color: AppColors.textSecondary.withAlpha((0.5 * 255).round()),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdminPasscodeDialog(BuildContext context) {
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
              "Please enter the secret passcode to access the admin dashboard.",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passController,
              obscureText: true,
              autofocus: true,
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
                  MaterialPageRoute(builder: (context) => const AdminPanel()),
                );
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Access Denied"),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text("Access", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
