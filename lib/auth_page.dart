import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool isVIP = false;

  void handleAuth() async {
    try {
      if (isLogin) {
        await auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      } else {
        final cred = await auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        // Store customer data in Firestore
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(cred.user!.uid)
            .set({
          'id': cred.user!.uid,
          'name': emailController.text,
          'isVIP': isVIP,
        });
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Authentication Page')),
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
                    decoration: InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  if (!isLogin)
                    Row(
                      children: [
                        Checkbox(
                          value: isVIP,
                          onChanged: (val) =>
                              setState(() => isVIP = val ?? false),
                        ),
                        Text('VIP Customer'),
                      ],
                    ),
                  ElevatedButton(
                    onPressed: handleAuth,
                    child: Text(isLogin ? 'Login' : 'Register'),
                  ),
                  TextButton(
                    onPressed: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin ? 'Create Account' : 'Already have an account?',
                    ),
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
