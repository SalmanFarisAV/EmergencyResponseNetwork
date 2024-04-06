import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  String? _imageUrl;
  String? _bloodGroup;
  String? _medicalConditions;
  String? _username;
  bool _isEditing = false;

  // Controllers for form fields
  final _medicalConditionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserName();
    _medicalConditionsController.text = _medicalConditions ?? '';
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _username = user.displayName;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (docSnapshot.exists) {
        setState(() {
          _bloodGroup = docSnapshot.data()?['bloodGroup'];
          _medicalConditions = docSnapshot.data()?['medicalConditions'];
          _medicalConditionsController.text = _medicalConditions ?? '';
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final docRef =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        final docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
          await docRef.update({
            'bloodGroup': _bloodGroup,
            'medicalConditions': _medicalConditionsController.text,
          });
          final updatedDocSnapshot = await docRef.get();
          if (updatedDocSnapshot.exists) {
            setState(() {
              _medicalConditions =
                  updatedDocSnapshot.data()?['medicalConditions'];
              _medicalConditionsController.text = _medicalConditions ?? '';
              _isEditing = false;
            });
          }
        } else {
          await docRef.set({
            'name': _username,
            'bloodGroup': _bloodGroup,
            'medicalConditions': _medicalConditionsController.text,
          });
          setState(() {
            _medicalConditions = _medicalConditionsController.text;
            _isEditing = false;
          });
        }
      }
    }
  }

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      print("Image selected: ${pickedFile.path}"); // Debug print statement
      await _uploadImageToFirebase(pickedFile.path);
      setState(() {
        _imageUrl = pickedFile.path;
      });
      print("Image URL updated: $_imageUrl"); // Debug print statement
      Navigator.of(context).pop(); // Dismiss the dialog
    } else {
      print("No image selected."); // Debug print statement
    }
  }

  Future<void> _uploadImageToFirebase(String filePath) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final ref = FirebaseStorage.instance.ref('profilePictures/${user.uid}');
      try {
        final task = ref.putFile(File(filePath));
        final snapshot = await task.whenComplete(() {});
        final url = await snapshot.ref.getDownloadURL();
        // ignore: deprecated_member_use
        await user.updateProfile(photoURL: url);
        print("Image uploaded successfully."); // Debug print statement
      } catch (e) {
        print("Error uploading image: $e"); // Debug print statement
      }
    }
  }

  void _showProfilePictureDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change Profile Picture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () => _pickImage(context),
                child: Text('Choose Image'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minHeight: MediaQuery.of(context).size.height),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  InkWell(
                    onTap: () => _showProfilePictureDialog(context),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: _imageUrl != null
                          ? FileImage(File(_imageUrl!))
                          : null,
                      child: _imageUrl == null
                          ? Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Hello, ${_username ?? 'Guest'}!',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 20),
                  if (_isEditing)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _updateProfile,
                      child: Text('Save Profile'),
                    ),
                  if (!_isEditing)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: () => setState(() => _isEditing = true),
                      child: Text('Edit Profile'),
                    ),
                  SizedBox(height: 20),
                  if (_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Blood Group'),
                        trailing: DropdownButton<String>(
                          value: _bloodGroup,
                          onChanged: (String? newValue) {
                            setState(() {
                              _bloodGroup = newValue;
                            });
                          },
                          items: <String>[
                            'A+',
                            'A-',
                            'B+',
                            'B-',
                            'AB+',
                            'AB-',
                            'O+',
                            'O-'
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (!_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Blood Group'),
                        trailing: Text(_bloodGroup ?? 'Not specified'),
                      ),
                    ),
                  SizedBox(height: 20),
                  if (_isEditing)
                    Card(
                      child: ListTile(
                        trailing: Container(
                          width: 360,
                          child: TextFormField(
                            controller: _medicalConditionsController,
                            decoration: InputDecoration(
                              hintText: 'Enter medical conditions',
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Medical Conditions'),
                        trailing: Text(_medicalConditions ?? 'Not specified'),
                      ),
                    ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
