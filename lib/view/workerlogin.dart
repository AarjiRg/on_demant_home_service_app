import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/workerlogin_controler.dart';
import 'package:on_demant_home_service_app/view/workerregscreen.dart';
import 'package:provider/provider.dart';

class WorkerLoginScreen extends StatefulWidget {
  const WorkerLoginScreen({super.key});

  @override
  _WorkerLoginScreenState createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool rememberMe = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2575FC), 
              Color(0xFF6A11CB),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                color: Colors.deepPurple[800], 
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                 
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.work,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),
                        
        
                        const Text(
                          "Worker Login",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Sign in to access your worker dashboard",
                          style: TextStyle(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Email", Icons.email),
                          validator: (value) {
                            if (value!.isEmpty) return "Email is required";
                            if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                              return "Enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        
            
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration("Password", Icons.lock),
                          validator: (value) {
                            if (value!.isEmpty) return "Password is required";
                            if (value.length < 6) return "Password must be at least 6 characters";
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        
        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: Colors.white70,
                                  ),
                                  child: Checkbox(
                                    value: rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        rememberMe = value!;
                                      });
                                    },
                                    checkColor: Colors.deepPurple,
                                    activeColor: Colors.white,
                                  ),
                                ),
                                const Text(
                                  "Remember me",
                                  style: TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                          
                                _showForgotPasswordDialog(context);
                              },
                              child: const Text(
                                "Forgot Password?",
                                style: TextStyle(color: Colors.lightBlueAccent),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 25),
                        
                
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 5,
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _handleLogin(context),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                  )
                                : const Text(
                                    "SIGN IN AS WORKER",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Not a worker yet?",
                              style: TextStyle(color: Colors.white70),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  PageRouteBuilder(
                                    transitionDuration: const Duration(milliseconds: 500),
                                    pageBuilder: (_, __, ___) =>  WorkerRegistrationScreen(),
                                    transitionsBuilder: (_, animation, __, child) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text(
                                "Register as Worker",
                                style: TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await context.read<WorkerLoginScreenController>().onWorkerLogin(
          email: emailController.text,
          password: passwordController.text,
          context: context,
        );
      } catch (e) {
 
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showForgotPasswordDialog(BuildContext context) async {
    final emailController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Enter your email'),
            keyboardType: TextInputType.emailAddress,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${e.toString()}')),
                  );
                }
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.orangeAccent),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
    );
  }
}