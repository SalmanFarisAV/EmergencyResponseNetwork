import 'package:flutter/material.dart';

void updateMaxValues(List<double> currentValues, List<double> maxValues) {
  for (int i = 0; i < 3; i++) {
    if (currentValues[i] > maxValues[i]) {
      maxValues[i] = currentValues[i];
    }
  }
}

void resetMaxValues(List<double> maxValues) {
  maxValues[0] = 0.0;
  maxValues[1] = 0.0;
  maxValues[2] = 0.0;
}

Widget buildSensorValues(List<double> values, String type) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'X: ${values[0].toStringAsFixed(2)} (${type})',
        style: TextStyle(fontSize: 18, color: getColor(values[0], type)),
      ),
      Text(
        'Y: ${values[1].toStringAsFixed(2)} (${type})',
        style: TextStyle(fontSize: 18, color: getColor(values[1], type)),
      ),
      Text(
        'Z: ${values[2].toStringAsFixed(2)} (${type})',
        style: TextStyle(fontSize: 18, color: getColor(values[2], type)),
      ),
    ],
  );
}

Color getColor(double value, String type) {
  if (type == 'Live') {
    if (value > 0) {
      return Colors.green;
    } else if (value < 0) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  } else {
    return Colors.black;
  }
}
