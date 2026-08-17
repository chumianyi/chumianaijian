import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../models/ai_config.dart';
import '../theme/colors.dart';
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
}
