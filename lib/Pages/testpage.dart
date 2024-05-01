import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:audioplayers/audioplayers.dart';
class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  late StreamSubscription<DatabaseEvent>? _alertSubscription;
  String _alertValue = '0'; // State variable to store the alert value
  AudioPlayer audioPlayer = AudioPlayer();
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // _listenToAlert();
  }



///////// accident popup
//   void _listenToAlert() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final DatabaseReference alertRef = FirebaseDatabase.instance
//           .reference()
//           .child('users/${user.uid}/location/alert');
//       _alertSubscription = alertRef.onValue.listen((event) {
//         final data = event.snapshot.value;
//         if (data != '0') {
//           setState(() {
//             _alertValue = data
//                 .toString(); // Update the state variable with the new alert value
//           });
//           _showAlertDialog(data.toString());
//         }
//       });
//     }
//   }

//   Future<void> playSound() async {
//     String audioPath = "audio/Emergency Alert.mp3";
//     await player.play(AssetSource(audioPath));
//   }

// void _showAlertDialog(String alertValue) async {
//     // Fetch the user's details from Firestore using the alertValue (UID)
//     final DocumentSnapshot userDoc = await FirebaseFirestore.instance
//         .collection('users')
//         .doc(alertValue)
//         .get();
//     final double? latitude = userDoc.get('latitude');
//     final double? longitude = userDoc.get('longitude');
//     playSound();
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return WillPopScope(
//           onWillPop: () async =>
//               false, // Prevent the dialog from closing when the back button is pressed
//           child: AlertDialog(
//             title: Text('EMERGENCY !',
//                 style: TextStyle(
//                     color: Colors.red,
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold)),
//             content: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment:
//                     CrossAxisAlignment.center, // Center the content
//                 children: [
//                   // Display the user's details
//                   Text('An accident has been detected.',
//                       style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold)),
//                   SizedBox(height: 20),
//                   Text('Name : ${userDoc.get('name')}',
//                       style: TextStyle(
//                           color: Colors.red,
//                           fontSize: 20,
//                           fontWeight: FontWeight.bold)),
//                   SizedBox(height: 10), // Add some space
//                   Text('Gender : ${userDoc.get('gender')}',
//                       style: TextStyle(color: Colors.red, fontSize: 18)),
//                   SizedBox(height: 10),
//                   Text('Blood Group : ${userDoc.get('bloodGroup')}',
//                       style: TextStyle(color: Colors.red, fontSize: 18)),
//                   SizedBox(height: 10), // Add some space
//                   Text(
//                       'Medical Condition : ${userDoc.get('medicalConditions')}',
//                       style: TextStyle(color: Colors.red, fontSize: 18)),
//                   SizedBox(height: 10), // Add some space
//                   Text('Phone Number : ${userDoc.get('phone')}',
//                       style: TextStyle(color: Colors.red, fontSize: 18)),
//                   SizedBox(height: 20),
//                   // Local image
//                   GestureDetector(
//                     onTap: () {
//                       _launchGoogleMaps(latitude, longitude);
//                     },
//                     child: Container(
//                       width: 200, // Adjust the width as needed
//                       height: 170, // Adjust the height as needed
//                       decoration: BoxDecoration(
//                         borderRadius:
//                             BorderRadius.circular(10), // Rounded corners
//                         image: DecorationImage(
//                           image: AssetImage('images/googlemap.webp'),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 10), // Add some space
//                   Text('Click to open Location',
//                       style: TextStyle(color: Colors.black, fontSize: 15)),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   _resetAlerts();
//                   Navigator.of(context).pop();
//                   player.stop();
//                 },
//                 child: Text('Close',
//                     style: TextStyle(
//                         color: Colors.red, fontWeight: FontWeight.bold)),
//               ),
//             ],
//             backgroundColor: const Color.fromARGB(
//                 255, 255, 255, 255), // Set a background color for the dialog
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20), // Add rounded corners
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void _resetAlerts() {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       final DatabaseReference alertRef = FirebaseDatabase.instance
//           .reference()
//           .child('users/${user.uid}/location/alert');
//       alertRef.set('0');

//       final userCollection = FirebaseFirestore.instance.collection('users');
//       userCollection.doc(user.uid).update({
//         'alert': '0', // Set the alert value to null in Firestore
//       });
//     }
//   }

  /////////

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
            
              ElevatedButton(
                onPressed: _resetAlertsForAllUsers,
                child: Text('Reset all Alerts'),
              ),
          ],
        ),
      ),
    );
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
}
