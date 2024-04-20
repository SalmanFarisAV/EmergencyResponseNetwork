import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Register extends StatefulWidget {
  const Register({Key? key}) : super(key: key);

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  bool _pending = false;
  bool _responder = false;
  bool _visible = false;
  bool _submitting = false; // Flag to track submission state

  Future<void> _selectDocument() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitDocument() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a document.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true; // Set submitting to true when starting submission
    });

    final String fileName =
        'documents/${FirebaseAuth.instance.currentUser!.uid}';
    final Reference ref = FirebaseStorage.instance.ref().child(fileName);
    final UploadTask uploadTask = ref.putFile(File(_selectedImage!.path));
    final TaskSnapshot taskSnapshot = await uploadTask;
    final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'document': downloadUrl,
      'pending': true,
      'visible': true,
    });

    setState(() {
      _pending = true;
      _submitting = false; // Set submitting to false after submission
    });
    _fetchDocumentStatus(); // Refresh the document status
  }

  Future<void> _fetchDocumentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _pending = docSnapshot.data()?['pending'] ?? false;
          _responder = docSnapshot.data()?['responder'] ?? false;
          _visible = docSnapshot.data()?['visible'] ?? false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDocumentStatus();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final String userName = user?.displayName ?? 'user';
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registration',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0), // Add left padding here
        child: _submitting
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ), // Loading indicator
                    SizedBox(
                        height: 20), // Space between the indicator and the text
                    Text(
                      'Please wait.. Document uploading...',
                      style: TextStyle(fontSize: 18, color: Colors.blue),
                    ),
                  ],
                ),
              ) // Show loading indicator in the body
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Register as a First Aid Responder',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.blue),
                    ),
                    SizedBox(
                      height: 30,
                    ),
                    Text(
                      'Hello, $userName!',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (!_visible) ...[
                      _selectedImage == null
                          ? Text('Choose document:',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.black))
                          : Text(''),
                      const SizedBox(height: 20),
                      _selectedImage != null
                          ? Image.file(
                              File(_selectedImage!.path),
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            )
                          : Text('No image selected',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.black)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _selectDocument,
                        child: Text('Choose Document Image',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitDocument,
                        child: Text('Submit',
                            style:
                                TextStyle(fontSize: 16, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                      ),
                    ] else ...[
                      Text('Document Submitted',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.green)), // Green for Submitted
                      if (_responder)
                        Text('Verified Successfully',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.green)) // Green for Verified
                      else
                        Text('Pending Verification',
                            style: TextStyle(
                                fontSize: 18,
                                color: Colors.red)), // Red for Pending
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
