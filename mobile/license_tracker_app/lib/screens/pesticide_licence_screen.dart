import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'update_pesticide_licence_screen.dart';

class PesticideLicenceScreen extends StatefulWidget {
  const PesticideLicenceScreen({super.key});

  @override
  State<PesticideLicenceScreen> createState() => _PesticideLicenceScreenState();
}

class _PesticideLicenceScreenState extends State<PesticideLicenceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _licenceTypes = [];
  Map<int, Map<String, dynamic>> _licencesByType = {};
  Map<int, List<dynamic>> _entriesByType = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const String pesticideCategoryName = 'Pesticide';

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
      final category = categories.firstWhere(
        (c) => c['name'] == pesticideCategoryName,
        orElse: () => null,
      );
      if (category == null) {
        setState(() {
          _errorMessage = 'Pesticide category not found.';
          _isLoading = false;
        });
        return;
      }
      final types = await _apiService.getLicenceTypes(category['id']);
      final licences = await _apiService.getMyLicencesByCategory(category['id']);

      final licencesByType = <int, Map<String, dynamic>>{};
      final entriesByType = <int, List<dynamic>>{};
      for (final l in licences) {
        final licence = l as Map<String, dynamic>;
        licencesByType[licence['licence_type']] = licence;
        entriesByType[licence['licence_type']] = await _apiService.getLicenceEntries(licence['id']);
      }

      setState(() {
        _licenceTypes = types;
        _licencesByType = licencesByType;
        _entriesByType = entriesByType;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load licences. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Widget _infoField(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
      child: Text('$label: $value', style: const TextStyle(fontSize: 15)),
    );
  }

  Future<void> _openUpdateScreen(Map<String, dynamic> type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdatePesticideLicenceScreen(
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
      appBar: AppBar(title: const Text('Pesticide Licence')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: _licenceTypes.map<Widget>((type) {
                    final licence = _licencesByType[type['id']];
                    final entries = _entriesByType[type['id']] ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(type['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            const SizedBox(height: 12),
                            if (licence == null)
                              const Text('Not added yet.', style: TextStyle(fontSize: 15))
                            else ...[
                              _infoField('Licence No', licence['licence_number']),
                              _infoField('Date of Issue', licence['issue_date']),
                              _infoField('Date of Expiry', licence['expiry_date']),
                              const Text('Company Entries', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              if (entries.isEmpty)
                                const Text('No entries added yet.')
                              else
                                ...entries.map((e) => Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Company: ${e['company_name']}'),
                                            Text('PC Validity Date: ${e['valid_upto']}'),
                                          ],
                                        ),
                                      ),
                                    )),
                              const SizedBox(height: 12),
                            ],
                            ElevatedButton(
                              onPressed: () => _openUpdateScreen(type),
                              child: Text(licence == null ? 'Add Licence' : 'Update Licence'),
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
