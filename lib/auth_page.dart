// auth_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'event_page.dart';
import 'customer_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final auth = FirebaseAuth.instance;
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  void handleAuth() async {
    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
            email: emailController.text, password: passwordController.text);
      } else {
        await auth.createUserWithEmailAndPassword(
            email: emailController.text, password: passwordController.text);
      }
    } catch (e) {
      print('Error: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Future.microtask(() {
              final user = snapshot.data!;
              final page = user.email == 'organizer@gmail.com'
                  ? EventPage()
                  : CustomerPage();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => page),
              );
            });
            return Center(child: CircularProgressIndicator());
          } else {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                      controller: emailController,
                      decoration: InputDecoration(labelText: 'Email')),
                  TextField(
                      controller: passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true),
                  ElevatedButton(
                    onPressed: handleAuth,
                    child: Text(isLogin ? 'Login' : 'Register'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(isLogin
                        ? 'Create Account'
                        : 'Already have an account?'),
                  )
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
