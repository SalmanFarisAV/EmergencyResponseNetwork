import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter/painting.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? _bloodGroup;
  String? _medicalConditions;
  String? _username;
  bool _isEditing = false;
  String? _gender; // New state variable for gender
  File? _profilePicture;
  String? _profilePictureUrl;
  final _phoneNumberController = TextEditingController();
  String? _phoneNumber; // New state variable for phone number


  // Controllers for form fields
  final _medicalConditionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _fetchUserName();
    _medicalConditionsController.text = _medicalConditions ?? '';
    _phoneNumberController.addListener(() {
      setState(() {
        _phoneNumber = _phoneNumberController.text;
      });
    });
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
          _gender =
              docSnapshot.data()?['gender']; // Initialize gender from Firestore
          _phoneNumber = docSnapshot
              .data()?['phone']; // Initialize phone number from Firestore
          _medicalConditionsController.text = _medicalConditions ?? '';
        });
      }
    }
  }


  Future<void> _selectProfilePicture() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profilePicture = File(image.path);
      });
      _uploadProfilePicture();
    }
  }

  Future<void> _uploadProfilePicture() async {
    if (_profilePicture != null) {
      final String fileName =
          'profile_pictures/${FirebaseAuth.instance.currentUser!.uid}';
      final Reference ref = FirebaseStorage.instance.ref().child(fileName);
      final UploadTask uploadTask = ref.putFile(_profilePicture!);
      final TaskSnapshot taskSnapshot = await uploadTask;
      final String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({'profilePictureUrl': downloadUrl});

      // Update the state with the new image URL
      setState(() {
        _profilePictureUrl = downloadUrl;
      });
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
            'gender': _gender, // Save the gender to Firestore
            'phone': _phoneNumber, // Save the phone number to Firestore
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
            'gender': _gender, // Save the gender to Firestore
            'phone': _phoneNumber, // Save the phone number to Firestore
          });
          setState(() {
            _medicalConditions = _medicalConditionsController.text;
            _isEditing = false;
          });
        }
      }
    }
  }


  @override
  void dispose() {
    _medicalConditionsController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
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
                  if (!_isEditing)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          final String? profilePictureUrl =
                              _profilePictureUrl ??
                                  (snapshot.data?.data() as Map<String,
                                          dynamic>)?['profilePictureUrl']
                                      as String?;
                          return GestureDetector(
                            onTap: () => _selectProfilePicture(),
                            child: Container(
                              width: 100, // Adjust the width as needed
                              height: 100, // Adjust the height as needed
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors
                                      .blueAccent, // Change the border color as needed
                                  width: 2, // Adjust the border width as needed
                                ),
                              ),
                              child: ClipOval(
                                child: profilePictureUrl != null
                                    ? Image.network(
                                        profilePictureUrl,
                                        width:
                                            100, // Adjust the width as needed
                                        height:
                                            100, // Adjust the height as needed
                                        fit: BoxFit
                                            .cover, // Adjust the fit as needed
                                      )
                                    : Image.asset(
                                        'images/profile.jpg', // Use the default profile picture
                                        width:
                                            100, // Adjust the width as needed
                                        height:
                                            100, // Adjust the height as needed
                                        fit: BoxFit
                                            .cover, // Adjust the fit as needed
                                      ),
                              ),
                            ),
                          );
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                    ),

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
                        title: Text('Gender'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text('Male'),
                            Radio<String>(
                              value: 'Male',
                              groupValue: _gender,
                              onChanged: (String? value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                            Text('Female'),
                            Radio<String>(
                              value: 'Female',
                              groupValue: _gender,
                              onChanged: (String? value) {
                                setState(() {
                                  _gender = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Gender'),
                        trailing: Text(
                          _gender ?? 'Not specified',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
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
                        trailing: Text(
                          _bloodGroup ?? 'Not specified',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  if (_isEditing)
                    Card(
                      child: ListTile(
                        trailing: Container(
                          width: 290, // Adjust the width as needed
                          child: TextFormField(
                            controller: _medicalConditionsController,
                            decoration: InputDecoration(
                              hintText: 'Any medical conditions?',
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (!_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Medical Conditions'),
                        trailing: Text(
                          _medicalConditions ?? 'Not specified',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  SizedBox(height: 20),
                  if (_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Phone :'),
                        trailing: Container(
                          width: 230, // Adjust the width as needed
                          child: TextFormField(
                            controller: _phoneNumberController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              hintText: 'Enter your phone number',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                    ),
                  if (!_isEditing)
                    Card(
                      child: ListTile(
                        title: Text('Phone Number'),
                        trailing: Text(
                          _phoneNumber ?? 'Not specified',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
