import 'package:flutter/material.dart';
import 'package:gowayanad/services/auth_services.dart';
import 'package:gowayanad/admin_panel.dart';
import 'package:gowayanad/registerscreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                "Welcome Back",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter your Phone Number to sign in",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixIcon: const Icon(Icons.phone),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock_outline),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => AuthService().loginAndRoute(
                    phoneController.text.trim(),
                    passwordController.text.trim(),
                    context,
                  ),

                  child: const Text("LOGIN", style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegisterScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    "ADD USER/DRIVER",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Secret or dedicated Admin Panel Button
              Center(
                child: TextButton(
                  onPressed: () {
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
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Access Denied"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text("Submit"),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    "Admin Dashboard",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // return Scaffold(
    //   body: Padding(
    //     padding: EdgeInsets.all(20),
    //     child: Column(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         TextField(controller: emailController, decoration: InputDecoration(labelText: 'Email')),
    //         TextField(controller: passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
    //         SizedBox(height: 20),
    //         ElevatedButton(
    //           onPressed: () => AuthService().loginAndRoute(
    //             emailController.text,
    //             passwordController.text,
    //             context
    //           ),
    //           child: Text("Login"),
    //         ),
    //         SizedBox(height: 30,

    //         ),
    //          ElevatedButton(
    //           child: Text("ADD USER"),
    //           onPressed: (){
    //           Navigator.of(context).push(MaterialPageRoute(builder: (context)=>RegisterScreen()));
    //           }
    //           ),

    //       ],
    //     ),
    //   ),
    // );
  }
}
