import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_format.dart';
import '../widgets/unsaved_changes_guard.dart';

class PesticideEntryDraft {
  int? existingId;
  final TextEditingController companyNameController = TextEditingController();
  final FocusNode companyNameFocusNode = FocusNode();
  DateTime? validUpto;
}

class _EntrySnapshot {
  final String companyName;
  final DateTime? validUpto;

  _EntrySnapshot(this.companyName, this.validUpto);
}

class UpdatePesticideLicenceScreen extends StatefulWidget {
  final int licenceTypeId;
  final String licenceTypeName;
  final Map<String, dynamic>? existingLicence;

  const UpdatePesticideLicenceScreen({
    super.key,
    required this.licenceTypeId,
    required this.licenceTypeName,
    this.existingLicence,
  });

  @override
  State<UpdatePesticideLicenceScreen> createState() =>
      _UpdatePesticideLicenceScreenState();
}

class _UpdatePesticideLicenceScreenState
    extends State<UpdatePesticideLicenceScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _licenceNumberController =
      TextEditingController();

  DateTime? _issueDate;
  int? _existingLicenceId;

  final List<PesticideEntryDraft> _entries = [PesticideEntryDraft()];

  String _initialLicenceNumber = '';
  DateTime? _initialIssueDate;
  List<_EntrySnapshot> _initialEntries = [];

  bool _isLoadingDropdowns = true;
  bool _isLoading = false;
  String? _errorMessage;
  int? _errorRowIndex;
  String? _errorFieldName;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    try {
      final existing = widget.existingLicence;
      if (existing != null) {
        _existingLicenceId = existing['id'];
        _licenceNumberController.text = existing['licence_number'];
        _issueDate = DateTime.parse(existing['issue_date']);

        final existingEntries = await _apiService.getLicenceEntries(
          _existingLicenceId!,
        );
        if (existingEntries.isNotEmpty) {
          _entries.clear();
          for (final e in existingEntries) {
            final draft = PesticideEntryDraft();
            draft.existingId = e['id'];
            draft.companyNameController.text = e['company_name'] ?? '';
            draft.validUpto = DateTime.parse(e['valid_upto']);
            _entries.add(draft);
          }
        }
      }

      _initialLicenceNumber = _licenceNumberController.text.trim();
      _initialIssueDate = _issueDate;
      _initialEntries = _entries.map(_snapshotOf).toList();

      setState(() => _isLoadingDropdowns = false);
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not load licence options. Check your connection.';
        _isLoadingDropdowns = false;
      });
    }
  }

  _EntrySnapshot _snapshotOf(PesticideEntryDraft entry) {
    return _EntrySnapshot(
      entry.companyNameController.text.trim(),
      entry.validUpto,
    );
  }

  bool _entryChanged(PesticideEntryDraft current, _EntrySnapshot original) {
    final snapshot = _snapshotOf(current);
    return snapshot.companyName != original.companyName ||
        snapshot.validUpto != original.validUpto;
  }

  bool _hasUnsavedChanges() {
    if (_licenceNumberController.text.trim() != _initialLicenceNumber) {
      return true;
    }
    if (_issueDate != _initialIssueDate) return true;
    if (_entries.length != _initialEntries.length) return true;
    for (var i = 0; i < _entries.length; i++) {
      if (_entryChanged(_entries[i], _initialEntries[i])) return true;
    }
    return false;
  }

  Future<void> _pickIssueDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2015),
      lastDate: now,
    );
    if (mounted) FocusScope.of(context).unfocus();
    if (picked != null) {
      setState(() => _issueDate = picked);
    }
  }

  Future<void> _pickValidUpto(PesticideEntryDraft entry) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );
    if (mounted) FocusScope.of(context).unfocus();
    if (picked != null) {
      setState(() => entry.validUpto = picked);
    }
  }

  void _addRow() {
    final newEntry = PesticideEntryDraft();
    setState(() => _entries.add(newEntry));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => newEntry.companyNameFocusNode.requestFocus(),
    );
  }

  Future<void> _removeRow(int index) async {
    if (_entries.length == 1) return;
    FocusScope.of(context).unfocus();
    final entry = _entries[index];
    if (entry.existingId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove Entry'),
          content: const Text(
            'This will permanently delete this company entry. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await _apiService.deleteLicenceEntry(entry.existingId!);
      } catch (e) {
        setState(
          () =>
              _errorMessage = 'Could not remove this entry. Please try again.',
        );
        return;
      }
    }
    setState(() => _entries.removeAt(index));
  }

  OutlineInputBorder _fieldBorder(int index, String fieldName) {
    final isError = _errorRowIndex == index && _errorFieldName == fieldName;
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: isError
          ? const BorderSide(color: Colors.red, width: 2)
          : BorderSide.none,
    );
  }

  Future<void> _submit() async {
    setState(() {
      _errorRowIndex = null;
      _errorFieldName = null;
    });

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
    for (var i = 0; i < _entries.length; i++) {
      final entry = _entries[i];
      if (entry.companyNameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage =
              'Entry ${i + 1}: Name of Company is not filled, please do fill it.';
          _errorRowIndex = i;
          _errorFieldName = 'companyName';
        });
        return;
      }
      if (entry.validUpto == null) {
        setState(() {
          _errorMessage =
              'Entry ${i + 1}: PC Validity Date is not filled, please do fill it.';
          _errorRowIndex = i;
          _errorFieldName = 'validUpto';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      int licenceId;
      if (_existingLicenceId != null) {
        await _apiService.updateLicence(
          licenceId: _existingLicenceId!,
          licenceType: widget.licenceTypeId,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: toApiDateString(_issueDate!),
        );
        licenceId = _existingLicenceId!;
      } else {
        final dealerId = await _apiService.getDealerId();
        if (dealerId == null) {
          setState(
            () => _errorMessage =
                'Could not find your dealer account. Please log in again.',
          );
          return;
        }
        final licenceResponse = await _apiService.createLicence(
          dealer: dealerId,
          licenceType: widget.licenceTypeId,
          licenceNumber: _licenceNumberController.text.trim(),
          issueDate: toApiDateString(_issueDate!),
        );
        licenceId = licenceResponse['id'];
      }

      for (final entry in _entries) {
        if (entry.existingId != null) {
          await _apiService.updateLicenceEntry(
            entryId: entry.existingId!,
            companyName: entry.companyNameController.text.trim(),
            validUpto: toApiDateString(entry.validUpto!),
          );
        } else {
          await _apiService.createLicenceEntry(
            licence: licenceId,
            companyName: entry.companyNameController.text.trim(),
            validUpto: toApiDateString(entry.validUpto!),
          );
        }
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
        appBar: AppBar(title: const Text('Update Pesticide Licence')),
        body: _isLoadingDropdowns
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.bug_report,
                          color: Colors.deepOrange,
                          size: 20,
                        ),
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
                      decoration: const InputDecoration(
                        hintText: 'Licence Number',
                      ),
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
                      onTap: _pickIssueDate,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Company Entries',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._entries.asMap().entries.map((mapEntry) {
                      final index = mapEntry.key;
                      final entry = mapEntry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Entry ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_entries.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeRow(index),
                                    ),
                                ],
                              ),
                              TextField(
                                controller: entry.companyNameController,
                                focusNode: entry.companyNameFocusNode,
                                decoration: InputDecoration(
                                  labelText: 'Name of Company',
                                  border: _fieldBorder(index, 'companyName'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                decoration: BoxDecoration(
                                  border:
                                      (_errorRowIndex == index &&
                                          _errorFieldName == 'validUpto')
                                      ? Border.all(color: Colors.red, width: 2)
                                      : null,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    entry.validUpto == null
                                        ? 'Select PC Validity Date'
                                        : 'PC Validity Date: ${toDisplayDateString(entry.validUpto!)}',
                                  ),
                                  trailing: const Icon(Icons.calendar_today),
                                  onTap: () => _pickValidUpto(entry),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    OutlinedButton.icon(
                      onPressed: _addRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another Company'),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null) ...[
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Pesticide Licence'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
