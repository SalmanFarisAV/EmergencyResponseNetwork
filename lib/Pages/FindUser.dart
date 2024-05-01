import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newapp/Pages/Location_page.dart';
import 'package:newapp/Pages/auth_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Functions/app_state.dart';

class FindUser extends StatefulWidget {
  const FindUser({Key? key}) : super(key: key);

  @override
  _FindUserState createState() => _FindUserState();
}

class _FindUserState extends State<FindUser> {
  String _location = 'Fetching location...';

  double _distance = 0.0;
  double _speed = 0.0;
  List<Map<String, dynamic>> _userLocations = [];
  bool buttonPressed = false;
  final appState = AppState();

  void _fetchUserLocations() async {
    setState(() {
      buttonPressed = true;
    });

    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference();
    final String path = 'users';
    databaseReference.child(path).once().then((DatabaseEvent event) {
      DataSnapshot snapshot = event.snapshot;
      Map<dynamic, dynamic>? values = snapshot.value as Map<dynamic, dynamic>?;
      if (values != null) {
        List<Map<String, dynamic>> userLocations = [];

        double currentLatitude = appState.previousPosition?.latitude ?? 0.0;
        double currentLongitude = appState.previousPosition?.longitude ?? 0.0;

        values.forEach((key, value) {
          if (key != FirebaseAuth.instance.currentUser?.uid) {
            double userLatitude = value['location']['latitude'];
            double userLongitude = value['location']['longitude'];

            double distance = Geolocator.distanceBetween(
              currentLatitude,
              currentLongitude,
              userLatitude,
              userLongitude,
            );

            if (distance <= 5000 && value['location']['responder'] == true) {
              // Add the UID to the map
              userLocations.add({
                'uid': value['location']['uid'],
                'name': value['location']['name'],
                'latitude': userLatitude,
                'longitude': userLongitude,
              });

              // Update the alert value in Firestore for each responder found
              final String responderPath =
                  'users/${value['location']['uid']}/alert';
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(value['location']['uid'])
                  .update({
                'alert': FirebaseAuth.instance.currentUser?.uid,
              });
              final String responderPath1 =
                  'users/${value['location']['uid']}/location/alert';
              databaseReference
                  .child(responderPath1)
                  .set(FirebaseAuth.instance.currentUser?.uid);
            }
          }
        });
        setState(() {
          _userLocations = userLocations;
        });
      } else {
        print("No data found at the specified path.");
      }
    });
  }



  @override
  Widget build(BuildContext context) {
    Position? previousPosition = appState.previousPosition;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            Text(
              'Coordinates: ${previousPosition?.latitude ?? 0.0}, ${previousPosition?.longitude ?? 0.0}',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
            ElevatedButton(
              onPressed: _fetchUserLocations,
              child: Text('Fetch User Locations'),
            ),
            SizedBox(height: 20),
            if (buttonPressed)
              _userLocations.isEmpty
                  ? Text(
                      'No users found within 5km radius.',
                      style: TextStyle(fontSize: 20),
                    )
                  : Text(
                      'User Found!',
                      style: TextStyle(
                        fontSize: 30,
                      ),
                    ),
            Expanded(
              child: ListView.builder(
                itemCount: _userLocations.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      _userLocations[index]['name'],
                      style: TextStyle(fontSize: 35),
                    ),
                    subtitle: Text(
                        'UID: ${_userLocations[index]['uid']}, Latitude: ${_userLocations[index]['latitude']}, Longitude: ${_userLocations[index]['longitude']}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
