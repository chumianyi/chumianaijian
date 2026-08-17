import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/editor_controller.dart';
import '../theme/colors.dart';
import '../theme/neumorphism_theme.dart';
import '../widgets/common/neu_widgets.dart';
import 'editor_screen.dart';
import 'drafts_screen.dart';
import 'settings_screen.dart';
import 'credits_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              NeuContainer(
                borderRadius: 24,
                blur: 20,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.accent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 20, spreadRadius: 2)],
                      ),
                      child: const Icon(Icons.cut, size: 40, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('初眠爱剪', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('专业横屏视频剪辑 · AI超能剪', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Main action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HomeActionCard(
                    icon: Icons.play_circle_fill,
                    title: '开始剪辑',
                    subtitle: '新建项目，导入素材',
                    color: AppColors.primary,
                    onTap: () async {
                      final controller = context.read<EditorController>();
                      await controller.createNewProject();
                      if (context.mounted) {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const EditorScreen()));
                      }
                    },
                  ),
                  const SizedBox(width: 20),
                  _HomeActionCard(
                    icon: Icons.folder_open,
                    title: '草稿箱',
                    subtitle: '继续编辑已有项目',
                    color: AppColors.accent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DraftsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HomeActionCard(
                    icon: Icons.settings,
                    title: '设置',
                    subtitle: '偏好与AI配置',
                    color: AppColors.success,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                  ),
                  const SizedBox(width: 20),
                  _HomeActionCard(
                    icon: Icons.favorite,
                    title: '致谢',
                    subtitle: '开源项目与许可',
                    color: AppColors.error,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreditsScreen())),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Features
              NeuContainer(
                borderRadius: 16,
                blur: 10,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('核心功能', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: const [
                        _FeatureChip(icon: Icons.videocam, text: '视频剪辑'),
                        _FeatureChip(icon: Icons.layers, text: '多轨道画中画'),
                        _FeatureChip(icon: Icons.diamond, text: '关键帧动画'),
                        _FeatureChip(icon: Icons.colorize, text: '色度抠像'),
                        _FeatureChip(icon: Icons.brush, text: '手动抠像'),
                        _FeatureChip(icon: Icons.auto_awesome, text: 'AI超能剪'),
                        _FeatureChip(icon: Icons.mic, text: '配音录音'),
                        _FeatureChip(icon: Icons.music_note, text: '音乐库'),
                        _FeatureChip(icon: Icons.save, text: '草稿自动保存'),
                        _FeatureChip(icon: Icons.high_quality, text: '高清导出'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('初眠爱剪 v1.0.0 · GPL 3.0 开源', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _HomeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return NeuContainer(
      onTap: onTap,
      borderRadius: 16,
      blur: 12,
      width: 200,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        boxShadow: NeuShadow.flat(blur: 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
