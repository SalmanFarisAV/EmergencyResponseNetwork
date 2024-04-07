import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:newapp/Pages/FindUser.dart';
import 'package:newapp/Pages/Location_page.dart';
import 'package:newapp/Pages/ProfilePage.dart';
import 'package:newapp/Pages/auth_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:newapp/Pages/motion_sensor.dart';
import 'package:newapp/Pages/testpage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_database/firebase_database.dart';
import '../Functions/app_state.dart';

class HomeScreen extends StatefulWidget {
  final User? user;

  HomeScreen({this.user});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _distance = 0.0;
  double _speed = 0.0;
  // Position? _previousPosition;
  @override
  void initState() {
    super.initState();
    _initializeUserProfile();
    _checkLocationPermission();
  }

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

  void _updateCoordinatesToFirebase(Position position) {
    // ignore: deprecated_member_use
    final DatabaseReference databaseReference =
        // ignore: deprecated_member_use
        FirebaseDatabase.instance.reference();
    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final String path = 'users/$userId/location';
    final String userName =
        FirebaseAuth.instance.currentUser?.displayName ?? 'Unknown';
    databaseReference.child(path).set({
      'name': userName,
      'latitude': position.latitude,
      'longitude': position.longitude,
      'timestamp': position.timestamp.millisecondsSinceEpoch,
    });
  }
/////////


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
        });
      }
    }
  }

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
          ListTile(
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => AuthPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
/////