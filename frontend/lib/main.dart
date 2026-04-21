import 'package:flutter/material.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const WeatherDashboard(),
    );
  }
}

class WeatherDashboard extends StatelessWidget {
  const WeatherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Dashboard'),
      ),
      body: const Center(
        child: Text('Weather data will be displayed here.'),
      ),
    );
  }
}