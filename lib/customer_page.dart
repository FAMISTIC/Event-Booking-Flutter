// customer_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_page.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({super.key});

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
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
                if (ss.hasData) {
                  print(ss.data!.docs.length);
                }
                if (!ss.hasData || ss.data!.docs.isEmpty) {
                  return Center(child: Text('No events available.'));
                }
                return ListView(
                  children: ss.data!.docs.map((d) {
                    final e = d.data() as Map<String, dynamic>;
                    final ticketsLeft = e['availableTickets'] as int;
                    return ListTile(
                      title: Text(e['name']),
                      subtitle: Text(
                          '${e['venue']} • ${e['date'].toDate()} • \$${e['ticketPrice']} • left: $ticketsLeft'),
                      trailing: ElevatedButton(
                          child: Text('Book'),
                          onPressed: () => _showBookingDialog(c, d.id, e)),
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

                          // Optionally increase availableTickets back
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
