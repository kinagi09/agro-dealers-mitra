import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'update_seed_licence_screen.dart';

class SeedLicenceScreen extends StatefulWidget {
  const SeedLicenceScreen({super.key});

  @override
  State<SeedLicenceScreen> createState() => _SeedLicenceScreenState();
}

class _SeedLicenceScreenState extends State<SeedLicenceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _licenceTypes = [];
  Map<int, Map<String, dynamic>> _licencesByType = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const String seedCategoryName = 'Seed';

  @override
  void initState() {
    super.initState();
    _loadLicences();
  }

  Future<void> _loadLicences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _apiService.getLicenceCategories();
      final seedCategory = categories.firstWhere(
        (c) => c['name'] == seedCategoryName,
        orElse: () => null,
      );
      if (seedCategory == null) {
        setState(() {
          _errorMessage = 'Seed category not found.';
          _isLoading = false;
        });
        return;
      }
      final types = await _apiService.getLicenceTypes(seedCategory['id']);
      final licences = await _apiService.getMyLicencesByCategory(
        seedCategory['id'],
      );

      final licencesByType = <int, Map<String, dynamic>>{};
      for (final l in licences) {
        final licence = l as Map<String, dynamic>;
        licencesByType[licence['licence_type']] = licence;
      }

      setState(() {
        _licenceTypes = types;
        _licencesByType = licencesByType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load licences. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.black54)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openUpdateScreen(Map<String, dynamic> type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateSeedLicenceScreen(
          licenceTypeId: type['id'],
          licenceTypeName: type['name'],
          existingLicence: _licencesByType[type['id']],
        ),
      ),
    );
    if (result == true) {
      _loadLicences();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Licence')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: _licenceTypes.map<Widget>((type) {
                final licence = _licencesByType[type['id']];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          type['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (licence == null)
                          const Text(
                            'Not added yet.',
                            style: TextStyle(color: Colors.black54),
                          )
                        else ...[
                          _infoRow('Licence No', licence['licence_number']),
                          _infoRow('Date of Issue', licence['issue_date']),
                          _infoRow('Date of Expiry', licence['expiry_date']),
                        ],
                        const SizedBox(height: 4),
                        ElevatedButton(
                          onPressed: () => _openUpdateScreen(type),
                          child: Text(
                            licence == null ? 'Add Licence' : 'Update Licence',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
    );
  }
}
