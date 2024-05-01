import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:newapp/Pages/auth_page.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset('video/splash_dark.mp4')
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true)
      ..setVolume(0.0)
      ..play();

    // Navigate to the AuthPage with a custom transition after 3 seconds
    Future.delayed(Duration(seconds: 6), () {
      if (mounted) {
        // Check if the widget is still in the widget tree
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => AuthPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              // Define your custom transition here
              // For example, a fade transition
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: _controller.value.isInitialized
              ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
              : Container(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }
}
