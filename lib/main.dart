import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_page.dart'; // Authentication Page

void main() async {
  // Running
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAnViiLpthVwRtg5iZHvdI5vmWhQiiIDxo",
      appId: "1:233644548352:android:2f7bf8a4e7663d108613e5",
      messagingSenderId: "Messaging sender id here",
      projectId: "fluttertest-1c80f",
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Booking Event',
      home: AuthPage(),
    );
  }
}
