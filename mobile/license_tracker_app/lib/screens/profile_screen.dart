import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _profile;
  List<String> _categoryOrder = [];
  Map<String, List<String>> _addedTypesByCategory = {};

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _apiService.getMyDealerProfile();
      final categories = await _apiService.getLicenceCategories();
      final myLicences = await _apiService.getMyLicences();

      final categoryNameById = <int, String>{
        for (final c in categories) c['id'] as int: c['name'] as String,
      };

      final categoryIdByTypeId = <int, int>{};
      final typeNameById = <int, String>{};
      for (final c in categories) {
        final types = await _apiService.getLicenceTypes(c['id']);
        for (final t in types) {
          categoryIdByTypeId[t['id'] as int] = c['id'] as int;
          typeNameById[t['id'] as int] = t['name'] as String;
        }
      }

      final addedTypesByCategory = <String, List<String>>{};
      for (final l in myLicences) {
        final typeId = l['licence_type'] as int?;
        final catId = typeId == null ? null : categoryIdByTypeId[typeId];
        if (catId == null) continue;
        final catName = categoryNameById[catId] ?? 'Other';
        final typeName =
            typeNameById[typeId] ?? l['licence_type_name'] ?? 'Unknown';
        addedTypesByCategory.putIfAbsent(catName, () => []).add(typeName);
      }

      setState(() {
        _profile = profile;
        _categoryOrder = categories.map((c) => c['name'] as String).toList();
        _addedTypesByCategory = addedTypesByCategory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load profile. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Widget _detailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              (value == null || value.isEmpty) ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Registration Details',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _detailRow('Firm Name', _profile?['shop_name']),
                          _detailRow('Person Name', _profile?['name']),
                          _detailRow(
                            'WhatsApp Number',
                            _profile?['whatsapp_number'],
                          ),
                          _detailRow('Address', _profile?['address']),
                          _detailRow('Taluka', _profile?['taluka_name']),
                          _detailRow('District', _profile?['district_name']),
                          _detailRow('State', _profile?['state_name']),
                          if (_profile?['created_at'] != null)
                            _detailRow(
                              'Member Since',
                              isoToDisplayDateString(_profile!['created_at']),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Licences Added',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ..._categoryOrder.map((categoryName) {
                    final types = _addedTypesByCategory[categoryName] ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  types.isEmpty
                                      ? Icons.remove_circle_outline
                                      : Icons.check_circle,
                                  color: types.isEmpty
                                      ? Colors.black38
                                      : AppColors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (types.isEmpty)
                              const Text(
                                'No licence added yet.',
                                style: TextStyle(color: Colors.black54),
                              )
                            else
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: types
                                    .map(
                                      (t) => Chip(
                                        label: Text(t),
                                        backgroundColor: AppColors.yellow
                                            .withValues(alpha: 0.25),
                                        side: BorderSide.none,
                                      ),
                                    )
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
