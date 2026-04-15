import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AppProvider>();
      if (p.weather.isEmpty) p.fetchWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final weather = provider.weather;
    final today = weather.isNotEmpty ? weather[0] : null;

    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: CustomScrollView(
        slivers: [
          // ── Hero Today Card ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Weather Forecast',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800)),
                          const Spacer(),
                          if (provider.weather.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white70),
                              onPressed: () => provider.fetchWeather(),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your farm location · Updated just now',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12),
                      ),
                      const SizedBox(height: 28),

                      // Today's big card
                      if (today == null)
                        const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white))
                      else ...[
                        Center(
                          child: Column(
                            children: [
                              Text(
                                today['condition_icon'] ?? '☀️',
                                style: const TextStyle(fontSize: 72),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${today['temperature'] ?? '--'}°C',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 60,
                                  fontWeight: FontWeight.w300,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                today['condition'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                today['date'] ?? '',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Metrics row
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _metric('💧', '${today['humidity']}%',
                                  'Humidity'),
                              _divider(),
                              _metric('💨',
                                  '${today['wind_speed_kmh']} km/h', 'Wind'),
                              _divider(),
                              _metric('🌧️', '${today['rainfall_mm']} mm',
                                  'Rainfall'),
                              _divider(),
                              _metric('🌡️',
                                  '${today['temperature_low']}° / ${today['temperature_high']}°',
                                  'Lo / Hi'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Forecast List ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 22, 20, 10),
                    child: Text('6-Day Forecast', style: AppTheme.heading2),
                  ),
                  if (weather.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                          child: CircularProgressIndicator(
                              color: AppTheme.primaryGreen)),
                    )
                  else
                    ...weather.map((day) => _ForecastDayCard(day: day)).toList(),
                  const SizedBox(height: 20),

                  // Farm advisory card
                  if (today != null && today['advisory'] != null)
                    _AdvisoryCard(advisory: today['advisory']),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String emoji, String value, String label) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 10)),
        ],
      );

  Widget _divider() => Container(
        height: 36,
        width: 1,
        color: Colors.white.withOpacity(0.2),
      );
}

class _ForecastDayCard extends StatelessWidget {
  final dynamic day;
  const _ForecastDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Day
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day['day'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          fontSize: 14)),
                  Text(
                    day['date'] == 'Today'
                        ? 'Today'
                        : day['date'] == 'Tomorrow'
                            ? 'Tmrw'
                            : '',
                    style: const TextStyle(
                        fontSize: 10, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
            // Icon
            Text(day['condition_icon'] ?? '☀️',
                style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            // Condition + rain
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(day['condition'] ?? '',
                      style: const TextStyle(
                          fontSize: 14, color: AppTheme.textPrimary)),
                  if ((day['rainfall_mm'] ?? 0) > 0)
                    Text('🌧 ${day['rainfall_mm']}mm rain',
                        style: const TextStyle(
                            fontSize: 11, color: AppTheme.infoBlue)),
                ],
              ),
            ),
            // Temp
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${day['temperature_high']}°',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppTheme.textPrimary)),
                Text('${day['temperature_low']}°',
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvisoryCard extends StatelessWidget {
  final String advisory;
  const _AdvisoryCard({required this.advisory});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.agriculture_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Farming Advisory',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            advisory,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}