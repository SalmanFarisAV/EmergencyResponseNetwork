import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../Functions/Functions.dart'; // Import the Functions.dart file
import 'package:audioplayers/audioplayers.dart';

class SensorValuesApp extends StatefulWidget {
  @override
  _SensorValuesAppState createState() => _SensorValuesAppState();
}

class _SensorValuesAppState extends State<SensorValuesApp> {
  List<double> _gyroscopeValues = [0.0, 0.0, 0.0];
  List<double> _accelerometerValues = [0.0, 0.0, 0.0];
  List<double> _maxGyroscopeValues = [0.0, 0.0, 0.0];
  List<double> _maxAccelerometerValues = [0.0, 0.0, 0.0];
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late StreamSubscription<UserAccelerometerEvent> _accelerometerSubscription;
  bool _dialogShown = false;
  int _remainingTime = 20; // Start with 10 seconds
  Timer? _timer;
  ValueNotifier<int> _remainingTimeNotifier = ValueNotifier<int>(10);
  AudioPlayer audioPlayer = AudioPlayer();
  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();

    // ignore: deprecated_member_use
    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscopeValues = [event.x, event.y, event.z];
        updateMaxValues([event.x, event.y, event.z], _maxGyroscopeValues);

        if (_gyroscopeValues.any((value) => value.abs() > 10)) {
          // _setSensorT();
          _showAccidentDialog();
        }
        // Print for debugging
      });
    }, onError: (error) {
      print("Gyroscope Error: $error");
    });

    _accelerometerSubscription =
        // ignore: deprecated_member_use
        userAccelerometerEvents.listen((UserAccelerometerEvent event) {
      setState(() {
        _accelerometerValues = [event.x, event.y, event.z];
        updateMaxValues([event.x, event.y, event.z], _maxAccelerometerValues);
        // Check if any value exceeds 10
        if (_accelerometerValues.any((value) => value.abs() > 10)) {
          // _setSensorT();
          _showAccidentDialog();
        }
      });
    }, onError: (error) {
      print("Accelerometer Error: $error");
    });
  }

  void _showAccidentDialog() {
    if (!_dialogShown) {
      _dialogShown =
          true; // Set the flag to true to indicate the dialog is shown
      _remainingTimeNotifier.value =
          20; // Reset the remaining time to 10 seconds
      _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
        if (_remainingTimeNotifier.value > 0) {
          _remainingTimeNotifier.value--; // Decrement the remaining time
        } else {
          t.cancel(); // Cancel the timer when the countdown is finished
          if (_dialogShown) {
            // Check if the dialog is still open
            Navigator.of(context).pop(); // Close the "Accident Detected" dialog
            _showSignalSentDialog();
            player.stop(); // Show the "Signal Sent" dialog
          }
        }
      });
      playSound();
      showDialog(
        context: context,
        barrierDismissible:
            false, // Prevent the dialog from closing when tapping outside
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async =>
                false, // Prevent the dialog from closing when the back button is pressed
            child: AlertDialog(
              title: Center(
                  child: Text(
                'Accident Detected',
                style: TextStyle(fontWeight: FontWeight.bold),
              )),
              content: ValueListenableBuilder<int>(
                valueListenable: _remainingTimeNotifier,
                builder: (BuildContext context, int value, Widget? child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Press Cancel if it is a False Alarm.',
                        style: TextStyle(fontSize: 15),
                      ),
                      SizedBox(height: 10),
                      Text('Time remaining:'),
                      Text(
                        '$value Seconds',
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.red,
                            fontWeight: FontWeight.bold),
                      )
                    ],
                  );
                },
              ),
              actions: <Widget>[
                Center(
                  child: Container(
                    width: 180, // Specify the desired width here
                    child: SwipeButton.expand(
                      thumb: Icon(
                        Icons.double_arrow_rounded,
                        color: Colors.white,
                      ),
                      child: Text(
                        "Cancel...",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                      activeThumbColor: Colors.red,
                      activeTrackColor: Colors.grey.shade300,
                      onSwipe: () {
                        _timer
                            ?.cancel(); // Cancel the timer when the dialog is closed
                        Navigator.of(context).pop(); // Close the dialog
                        _resetMaxValues(); // Optionally reset max values and sensor threshold
                        _dialogShown =
                            false; // Reset the flag when the dialog is closed
                        player.stop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  void _showSignalSentDialog() {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Prevent the dialog from closing when tapping outside
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async =>
              false, // Prevent the dialog from closing when the back button is pressed
          child: AlertDialog(
            title: Text('Signal Sent'),
            content: Text(
                'A signal has been sent to alert for the detected accident.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _resetMaxValues(); // Close the dialog
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> playSound() async {
    String audioPath = "audio/emergency.mp3";
    await player.play(AssetSource(audioPath));
  }

  void _resetMaxValues() {
    setState(() {
      resetMaxValues(_maxGyroscopeValues);
      resetMaxValues(_maxAccelerometerValues);
      _dialogShown = false; // Reset the flag when the dialog is closed
      _timer?.cancel();
      _remainingTimeNotifier.value = 20;
    });
  }

  @override
  void dispose() {
    _gyroscopeSubscription.cancel();
    _accelerometerSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sensor Values'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gyroscope Values:',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 10),
                      buildSensorValues(_gyroscopeValues, 'Live'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      buildSensorValues(_maxGyroscopeValues, 'Max'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accelerometer Values:',
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(height: 10),
                      buildSensorValues(_accelerometerValues, 'Live'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 30),
                      buildSensorValues(_maxAccelerometerValues, 'Max'),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _resetMaxValues,
                child: Text('Reset Max Values'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
