import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({Key? key}) : super(key: key);

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  late Stream<QuerySnapshot> _usersStream;

  @override
  void initState() {
    super.initState();
    _usersStream = FirebaseFirestore.instance
        .collection('users')
        .where('visible', isEqualTo: true)
        .snapshots();
  }

  void _updateResponderInFirestoreAndRealtime(String userId, bool value) {
    // Update the responder value in Firestore
    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'responder': value,
      'pending': !value,
      
    });

    
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference();
    final String path = 'users/$userId/location';
    databaseReference.child(path).update({
      'responder': value,
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin - Verification'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _usersStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }

          if (snapshot.data!.docs.isEmpty) {
            return Text('No users found');
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(data['name'] ?? 'No Name'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        // Display the document image
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: Image.network(data['document']),
                            );
                          },
                        );
                      },
                    ),
                    Switch(
                      value: data['responder'] ?? false,
                      onChanged: (bool value) {
                        // Update the responder and pending values in both Firestore and Realtime Database
                        _updateResponderInFirestoreAndRealtime(
                            document.id, value);
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
