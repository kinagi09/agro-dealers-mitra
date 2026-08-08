import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'update_fertilizer_licence_screen.dart';

class FertilizerLicenceScreen extends StatefulWidget {
  const FertilizerLicenceScreen({super.key});

  @override
  State<FertilizerLicenceScreen> createState() =>
      _FertilizerLicenceScreenState();
}

class _FertilizerLicenceScreenState extends State<FertilizerLicenceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _licenceTypes = [];
  Map<int, Map<String, dynamic>> _licencesByType = {};
  Map<int, List<dynamic>> _entriesByType = {};
  bool _isLoading = true;
  String? _errorMessage;

  static const String fertilizerCategoryName = 'Fertilizer';

  // Display order: Retail Dealer, District Wholesale Dealer, State Wholesale
  // Dealer - not alphabetical, so sort explicitly rather than relying on the
  // API's default (name) ordering.
  static const List<String> _typeOrderKeywords = [
    'retail',
    'district',
    'state',
  ];

  int _typeSortOrder(String name) {
    final lower = name.toLowerCase();
    final index = _typeOrderKeywords.indexWhere((k) => lower.contains(k));
    return index == -1 ? _typeOrderKeywords.length : index;
  }

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
      final types = await _apiService.getLicenceTypes(category['id']);
      types.sort(
        (a, b) =>
            _typeSortOrder(a['name']).compareTo(_typeSortOrder(b['name'])),
      );
      final licences = await _apiService.getMyLicencesByCategory(
        category['id'],
      );

      final licencesByType = <int, Map<String, dynamic>>{};
      final entriesByType = <int, List<dynamic>>{};
      for (final l in licences) {
        final licence = l as Map<String, dynamic>;
        licencesByType[licence['licence_type']] = licence;
        entriesByType[licence['licence_type']] = await _apiService
            .getLicenceEntries(licence['id']);
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

  // 'Source Type (Company Name)', e.g. 'Retailer (ABC Traders)'. Falls back
  // to just the company name when no source type was recorded.
  String _entryLabel(Map<String, dynamic> entry) {
    final sourceType = entry['source_type'];
    final companyName = entry['company_name'];
    if (sourceType == null || sourceType == '') return companyName;
    return '$sourceType ($companyName)';
  }

  Future<void> _openUpdateScreen(Map<String, dynamic> type) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UpdateFertilizerLicenceScreen(
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

  Future<void> _deleteLicence(
    Map<String, dynamic> licence,
    String typeName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Licence'),
        content: Text(
          'This will permanently delete the $typeName licence and all its entries. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _apiService.deleteLicence(licence['id']);
      _loadLicences();
    } catch (e) {
      setState(
        () =>
            _errorMessage = 'Could not delete this licence. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fertilizer Licence')),
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
                final entries = _entriesByType[type['id']] ?? [];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                type['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (licence != null)
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                                tooltip: 'Delete Licence',
                                onPressed: () =>
                                    _deleteLicence(licence, type['name']),
                              ),
                          ],
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
                          const SizedBox(height: 4),
                          const Text(
                            'Source / Company Entries',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (entries.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text(
                                'No entries added yet.',
                                style: TextStyle(color: Colors.black54),
                              ),
                            )
                          else
                            ...entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_entryLabel(e)),
                                    Text(
                                      'Valid Upto: ${e['valid_upto']}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Divider(height: 16),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
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
