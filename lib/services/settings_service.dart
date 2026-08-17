import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_config.dart';

class SettingsService {
  static const String _keyAIConfig = 'ai_config';
  static const String _keyTouchMode = 'touch_mode';
  static const String _keyTheme = 'theme';
  static const String _keyLastProject = 'last_project';

  Future<AIConfig> loadAIConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_keyAIConfig);
    if (str != null) {
      try {
        return AIConfig.fromJson(jsonDecode(str));
      } catch (_) {}
    }
    return AIConfig();
  }

  Future<void> saveAIConfig(AIConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAIConfig, jsonEncode(config.toJson()));
  }

  Future<bool> isTouchMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyTouchMode) ?? false;
  }

  Future<void> setTouchMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyTouchMode, enabled);
  }

  Future<String?> getLastProjectId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastProject);
  }

  Future<void> setLastProjectId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id != null) {
      await prefs.setString(_keyLastProject, id);
    } else {
      await prefs.remove(_keyLastProject);
    }
  }
}
