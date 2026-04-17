import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class CropsScreen extends StatefulWidget {
  const CropsScreen({Key? key}) : super(key: key);

  @override
  State<CropsScreen> createState() => _CropsScreenState();
}

class _CropsScreenState extends State<CropsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  final List<String> _categories = ['All', 'Cereal', 'Vegetable', 'Root Crop'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    Future.microtask(() {
      final p = context.read<AppProvider>();
      if (p.crops.isEmpty) p.fetchCrops();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filtered(List<dynamic> crops, String category) {
    return crops.where((c) {
      final matchCat = category == 'All' || c['type'] == category;
      final matchSearch = _searchQuery.isEmpty ||
          c['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: AppTheme.primaryGreen,
            elevation: 0,
            // Shown when the bar is fully collapsed (scrolled up)
            title: const Text(
              'Crop Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            // Hide title when expanded (flexibleSpace shows it)
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Container(
                decoration: const BoxDecoration(
                    gradient: AppTheme.heroGradient),
                child: SafeArea(
                  child: Padding(
                    // Top padding gives room for the status bar + action row;
                    // bottom padding keeps text well above the TabBar.
                    padding:
                        const EdgeInsets.fromLTRB(20, 56, 20, 56),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Crop Monitor',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${provider.crops.length} crops tracked across your farm',
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
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                tooltip: 'Add crop',
                onPressed: () => _showAddCropSheet(context),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.15),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13),
                  tabs:
                      _categories.map((c) => Tab(text: c)).toList(),
                ),
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search crops...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textMuted),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: AppTheme.buttonRadius,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _categories.map((cat) {
                  final list = _filtered(provider.crops, cat);
                  if (provider.crops.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGreen));
                  }
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No crops found',
                          style: TextStyle(color: AppTheme.textMuted)),
                    );
                  }
                  return RefreshIndicator(
                    color: AppTheme.primaryGreen,
                    onRefresh: () => provider.fetchCrops(),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _CropCard(crop: list[i]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCropSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text('Add New Crop', style: AppTheme.heading1),
            const SizedBox(height: 4),
            const Text(
              'Track a new crop across your farm zones.',
              style: AppTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _AddCropForm(onClose: () => Navigator.pop(context)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _CropCard extends StatelessWidget {
  final dynamic crop;
  const _CropCard({required this.crop});

  Color _healthColor(String status) {
    switch (status.toLowerCase()) {
      case 'excellent': return AppTheme.lightGreen;
      case 'good': return AppTheme.primaryGreen;
      case 'fair': return AppTheme.accentOrange;
      default: return AppTheme.errorRed;
    }
  }

  Color _healthBg(String status) {
    switch (status.toLowerCase()) {
      case 'excellent': return const Color(0xFFE3F9EC);
      case 'good': return const Color(0xFFDDF3E4);
      case 'fair': return const Color(0xFFFFF3DC);
      default: return const Color(0xFFFFEBEB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final health = crop['health_status'] ?? 'good';
    final pct = (crop['health_percentage'] ?? 0) as int;
    final col = _healthColor(health);
    final bg = _healthBg(health);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.cardRadius,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Top section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.mintGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco_rounded,
                          color: AppTheme.primaryGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(crop['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary)),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              _tag(crop['type'] ?? ''),
                              const SizedBox(width: 6),
                              if (crop['zone'] != null) _tag(crop['zone']),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        health.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: col,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Health progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Health',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: col)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey[100],
                    valueColor: AlwaysStoppedAnimation<Color>(col),
                  ),
                ),
              ],
            ),
          ),

          // Bottom details
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _detailChip(Icons.landscape_outlined,
                    '${crop['area_hectares']} ha'),
                const SizedBox(width: 12),
                _detailChip(Icons.calendar_today_outlined,
                    'Harvest: ${crop['expected_harvest'] ?? '—'}'),
                if (crop['growth_stage'] != null) ...[
                  const SizedBox(width: 12),
                  _detailChip(
                      Icons.trending_up, crop['growth_stage']),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tag(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.mintGreen.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600)),
      );

  Widget _detailChip(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
        ],
      );
}

// ── Add Crop Form ─────────────────────────────────────────────────────────────

class _AddCropForm extends StatefulWidget {
  final VoidCallback onClose;
  const _AddCropForm({required this.onClose});

  @override
  State<_AddCropForm> createState() => _AddCropFormState();
}

class _AddCropFormState extends State<_AddCropForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _type = 'Cereal';
  String _zone = 'Zone A';
  String _waterNeed = 'Medium';
  bool _saving = false;

  final _types = ['Cereal', 'Vegetable', 'Root Crop', 'Fruit', 'Legume'];
  final _zones = ['Zone A', 'Zone B', 'Zone C', 'Zone D', 'Zone E'];
  final _waterNeeds = ['Low', 'Medium', 'High'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _areaCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final harvestDate = DateTime(now.year, now.month + 4, now.day);
    final crop = {
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'zone': _zone,
      'area_hectares': double.tryParse(_areaCtrl.text.trim()) ?? 1.0,
      'water_need': _waterNeed,
      'health_status': 'good',
      'health_percentage': 80,
      'planted_date':
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      'expected_harvest':
          '${harvestDate.year}-${harvestDate.month.toString().padLeft(2, '0')}-${harvestDate.day.toString().padLeft(2, '0')}',
      'growth_stage': 'Seedling',
      'notes': _notesCtrl.text.trim(),
    };

    await context.read<AppProvider>().addCrop(crop);
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Crop Name
          _label('Crop Name'),
          const SizedBox(height: 5),
          TextFormField(
            controller: _nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: _inputDec('e.g. Jasmine Rice', Icons.eco_outlined),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Crop name is required' : null,
          ),
          const SizedBox(height: 12),

          // Type + Zone row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Crop Type'),
                    const SizedBox(height: 5),
                    _dropdown(
                      value: _type,
                      items: _types,
                      icon: Icons.category_outlined,
                      onChanged: (v) => setState(() => _type = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Farm Zone'),
                    const SizedBox(height: 5),
                    _dropdown(
                      value: _zone,
                      items: _zones,
                      icon: Icons.map_outlined,
                      onChanged: (v) => setState(() => _zone = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Area + Water row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Area (hectares)'),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _areaCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      decoration:
                          _inputDec('e.g. 2.5', Icons.landscape_outlined),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Water Need'),
                    const SizedBox(height: 5),
                    _dropdown(
                      value: _waterNeed,
                      items: _waterNeeds,
                      icon: Icons.water_drop_outlined,
                      onChanged: (v) => setState(() => _waterNeed = v!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Notes
          _label('Notes (optional)'),
          const SizedBox(height: 5),
          TextFormField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration:
                _inputDec('Any observations...', Icons.notes_outlined),
          ),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check, size: 18),
              label: Text(_saving ? 'Saving...' : 'Add Crop',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary),
      );

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 18),
        filled: true,
        fillColor: AppTheme.backgroundLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
      );

  Widget _dropdown({
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) =>
      DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        decoration: _inputDec('', icon),
        style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      );
}