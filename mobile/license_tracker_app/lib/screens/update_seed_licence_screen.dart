import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UpdateSeedLicenceScreen extends StatefulWidget {
  const UpdateSeedLicenceScreen({super.key});

  @override
  State<UpdateSeedLicenceScreen> createState() => _UpdateSeedLicenceScreenState();
}

class _UpdateSeedLicenceScreenState extends State<UpdateSeedLicenceScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _licenceNumberController = TextEditingController();

  List<dynamic> _seedLicenceTypes = [];
  int? _selectedTypeId;
  DateTime? _issueDate;
  DateTime? _expiryDate;
  int? _existingLicenceId;

  bool _isLoadingDropdowns = true;
  bool _isLoading = false;
  String? _errorMessage;

  static const String seedCategoryName = 'Seed';
  int? _seedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final categories = await _apiService.getLicenceCategories();
      final seedCategory = categories.firstWhere(
        (c) => c['name'] == seedCategoryName,
        orElse: () => null,
      );
      if (seedCategory == null) {
        setState(() {
          _errorMessage = 'Seed category not found. Please contact support.';
          _isLoadingDropdowns = false;
        });
        return;
      }
      _seedCategoryId = seedCategory['id'];

      final types = await _apiService.getLicenceTypes(_seedCategoryId!);
      final existingLicences = await _apiService.getMyLicencesByCategory(_seedCategoryId!);

      if (existingLicences.isNotEmpty) {
        final existing = existingLicences.first as Map<String, dynamic>;
        _existingLicenceId = existing['id'];
        _selectedTypeId = existing['licence_type'];
        _licenceNumberController.text = existing['licence_number'];
        _issueDate = DateTime.parse(existing['issue_date']);
        _expiryDate = DateTime.parse(existing['expiry_date']);
      }

      setState(() {
        _seedLicenceTypes = types;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load licence options. Check your connection.';
        _isLoadingDropdowns = false;
      });
    }
  }

  Future<void> _pickLicenceDate({required bool isIssueDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate ? now : (_issueDate?.add(const Duration(days: 1)) ?? today.add(const Duration(days: 1))),
      firstDate: isIssueDate ? DateTime(2015) : (_issueDate?.add(const Duration(days: 1)) ?? today.add(const Duration(days: 1))),
      lastDate: isIssueDate ? now : DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          if (_expiryDate != null && !_expiryDate!.isAfter(picked)) {
            _expiryDate = null;
          }
        } else {
          _expiryDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_selectedTypeId == null) {
      setState(() => _errorMessage = 'The Licence Type field is not filled, please do fill it.');
      return;
    }
    if (_licenceNumberController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'The Licence Number field is not filled, please do fill it.');
      return;
    }
    if (_issueDate == null) {
      setState(() => _errorMessage = 'The Date of Issue field is not filled, please do fill it.');
      return;
    }
    if (_expiryDate == null) {
      setState(() => _errorMessage = 'The Date of Expiry field is not filled, please do fill it.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_existingLicenceId != null) {
        await _apiService.updateLicence(
          licenceId: _existingLicenceId!,
          licenceType: _selectedTypeId!,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: _formatDate(_issueDate!),
          expiryDate: _formatDate(_expiryDate!),
        );
      } else {
        final dealerId = await _apiService.getDealerId();
        if (dealerId == null) {
          setState(() => _errorMessage = 'Could not find your dealer account. Please log in again.');
          return;
        }
        await _apiService.createLicence(
          dealer: dealerId,
          licenceType: _selectedTypeId!,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: _formatDate(_issueDate!),
          expiryDate: _formatDate(_expiryDate!),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _errorMessage = e is ApiException
          ? e.errorData.toString()
          : 'Failed to save licence. Please check your details and try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Seed Licence')),
      body: _isLoadingDropdowns
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedTypeId,
                      decoration: const InputDecoration(labelText: 'Type of Licence', border: OutlineInputBorder()),
                      items: _seedLicenceTypes
                          .map<DropdownMenuItem<int>>((t) => DropdownMenuItem(value: t['id'], child: Text(t['name'])))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedTypeId = value),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _licenceNumberController,
                    decoration: const InputDecoration(labelText: 'Licence Number', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_issueDate == null ? 'Date of Issue of Licence' : 'Date of Issue: ${_formatDate(_issueDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickLicenceDate(isIssueDate: true),
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_expiryDate == null ? 'Date of expiry Licence' : 'Date of Expiry: ${_formatDate(_expiryDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickLicenceDate(isIssueDate: false),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Update Licence'),
                  ),
                ],
              ),
            ),
    );
  }
}