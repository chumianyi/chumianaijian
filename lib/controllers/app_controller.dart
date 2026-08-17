import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/settings_service.dart';

/// 屏幕方向选项
enum ScreenOrientation { auto, landscape, portrait }

/// 全局应用设置控制器（屏幕方向 + UI缩放）
class AppController extends ChangeNotifier {
  final SettingsService _settings = SettingsService();

  ScreenOrientation _orientation = ScreenOrientation.auto;
  double _uiScale = 1.0; // 0.8 小 / 1.0 标准 / 1.2 大 / 1.4 超大

  ScreenOrientation get orientation => _orientation;
  double get uiScale => _uiScale;

  static const List<double> scalePresets = [0.8, 1.0, 1.2, 1.4];
  static const List<String> scaleLabels = ['小', '标准', '大', '超大'];

  Future<void> init() async {
    _orientation = await _settings.getScreenOrientation();
    _uiScale = await _settings.getUIScale();
    applyOrientation();
    notifyListeners();
  }

  void setOrientation(ScreenOrientation mode) {
    _orientation = mode;
    _settings.setScreenOrientation(mode);
    applyOrientation();
    notifyListeners();
  }

  void setUIScale(double scale) {
    _uiScale = scale;
    _settings.setUIScale(scale);
    notifyListeners();
  }

  void applyOrientation() {
    switch (_orientation) {
      case ScreenOrientation.landscape:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
      case ScreenOrientation.portrait:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
        break;
      case ScreenOrientation.auto:
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        break;
    }
  }

  /// 获取当前UI缩放的文字倍率
  double get textScaleFactor => _uiScale;
}
