import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
import 'package:newapp/Pages/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _keepMeSignedIn = false;
  bool _isPasswordVisible = false;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _checkKeepMeSignedIn();
  }

  Future<void> _checkKeepMeSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final keepMeSignedIn = prefs.getBool('keepMeSignedIn') ?? false;
    setState(() {
      _keepMeSignedIn = keepMeSignedIn;
    });
    if (keepMeSignedIn) {
      final user = _auth.currentUser;
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(user: user)),
        );
      }
    }
  }

  Future<void> _toggleKeepMeSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final keepMeSignedIn = !_keepMeSignedIn;
    await prefs.setBool('keepMeSignedIn', keepMeSignedIn);
    setState(() {
      _keepMeSignedIn = keepMeSignedIn;
    });
  }

  // Future<void> _handleGoogleSignIn() async {
  //   try {
  //     final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  //     if (googleUser == null) {
  //       print("Google sign-in failed: No user selected.");
  //       return;
  //     }
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //     final credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //     final userCredential = await _auth.signInWithCredential(credential);
  //     print("Google sign-in successful: ${userCredential.user?.displayName}");
  //     Navigator.pushReplacement(
  //       context,
  //       MaterialPageRoute(
  //           builder: (context) => HomeScreen(user: userCredential.user)),
  //     );
  //   } catch (error) {
  //     print("Google sign-in error: $error");
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (!_isLogin)
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),
                ),
                obscureText: !_isPasswordVisible,
              ),
              SizedBox(height: 20),
              CheckboxListTile(
                title: Text('Keep me signed in'),
                value: _keepMeSignedIn,
                onChanged: (bool? value) {
                  _toggleKeepMeSignedIn();
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  try {
                    if (_isLogin) {
                      final userCredential =
                          await _auth.signInWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                HomeScreen(user: userCredential.user)),
                      );
                    } else {
                      final userCredential =
                          await _auth.createUserWithEmailAndPassword(
                        email: _emailController.text,
                        password: _passwordController.text,
                      );
                      await userCredential.user
                          ?.updateDisplayName(_nameController.text);
                      // Navigate back to the login UI after successful sign-up
                      // This is where you might want to show a message or prompt the user to sign in
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                AuthPage()), // Navigate back to the login UI
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String errorMessage;
                    switch (e.code) {
                      case 'user-not-found':
                        errorMessage = 'No user found for that email.';
                        break;
                      case 'wrong-password':
                        errorMessage = 'Wrong password provided for that user.';
                        break;
                      case 'email-already-in-use':
                        errorMessage =
                            'The account already exists for that email.';
                        break;
                      case 'weak-password':
                        errorMessage = 'The password provided is too weak.';
                        break;
                      default:
                        errorMessage = 'An unknown error occurred.';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('An unknown error occurred.')),
                    );
                  }
                },
                child: Text(_isLogin ? 'Login' : 'Sign Up'),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(_isLogin ? 'Sign Up' : 'Login'),
              ),
              // SizedBox(height: 20),
              // IconButton(
              //   icon: Image.asset(
              //     'images/google_logo.png',
              //     width: 45,
              //     height: 45,
              //   ),
              //   onPressed: _handleGoogleSignIn,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
