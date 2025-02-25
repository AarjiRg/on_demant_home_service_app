
import 'package:flutter/material.dart';
import 'package:on_demant_home_service_app/controller/login_controller.dart';
import 'package:on_demant_home_service_app/view/registration_screen';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Welcome Back",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[900]),
              ),
              SizedBox(height: 10),
              Text("Please sign in to continue", style: TextStyle(color: Colors.blue[700])),
              SizedBox(height: 30),
              
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration("Email"),
                validator: (value) {
                  if (value!.isEmpty) return "Email is required";
                  if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              SizedBox(height: 15),
              
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: inputDecoration("Password"),
                validator: (value) {
                  if (value!.isEmpty) return "Password is required";
                  if (value.length < 6) return "Password must be at least 6 characters";
                  return null;
                },
              ),
              SizedBox(height: 10),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: rememberMe,
                        onChanged: (value) {
                          setState(() {
                            rememberMe = value!;
                          });
                        },
                        checkColor: Colors.white,
                        activeColor: Colors.blue[600],
                      ),
                      Text("Remember me", style: TextStyle(color: Colors.blue[700])),
                    ],
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text("Forgot Password?", style: TextStyle(color: Colors.blue[800])),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.read<LoginScreenController>().onLogin(
                        email: emailController.text,
                        password: passwordController.text,
                        context: context,
                      );
                    }
                  },
                  child: Text("SIGN IN", style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: TextStyle(color: Colors.blue[700])),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => RegistrationScreen()),
                      );
                    },
                    child: Text("Sign Up", style: TextStyle(color: Colors.blue[800])),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blue[700]),
      filled: true,
      fillColor: Colors.blue[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    );
  }
}
