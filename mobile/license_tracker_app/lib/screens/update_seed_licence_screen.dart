import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/wave_header.dart';

class UpdateSeedLicenceScreen extends StatefulWidget {
  final int licenceTypeId;
  final String licenceTypeName;
  final Map<String, dynamic>? existingLicence;

  const UpdateSeedLicenceScreen({
    super.key,
    required this.licenceTypeId,
    required this.licenceTypeName,
    this.existingLicence,
  });

  @override
  State<UpdateSeedLicenceScreen> createState() =>
      _UpdateSeedLicenceScreenState();
}

class _UpdateSeedLicenceScreenState extends State<UpdateSeedLicenceScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _licenceNumberController =
      TextEditingController();

  DateTime? _issueDate;
  DateTime? _expiryDate;
  int? _existingLicenceId;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingLicence;
    if (existing != null) {
      _existingLicenceId = existing['id'];
      _licenceNumberController.text = existing['licence_number'];
      _issueDate = DateTime.parse(existing['issue_date']);
      _expiryDate = DateTime.parse(existing['expiry_date']);
    }
  }

  Future<void> _pickLicenceDate({required bool isIssueDate}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? now
          : (_issueDate?.add(const Duration(days: 1)) ??
                today.add(const Duration(days: 1))),
      firstDate: isIssueDate
          ? DateTime(2015)
          : (_issueDate?.add(const Duration(days: 1)) ??
                today.add(const Duration(days: 1))),
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
    if (_licenceNumberController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'The Licence Number field is not filled, please do fill it.',
      );
      return;
    }
    if (_issueDate == null) {
      setState(
        () => _errorMessage =
            'The Date of Issue field is not filled, please do fill it.',
      );
      return;
    }
    if (_expiryDate == null) {
      setState(
        () => _errorMessage =
            'The Date of Expiry field is not filled, please do fill it.',
      );
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
          licenceType: widget.licenceTypeId,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: _formatDate(_issueDate!),
          expiryDate: _formatDate(_expiryDate!),
        );
      } else {
        final dealerId = await _apiService.getDealerId();
        if (dealerId == null) {
          setState(
            () => _errorMessage =
                'Could not find your dealer account. Please log in again.',
          );
          return;
        }
        await _apiService.createLicence(
          dealer: dealerId,
          licenceType: widget.licenceTypeId,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: _formatDate(_issueDate!),
          expiryDate: _formatDate(_expiryDate!),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      setState(
        () => _errorMessage = e is ApiException
            ? e.errorData.toString()
            : 'Failed to save licence. Please check your details and try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WaveHeaderBar(
            title: 'Update Seed Licence',
            leading: WaveHeaderIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.grass, color: Colors.brown),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Licence Type: ${widget.licenceTypeName}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _licenceNumberController,
                    decoration: const InputDecoration(
                      hintText: 'Licence Number',
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _issueDate == null
                          ? 'Date of Issue of Licence'
                          : 'Date of Issue: ${_formatDate(_issueDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickLicenceDate(isIssueDate: true),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    tileColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    title: Text(
                      _expiryDate == null
                          ? 'Date of expiry Licence'
                          : 'Date of Expiry: ${_formatDate(_expiryDate!)}',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () => _pickLicenceDate(isIssueDate: false),
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Licence'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
