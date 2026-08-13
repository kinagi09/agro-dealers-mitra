import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_format.dart';
import '../widgets/unsaved_changes_guard.dart';

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

  late final String _initialLicenceNumber;
  late final DateTime? _initialIssueDate;
  late final DateTime? _initialExpiryDate;

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
    _initialLicenceNumber = _licenceNumberController.text.trim();
    _initialIssueDate = _issueDate;
    _initialExpiryDate = _expiryDate;
  }

  bool _hasUnsavedChanges() {
    return _licenceNumberController.text.trim() != _initialLicenceNumber ||
        _issueDate != _initialIssueDate ||
        _expiryDate != _initialExpiryDate;
  }

  Future<void> _pickLicenceDate({required bool isIssueDate}) async {
    FocusScope.of(context).unfocus();
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
    if (mounted) FocusScope.of(context).requestFocus(FocusNode());
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
            'The Date of Issue of Licence field is not filled, please do fill it.',
      );
      return;
    }
    if (_expiryDate == null) {
      setState(
        () => _errorMessage =
            'The Date of Expiry of Licence field is not filled, please do fill it.',
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
          issueDate: toApiDateString(_issueDate!),
          expiryDate: toApiDateString(_expiryDate!),
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
          issueDate: toApiDateString(_issueDate!),
          expiryDate: toApiDateString(_expiryDate!),
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
    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(title: const Text('Update Seed Licence')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.grass, color: Colors.brown, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Licence Type: ${widget.licenceTypeName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _licenceNumberController,
                decoration: const InputDecoration(hintText: 'Licence Number'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _issueDate == null
                      ? 'Select Date of Issue of Licence'
                      : 'Date of Issue of Licence: ${toDisplayDateString(_issueDate!)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickLicenceDate(isIssueDate: true),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _expiryDate == null
                      ? 'Select Date of Expiry of Licence'
                      : 'Date of Expiry of Licence: ${toDisplayDateString(_expiryDate!)}',
                ),
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
    );
  }
}
