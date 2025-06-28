# 🎟️ Event Booking App (Flutter + Firebase)

A simple Flutter application that allows users to register/login, create events (organizers), and book event tickets (customers). Includes time-based VIP access control.

## 🔧 Features

- Firebase Authentication (email/password)
- Firestore database integration
- Separate flows for:
  - **Organizers** – Create and manage events
  - **Customers** – Browse and book tickets
- VIP-only access for first 24 hours after event creation
- Booking management (view and delete)

---

## 📁 Project Structure

### `main.dart` – ⚙️ Running Page

```dart
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
```
### `auth_page.dart` – 🔐 Authentication Page

- Handles **login and registration**
- Upon registration:
  - Accepts `email`, `password`, and `VIP` status
  - Saves user to Firebase Auth
  - Creates a Firestore document in `customers` collection:
    ```dart
    
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
    ```
- Role-based routing:
  - If `email == organizer@gmail.com` → `EventPage`
  - Else → `CustomerPage`

---

### `event_page.dart` – 🎤 Organizer Page

- Allows **organizers** to:
  - Create events with:
    - Name
    - Venue
    - Date
    - Total tickets
    - Ticket price
- Displays upcoming events
- Events stored in `events` collection
- Customers stored in `customers` collection
- Bookings stored in `bookings` collection

### `customer_page.dart` – 🙋‍♂️ Customer Page

- Displays list of **available events**
- For each event:
  - Shows name, venue, date, price, and tickets left
  - If event is within 24 hours of creation:
    - Only VIP users can book
    - Non-VIP sees “VIP Only for now”
- After 24 hours:
  - All users can book
- Bookings stored in `bookings` collection:
  ```json
  {
    "eventId": "...",
    "userId": "...",
    "ticketCount": 2,
    "totalPrice": 50,
    "bookedAt": Timestamp
  }
