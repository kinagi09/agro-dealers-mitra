import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/otp_input.dart';
import '../widgets/resend_otp_button.dart';
import '../widgets/unsaved_changes_guard.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final ApiService _apiService = ApiService();

  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();

  bool _otpSent = false;
  bool _otpVerified = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _otpFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  List<dynamic> _states = [];
  List<dynamic> _districts = [];
  List<dynamic> _talukas = [];

  int? _selectedStateId;
  int? _selectedDistrictId;
  int? _selectedTalukaId;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    try {
      final states = await _apiService.getStates();
      setState(() => _states = states);
    } catch (e) {
      setState(
        () => _errorMessage = 'Could not load states. Check your connection.',
      );
    }
  }

  Future<void> _onStateSelected(int? stateId) async {
    setState(() {
      _selectedStateId = stateId;
      _selectedDistrictId = null;
      _selectedTalukaId = null;
      _districts = [];
      _talukas = [];
    });
    if (stateId != null) {
      final districts = await _apiService.getDistricts(stateId);
      setState(() => _districts = districts);
    }
  }

  Future<void> _onDistrictSelected(int? districtId) async {
    setState(() {
      _selectedDistrictId = districtId;
      _selectedTalukaId = null;
      _talukas = [];
    });
    if (districtId != null) {
      final talukas = await _apiService.getTalukas(districtId);
      setState(() => _talukas = talukas);
    }
  }

  Future<void> _sendOtp() async {
    final number = _whatsappController.text.trim();
    if (number.isEmpty) {
      setState(
        () => _errorMessage = 'Please enter your WhatsApp number first.',
      );
      return;
    }
    if (number.length != 10) {
      setState(
        () => _errorMessage = 'Please enter a valid 10-digit WhatsApp number.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.sendOtp(number, purpose: 'register');
      setState(() => _otpSent = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _otpFocusNode.requestFocus(),
      );
    } catch (e) {
      setState(
        () => _errorMessage = e is ApiException
            ? (e.errorData['detail'] ?? 'Failed to send OTP.').toString()
            : 'Failed to send OTP. Check the number and try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    _otpController.clear();
    await _sendOtp();
  }

  Future<void> _verifyOtp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.verifyOtp(
        _whatsappController.text.trim(),
        _otpController.text.trim(),
      );
      setState(() => _otpVerified = true);
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _nameFocusNode.requestFocus(),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Invalid or expired OTP. Try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (_nameController.text.trim().isEmpty) {
      setState(
        () =>
            _errorMessage = 'The Name field is not filled, please do fill it.',
      );
      return;
    }
    if (_shopNameController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'The Shop Name field is not filled, please do fill it.',
      );
      return;
    }
    if (_addressController.text.trim().isEmpty) {
      setState(
        () => _errorMessage =
            'The Address field is not filled, please do fill it.',
      );
      return;
    }
    if (_selectedStateId == null) {
      setState(
        () =>
            _errorMessage = 'The State field is not filled, please do fill it.',
      );
      return;
    }
    if (_selectedDistrictId == null) {
      setState(
        () => _errorMessage =
            'The District field is not filled, please do fill it.',
      );
      return;
    }
    if (_selectedTalukaId == null) {
      setState(
        () => _errorMessage =
            'The Taluka field is not filled, please do fill it.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _apiService.registerDealer(
        whatsappNumber: _whatsappController.text.trim(),
        name: _nameController.text.trim(),
        shopName: _shopNameController.text.trim(),
        address: _addressController.text.trim(),
        taluka: _selectedTalukaId!,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      setState(
        () => _errorMessage = e is ApiException
            ? (e.errorData['detail'] ?? 'Registration failed.').toString()
            : 'Registration failed. Check your details and try again.',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _hasUnsavedChanges() {
    return _whatsappController.text.trim().isNotEmpty ||
        _otpController.text.trim().isNotEmpty ||
        _nameController.text.trim().isNotEmpty ||
        _shopNameController.text.trim().isNotEmpty ||
        _addressController.text.trim().isNotEmpty ||
        _selectedStateId != null ||
        _selectedDistrictId != null ||
        _selectedTalukaId != null;
  }

  @override
  Widget build(BuildContext context) {
    return UnsavedChangesGuard(
      hasUnsavedChanges: _hasUnsavedChanges,
      child: Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _whatsappController,
                enabled: !_otpSent,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: 'WhatsApp Number',
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),

              if (!_otpSent)
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send OTP'),
                ),

              if (_otpSent && !_otpVerified) ...[
                OtpInput(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  onCompleted: (_) => _verifyOtp(),
                ),
                ResendOtpButton(onResend: _resendOtp),
                const SizedBox(height: 4),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify OTP'),
                ),
              ],

              if (_otpVerified) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Person Full Name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _shopNameController,
                  decoration: const InputDecoration(hintText: 'Firm Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(hintText: 'Firm Address'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedStateId,
                    decoration: const InputDecoration(hintText: 'State'),
                    items: _states
                        .map<DropdownMenuItem<int>>(
                          (s) => DropdownMenuItem(
                            value: s['id'],
                            child: Text(s['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _onStateSelected,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedDistrictId,
                    decoration: const InputDecoration(hintText: 'District'),
                    items: _districts
                        .map<DropdownMenuItem<int>>(
                          (d) => DropdownMenuItem(
                            value: d['id'],
                            child: Text(d['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _selectedStateId == null
                        ? null
                        : _onDistrictSelected,
                  ),
                ),
                const SizedBox(height: 12),
                Material(
                  color: Colors.transparent,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedTalukaId,
                    decoration: const InputDecoration(hintText: 'Taluka'),
                    items: _talukas
                        .map<DropdownMenuItem<int>>(
                          (t) => DropdownMenuItem(
                            value: t['id'],
                            child: Text(t['name']),
                          ),
                        )
                        .toList(),
                    onChanged: _selectedDistrictId == null
                        ? null
                        : (value) => setState(() => _selectedTalukaId = value),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Complete Registration'),
                ),
              ],

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
