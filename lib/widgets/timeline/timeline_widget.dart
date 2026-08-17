import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/editor_controller.dart';
import '../../models/clip.dart';
import '../../models/track.dart';
import '../../theme/colors.dart';
import '../../theme/neumorphism_theme.dart';
import '../../utils/time_utils.dart';
import '../common/neu_widgets.dart';

class TimelineWidget extends StatefulWidget {
  const TimelineWidget({super.key});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _hScroll = ScrollController();
  final ScrollController _vScroll = ScrollController();
  double _pixelsPerSecond = 80;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<EditorController>();
      _pixelsPerSecond = 80 * controller.zoom;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, controller, _) {
        _pixelsPerSecond = 80 * controller.zoom;
        final project = controller.project;
        if (project == null) return const SizedBox.shrink();

        final totalWidth = (project.totalDuration.inMilliseconds / 1000 * _pixelsPerSecond).clamp(800.0, 100000.0);
        final trackHeight = 56.0;
        final timelineHeight = project.tracks.length * trackHeight + 60;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(color: AppColors.shadowDark.withOpacity(0.3), offset: const Offset(0, -2), blurRadius: 8),
            ],
          ),
          child: Column(
            children: [
              // Ruler
              SizedBox(
                height: 28,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _hScroll,
                  itemCount: (totalWidth / 100).ceil() + 2,
                  itemBuilder: (context, index) {
                    final time = Duration(seconds: index);
                    return SizedBox(
                      width: _pixelsPerSecond,
                      child: CustomPaint(
                        painter: _RulerPainter(
                          time: time,
                          pixelsPerSecond: _pixelsPerSecond,
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Tracks
              Expanded(
                child: RawScrollbar(
                  controller: _vScroll,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _vScroll,
                    scrollDirection: Axis.vertical,
                    child: SizedBox(
                      height: timelineHeight,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        controller: _hScroll,
                        itemCount: 1,
                        itemBuilder: (context, _) {
                          return SizedBox(
                            width: totalWidth + 200,
                            child: Stack(
                              children: [
                                // Track backgrounds
                                ...project.tracks.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final track = entry.value;
                                  return Positioned(
                                    top: idx * trackHeight.toDouble(),
                                    left: 0,
                                    right: 0,
                                    height: trackHeight,
                                    child: _TrackRow(
                                      track: track,
                                      trackHeight: trackHeight,
                                      pixelsPerSecond: _pixelsPerSecond,
                                    ),
                                  );
                                }),
                                // Playhead
                                Positioned(
                                  left: 120 + controller.playhead.inMilliseconds / 1000 * _pixelsPerSecond,
                                  top: 0,
                                  bottom: 0,
                                  child: _PlayheadLine(),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track track;
  final double trackHeight;
  final double pixelsPerSecond;

  const _TrackRow({
    required this.track,
    required this.trackHeight,
    required this.pixelsPerSecond,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorController>(
      builder: (context, controller, _) {
        return Row(
          children: [
            // Track header
            GestureDetector(
              onTap: () => controller.selectClip(null),
              child: Container(
                width: 120,
                height: trackHeight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(right: BorderSide(color: AppColors.windowBorder.withOpacity(0.5), width: 1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _trackIcon(track.type),
                        const SizedBox(width: 4),
                        if (track.type == TrackType.audio)
                          GestureDetector(
                            onTap: () => controller.toggleTrackMute(track.id),
                            child: Icon(
                              track.isMuted ? Icons.volume_off : Icons.volume_up,
                              size: 14,
                              color: track.isMuted ? AppColors.error : AppColors.textSecondary,
                            ),
                          ),
                        if (track.type == TrackType.video)
                          GestureDetector(
                            onTap: () => controller.toggleTrackVisible(track.id),
                            child: Icon(
                              track.isVisible ? Icons.visibility : Icons.visibility_off,
                              size: 14,
                              color: track.isVisible ? AppColors.textSecondary : AppColors.error,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Track content
            Expanded(
              child: GestureDetector(
                onTapDown: (details) {
                  final dx = details.localPosition.dx;
                  final time = Duration(milliseconds: (dx / pixelsPerSecond * 1000).round());
                  controller.setPlayhead(time);
                },
                child: Container(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: track.type == TrackType.video
                        ? AppColors.trackVideo.withOpacity(0.05)
                        : AppColors.trackAudio.withOpacity(0.05),
                    border: Border(bottom: BorderSide(color: AppColors.windowBorder.withOpacity(0.3), width: 1)),
                  ),
                  child: Stack(
                    children: track.clips.map((clip) => _ClipWidget(
                      clip: clip,
                      track: track,
                      pixelsPerSecond: pixelsPerSecond,
                      trackHeight: trackHeight,
                    )).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trackIcon(TrackType type) {
    IconData icon;
    Color color;
    switch (type) {
      case TrackType.video:
        icon = Icons.videocam;
        color = AppColors.trackVideo;
        break;
      case TrackType.audio:
        icon = Icons.audiotrack;
        color = AppColors.trackAudio;
        break;
      case TrackType.effect:
        icon = Icons.auto_awesome;
        color = AppColors.trackEffect;
        break;
      case TrackType.text:
        icon = Icons.text_fields;
        color = AppColors.trackText;
        break;
    }
    return Icon(icon, size: 12, color: color);
  }
}

class _ClipWidget extends StatefulWidget {
  final Clip clip;
  final Track track;
  final double pixelsPerSecond;
  final double trackHeight;

  const _ClipWidget({
    required this.clip,
    required this.track,
    required this.pixelsPerSecond,
    required this.trackHeight,
  });

  @override
  State<_ClipWidget> createState() => _ClipWidgetState();
}

class _ClipWidgetState extends State<_ClipWidget> {
  bool _isDragging = false;
  Offset? _dragStart;
  Duration? _originalStart;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<EditorController>();
    final left = 120 + widget.clip.startTime.inMilliseconds / 1000 * widget.pixelsPerSecond;
    final width = widget.clip.duration.inMilliseconds / 1000 * widget.pixelsPerSecond;
    final isSelected = controller.selectedClipId == widget.clip.id;

    Color clipColor;
    switch (widget.clip.type) {
      case ClipType.video:
        clipColor = AppColors.trackVideo;
        break;
      case ClipType.audio:
        clipColor = AppColors.trackAudio;
        break;
      case ClipType.image:
        clipColor = AppColors.trackEffect;
        break;
      case ClipType.color:
        clipColor = Color(widget.clip.colorValue ?? 0xFF888888);
        break;
      case ClipType.text:
        clipColor = AppColors.trackText;
        break;
    }

    return Positioned(
      left: left,
      top: 4,
      width: width.clamp(20.0, 10000.0),
      height: widget.trackHeight - 8,
      child: GestureDetector(
        onTap: () => controller.selectClip(widget.clip.id),
        onHorizontalDragStart: (details) {
          _isDragging = true;
          _dragStart = details.globalPosition;
          _originalStart = widget.clip.startTime;
          controller.selectClip(widget.clip.id);
        },
        onHorizontalDragUpdate: (details) {
          if (!_isDragging || _dragStart == null || _originalStart == null) return;
          final delta = details.globalPosition.dx - _dragStart!.dx;
          final timeDelta = Duration(milliseconds: (delta / widget.pixelsPerSecond * 1000).round());
          final newStart = Duration(milliseconds: (_originalStart!.inMilliseconds + timeDelta.inMilliseconds).clamp(0, Duration(hours: 1).inMilliseconds));
          controller.moveClip(widget.clip.id, newStart);
        },
        onHorizontalDragEnd: (_) {
          _isDragging = false;
          _dragStart = null;
          _originalStart = null;
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          decoration: BoxDecoration(
            color: clipColor.withOpacity(0.7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.primary : clipColor.withOpacity(0.8),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: Stack(
            children: [
              // Trim handles
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final delta = Duration(milliseconds: (details.delta.dx / widget.pixelsPerSecond * 1000).round());
                    final newSourceStart = Duration(milliseconds: (widget.clip.sourceStart.inMilliseconds + delta.inMilliseconds).clamp(0, widget.clip.sourceDuration.inMilliseconds));
                    controller.trimClipStart(widget.clip.id, newSourceStart);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(6)),
                    ),
                    child: const Icon(Icons.drag_handle, size: 10, color: Colors.white),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    final delta = Duration(milliseconds: (details.delta.dx / widget.pixelsPerSecond * 1000).round());
                    final newDuration = Duration(milliseconds: (widget.clip.duration.inMilliseconds + delta.inMilliseconds).clamp(100, widget.clip.sourceDuration.inMilliseconds));
                    controller.trimClipEnd(widget.clip.id, newDuration);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(6)),
                    ),
                    child: const Icon(Icons.drag_handle, size: 10, color: Colors.white),
                  ),
                ),
              ),
              // Clip info
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 10, top: 4),
                child: Text(
                  widget.clip.name,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Keyframe markers
              ...widget.clip.keyframes.map((kf) {
                final kfLeft = kf.time.inMilliseconds / 1000 * widget.pixelsPerSecond - 4;
                return Positioned(
                  left: kfLeft,
                  bottom: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayheadLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      color: AppColors.error,
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(left: -5),
            decoration: const BoxDecoration(
              color: AppColors.error,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final Duration time;
  final double pixelsPerSecond;

  _RulerPainter({required this.time, required this.pixelsPerSecond});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.textMuted;
    final textPainter = TextPainter(
      text: TextSpan(
        text: TimeUtils.formatShort(time),
        style: TextStyle(fontSize: 9, color: AppColors.textSecondary),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, const Offset(4, 2));

    // Major tick
    canvas.drawLine(const Offset(0, 18), const Offset(0, 26), paint..strokeWidth = 1.5);
    // Minor ticks
    for (int i = 1; i < 4; i++) {
      final x = i * pixelsPerSecond / 4;
      canvas.drawLine(Offset(x, 20), Offset(x, 26), paint..strokeWidth = 0.5);
    }
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) => false;
}
