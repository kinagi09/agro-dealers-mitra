import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/wave_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();

  int? _preferenceId;
  bool _pushEnabled = true;
  bool _whatsappEnabled = true;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final preference = await _apiService.getMyNotificationPreference();
      setState(() {
        _preferenceId = preference['id'];
        _pushEnabled = preference['push_enabled'] ?? true;
        _whatsappEnabled = preference['whatsapp_enabled'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not load notification settings. Check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _save({bool? pushEnabled, bool? whatsappEnabled}) async {
    if (_preferenceId == null) return;
    final previousPush = _pushEnabled;
    final previousWhatsapp = _whatsappEnabled;
    setState(() {
      _pushEnabled = pushEnabled ?? _pushEnabled;
      _whatsappEnabled = whatsappEnabled ?? _whatsappEnabled;
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      await _apiService.updateNotificationPreference(
        id: _preferenceId!,
        pushEnabled: _pushEnabled,
        whatsappEnabled: _whatsappEnabled,
      );
    } catch (e) {
      setState(() {
        _pushEnabled = previousPush;
        _whatsappEnabled = previousWhatsapp;
        _errorMessage = 'Could not save your changes. Please try again.';
      });
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          WaveHeaderBar(
            title: 'Notification Settings',
            leading: WaveHeaderIconButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Card(
                          child: SwitchListTile(
                            title: const Text('Push Notifications'),
                            subtitle: const Text(
                              'Get reminders as app notifications',
                            ),
                            value: _pushEnabled,
                            onChanged: _isSaving
                                ? null
                                : (value) => _save(pushEnabled: value),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: SwitchListTile(
                            title: const Text('WhatsApp Notifications'),
                            subtitle: const Text('Get reminders on WhatsApp'),
                            value: _whatsappEnabled,
                            onChanged: _isSaving
                                ? null
                                : (value) => _save(whatsappEnabled: value),
                          ),
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
