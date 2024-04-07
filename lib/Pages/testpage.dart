import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TestPage extends StatefulWidget {
  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _displayName = 'Loading...';

  // @override
  // void initState() {
  //   super.initState();
  //   _getUser();
  // }

  // void _getUser() async {
  //   final user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     setState(() {
  //       _displayName = ;
  //     });
  //   } else {
  //     setState(() {
  //       _displayName = 'No user logged in';
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Hello World App'),
        ),
        body: Column(
          children: [
            Center(
              child: Text(
                user?.displayName ?? 'No display name',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              
            ),
            
          ],
        ),
        
      ),
    );
  }
}
