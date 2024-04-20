import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:newapp/Pages/auth_page.dart';
// import 'package:newapp/login_screen.dart';
// import 'package:newapp/signup_screen.dart';
import 'firebase_options.dart'; // Import your firebase_options.dart file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(
      debug: true // optional: set false to disable printing logs to console
      );
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthPage(),
    );
  }
}
