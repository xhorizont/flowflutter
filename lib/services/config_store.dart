import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_config.dart';

class ConfigStore {
  static const String _configKey = 'app_config';

  Future<AppConfig> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = prefs.getString(_configKey);

      if (configJson == null) {
        return AppConfig.defaultConfig;
      }

      final Map<String, dynamic> data = json.decode(configJson);
      return AppConfig.fromJson(data);
    } catch (e) {
      return AppConfig.defaultConfig;
    }
  }

  Future<void> saveConfig(AppConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configJson = json.encode(config.toJson());
      await prefs.setString(_configKey, configJson);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }
}
