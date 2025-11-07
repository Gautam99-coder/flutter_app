import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _settingsKey = 'app_settings';

  Future<SettingsModel> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_settingsKey);

    if (settingsString != null) {
      try {
        final settingsMap = Map<String, dynamic>.from(
            json.decode(settingsString) as Map<String, dynamic>
        );
        return SettingsModel.fromMap(settingsMap);
      } catch (e) {
        print('Error parsing settings: $e');
      }
    }

    // Return default settings
    return SettingsModel(
      pushNotifications: true,
      darkMode: false,
      locationServices: true,
    );
  }

  Future<void> saveSettings(SettingsModel settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = json.encode(settings.toMap());
    await prefs.setString(_settingsKey, settingsString);
  }
}
