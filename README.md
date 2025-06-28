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

## 📸 Screenshots - Every Page
- Login Page
<img src="https://github.com/user-attachments/assets/7e5b8d02-2185-4bb4-96cc-764aa06472fd" alt="Food Ordering App Screenshot" width="300"/>

- Organizer Page
<img src="https://github.com/user-attachments/assets/d3d821ed-038c-4ef6-b867-2387163656ec" alt="Food Ordering App Screenshot" width="300"/>

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
  ```dart       
    class _CustomerPageState extends State<CustomerPage> {
      bool isVIP = false;
    
      @override
      void initState() {
        super.initState();
        _checkVIP();
      }
    
      Future<void> _checkVIP() async {
        final uid = FirebaseAuth.instance.currentUser!.uid;
        final doc =
            await FirebaseFirestore.instance.collection('customers').doc(uid).get();
        setState(() => isVIP = doc['isVIP'] ?? false);
      }
    
      @override
      Widget build(BuildContext c) {
        final user = FirebaseAuth.instance.currentUser!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Book an Event'),
            actions: [
              IconButton(
                  icon: Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(c).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => AuthPage()),
                        (_) => false);
                  })
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('events')
                      .where('date', isGreaterThan: Timestamp.now())
                      .snapshots(),
                  builder: (_, ss) {
                    if (ss.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!ss.hasData || ss.data!.docs.isEmpty) {
                      return Center(child: Text('No events available.'));
                    }
                    return ListView(
                      children: ss.data!.docs.map((d) {
                        final e = d.data() as Map<String, dynamic>;
                        final ticketsLeft = e['availableTickets'] as int;
                        final isCancelled =
                            e['name'].toString().toLowerCase().contains('canceled');
                        final createdAt = (e['createdAt'] as Timestamp).toDate();
                        final now = DateTime.now();
                        final withinVIPWindow =
                            now.difference(createdAt).inHours < 24;
                        final canBook = !withinVIPWindow || isVIP;
    
                        return ListTile(
                          title: Text(e['name'],
                              style: TextStyle(
                                  color: isCancelled ? Colors.red : null,
                                  fontStyle:
                                      isCancelled ? FontStyle.italic : null)),
                          subtitle: Text(
                              '${e['venue']} • ${e['date'].toDate()} • \$${e['ticketPrice']} • left: $ticketsLeft'),
                          trailing: isCancelled
                              ? Text('Canceled',
                                  style: TextStyle(color: Colors.red))
                              : ElevatedButton(
                                  child: Text('Book'),
                                  onPressed: canBook
                                      ? () => _showBookingDialog(c, d.id, e)
                                      : null,
                                ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
              Divider(),
              Text('Your Bookings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .snapshots(),
                  builder: (_, ss) {
                    if (ss.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (ss.hasError) {
                      return Center(child: Text('Error loading bookings'));
                    }
                    if (!ss.hasData || ss.data!.docs.isEmpty) {
                      return Center(child: Text('No bookings found.'));
                    }
                    return ListView(
                      children: ss.data!.docs.map((b) {
                        final bk = b.data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text('Event: ${bk['eventName']}'),
                          subtitle: Text(
                              'Tickets: ${bk['ticketCount']} • \$${bk['totalPrice']} • ${bk['bookedAt'].toDate()}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(b.id)
                                  .delete();
    
                              await FirebaseFirestore.instance
                                  .collection('events')
                                  .doc(bk['eventId'])
                                  .update({
                                'availableTickets':
                                    FieldValue.increment(bk['ticketCount'])
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }
    
      void _showBookingDialog(BuildContext c, String eventId, Map e) {
        final _ticketCtr = TextEditingController();
        showDialog(
            context: c,
            builder: (_) => AlertDialog(
                  title: Text('Book ${e['name']}'),
                  content: TextField(
                    controller: _ticketCtr,
                    decoration: InputDecoration(labelText: 'Number of tickets'),
                    keyboardType: TextInputType.number,
                  ),
                  actions: [
                    TextButton(
                        child: Text('Cancel'), onPressed: () => Navigator.pop(c)),
                    ElevatedButton(
                        child: Text('Confirm'),
                        onPressed: () async {
                          final count = int.tryParse(_ticketCtr.text) ?? 0;
                          if (count <= 0 || count > e['availableTickets']) return;
                          final price =
                              count * (e['ticketPrice'] as num).toDouble();
                          final batch = FirebaseFirestore.instance.batch();
                          final evRef = FirebaseFirestore.instance
                              .collection('events')
                              .doc(eventId);
                          final bkRef = FirebaseFirestore.instance
                              .collection('bookings')
                              .doc();
                          batch.update(evRef,
                              {'availableTickets': FieldValue.increment(-count)});
                          batch.set(bkRef, {
                            'userId': FirebaseAuth.instance.currentUser!.uid,
                            'eventId': eventId,
                            'eventName': e['name'],
                            'ticketCount': count,
                            'totalPrice': price,
                            'bookedAt': Timestamp.now(),
                          });
                          await batch.commit();
                          Navigator.pop(c);
                        }),
                  ],
                ));
      }
    }


