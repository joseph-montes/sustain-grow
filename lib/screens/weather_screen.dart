import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppProvider>().fetchWeather());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Forecast'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.weather.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchWeather(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.weather.length,
              itemBuilder: (context, index) {
                final day = provider.weather[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              day['date'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Icon(
                              _getWeatherIcon(day['condition']),
                              size: 32,
                              color: Colors.orange,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          day['condition'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherDetail(
                              Icons.thermostat,
                              '${day['temperature_high']}C / ${day['temperature_low']}C',
                            ),
                            _buildWeatherDetail(
                              Icons.water_drop,
                              '${day['humidity']}%',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildWeatherDetail(
                              Icons.air,
                              '${day['wind_speed_kmh']} km/h',
                            ),
                            _buildWeatherDetail(
                              Icons.umbrella,
                              '${day['rainfall_mm']} mm',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  day['advisory'],
                                  style: TextStyle(
                                    color: Colors.green[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  IconData _getWeatherIcon(String condition) {
    if (condition.toLowerCase().contains('sunny')) {
      return Icons.wb_sunny;
    } else if (condition.toLowerCase().contains('rain')) {
      return Icons.water_drop;
    } else if (condition.toLowerCase().contains('cloud')) {
      return Icons.cloud;
    }
    return Icons.wb_cloudy;
  }
}