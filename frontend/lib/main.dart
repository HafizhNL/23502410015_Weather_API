import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WeatherScreen(),
    );
  }
}

// ─── Model ───────────────────────────────────────────────────────────────────

class WeatherData {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final int visibility;

  const WeatherData({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.visibility,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      cityName: json['name'] as String,
      country: json['sys']['country'] as String,
      temperature: (json['main']['temp'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      iconCode: json['weather'][0]['icon'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      visibility: json['visibility'] as int,
    );
  }

  IconData get weatherIcon {
    final code = iconCode.substring(0, 2);
    switch (code) {
      case '01': return Icons.wb_sunny_rounded;
      case '02':
      case '03': return Icons.wb_cloudy_rounded;
      case '04': return Icons.cloud_rounded;
      case '09':
      case '10': return Icons.grain_rounded;
      case '11': return Icons.thunderstorm_rounded;
      case '13': return Icons.ac_unit_rounded;
      case '50': return Icons.foggy;
      default:   return Icons.wb_sunny_rounded;
    }
  }

  Color get iconColor {
    final code = iconCode.substring(0, 2);
    if (iconCode.endsWith('n')) return const Color(0xFFB0C4DE);
    switch (code) {
      case '01': return const Color(0xFFFFD700);
      case '09':
      case '10': return const Color(0xFF90CAF9);
      case '11': return const Color(0xFFFFE566);
      case '13': return Colors.white;
      default:   return Colors.white70;
    }
  }

  List<Color> get backgroundGradient {
    final code = iconCode.substring(0, 2);
    if (iconCode.endsWith('n')) {
      return [const Color(0xFF0D1B2A), const Color(0xFF1B2A3B)];
    }
    switch (code) {
      case '01': return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
      case '02':
      case '03': return [const Color(0xFF37474F), const Color(0xFF78909C)];
      case '04': return [const Color(0xFF455A64), const Color(0xFF90A4AE)];
      case '09':
      case '10': return [const Color(0xFF1A237E), const Color(0xFF3949AB)];
      case '11': return [const Color(0xFF212121), const Color(0xFF37474F)];
      case '13': return [const Color(0xFF546E7A), const Color(0xFFB0BEC5)];
      case '50': return [const Color(0xFF607D8B), const Color(0xFF90A4AE)];
      default:   return [const Color(0xFF1565C0), const Color(0xFF42A5F5)];
    }
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class WeatherService {
  static const _base = 'http://127.0.0.1:8000/api/weather';

  Future<WeatherData> fetch(String city) async {
    final uri = Uri.parse('$_base/?city=$city');
    final res = await http.get(uri);

    if (res.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(res.body));
    } else if (res.statusCode == 404) {
      throw Exception('City not found');
    } else if (res.statusCode == 401) {
      throw Exception('Invalid API key');
    } else {
      throw Exception('Error ${res.statusCode}');
    }
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with SingleTickerProviderStateMixin {

  final _cityCtrl = TextEditingController();
  final _service  = WeatherService();

  WeatherData? _data;
  bool _loading   = false;
  String? _error;

  late final AnimationController _anim = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700),
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08), end: Offset.zero,
  ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));

  @override
  void dispose() {
    _cityCtrl.dispose();
    _anim.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) {
      setState(() => _error = 'Please enter a city name');
      return;
    }
    FocusScope.of(context).unfocus();

    setState(() { _loading = true; _error = null; _data = null; });
    _anim.reset();

    try {
      final result = await _service.fetch(city);
      setState(() { _data = result; _loading = false; });
      _anim.forward();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Color> get _bg => _data?.backgroundGradient ??
      [const Color(0xFF102A43), const Color(0xFF1E3A5F)];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _bg,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 48),

                        // Icon + city name
                        if (_data != null)
                          SlideTransition(
                            position: _slide,
                            child: FadeTransition(
                              opacity: _fade,
                              child: _IconSection(data: _data!),
                            ),
                          )
                        else
                          _EmptyIcon(loading: _loading),

                        const SizedBox(height: 28),

                        // Temperature
                        if (_data != null)
                          SlideTransition(
                            position: _slide,
                            child: FadeTransition(
                              opacity: _fade,
                              child: _TempSection(data: _data!),
                            ),
                          )
                        else if (!_loading)
                          Text(
                            '--°',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.2),
                              fontSize: 90,
                              fontWeight: FontWeight.w200,
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Info rows
                        if (_data != null)
                          SlideTransition(
                            position: _slide,
                            child: FadeTransition(
                              opacity: _fade,
                              child: _InfoRows(data: _data!),
                            ),
                          ),

                        // Error
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Color(0xFFFF6B6B),
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),

              // City input (pinned at bottom)
              _CityInput(
                controller: _cityCtrl,
                loading: _loading,
                onSearch: _search,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _IconSection extends StatelessWidget {
  final WeatherData data;
  const _IconSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(data.weatherIcon, size: 120, color: data.iconColor),
        const SizedBox(height: 14),
        Text(
          '${data.cityName}, ${data.country}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _EmptyIcon extends StatelessWidget {
  final bool loading;
  const _EmptyIcon({required this.loading});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(
        height: 140,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2),
        ),
      );
    }
    return Column(
      children: [
        Icon(Icons.cloud_outlined, size: 120,
            color: Colors.white.withOpacity(0.12)),
        const SizedBox(height: 14),
        Text(
          'Search a city to see the weather',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _TempSection extends StatelessWidget {
  final WeatherData data;
  const _TempSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${data.temperature.round()}°',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 90,
            fontWeight: FontWeight.w200,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          data.description,
          style: TextStyle(
            color: Colors.white.withOpacity(0.65),
            fontSize: 16,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _InfoRows extends StatelessWidget {
  final WeatherData data;
  const _InfoRows({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Feels like',  '${data.feelsLike.round()}°C'),
      ('Humidity',    '${data.humidity}%'),
      ('Wind',        '${data.windSpeed.toStringAsFixed(1)} m/s'),
      ('Visibility',  '${(data.visibility / 1000).toStringAsFixed(1)} km'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final label = rows[i].$1;
          final value = rows[i].$2;
          final isLast = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 14)),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 0, thickness: 0.5,
                  color: Colors.white.withOpacity(0.1),
                  indent: 24, endIndent: 24,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _CityInput extends StatelessWidget {
  final TextEditingController controller;
  final bool loading;
  final VoidCallback onSearch;

  const _CityInput({
    required this.controller,
    required this.loading,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => onSearch(),
                decoration: InputDecoration(
                  hintText: 'City...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
                  prefixIcon: Icon(Icons.location_on_rounded,
                      color: Colors.white.withOpacity(0.45), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: loading ? null : onSearch,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: loading
                    ? Colors.white.withOpacity(0.15)
                    : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: loading
                  ? const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : const Icon(Icons.search_rounded,
                      color: Color(0xFF1E3A5F), size: 24),
            ),
          ),
        ],
      ),
    );
  }
}