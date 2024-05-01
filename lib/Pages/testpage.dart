import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late StreamSubscription<DatabaseEvent>? _alertSubscription;
  String _alertValue = '0'; // State variable to store the alert value

  @override
  void initState() {
    super.initState();
    _listenToAlert();
  }

  void _listenToAlert() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference alertRef = FirebaseDatabase.instance
          .reference()
          .child('users/${user.uid}/location/alert');
      _alertSubscription = alertRef.onValue.listen((event) {
        final data = event.snapshot.value;
        if (data != '0') {
          setState(() {
            _alertValue = data
                .toString(); // Update the state variable with the new alert value
          });
          _showAlertDialog(data.toString());
        }
      });
    }
  }

  void _showAlertDialog(String alertValue) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent the dialog from closing when the back button is pressed
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(alertValue)
                .get(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text("Something went wrong");
              }

              if (snapshot.connectionState == ConnectionState.done) {
                Map<String, dynamic> data =
                    snapshot.data!.data() as Map<String, dynamic>;
                return AlertDialog(
                  title: Text('EMERGENCY !',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  content: Container(
                    width: 300, // Set a specific width for the container
                    height: 200, // Set a specific height for the container
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add some space
                        Text('An accident has been detected.',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 20),
                        Text('Name : ${data['name']}',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 10), // Add some space
                        Text('Gender : ${data['gender']}',
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                        Text('Blood Group : ${data['bloodGroup']}',
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                        SizedBox(height: 10), // Add some space
                        Text('Medical Condition : ${data['medicalConditions']}',
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                        SizedBox(height: 10), // Add some space
                        Text('Phone Number : ${data['phone']}',
                            style: TextStyle(color: Colors.red, fontSize: 16)),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        _resetAlerts();
                        Navigator.of(context).pop();
                      },
                      child: Text('Close',
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                  backgroundColor: const Color.fromARGB(255, 255, 255,
                      255), // Set a background color for the dialog
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(20), // Add rounded corners
                  ),
                );
              }

              // By default, show a loading spinner.
              return CircularProgressIndicator();
            },
          ),
        );
      },
    );
  }

  void _resetAlerts() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final DatabaseReference alertRef = FirebaseDatabase.instance
          .reference()
          .child('users/${user.uid}/location/alert');
      alertRef.set('0');

      final userCollection = FirebaseFirestore.instance.collection('users');
      userCollection.doc(user.uid).update({
        'alert': '0', // Set the alert value to null in Firestore
      });
    }
  }

  void _resetAlertsForAllUsers() {
    final userCollection = FirebaseFirestore.instance.collection('users');
    userCollection.get().then((QuerySnapshot querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        final uid = doc.id;
        final DatabaseReference alertRef = FirebaseDatabase.instance
            .reference()
            .child('users/$uid/location/alert');
        alertRef.set('0');

        userCollection.doc(uid).update({
          'alert': '0', // Set the alert value to null in Firestore
        });
      });
    });
  }

  @override
  void dispose() {
    _alertSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? '';
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hello World'),
        ),
        body: Column(
          children: [
            Center(
              child: Text(
                user?.displayName ?? 'No display name',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
            ),
            if (userEmail == 'salu9651@gmail.com')
              ElevatedButton(
                onPressed: _resetAlertsForAllUsers,
                child: Text('Reset all Alerts'),
              ),
          ],
        ),
      ),
    );
  }
}
