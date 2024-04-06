import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

class AppState {
  static final AppState _singleton = AppState._internal();

  factory AppState() {
    return _singleton;
  }

  AppState._internal();

  Position? _previousPosition;

  Position? get previousPosition => _previousPosition;

  set previousPosition(Position? value) {
    _previousPosition = value;
  }
}
