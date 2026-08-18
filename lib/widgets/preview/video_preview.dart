import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../../controllers/editor_controller.dart';
import '../../models/clip.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism_theme.dart';
import '../../utils/time_utils.dart';
import '../common/neu_widgets.dart';

class VideoPreview extends StatefulWidget {
  const VideoPreview({super.key});

  @override
  State<VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<VideoPreview> {
  bool _isDragging = false;
  Offset? _dragStart;
  double? _startPosX;
  double? _startPosY;

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
                _buildCheckerboard(),
                // 可拖动的素材层
                GestureDetector(
                  onPanStart: (details) {
                    if (clip != null) {
                      setState(() {
                        _isDragging = true;
                        _dragStart = details.localPosition;
                        _startPosX = clip.positionX;
                        _startPosY = clip.positionY;
                      });
                    }
                  },
                  onPanUpdate: (details) {
                    if (_isDragging && clip != null && _dragStart != null) {
                      final size = context.size;
                      if (size != null) {
                        final dx = (details.localPosition.dx - _dragStart!.dx) / size.width * 2;
                        final dy = (details.localPosition.dy - _dragStart!.dy) / size.height * 2;
                        controller.setClipPosition(
                          clip.id,
                          (_startPosX! + dx).clamp(-1.0, 1.0),
                          (_startPosY! + dy).clamp(-1.0, 1.0),
                        );
                      }
                    }
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _isDragging = false;
                      _dragStart = null;
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 视频或颜色预览
                      if (videoCtrl != null && videoCtrl.value.isInitialized && clip?.type == ClipType.video)
                        Center(
                          child: Transform.translate(
                            offset: Offset(
                              (clip?.positionX ?? 0) * (context.size?.width ?? 300) / 2,
                              (clip?.positionY ?? 0) * (context.size?.height ?? 200) / 2,
                            ),
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
                          ),
                        )
                      else if (clip?.type == ClipType.color)
                        Center(
                          child: Transform.translate(
                            offset: Offset(
                              (clip?.positionX ?? 0) * (context.size?.width ?? 300) / 2,
                              (clip?.positionY ?? 0) * (context.size?.height ?? 200) / 2,
                            ),
                            child: Transform.scale(
                              scale: clip?.scale ?? 1.0,
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Color(clip!.colorValue ?? 0xFF000000),
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.movie_outlined, size: 64, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text('选择或导入视频素材开始预览', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text('选中素材后可直接拖动调整位置', style: TextStyle(color: AppColors.textMuted.withOpacity(0.7), fontSize: 11)),
                            ],
                          ),
                        ),
                      // 选中高亮边框
                      if (clip != null && _isDragging)
                        IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.primary, width: 2, style: BorderStyle.solid),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // 帧信息
                Positioned(
                  top: 8,
                  left: 8,
                  child: _buildInfoBadge(controller),
                ),
                // 拖动提示
                if (_isDragging)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('拖动中 X:${(clip?.positionX ?? 0).toStringAsFixed(2)} Y:${(clip?.positionY ?? 0).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
                // 播放控制
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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
      ),
    );
  }

  Widget _buildInfoBadge(EditorController controller) {
    final fps = controller.project?.fps ?? 30;
    final frame = (controller.playhead.inMilliseconds / 1000 * fps).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '帧: $frame | ${TimeUtils.formatDuration(controller.playhead)}',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildPlaybackControls(EditorController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NeuButton(
          icon: Icons.fast_rewind,
          onPressed: () => controller.stepFrame(-1),
          child: const Text('退帧'),
        ),
        const SizedBox(width: 8),
        NeuButton(
          isPrimary: true,
          icon: controller.isPlaying ? Icons.pause : Icons.play_arrow,
          onPressed: () => controller.togglePlay(),
          child: Text(controller.isPlaying ? '暂停' : '播放'),
        ),
        const SizedBox(width: 8),
        NeuButton(
          icon: Icons.fast_forward,
          onPressed: () => controller.stepFrame(1),
          child: const Text('进帧'),
        ),
      ],
    );
  }
}
