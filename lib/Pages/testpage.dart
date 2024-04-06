import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_swipe_button/flutter_swipe_button.dart';

class TestPage extends StatelessWidget {
  AudioPlayer audioPlayer = AudioPlayer();
  final player = AudioPlayer();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('AudioPlayer Example'),
        ),
        body: Builder(builder: (BuildContext context) {
          return Center(
            child: Container(
              width: 180, // Specify the desired width here
              child: SwipeButton.expand(
                thumb: Icon(
                  Icons.double_arrow_rounded,
                  color: Colors.white,
                ),
                child: Text(
                  "Cancel...",
                  style:
                      TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                activeThumbColor: Colors.red,
                activeTrackColor: Colors.grey.shade300,
                onSwipe: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Swipped"),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Future<void> playSound() async {
    String audioPath = "audio/emergency.mp3";
    await player.play(AssetSource(audioPath));
  }
}



// ElevatedButton(
//             onPressed: () {
//               playSound();
//             },
//             child: Text("Play Sound"),
//           ),
          