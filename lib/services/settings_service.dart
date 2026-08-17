import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_config.dart';
import '../controllers/app_controller.dart';

class SettingsService {
  static const String _keyAIConfig = 'ai_config';
  static const String _keyTouchMode = 'touch_mode';
  static const String _keyTheme = 'theme';
  static const String _keyLastProject = 'last_project';
  static const String _keyScreenOrientation = 'screen_orientation';
  static const String _keyUIScale = 'ui_scale';

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

  // ===== 屏幕方向 =====
  Future<ScreenOrientation> getScreenOrientation() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_keyScreenOrientation) ?? 0;
    return ScreenOrientation.values[idx.clamp(0, ScreenOrientation.values.length - 1)];
  }

  Future<void> setScreenOrientation(ScreenOrientation mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyScreenOrientation, mode.index);
  }

  // ===== UI缩放 =====
  Future<double> getUIScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyUIScale) ?? 1.0;
  }

  Future<void> setUIScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyUIScale, scale);
  }
}
