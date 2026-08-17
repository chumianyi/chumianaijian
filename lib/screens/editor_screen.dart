import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../controllers/editor_controller.dart';
import '../services/ffmpeg_service.dart';
import '../theme/colors.dart';
import '../widgets/common/neu_widgets.dart';
import '../widgets/common/virtual_mouse.dart';
import '../widgets/menus/menu_bar.dart';
import '../widgets/preview/video_preview.dart';
import '../widgets/preview/properties_panel.dart';
import '../widgets/timeline/timeline_widget.dart';
import 'settings_screen.dart';
import 'credits_screen.dart';
import 'drafts_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final VirtualMouseController _mouseController = VirtualMouseController();
  bool _showImportPanel = false;
  bool _showAIPanel = false;
  bool _showExportPanel = false;
  final TextEditingController _aiPromptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _aiPromptController.dispose();
    super.dispose();
  }

  Future<void> _importVideo() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result != null && result.files.single.path != null) {
      final controller = context.read<EditorController>();
      final path = result.files.single.path!;
      final name = result.files.single.name;
      final ffmpeg = FFmpegService();
      final info = await ffmpeg.getVideoInfo(path);
      final duration = info['duration'] as Duration? ?? const Duration(seconds: 10);
      await controller.addVideoClip(path, name, duration);
      await controller.prepareVideoPreview(path);
      setState(() => _showImportPanel = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入: $name')));
      }
    }
  }

  Future<void> _importAudio() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result.files.single.path != null) {
      final controller = context.read<EditorController>();
      await controller.addAudioClip(result.files.single.path!, result.files.single.name, const Duration(seconds: 10));
      setState(() => _showImportPanel = false);
    }
  }

  Future<void> _addDefaultMaterial(int color, String name) async {
    final controller = context.read<EditorController>();
    await controller.addColorClip(color, name);
    setState(() => _showImportPanel = false);
  }

  Future<void> _runExport(int width, int height, int bitrate) async {
    final controller = context.read<EditorController>();
    setState(() => _showExportPanel = false);
    try {
      final path = await controller.exportVideo(ExportSettings(width: width, height: height, videoBitrate: bitrate));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出成功: $path'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _runAI() async {
    final controller = context.read<EditorController>();
    final prompt = _aiPromptController.text.trim();
    if (prompt.isEmpty) return;
    try {
      final instruction = await controller.runAIEdit(prompt);
      await controller.executeAICommands(instruction);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI已执行: ${instruction.description}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI错误: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, controller, _) {
        return WillPopScope(
          onWillPop: () async {
            await controller.autoSave();
            return true;
          },
          child: VirtualMouseWrapper(
            controller: _mouseController,
            enabled: !controller.touchMode,
            child: Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: Stack(
                  children: [
                    Column(
                      children: [
                        AppMenuBar(
                          onNewProject: () async { await controller.createNewProject(); },
                          onOpenDraft: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftsScreen())),
                          onSave: () => controller.autoSave(),
                          onExport: () => setState(() => _showExportPanel = true),
                          onSettings: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                          onCredits: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen())),
                        ),
                        const ToolBar(),
                        Expanded(
                          child: Row(
                            children: [
                              _buildLeftToolbar(controller),
                              const Expanded(child: VideoPreview()),
                              const PropertiesPanel(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 200, child: TimelineWidget()),
                        _buildStatusBar(controller),
                      ],
                    ),
                    _buildImportPanel(),
                    if (_showAIPanel) _buildAIPanel(controller),
                    if (_showExportPanel) _buildExportPanel(),
                  ],
                ),
              ),
              floatingActionButton: _showImportPanel ? null : FloatingActionButton.extended(
                onPressed: () => setState(() => _showImportPanel = true),
                backgroundColor: AppColors.primary,
                icon: const Icon(Icons.add),
                label: const Text('导入素材'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftToolbar(EditorController controller) {
    return Container(
      width: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: AppColors.shadowDark.withOpacity(0.2), offset: const Offset(2, 0), blurRadius: 4)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _ToolbarIcon(icon: Icons.videocam, label: '视频', onTap: _importVideo),
          _ToolbarIcon(icon: Icons.audiotrack, label: '音频', onTap: _importAudio),
          _ToolbarIcon(icon: Icons.palette, label: '素材', onTap: () => setState(() => _showImportPanel = true)),
          _ToolbarIcon(icon: Icons.text_fields, label: '文字', onTap: () {}),
          const Divider(height: 16),
          _ToolbarIcon(icon: Icons.content_cut, label: '分割', onTap: () => controller.splitClipAtPlayhead()),
          _ToolbarIcon(icon: Icons.delete, label: '删除', onTap: () => controller.deleteSelectedClip()),
          const Divider(height: 16),
          _ToolbarIcon(icon: Icons.auto_awesome, label: 'AI', onTap: () => setState(() => _showAIPanel = true)),
          _ToolbarIcon(icon: Icons.undo, label: '撤销', onTap: () {}),
          const Spacer(),
          _ToolbarIcon(icon: controller.touchMode ? Icons.touch_app : Icons.mouse, label: controller.touchMode ? '触控' : '鼠标', onTap: () => controller.setTouchMode(!controller.touchMode)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatusBar(EditorController controller) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.menuBar,
        border: Border(top: BorderSide(color: AppColors.windowBorder.withOpacity(0.3))),
      ),
      child: Row(
        children: [
          Text('项目: ${controller.project?.name ?? "无"}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Text('时长: ${controller.project?.totalDuration.inSeconds ?? 0}s', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(width: 16),
          Text('缩放: ${(controller.zoom * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const Spacer(),
          if (controller.isExporting)
            Row(
              children: [
                SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, value: controller.exportProgress)),
                const SizedBox(width: 6),
                Text('导出中 ${(controller.exportProgress * 100).toStringAsFixed(0)}%', style: const TextStyle(fontSize: 10, color: AppColors.primary)),
              ],
            )
          else
            const Text('就绪', style: TextStyle(fontSize: 10, color: AppColors.success)),
        ],
      ),
    );
  }

  Widget _buildImportPanel() {
    if (!_showImportPanel) return const SizedBox.shrink();
    return Positioned(
      left: 60,
      top: 100,
      child: NeuContainer(
        borderRadius: 12,
        blur: 16,
        padding: const EdgeInsets.all(16),
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('导入素材', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showImportPanel = false)),
              ],
            ),
            const SizedBox(height: 12),
            _ImportOption(icon: Icons.videocam, title: '导入视频', subtitle: 'MP4, MOV, AVI等', onTap: _importVideo),
            _ImportOption(icon: Icons.audiotrack, title: '导入音频', subtitle: 'MP3, WAV, AAC等', onTap: _importAudio),
            const Divider(),
            const Text('默认素材', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                _DefaultMaterialButton(color: 0xFF000000, label: '黑底', onTap: () => _addDefaultMaterial(0xFF000000, '黑底素材')),
                const SizedBox(width: 8),
                _DefaultMaterialButton(color: 0xFFFFFFFF, label: '白底', onTap: () => _addDefaultMaterial(0xFFFFFFFF, '白底素材')),
                const SizedBox(width: 8),
                _DefaultMaterialButton(color: 0xFF00FF00, label: '绿幕', onTap: () => _addDefaultMaterial(0xFF00FF00, '绿幕素材')),
                const SizedBox(width: 8),
                _DefaultMaterialButton(color: 0x00000000, label: '透明', onTap: () => _addDefaultMaterial(0x00000000, '透明素材')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIPanel(EditorController controller) {
    return Positioned(
      right: 300,
      top: 100,
      child: NeuContainer(
        borderRadius: 12,
        blur: 16,
        padding: const EdgeInsets.all(16),
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('AI超能剪', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showAIPanel = false)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('描述你想要的效果，AI会自动操作时间线', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: _aiPromptController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '例如：把视频前3秒裁剪掉，在第5秒添加缩放关键帧，添加淡入转场',
                hintStyle: TextStyle(fontSize: 11, color: AppColors.textMuted),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: AppColors.background,
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            if (!controller.aiConfig.enabled)
              const Text('请先在设置中配置AI模型', style: TextStyle(fontSize: 10, color: AppColors.error))
            else
              Text('当前模型: ${controller.aiConfig.modelName}', style: const TextStyle(fontSize: 10, color: AppColors.success)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    isPrimary: true,
                    icon: Icons.bolt,
                    onPressed: controller.aiConfig.enabled ? _runAI : null,
                    child: const Text('执行AI剪辑'),
                  ),
                ),
                const SizedBox(width: 8),
                NeuButton(
                  icon: Icons.settings,
                  onPressed: () {
                    setState(() => _showAIPanel = false);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                  },
                  child: const Text('配置'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportPanel() {
    return Positioned(
      right: 300,
      top: 100,
      child: NeuContainer(
        borderRadius: 12,
        blur: 16,
        padding: const EdgeInsets.all(16),
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.video_file, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('导出视频', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: () => setState(() => _showExportPanel = false)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('分辨率', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                _ExportPresetButton(label: '720p', onTap: () => _runExport(1280, 720, 4000)),
                const SizedBox(width: 8),
                _ExportPresetButton(label: '1080p', onTap: () => _runExport(1920, 1080, 8000)),
                const SizedBox(width: 8),
                _ExportPresetButton(label: '4K', onTap: () => _runExport(3840, 2160, 20000)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('格式: MP4 (H.264 + AAC)', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _ToolbarIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolbarIcon({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: NeuIconButton(icon: icon, tooltip: label, onPressed: onTap, size: 40, iconSize: 20),
    );
  }
}

class _ImportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ImportOption({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontSize: 13)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
      onTap: onTap,
    );
  }
}

class _DefaultMaterialButton extends StatelessWidget {
  final int color;
  final String label;
  final VoidCallback onTap;
  const _DefaultMaterialButton({required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Color(color),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.windowBorder),
            ),
            child: color == 0x00000000 ? const Icon(Icons.check_box_outline_blank, color: AppColors.textMuted) : null,
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ExportPresetButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ExportPresetButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: NeuButton(
        isPrimary: true,
        padding: 10,
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
