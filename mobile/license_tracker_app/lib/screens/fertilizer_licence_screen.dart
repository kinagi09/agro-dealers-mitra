import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'update_fertilizer_licence_screen.dart';

class FertilizerLicenceScreen extends StatefulWidget {
  const FertilizerLicenceScreen({super.key});

  @override
  State<FertilizerLicenceScreen> createState() => _FertilizerLicenceScreenState();
}

class _FertilizerLicenceScreenState extends State<FertilizerLicenceScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _licence;
  List<dynamic> _entries = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const String fertilizerCategoryName = 'Fertilizer';

  @override
  void initState() {
    super.initState();
    _loadLicence();
  }

  Future<void> _loadLicence() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final categories = await _apiService.getLicenceCategories();
      final category = categories.firstWhere(
        (c) => c['name'] == fertilizerCategoryName,
        orElse: () => null,
      );
      if (category == null) {
        setState(() {
          _errorMessage = 'Fertilizer category not found.';
          _isLoading = false;
        });
        return;
      }
      final licences = await _apiService.getMyLicencesByCategory(category['id']);
      if (licences.isEmpty) {
        setState(() {
          _licence = null;
          _isLoading = false;
        });
        return;
      }
      final licence = licences.first as Map<String, dynamic>;
      final entries = await _apiService.getLicenceEntries(licence['id']);
      setState(() {
        _licence = licence;
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load licence. Check your connection.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fertilizer Licence')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                  else if (_licence == null)
                    const Text('No Fertilizer Licence added yet.', style: TextStyle(fontSize: 16))
                  else ...[
                    _infoField('Licence No', _licence!['licence_number']),
                    _infoField('Date of Issue', _licence!['issue_date']),
                    _infoField('Date of Expiry', _licence!['expiry_date']),
                    const SizedBox(height: 16),
                    const Text('Source / Company Entries', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    if (_entries.isEmpty)
                      const Text('No entries added yet.')
                    else
                      ..._entries.map((e) => Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Company: ${e['company_name']}'),
                                  Text('Source Type: ${e['source_type'] ?? '-'}'),
                                  Text('Valid Upto: ${e['valid_upto']}'),
                                ],
                              ),
                            ),
                          )),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpdateFertilizerLicenceScreen()),
            );
            if (result == true) {
              _loadLicence();
            }
          },
          child: const Text('Add or Update Licence'),
        ),
      ),
    );
  }
}