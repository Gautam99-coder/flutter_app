import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:abc_app/services/settings_service.dart';
import 'package:abc_app/models/settings_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsService _settingsService;
  late Future<SettingsModel> _settingsFuture;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _settingsFuture = _settingsService.getSettings();
  }

  void _updateSetting(String key, bool value) {
    setState(() {
      _settingsFuture = _settingsFuture.then((settings) {
        final updated = settings.copyWith(
          pushNotifications: key == 'pushNotifications' ? value : settings.pushNotifications,
          darkMode: key == 'darkMode' ? value : settings.darkMode,
          locationServices: key == 'locationServices' ? value : settings.locationServices,
        );
        _settingsService.saveSettings(updated);

        // Update theme if dark mode changed
        if (key == 'darkMode') {
          final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
          themeNotifier.setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
        }

        return updated;
      });
    });
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: const Text('Email: support@abcapp.com\nPhone: +1-234-567-8900'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: FutureBuilder<SettingsModel>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final settings = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Settings Section
              _buildSectionHeader('Settings'),
              _buildSettingSwitch(
                title: 'Enable push notifications for updates and reminders',
                value: settings.pushNotifications,
                onChanged: (value) => _updateSetting('pushNotifications', value),
              ),
              _buildSettingSwitch(
                title: 'Switch to a darker color scheme for better visibility at night',
                value: settings.darkMode,
                onChanged: (value) => _updateSetting('darkMode', value),
              ),
              _buildSettingSwitch(
                title: 'Allow the app to access your location for nearby pharmacy',
                value: settings.locationServices,
                onChanged: (value) => _updateSetting('locationServices', value),
              ),

              const Divider(height: 40),

              // Help & Support Section
              _buildSectionHeader('Help & Support'),
              _buildListTile(
                title: 'Contact Us',
                onTap: _showContactDialog,
              ),
              _buildListTile(
                title: 'FAQ',
                onTap: () => _launchURL('https://abcapp.com/faq'),
              ),

              const Divider(height: 40),

              // About Section
              _buildSectionHeader('About'),
              _buildListTile(
                title: 'App Version',
                trailing: const Text('1.2.3'),
                onTap: () {},
              ),
              _buildListTile(
                title: 'Terms of Service',
                onTap: () => _launchURL('https://abcapp.com/terms'),
              ),
              _buildListTile(
                title: 'Privacy Policy',
                onTap: () => _launchURL('https://abcapp.com/privacy'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _buildListTile({
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(fontSize: 16),
      ),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }
}