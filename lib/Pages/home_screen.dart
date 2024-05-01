import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newapp/Pages/FindUser.dart';
import 'package:newapp/Pages/Location_page.dart';
import 'package:newapp/Pages/ProfilePage.dart';
import 'package:newapp/Pages/admin.dart';
import 'package:newapp/Pages/auth_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:newapp/Pages/motion_sensor.dart';
import 'package:newapp/Pages/register.dart';
import 'package:newapp/Pages/testpage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Functions/app_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  HomeScreen({this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _distance = 0.0;
  double _speed = 0.0;
  late StreamSubscription<DatabaseEvent>? _alertSubscription;
  String _alertValue = '0'; // State variable to store the alert value
  AudioPlayer audioPlayer = AudioPlayer();
  final player = AudioPlayer();
  // Position? _previousPosition;
  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
    _checkLocationPermission();
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

  Future<void> playSound() async {
    String audioPath = "audio/Emergency Alert.mp3";
    await player.play(AssetSource(audioPath));
  }

  void _showAlertDialog(String alertValue) async {
    // Fetch the user's details from Firestore using the alertValue (UID)
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(alertValue)
        .get();
    final double? latitude = userDoc.get('latitude');
    final double? longitude = userDoc.get('longitude');
    playSound();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent the dialog from closing when the back button is pressed
          child: AlertDialog(
            title: Text('EMERGENCY !',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Center the content
                children: [
                  // Display the user's details
                  Text('An accident has been detected.',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 20),
                  Text('Name : ${userDoc.get('name')}',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 10), // Add some space
                  Text('Gender : ${userDoc.get('gender')}',
                      style: TextStyle(color: Colors.red, fontSize: 18)),
                  SizedBox(height: 10),
                  Text('Blood Group : ${userDoc.get('bloodGroup')}',
                      style: TextStyle(color: Colors.red, fontSize: 18)),
                  SizedBox(height: 10), // Add some space
                  Text(
                      'Medical Condition : ${userDoc.get('medicalConditions')}',
                      style: TextStyle(color: Colors.red, fontSize: 18)),
                  SizedBox(height: 10), // Add some space
                  Text('Phone Number : ${userDoc.get('phone')}',
                      style: TextStyle(color: Colors.red, fontSize: 18)),
                  SizedBox(height: 20),
                  // Local image
                  GestureDetector(
                    onTap: () {
                      _launchGoogleMaps(latitude, longitude);
                    },
                    child: Container(
                      width: 200, // Adjust the width as needed
                      height: 170, // Adjust the height as needed
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(10), // Rounded corners
                        image: DecorationImage(
                          image: AssetImage('images/googlemap.webp'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // Add some space
                  Text('Click to open Location',
                      style: TextStyle(color: Colors.black, fontSize: 15)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  _resetAlerts();
                  Navigator.of(context).pop();
                  player.stop();
                },
                child: Text('Close',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            ],
            backgroundColor: const Color.fromARGB(
                255, 255, 255, 255), // Set a background color for the dialog
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Add rounded corners
            ),
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

  void _launchGoogleMaps(double? latitude, double? longitude) async {
    if (latitude != null && longitude != null) {
      final String googleUrl =
          'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      if (await canLaunch(googleUrl)) {
        await launch(googleUrl);
      } else {
        throw 'Could not launch $googleUrl';
      }
    }
  }

  //////////////


//Location accessing and Updating to Firebase
  void _checkLocationPermission() async {
    PermissionStatus permissionStatus = await Permission.location.request();
    if (permissionStatus == PermissionStatus.granted) {
      _getCurrentLocation();
    } else {
      // Handle denied or restricted permissions
      print('Location permission denied or restricted');
    }
  }

  void _getCurrentLocation() async {
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream().listen(
      (Position position) {
        final appState = AppState();
        if (appState.previousPosition != null) {
          double newDistance = Geolocator.distanceBetween(
            appState.previousPosition!.latitude,
            appState.previousPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          double newSpeed = newDistance /
              (position.timestamp
                  .difference(appState.previousPosition!.timestamp)
                  .inSeconds);
          setState(() {
            _distance += newDistance;
            _speed = newSpeed;
          });
        }
        appState.previousPosition = position;

        // Update coordinates to Firebase Realtime Database
        _updateCoordinatesToFirebase(position);
      },
      onError: (error) => print('Error getting location: $error'),
    );
  }

  void _updateCoordinatesToFirebase(Position position) async {
    // Fetch the responder value from Firestore
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final bool responder = userDoc.get('responder') ?? false;
    final String alert = userDoc.get('alert') ?? '0';

    // Update the location in Firebase Realtime Database
    final DatabaseReference databaseReference =
        FirebaseDatabase.instance.reference();
    final String path = 'users/$userId/location';
    final String userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';
    databaseReference.child(path).set({
      'uid': userId,
      'name': userName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': position.timestamp.millisecondsSinceEpoch,
      'responder': responder, // Include the responder value
      'alert': alert,
    });

    // Update the latitude and longitude in Firestore
    final DocumentReference userDocRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    await userDocRef.update({
      'latitude': position.latitude,
      'longitude': position.longitude,
    });
}


/////////

//initializing user profile to firestore
  Future<void> _initializeUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // If the document does not exist, create a new one with default values
        await docRef.set({
          'name': user.displayName ?? 'username',
          'bloodGroup': null,
          'medicalConditions': null,
          'gender': null,
          'phone': null,
          'profilePictureUrl': 'https://i.ibb.co/R7NQ88g/profile.jpg',
          'pending': false,
          'responder': false,
          'document': null,
          'visible': false,
          'powerSaver': false,
          'alert': null,
          'latitude': null,
          'longitude': null,
        });
      }
     
    }
  }
///////

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print("HomeScreen build: ${user?.displayName ?? 'No user'}");
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
          // IconButton(
          //   icon: Icon(Icons.search),
          //   onPressed: _fetchUserLocations,
          // ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Hello, ${widget.user?.displayName ?? 'Guest'}!',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

//appdrawer
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userEmail = user?.email ?? '';
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          if (userEmail == 'salu9651@gmail.com')
          ListTile(
            title: const Text('Location Demo'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LocationPage()),
              );
              // Close the drawer
            },
          ),
          if (userEmail == 'salu9651@gmail.com')
          ListTile(
            title: const Text('Find User'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FindUser()),
              );
              // Close the drawer
            },
          ),
          ListTile(
            title: const Text('Motion Sensor Demo'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SensorValuesApp()),
              );
            },
          ),
          // Add more ListTile widgets for additional items
          if (userEmail == 'salu9651@gmail.com')
          ListTile(
            title: const Text('Test'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TestPage()),
              );
            },
          ),
          /////
          ListTile(
            title: const Text('Register'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Register()),
              );
            },
          ),
          ////
          ListTile(
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
          /////
          if (userEmail == 'salu9651@gmail.com')
            ListTile(
              title: const Text('Admin'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminPage()),
                );
              },
            ),
          //////
          ListTile(
            title: const Text(
              'Logout',
              style: TextStyle(color: Color.fromARGB(255, 199, 13, 0)),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
          ),
          //////
        ],
      ),
    );
  }
}
/////
