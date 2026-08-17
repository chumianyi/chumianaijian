import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../controllers/app_controller.dart';
import '../models/ai_config.dart';
import '../theme/colors.dart';
import '../theme/neumorphism_theme.dart';
import '../widgets/common/neu_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiUrlCtrl;
  late TextEditingController _apiKeyCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _headersCtrl;
  double _temperature = 0.7;
  int _maxTokens = 4096;

  @override
  void initState() {
    super.initState();
    final config = context.read<EditorController>().aiConfig;
    _apiUrlCtrl = TextEditingController(text: config.apiBaseUrl);
    _apiKeyCtrl = TextEditingController(text: config.apiKey);
    _modelCtrl = TextEditingController(text: config.modelName);
    _headersCtrl = TextEditingController(text: config.customHeaders);
    _temperature = config.temperature;
    _maxTokens = config.maxTokens;
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    _apiKeyCtrl.dispose();
    _modelCtrl.dispose();
    _headersCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final controller = context.read<EditorController>();
    final config = AIConfig(
      apiBaseUrl: _apiUrlCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim(),
      modelName: _modelCtrl.text.trim(),
      customHeaders: _headersCtrl.text.trim(),
      temperature: _temperature,
      maxTokens: _maxTokens,
      enabled: _apiKeyCtrl.text.trim().isNotEmpty,
    );
    controller.updateAIConfig(config);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('设置已保存'), backgroundColor: AppColors.success));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditorController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('设置', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Interaction mode
            NeuContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('交互模式', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.mouse, size: 20, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      const Text('虚拟鼠标模式', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: !controller.touchMode,
                        onChanged: (v) => controller.setTouchMode(!v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('开启后触摸拖动模拟鼠标操作，适合精确剪辑；关闭后为直接触控模式', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 屏幕方向
            _buildOrientationCard(),
            const SizedBox(height: 20),
            // UI缩放
            _buildUIScaleCard(),
            const SizedBox(height: 20),
            // AI Config
            NeuContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('AI超能剪配置', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: controller.aiConfig.enabled ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(controller.aiConfig.enabled ? '已启用' : '未配置', style: TextStyle(fontSize: 10, color: controller.aiConfig.enabled ? AppColors.success : AppColors.error)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField('API 地址 (OpenAI兼容)', _apiUrlCtrl, 'https://api.openai.com/v1'),
                  const SizedBox(height: 12),
                  _buildTextField('API Key', _apiKeyCtrl, 'sk-...', obscure: true),
                  const SizedBox(height: 12),
                  _buildTextField('模型名称', _modelCtrl, 'gpt-4o / qwen-max / claude-3-opus'),
                  const SizedBox(height: 12),
                  _buildTextField('自定义 Headers (JSON)', _headersCtrl, '{"Authorization": "Bearer ..."}'),
                  const SizedBox(height: 12),
                  NeuSlider(label: 'Temperature: ${_temperature.toStringAsFixed(2)}', value: _temperature, min: 0, max: 2, onChanged: (v) => setState(() => _temperature = v)),
                  const SizedBox(height: 12),
                  NeuSlider(label: 'Max Tokens: $_maxTokens', value: _maxTokens.toDouble(), min: 256, max: 8192, divisions: 31, onChanged: (v) => setState(() => _maxTokens = v.round())),
                  const SizedBox(height: 16),
                  NeuButton(isPrimary: true, icon: Icons.save, onPressed: _save, child: const Text('保存AI配置')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // About
            NeuContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('关于', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('初眠爱剪 v1.0.0', style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('基于 Flutter 框架开发，GPL 3.0 开源协议', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('字体: Noto Sans SC (开源)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ],
    );
  }

  Widget _buildOrientationCard() {
    final appController = context.watch<AppController>();
    return NeuContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.screen_rotation, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text('屏幕方向', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _OrientationOption(
                  label: '自动',
                  icon: Icons.auto_awesome,
                  selected: appController.orientation == ScreenOrientation.auto,
                  onTap: () => appController.setOrientation(ScreenOrientation.auto),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OrientationOption(
                  label: '横屏',
                  icon: Icons.stay_current_landscape,
                  selected: appController.orientation == ScreenOrientation.landscape,
                  onTap: () => appController.setOrientation(ScreenOrientation.landscape),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OrientationOption(
                  label: '竖屏',
                  icon: Icons.stay_current_portrait,
                  selected: appController.orientation == ScreenOrientation.portrait,
                  onTap: () => appController.setOrientation(ScreenOrientation.portrait),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('选择编辑器和全局界面的屏幕方向，默认自动适配', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildUIScaleCard() {
    final appController = context.watch<AppController>();
    final currentIndex = AppController.scalePresets.indexOf(appController.uiScale).clamp(0, AppController.scalePresets.length - 1);
    return NeuContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.zoom_in, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text('界面大小', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(AppController.scalePresets.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < AppController.scalePresets.length - 1 ? 8 : 0),
                  child: _OrientationOption(
                    label: AppController.scaleLabels[i],
                    icon: i == 0 ? Icons.text_fields : (i == 1 ? Icons.text_fields : (i == 2 ? Icons.format_size : Icons.format_size)),
                    selected: currentIndex == i,
                    onTap: () => appController.setUIScale(AppController.scalePresets[i]),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          NeuSlider(
            label: '缩放: ${(appController.uiScale * 100).toStringAsFixed(0)}%',
            value: appController.uiScale,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            onChanged: (v) => appController.setUIScale(v),
          ),
          const SizedBox(height: 8),
          Text('调整全局文字和界面元素大小，设置后立即生效', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _OrientationOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _OrientationOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? AppColors.primary : Colors.transparent, width: 1.5),
          boxShadow: selected ? null : NeuShadow.flat(blur: 4),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
