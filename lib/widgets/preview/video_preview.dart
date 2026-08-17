import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/editor_controller.dart';
import '../../models/clip.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism_theme.dart';
import '../../utils/time_utils.dart';
import '../common/neu_widgets.dart';

class VideoPreview extends StatelessWidget {
  const VideoPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, controller, _) {
        final project = controller.project;
        final clip = controller.selectedClip;
        final videoCtrl = controller.videoController;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: NeuShadow.concave(blur: 16),
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background checkerboard for transparency
                _buildCheckerboard(),
                // Video or color preview
                if (videoCtrl != null && videoCtrl.value.isInitialized && clip?.type == ClipType.video)
                  Center(
                    child: AspectRatio(
                      aspectRatio: videoCtrl.value.aspectRatio,
                      child: Transform.scale(
                        scale: clip?.scale ?? 1.0,
                        child: Transform.rotate(
                          angle: (clip?.rotation ?? 0) * 3.14159 / 180,
                          child: Opacity(
                            opacity: clip?.opacity ?? 1.0,
                            child: VideoPlayer(videoCtrl),
                          ),
                        ),
                      ),
                    ),
                  )
                else if (clip?.type == ClipType.color)
                  Container(color: Color(clip!.colorValue ?? 0xFF000000))
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.movie_outlined, size: 64, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('选择或导入视频素材开始预览', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                // Frame info overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildInfoBadge(controller),
                ),
                // Playback controls overlay
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: _buildPlaybackControls(controller),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCheckerboard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: constraints.biggest,
          painter: _CheckerboardPainter(),
        );
      },
    );
  }

  Widget _buildInfoBadge(EditorController controller) {
    final project = controller.project;
    final frame = project != null ? TimeUtils.frameNumber(controller.playhead, project.fps) : 0;
    return NeuContainer(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      borderRadius: 8,
      blur: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text(
            TimeUtils.formatDuration(controller.playhead),
            style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          Icon(Icons.layers, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Text('帧 $frame', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(EditorController controller) {
    return Center(
      child: NeuContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        borderRadius: 20,
        blur: 8,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NeuIconButton(
              icon: Icons.fast_rewind,
              iconSize: 16,
              size: 32,
              tooltip: '后退一帧',
              onPressed: () => controller.stepFrame(-1),
            ),
            const SizedBox(width: 6),
            NeuIconButton(
              icon: controller.isPlaying ? Icons.pause : Icons.play_arrow,
              iconSize: 20,
              size: 36,
              tooltip: controller.isPlaying ? '暂停' : '播放',
              onPressed: () => controller.togglePlay(),
            ),
            const SizedBox(width: 6),
            NeuIconButton(
              icon: Icons.fast_forward,
              iconSize: 16,
              size: 32,
              tooltip: '前进一帧',
              onPressed: () => controller.stepFrame(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 20.0;
    final paint1 = Paint()..color = const Color(0xFF333333);
    final paint2 = Paint()..color = const Color(0xFF444444);
    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        final isEven = ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), isEven ? paint1 : paint2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
