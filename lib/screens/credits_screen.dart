import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../widgets/common/neu_widgets.dart';

class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const List<_CreditItem> _credits = [
    _CreditItem(name: 'Flutter', url: 'https://flutter.dev', license: 'BSD-3-Clause', desc: 'UI框架，跨平台应用开发'),
    _CreditItem(name: 'Dart', url: 'https://dart.dev', license: 'BSD-3-Clause', desc: '编程语言'),
    _CreditItem(name: 'ffmpeg_kit_flutter', url: 'https://github.com/arthenica/ffmpeg-kit', license: 'LGPL-3.0', desc: 'FFmpeg的Flutter封装，用于视频解码/编码/滤镜'),
    _CreditItem(name: 'FFmpeg', url: 'https://ffmpeg.org', license: 'LGPL-2.1+ / GPL-2+', desc: '完整的视频/音频处理解决方案，本项目使用GPL版本'),
    _CreditItem(name: 'video_player', url: 'https://pub.dev/packages/video_player', license: 'BSD-3-Clause', desc: 'Flutter官方视频播放插件'),
    _CreditItem(name: 'file_picker', url: 'https://pub.dev/packages/file_picker', license: 'MIT', desc: '文件选择器，用于导入素材'),
    _CreditItem(name: 'provider', url: 'https://pub.dev/packages/provider', license: 'MIT', desc: '状态管理'),
    _CreditItem(name: 'google_fonts', url: 'https://pub.dev/packages/google_fonts', license: 'Apache-2.0', desc: 'Google字体加载，使用Noto Sans SC'),
    _CreditItem(name: 'Noto Sans SC', url: 'https://fonts.google.com/noto/specimen/Noto+Sans+SC', license: 'SIL Open Font License 1.1', desc: '开源中文字体'),
    _CreditItem(name: 'path_provider', url: 'https://pub.dev/packages/path_provider', license: 'BSD-3-Clause', desc: '获取应用存储路径'),
    _CreditItem(name: 'shared_preferences', url: 'https://pub.dev/packages/shared_preferences', license: 'BSD-3-Clause', desc: '键值对持久化存储'),
    _CreditItem(name: 'http', url: 'https://pub.dev/packages/http', license: 'BSD-3-Clause', desc: 'HTTP客户端，用于AI接口调用'),
    _CreditItem(name: 'image', url: 'https://pub.dev/packages/image', license: 'MIT', desc: '图像处理库'),
    _CreditItem(name: 'uuid', url: 'https://pub.dev/packages/uuid', license: 'MIT', desc: '唯一ID生成'),
    _CreditItem(name: 'intl', url: 'https://pub.dev/packages/intl', license: 'BSD-3-Clause', desc: '国际化与数字格式化'),
    _CreditItem(name: 'permission_handler', url: 'https://pub.dev/packages/permission_handler', license: 'MIT', desc: 'Android权限管理'),
    _CreditItem(name: 'gallery_saver', url: 'https://pub.dev/packages/gallery_saver', license: 'Apache-2.0', desc: '保存视频到相册'),
    _CreditItem(name: 'wakelock_plus', url: 'https://pub.dev/packages/wakelock_plus', license: 'BSD-3-Clause', desc: '屏幕常亮控制'),
    _CreditItem(name: 'Pixabay Music API', url: 'https://pixabay.com/api/docs/', license: 'Pixabay Content License', desc: '免费音乐素材库API'),
    _CreditItem(name: 'OpenAI API', url: 'https://openai.com', license: '商用API', desc: 'AI超能剪兼容的接口标准（用户自行配置）'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text('致谢', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            NeuContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite, color: AppColors.error, size: 24),
                      const SizedBox(width: 12),
                      const Text('初眠爱剪', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('本项目基于 GPL 3.0 协议开源，使用了以下优秀的开源项目和资源。我们向所有贡献者致以诚挚的感谢。', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('所有第三方代码均保留其原始署名和许可证，未做任何篡改或替换。', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('开源依赖', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            ..._credits.map((c) => _buildCreditCard(c)),
            const SizedBox(height: 20),
            NeuContainer(
              borderRadius: 12,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GPL 3.0 许可证声明', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('本程序是自由软件：你可以根据自由软件基金会发布的GNU通用公共许可证第三版重新分发和/或修改它。', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('源代码：本应用的完整源代码可在项目仓库获取。', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(child: Text('初眠爱剪 v1.0.0 · 感谢所有开源贡献者', style: TextStyle(fontSize: 11, color: AppColors.textMuted))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditCard(_CreditItem item) {
    return NeuContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderRadius: 10,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.code, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(item.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(item.license, style: TextStyle(fontSize: 9, color: AppColors.success)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.desc, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(item.url, style: TextStyle(fontSize: 10, color: AppColors.primary, decoration: TextDecoration.underline)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreditItem {
  final String name;
  final String url;
  final String license;
  final String desc;
  const _CreditItem({required this.name, required this.url, required this.license, required this.desc});
}
