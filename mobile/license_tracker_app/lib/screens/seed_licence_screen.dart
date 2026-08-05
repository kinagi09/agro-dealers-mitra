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
  Map<String, dynamic>? _licence;
  bool _isLoading = true;
  String? _errorMessage;

  static const String seedCategoryName = 'Seed';

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
      final licences = await _apiService.getMyLicencesByCategory(seedCategory['id']);
      setState(() {
        _licence = licences.isNotEmpty ? licences.first as Map<String, dynamic> : null;
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seed Licence')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_errorMessage != null)
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                  else if (_licence == null)
                    const Text('No Seed Licence added yet.', style: TextStyle(fontSize: 16))
                  else ...[
                    _infoField('Licence No', _licence!['licence_number']),
                    _infoField('Date of Issue', _licence!['issue_date']),
                    _infoField('Date of Expiry', _licence!['expiry_date']),
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
              MaterialPageRoute(builder: (_) => const UpdateSeedLicenceScreen()),
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