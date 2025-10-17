import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/config_store.dart';
import 'chat_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiHostController = TextEditingController();
  final _chatflowIdController = TextEditingController();
  bool _useStreaming = true;
  bool _isLoading = true;

  final ConfigStore _configStore = ConfigStore();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);

    try {
      final config = await _configStore.loadConfig();
      _apiHostController.text = config.apiHost;
      _chatflowIdController.text = config.chatflowId;
      _useStreaming = config.useStreaming;
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAndGoBack() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final config = AppConfig(
      apiHost: _apiHostController.text.trim(),
      chatflowId: _chatflowIdController.text.trim(),
      useStreaming: _useStreaming,
    );

    try {
      await _configStore.saveConfig(config);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Go back to chat with success result
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiHostController.dispose();
    _chatflowIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flowise Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Configure your Flowise connection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _apiHostController,
                      decoration: const InputDecoration(
                        labelText: 'API Host',
                        hintText: 'https://your-flowise-instance.com',
                        border: OutlineInputBorder(),
                        helperText: 'Your Flowise server URL',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter API Host';
                        }
                        if (!value.startsWith('http://') &&
                            !value.startsWith('https://')) {
                          return 'Must start with http:// or https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _chatflowIdController,
                      decoration: const InputDecoration(
                        labelText: 'Chatflow ID',
                        hintText: 'abc-123-def-456',
                        border: OutlineInputBorder(),
                        helperText: 'The ID of your chatflow',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter Chatflow ID';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Use Streaming'),
                      subtitle: const Text(
                        'Enable real-time token streaming (recommended)',
                      ),
                      value: _useStreaming,
                      onChanged: (value) {
                        setState(() => _useStreaming = value);
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _saveAndGoBack,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
