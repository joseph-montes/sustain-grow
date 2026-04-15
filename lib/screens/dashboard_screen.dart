import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'login_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final p = context.read<AppProvider>();
      if (p.dashboardStats == null) {
        p.fetchDashboardStats();
        p.fetchAlerts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.eco_rounded,
                                  color: Colors.white, size: 26),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications_outlined,
                                  color: Colors.white),
                              onPressed: () => _showAlerts(context, provider),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  color: Colors.white),
                              onSelected: (v) {
                                if (v == 'logout') {
                                  provider.logout();
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                        builder: (_) => const LoginPage()),
                                    (route) => false,
                                  );
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                    value: 'logout', child: Text('Logout')),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Good morning, ${user?['name'] ?? 'Farmer'} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Here\'s your farm overview today',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────────────────
          if (provider.isLoading && provider.dashboardStats == null)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGreen),
              ),
            )
          else
            SliverToBoxAdapter(
              child: RefreshIndicator(
                color: AppTheme.primaryGreen,
                onRefresh: () async {
                  await provider.fetchDashboardStats();
                  await provider.fetchAlerts();
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Sustainability Card ──────────────────────────────
                      _SustainabilityCard(stats: provider.dashboardStats ?? {}),
                      const SizedBox(height: 20),

                      // ── Stats Row ────────────────────────────────────────
                      const Text('Farm Summary', style: AppTheme.heading2),
                      const SizedBox(height: 12),
                      _StatsGrid(stats: provider.dashboardStats ?? {}),
                      const SizedBox(height: 24),

                      // ── Alerts ───────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Recent Alerts', style: AppTheme.heading2),
                          TextButton(
                            onPressed: () => _showAlerts(context, provider),
                            child: const Text('See all',
                                style: TextStyle(
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...provider.alerts
                          .take(3)
                          .map((a) => _AlertCard(alert: a))
                          .toList(),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showAlerts(BuildContext ctx, AppProvider provider) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.85,
        minChildSize: 0.35,
        expand: false,
        builder: (_, scroll) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('All Alerts', style: AppTheme.heading1),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: provider.alerts.map((a) => _AlertCard(alert: a)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SustainabilityCard extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _SustainabilityCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final score = (stats['sustainability_score'] ?? 0) as int;
    final col = score >= 80
        ? AppTheme.lightGreen
        : score >= 60
            ? AppTheme.accentAmber
            : AppTheme.errorRed;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.elevatedShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Score circle
          SizedBox(
            width: 88,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(col),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const Text('%',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Right content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sustainability Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  score >= 80
                      ? '🌟 Excellent! Your farm is thriving.'
                      : score >= 60
                          ? '👍 Good job. Keep improving!'
                          : '⚠️ Attention needed.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat('💧 ${stats['water_usage_liters'] ?? 0}L', 'Water Used'),
                    const SizedBox(width: 16),
                    _miniStat('🌿 ${stats['carbon_saved_kg'] ?? 0}kg', 'CO₂ Saved'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.6), fontSize: 11)),
        ],
      );
}

class _StatsGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Total Crops', '${stats['total_crops'] ?? 0}',
            Icons.agriculture, AppTheme.primaryGreen, AppTheme.mintGreen),
        _statCard('Healthy', '${stats['healthy_crops'] ?? 0}',
            Icons.eco_rounded, AppTheme.lightGreen, const Color(0xFFDDF3E4)),
        _statCard('Alerts', '${stats['alerts_count'] ?? 0}',
            Icons.warning_amber_rounded, AppTheme.accentOrange, const Color(0xFFFFEDD5)),
        _statCard('Total Area', '${stats['total_area_hectares'] ?? 0} ha',
            Icons.landscape_rounded, AppTheme.infoBlue, const Color(0xFFDBEDFF)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color iconColor,
      Color bgColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Text(label, style: AppTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final dynamic alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final sev = alert['severity'] ?? 'info';
    final color = sev == 'critical'
        ? AppTheme.errorRed
        : sev == 'warning'
            ? AppTheme.warningOrange
            : AppTheme.infoBlue;
    final bgColor = sev == 'critical'
        ? const Color(0xFFFFF0F0)
        : sev == 'warning'
            ? const Color(0xFFFFF8E8)
            : const Color(0xFFEBF4FF);
    final icon = sev == 'critical'
        ? Icons.error_outline_rounded
        : sev == 'warning'
            ? Icons.warning_amber_rounded
            : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          alert['title'] ?? '',
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(alert['message'] ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary)),
            if (alert['time'] != null) ...[
              const SizedBox(height: 4),
              Text(alert['time'],
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
            ]
          ],
        ),
      ),
    );
  }
}