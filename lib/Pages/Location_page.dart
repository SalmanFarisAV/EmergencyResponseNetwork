import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPage extends StatelessWidget {
  const LocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Demo'),
      ),
      body: const Center(
        child: LocationStreamWidget(),
      ),
    );
  }
}

class LocationStreamWidget extends StatefulWidget {
  const LocationStreamWidget({super.key});

  @override
  _LocationStreamWidgetState createState() => _LocationStreamWidgetState();
}

class _LocationStreamWidgetState extends State<LocationStreamWidget> {
  double _distance = 0.0;
  double _speed = 0.0;
  Position? _previousPosition;
  bool _travelling = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

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
        if (_previousPosition != null) {
          double newDistance = Geolocator.distanceBetween(
            _previousPosition!.latitude,
            _previousPosition!.longitude,
            position.latitude,
            position.longitude,
          );
          double newSpeed = newDistance /
              (position.timestamp
                  .difference(_previousPosition!.timestamp)
                  .inSeconds);
          setState(() {
            _distance += newDistance;
            _speed = newSpeed;
            _travelling = _speed > 5;
          });
        }
        _previousPosition = position;
      },
      onError: (error) => print('Error getting location: $error'),
    );
  }

  void _resetDistance() {
    setState(() {
      _distance = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Coordinates: ${_previousPosition?.latitude ?? 0.0}, ${_previousPosition?.longitude ?? 0.0}',
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        const SizedBox(height: 20),
        Text(
          'Distance: ${_distance.toStringAsFixed(2)} meters',
          style: TextStyle(fontSize: 16, color: Colors.blue[900]),
        ),
        const SizedBox(height: 20),
        Text(
          'Speed: ${_speed.toStringAsFixed(2)} m/s',
          style: TextStyle(fontSize: 20, color: Colors.blue[900]),
        ),
        const SizedBox(height: 20),
        if (_travelling)
          const Text(
            'YOU ARE TRAVELING',
            style: TextStyle(fontSize: 25, color: Colors.green),
          )
        else
          const Text(
            'YOU ARE NOT TRAVELING',
            style: TextStyle(fontSize: 25, color: Colors.red),
          ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _resetDistance,
          child: const Text('Reset Distance'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
    _previousPosition = null;
  }
}
