import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_format.dart';
import '../widgets/unsaved_changes_guard.dart';

class SourceEntryDraft {
  int? existingId;
  final TextEditingController sourceTypeController = TextEditingController();
  final TextEditingController companyNameController = TextEditingController();
  final FocusNode sourceTypeFocusNode = FocusNode();
  List<int> fertilizerTypeIds = [];
  DateTime? validUpto;
}

class _EntrySnapshot {
  final String sourceType;
  final String companyName;
  final List<int> fertilizerTypeIds;
  final DateTime? validUpto;

  _EntrySnapshot(
    this.sourceType,
    this.companyName,
    this.fertilizerTypeIds,
    this.validUpto,
  );
}

class UpdateFertilizerLicenceScreen extends StatefulWidget {
  final int licenceTypeId;
  final String licenceTypeName;
  final Map<String, dynamic>? existingLicence;

  const UpdateFertilizerLicenceScreen({
    super.key,
    required this.licenceTypeId,
    required this.licenceTypeName,
    this.existingLicence,
  });

  @override
  State<UpdateFertilizerLicenceScreen> createState() =>
      _UpdateFertilizerLicenceScreenState();
}

class _UpdateFertilizerLicenceScreenState
    extends State<UpdateFertilizerLicenceScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _licenceNumberController =
      TextEditingController();

  List<dynamic> _fertilizerTypeOptions = [];

  DateTime? _issueDate;
  DateTime? _expiryDate;
  int? _existingLicenceId;

  final List<SourceEntryDraft> _sourceEntries = [SourceEntryDraft()];

  String _initialLicenceNumber = '';
  DateTime? _initialIssueDate;
  DateTime? _initialExpiryDate;
  List<_EntrySnapshot> _initialEntries = [];

  bool _isLoadingDropdowns = true;
  bool _isLoading = false;
  String? _errorMessage;
  int? _errorRowIndex;
  String? _errorFieldName;

  @override
  void initState() {
    super.initState();
    _loadDropdownData();
  }

  Future<void> _loadDropdownData() async {
    try {
      final fertilizerTypeOptions = await _apiService.getFertilizerTypes();

      final existing = widget.existingLicence;
      if (existing != null) {
        _existingLicenceId = existing['id'];
        _licenceNumberController.text = existing['licence_number'];
        _issueDate = DateTime.parse(existing['issue_date']);
        _expiryDate = DateTime.parse(existing['expiry_date']);

        final existingEntries = await _apiService.getLicenceEntries(
          _existingLicenceId!,
        );
        if (existingEntries.isNotEmpty) {
          _sourceEntries.clear();
          for (final e in existingEntries) {
            final draft = SourceEntryDraft();
            draft.existingId = e['id'];
            draft.sourceTypeController.text = e['source_type'] ?? '';
            draft.companyNameController.text = e['company_name'] ?? '';
            draft.fertilizerTypeIds = List<int>.from(
              e['fertilizer_type'] ?? [],
            );
            draft.validUpto = DateTime.parse(e['valid_upto']);
            _sourceEntries.add(draft);
          }
        }
      }

      _initialLicenceNumber = _licenceNumberController.text.trim();
      _initialIssueDate = _issueDate;
      _initialExpiryDate = _expiryDate;
      _initialEntries = _sourceEntries.map(_snapshotOf).toList();

      setState(() {
        _fertilizerTypeOptions = fertilizerTypeOptions;
        _isLoadingDropdowns = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not load licence options. Check your connection.';
        _isLoadingDropdowns = false;
      });
    }
  }

  _EntrySnapshot _snapshotOf(SourceEntryDraft entry) {
    return _EntrySnapshot(
      entry.sourceTypeController.text.trim(),
      entry.companyNameController.text.trim(),
      List<int>.from(entry.fertilizerTypeIds)..sort(),
      entry.validUpto,
    );
  }

  bool _entryChanged(SourceEntryDraft current, _EntrySnapshot original) {
    final snapshot = _snapshotOf(current);
    return snapshot.sourceType != original.sourceType ||
        snapshot.companyName != original.companyName ||
        snapshot.validUpto != original.validUpto ||
        !listEquals(snapshot.fertilizerTypeIds, original.fertilizerTypeIds);
  }

  bool _hasUnsavedChanges() {
    if (_licenceNumberController.text.trim() != _initialLicenceNumber) {
      return true;
    }
    if (_issueDate != _initialIssueDate) return true;
    if (_expiryDate != _initialExpiryDate) return true;
    if (_sourceEntries.length != _initialEntries.length) return true;
    for (var i = 0; i < _sourceEntries.length; i++) {
      if (_entryChanged(_sourceEntries[i], _initialEntries[i])) return true;
    }
    return false;
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

  Future<void> _pickValidUpto(SourceEntryDraft entry) async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2015),
      lastDate: DateTime(2035),
    );
    if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    if (picked != null) {
      setState(() => entry.validUpto = picked);
    }
  }

  Future<void> _pickFertilizerTypes(SourceEntryDraft entry) async {
    FocusScope.of(context).unfocus();
    final tempSelected = List<int>.from(entry.fertilizerTypeIds);
    final result = await showDialog<List<int>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Type(s) of Fertilizer'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _fertilizerTypeOptions.map((f) {
                    final id = f['id'] as int;
                    final isChecked = tempSelected.contains(id);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text(f['name']),
                      onChanged: (checked) {
                        setDialogState(() {
                          if (checked == true) {
                            tempSelected.add(id);
                          } else {
                            tempSelected.remove(id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
    // Closing the dialog can hand focus (and the keyboard) right back to
    // whichever field had it before the dialog opened - unfocus again here,
    // after the dialog is gone, not just before it opened.
    if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    if (result != null) {
      setState(() => entry.fertilizerTypeIds = result);
    }
  }

  void _addSourceRow() {
    final newEntry = SourceEntryDraft();
    setState(() => _sourceEntries.add(newEntry));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => newEntry.sourceTypeFocusNode.requestFocus(),
    );
  }

  Future<void> _removeSourceRow(int index) async {
    if (_sourceEntries.length == 1) return;
    FocusScope.of(context).unfocus();
    final entry = _sourceEntries[index];
    if (entry.existingId != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove O-form Entry'),
          content: const Text(
            'This will permanently delete this O-form entry. Continue?',
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
      if (mounted) FocusScope.of(context).requestFocus(FocusNode());
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
    setState(() => _sourceEntries.removeAt(index));
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
    if (_expiryDate == null) {
      setState(
        () => _errorMessage =
            'The Date of Expiry of Licence field is not filled, please do fill it.',
      );
      return;
    }
    for (var i = 0; i < _sourceEntries.length; i++) {
      final entry = _sourceEntries[i];
      if (entry.companyNameController.text.trim().isEmpty) {
        setState(() {
          _errorMessage =
              'O-form Entry ${i + 1}: Source Company Name is not filled, please do fill it.';
          _errorRowIndex = i;
          _errorFieldName = 'companyName';
        });
        return;
      }
      if (entry.fertilizerTypeIds.isEmpty) {
        setState(() {
          _errorMessage =
              'O-form Entry ${i + 1}: At least one Type of Fertilizer must be selected.';
          _errorRowIndex = i;
          _errorFieldName = 'fertilizerType';
        });
        return;
      }
      if (entry.validUpto == null) {
        setState(() {
          _errorMessage =
              'O-form Entry ${i + 1}: Valid Upto date is not filled, please do fill it.';
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
          expiryDate: toApiDateString(_expiryDate!),
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
          expiryDate: toApiDateString(_expiryDate!),
        );
        licenceId = licenceResponse['id'];
      }

      for (final entry in _sourceEntries) {
        if (entry.existingId != null) {
          await _apiService.updateLicenceEntry(
            entryId: entry.existingId!,
            sourceType: entry.sourceTypeController.text.trim(),
            companyName: entry.companyNameController.text.trim(),
            fertilizerType: entry.fertilizerTypeIds,
            validUpto: toApiDateString(entry.validUpto!),
          );
        } else {
          await _apiService.createLicenceEntry(
            licence: licenceId,
            sourceType: entry.sourceTypeController.text.trim(),
            companyName: entry.companyNameController.text.trim(),
            fertilizerType: entry.fertilizerTypeIds,
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
        appBar: AppBar(title: const Text('Update Fertilizer Licence')),
        body: _isLoadingDropdowns
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.eco, color: AppColors.green, size: 20),
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
                    const Text(
                      'O-form Entries',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._sourceEntries.asMap().entries.map((mapEntry) {
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
                                    'O-form Entry ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_sourceEntries.length > 1)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () => _removeSourceRow(index),
                                    ),
                                ],
                              ),
                              TextField(
                                controller: entry.sourceTypeController,
                                focusNode: entry.sourceTypeFocusNode,
                                decoration: const InputDecoration(
                                  hintText: 'Source Type',
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: entry.companyNameController,
                                decoration: InputDecoration(
                                  labelText: 'Source Company Name',
                                  border: _fieldBorder(index, 'companyName'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () => _pickFertilizerTypes(entry),
                                child: InputDecorator(
                                  isEmpty: entry.fertilizerTypeIds.isEmpty,
                                  decoration: InputDecoration(
                                    labelText: 'Type(s) of Fertilizer',
                                    border: _fieldBorder(
                                      index,
                                      'fertilizerType',
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: entry.fertilizerTypeIds.isEmpty
                                        ? const []
                                        : entry.fertilizerTypeIds.map((id) {
                                            final match = _fertilizerTypeOptions
                                                .firstWhere(
                                                  (f) => f['id'] == id,
                                                );
                                            return Chip(
                                              label: Text(match['name']),
                                            );
                                          }).toList(),
                                  ),
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
                                        ? 'Select Valid Upto'
                                        : 'Valid Upto: ${toDisplayDateString(entry.validUpto!)}',
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
                      onPressed: _addSourceRow,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Another O-form Entry'),
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
                          : const Text('Save Fertilizer Licence'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
