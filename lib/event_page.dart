import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_2025/auth_page.dart';

class EventPage extends StatefulWidget {
  const EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '', _venue = '';
  DateTime? _date;
  int _totalTickets = 0;
  double _ticketPrice = 0;

  _submit() async {
    if (_formKey.currentState!.validate() && _date != null) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseFirestore.instance.collection('events').add({
        'name': _name,
        'venue': _venue,
        'date': Timestamp.fromDate(_date!),
        'totalTickets': _totalTickets,
        'availableTickets': _totalTickets,
        'ticketPrice': _ticketPrice,
        'createdAt': Timestamp.now(),
        'organizerId': user.uid,
      });
      _formKey.currentState!.reset();
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Events'),
        actions: [
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => AuthPage()),
                    (_) => false);
              })
        ],
      ),
      body: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Event Name'),
                onSaved: (v) => _name = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Venue'),
                onSaved: (v) => _venue = v!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Total Tickets'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter ticket count' : null,
                onSaved: (v) => _totalTickets = int.parse(v!),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ticket Price'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Enter price' : null,
                onSaved: (v) => _ticketPrice = double.parse(v!),
                keyboardType: TextInputType.number,
              ),
              ElevatedButton(
                child: Text(_date == null ? 'Pick Date' : _date.toString()),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _date = d);
                },
              ),
              ElevatedButton(child: Text('Create Event'), onPressed: _submit),
            ]),
          ),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('date', isGreaterThan: Timestamp.now())
                .snapshots(),
            builder: (_, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasData) {
                print(snapshot.data!.docs.length);
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No events available.'));
              }
              return ListView(
                children: snapshot.data!.docs.map((doc) {
                  final e = doc.data() as Map<String, dynamic>;
                  return ListTile(title: Text(e['name'] ?? 'Unnamed Event'));
                }).toList(),
              );
            },
          ))
        ],
      ),
    );
  }
}
