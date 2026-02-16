import 'package:flutter/material.dart';
import 'package:gowayanad/services/auth_services.dart';
import 'package:gowayanad/services/user_add.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return  Scaffold(
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
                "Enter your Email to sign in",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: const Icon(Icons.email),
                  
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
               TextField(
                controller: passwordController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.email),
                  
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
                  onPressed: ()=> AuthService().loginAndRoute(
                emailController.text, 
                 passwordController.text, 
                 context
               ),
                   
                  
                  child: const Text("LOGIN", style: TextStyle(fontSize: 16)),
                ),
              ),
            SizedBox(height: 20,),
            
               SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                     child: const Text("ADD USER/DRIVER", style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (){
 Navigator.of(context).push(MaterialPageRoute(builder: (context)=>RegisterScreen()));
                  }
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