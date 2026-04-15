import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({Key? key}) : super(key: key);

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AppProvider>().fetchCrops());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Monitor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          if (provider.crops.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.fetchCrops(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.crops.length,
              itemBuilder: (context, index) {
                final crop = provider.crops[index];
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
                            Expanded(
                              child: Text(
                                crop['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Chip(
                              label: Text(crop['health_status'].toUpperCase()),
                              backgroundColor: _getHealthColor(crop['health_status']),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.category, size: 16),
                            const SizedBox(width: 8),
                            Text('Type: ${crop['type']}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.landscape, size: 16),
                            const SizedBox(width: 8),
                            Text('Area: ${crop['area_hectares']} hectares'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text('Planted: ${crop['planted_date']}'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.event, size: 16),
                            const SizedBox(width: 8),
                            Text('Expected Harvest: ${crop['expected_harvest']}'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Health:'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: crop['health_percentage'] / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getHealthColor(crop['health_status']),
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${crop['health_percentage']}%',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (crop['notes'] != null && crop['notes'].isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            'Notes: ${crop['notes']}',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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

  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}