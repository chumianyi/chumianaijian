import 'dart:io';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import '../models/project.dart';
import '../models/clip.dart';
import '../models/track.dart';
import '../models/keyframe.dart';
import '../models/ai_config.dart';
import '../services/project_storage.dart';
import '../services/ffmpeg_service.dart';
import '../services/ai_service.dart';
import '../services/settings_service.dart';

class EditorController extends ChangeNotifier {
  final ProjectStorage _storage = ProjectStorage();
  final FFmpegService _ffmpeg = FFmpegService();
  final AIService _ai = AIService();
  final SettingsService _settings = SettingsService();

  Project? _project;
  Project? get project => _project;

  Duration _playhead = Duration.zero;
  Duration get playhead => _playhead;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  String? _selectedClipId;
  String? get selectedClipId => _selectedClipId;

  String? _selectedTrackId;
  String? get selectedTrackId => _selectedTrackId;

  VideoPlayerController? _videoController;
  VideoPlayerController? get videoController => _videoController;

  double _zoom = 1.0;
  double get zoom => _zoom;

  bool _touchMode = false;
  bool get touchMode => _touchMode;

  AIConfig _aiConfig = AIConfig();
  AIConfig get aiConfig => _aiConfig;

  bool _isExporting = false;
  bool get isExporting => _isExporting;
  double _exportProgress = 0;
  double get exportProgress => _exportProgress;

  final Uuid _uuid = const Uuid();

  Future<void> init() async {
    _touchMode = await _settings.isTouchMode();
    _aiConfig = await _settings.loadAIConfig();
    notifyListeners();
  }

  Future<Project> createNewProject({String name = '未命名项目'}) async {
    final now = DateTime.now();
    _project = Project(
      id: _uuid.v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      tracks: [
        Track(id: _uuid.v4(), name: '视频轨道 1', type: TrackType.video),
        Track(id: _uuid.v4(), name: '视频轨道 2', type: TrackType.video),
        Track(id: _uuid.v4(), name: '音频轨道 1', type: TrackType.audio),
      ],
      width: 1920,
      height: 1080,
      fps: 30,
    );
    _playhead = Duration.zero;
    _selectedClipId = null;
    await _saveDraft();
    notifyListeners();
    return _project!;
  }

  Future<void> loadProject(Project p) async {
    _project = p;
    _playhead = Duration.zero;
    _selectedClipId = null;
    await _settings.setLastProjectId(p.id);
    notifyListeners();
  }

  Future<void> _saveDraft() async {
    if (_project != null) {
      await _storage.saveDraft(_project!);
    }
  }

  Future<void> autoSave() async {
    await _saveDraft();
  }

  // Clip operations
  Future<void> addVideoClip(String filePath, String name, Duration sourceDuration) async {
    if (_project == null) return;
    final track = _project!.videoTracks.first;
    final clip = Clip(
      id: _uuid.v4(),
      type: ClipType.video,
      filePath: filePath,
      name: name,
      startTime: _playhead,
      duration: sourceDuration,
      sourceStart: Duration.zero,
      sourceDuration: sourceDuration,
    );
    track.addClip(clip);
    _project!.recalculateDuration();
    _selectedClipId = clip.id;
    _selectedTrackId = track.id;
    await _saveDraft();
    notifyListeners();
  }

  Future<void> addAudioClip(String filePath, String name, Duration sourceDuration) async {
    if (_project == null) return;
    final track = _project!.audioTracks.first;
    final clip = Clip(
      id: _uuid.v4(),
      type: ClipType.audio,
      filePath: filePath,
      name: name,
      startTime: _playhead,
      duration: sourceDuration,
      sourceStart: Duration.zero,
      sourceDuration: sourceDuration,
    );
    track.addClip(clip);
    _project!.recalculateDuration();
    _selectedClipId = clip.id;
    await _saveDraft();
    notifyListeners();
  }

  Future<void> addColorClip(int color, String name) async {
    if (_project == null) return;
    final track = _project!.videoTracks.first;
    final clip = Clip(
      id: _uuid.v4(),
      type: ClipType.color,
      filePath: '',
      name: name,
      startTime: _playhead,
      duration: const Duration(seconds: 5),
      sourceStart: Duration.zero,
      sourceDuration: const Duration(seconds: 5),
      colorValue: color,
    );
    track.addClip(clip);
    _project!.recalculateDuration();
    _selectedClipId = clip.id;
    await _saveDraft();
    notifyListeners();
  }

  void selectClip(String? clipId) {
    _selectedClipId = clipId;
    notifyListeners();
  }

  Clip? get selectedClip {
    if (_project == null || _selectedClipId == null) return null;
    for (final track in _project!.tracks) {
      for (final clip in track.clips) {
        if (clip.id == _selectedClipId) return clip;
      }
    }
    return null;
  }

  Future<void> splitClipAtPlayhead() async {
    final clip = selectedClip;
    if (clip == null || _project == null) return;
    if (_playhead <= clip.startTime || _playhead >= clip.endTime) return;

    final splitOffset = _playhead - clip.startTime;
    final newDuration = clip.duration - splitOffset;
    final newSourceStart = clip.sourceStart + splitOffset;

    // Shorten original
    final originalTrack = _project!.tracks.firstWhere((t) => t.clips.any((c) => c.id == clip.id));
    clip.duration = splitOffset;

    // Create new clip
    final newClip = Clip(
      id: _uuid.v4(),
      type: clip.type,
      filePath: clip.filePath,
      name: '${clip.name} (分割)',
      startTime: _playhead,
      duration: newDuration,
      sourceStart: newSourceStart,
      sourceDuration: clip.sourceDuration,
      volume: clip.volume,
      scale: clip.scale,
      positionX: clip.positionX,
      positionY: clip.positionY,
      opacity: clip.opacity,
      rotation: clip.rotation,
      colorValue: clip.colorValue,
    );
    originalTrack.addClip(newClip);
    _selectedClipId = newClip.id;
    _project!.recalculateDuration();
    await _saveDraft();
    notifyListeners();
  }

  Future<void> deleteSelectedClip() async {
    if (_selectedClipId == null || _project == null) return;
    for (final track in _project!.tracks) {
      track.removeClip(_selectedClipId!);
    }
    _selectedClipId = null;
    _project!.recalculateDuration();
    await _saveDraft();
    notifyListeners();
  }

  Future<void> moveClip(String clipId, Duration newStart) async {
    if (_project == null) return;
    for (final track in _project!.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) {
          clip.startTime = newStart;
        }
      }
      track.clips.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    _project!.recalculateDuration();
    await _saveDraft();
    notifyListeners();
  }

  Future<void> trimClipStart(String clipId, Duration newSourceStart) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    final delta = newSourceStart - clip.sourceStart;
    if (delta >= clip.duration) return;
    clip.sourceStart = newSourceStart;
    clip.startTime += delta;
    clip.duration -= delta;
    _project!.recalculateDuration();
    await _saveDraft();
    notifyListeners();
  }

  Future<void> trimClipEnd(String clipId, Duration newDuration) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    clip.duration = newDuration;
    _project!.recalculateDuration();
    await _saveDraft();
    notifyListeners();
  }

  Clip? _findClip(String clipId) {
    if (_project == null) return null;
    for (final track in _project!.tracks) {
      for (final clip in track.clips) {
        if (clip.id == clipId) return clip;
      }
    }
    return null;
  }

  // Property updates
  Future<void> updateClipProperty(String clipId, {
    double? scale,
    double? positionX,
    double? positionY,
    double? opacity,
    double? rotation,
    double? volume,
  }) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    if (scale != null) clip.scale = scale;
    if (positionX != null) clip.positionX = positionX;
    if (positionY != null) clip.positionY = positionY;
    if (opacity != null) clip.opacity = opacity;
    if (rotation != null) clip.rotation = rotation;
    if (volume != null) clip.volume = volume;
    await _saveDraft();
    notifyListeners();
  }

  // Keyframes
  Future<void> addKeyframe(String clipId, KeyframeProperty property, double value) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    // Remove existing keyframe at same time+property
    clip.keyframes.removeWhere((k) => k.time == _playhead && k.property == property);
    clip.keyframes.add(Keyframe(
      id: _uuid.v4(),
      time: _playhead,
      property: property,
      value: value,
    ));
    clip.keyframes.sort((a, b) => a.time.compareTo(b.time));
    await _saveDraft();
    notifyListeners();
  }

  Future<void> removeKeyframe(String clipId, String keyframeId) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    clip.keyframes.removeWhere((k) => k.id == keyframeId);
    await _saveDraft();
    notifyListeners();
  }

  // Chroma key
  Future<void> setChromaKey(String clipId, int color, double threshold, double softness) async {
    final clip = _findClip(clipId);
    if (clip == null) return;
    clip.chromaKey = ChromaKeyConfig(color: color, threshold: threshold, softness: softness);
    await _saveDraft();
    notifyListeners();
  }

  Future<void> toggleChromaKey(String clipId) async {
    final clip = _findClip(clipId);
    if (clip == null || clip.chromaKey == null) return;
    clip.chromaKey = ChromaKeyConfig(
      color: clip.chromaKey!.color,
      threshold: clip.chromaKey!.threshold,
      softness: clip.chromaKey!.softness,
      enabled: !clip.chromaKey!.enabled,
    );
    await _saveDraft();
    notifyListeners();
  }

  // Playback
  void setPlayhead(Duration time) {
    if (_project == null) return;
    _playhead = Duration(milliseconds: time.inMilliseconds.clamp(0, _project!.totalDuration.inMilliseconds));
    _seekVideoToPlayhead();
    notifyListeners();
  }

  void stepFrame(int frames) {
    if (_project == null) return;
    final frameDuration = Duration(milliseconds: (1000 / _project!.fps).round());
    setPlayhead(_playhead + frameDuration * frames);
  }

  Future<void> _seekVideoToPlayhead() async {
    final clip = _currentVideoClip();
    if (clip == null || clip.type != ClipType.video) {
      await _videoController?.pause();
      return;
    }
    final clipTime = _playhead - clip.startTime + clip.sourceStart;
    if (_videoController != null && _videoController!.value.isInitialized) {
      await _videoController!.seekTo(clipTime);
    }
  }

  Clip? _currentVideoClip() {
    if (_project == null) return null;
    for (final track in _project!.videoTracks) {
      final clip = track.findClipAt(_playhead);
      if (clip != null) return clip;
    }
    return null;
  }

  Future<void> prepareVideoPreview(String filePath) async {
    await _videoController?.dispose();
    _videoController = VideoPlayerController.file(File(filePath));
    try {
      await _videoController!.initialize();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_videoController == null) return;
    if (_isPlaying) {
      await _videoController!.pause();
    } else {
      await _videoController!.play();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void setZoom(double z) {
    _zoom = z.clamp(0.25, 8.0);
    notifyListeners();
  }

  // Tracks
  Future<void> addTrack(TrackType type) async {
    if (_project == null) return;
    final count = type == TrackType.video ? _project!.videoTracks.length : _project!.audioTracks.length;
    final track = Track(
      id: _uuid.v4(),
      name: '${type == TrackType.video ? "视频" : "音频"}轨道 ${count + 1}',
      type: type,
    );
    _project!.tracks.add(track);
    await _saveDraft();
    notifyListeners();
  }

  Future<void> toggleTrackMute(String trackId) async {
    if (_project == null) return;
    final track = _project!.tracks.firstWhere((t) => t.id == trackId);
    track.isMuted = !track.isMuted;
    await _saveDraft();
    notifyListeners();
  }

  Future<void> toggleTrackVisible(String trackId) async {
    if (_project == null) return;
    final track = _project!.tracks.firstWhere((t) => t.id == trackId);
    track.isVisible = !track.isVisible;
    await _saveDraft();
    notifyListeners();
  }

  // AI
  Future<void> updateAIConfig(AIConfig config) async {
    _aiConfig = config;
    await _settings.saveAIConfig(config);
    notifyListeners();
  }

  Future<AIInstruction> runAIEdit(String prompt) async {
    final context = _project != null ? _project!.toJsonString() : null;
    return _ai.generateEdit(_aiConfig, prompt, projectContext: context);
  }

  Future<void> executeAICommands(AIInstruction instruction) async {
    for (final cmd in instruction.commands) {
      await _executeAICommand(cmd);
    }
    await _saveDraft();
    notifyListeners();
  }

  Future<void> _executeAICommand(AICommand cmd) async {
    switch (cmd.action) {
      case 'add_clip':
        final trackType = cmd.params['track_type'] == 'audio' ? TrackType.audio : TrackType.video;
        final track = trackType == TrackType.video
            ? _project!.videoTracks.first
            : _project!.audioTracks.first;
        final clip = Clip(
          id: _uuid.v4(),
          type: trackType == TrackType.video ? ClipType.video : ClipType.audio,
          filePath: cmd.params['file_path'] ?? '',
          name: cmd.params['name'] ?? 'AI素材',
          startTime: Duration(milliseconds: cmd.params['start_time_ms'] ?? 0),
          duration: Duration(milliseconds: cmd.params['duration_ms'] ?? 5000),
          sourceStart: Duration(milliseconds: cmd.params['source_start_ms'] ?? 0),
          sourceDuration: Duration(milliseconds: cmd.params['duration_ms'] ?? 5000),
        );
        track.addClip(clip);
        break;
      case 'split_clip':
        final clip = _findClip(cmd.params['clip_id'] ?? '');
        if (clip != null) {
          _playhead = Duration(milliseconds: cmd.params['time_ms'] ?? 0);
          await splitClipAtPlayhead();
        }
        break;
      case 'delete_clip':
        for (final t in _project!.tracks) {
          t.removeClip(cmd.params['clip_id'] ?? '');
        }
        break;
      case 'move_clip':
        await moveClip(cmd.params['clip_id'] ?? '', Duration(milliseconds: cmd.params['new_start_ms'] ?? 0));
        break;
      case 'set_clip_property':
        final prop = cmd.params['property'];
        final value = (cmd.params['value'] as num).toDouble();
        await updateClipProperty(cmd.params['clip_id'] ?? '',
          scale: prop == 'scale' ? value : null,
          positionX: prop == 'positionX' ? value : null,
          positionY: prop == 'positionY' ? value : null,
          opacity: prop == 'opacity' ? value : null,
          rotation: prop == 'rotation' ? value : null,
          volume: prop == 'volume' ? value : null,
        );
        break;
      case 'add_keyframe':
        _playhead = Duration(milliseconds: cmd.params['time_ms'] ?? 0);
        await addKeyframe(
          cmd.params['clip_id'] ?? '',
          KeyframeProperty.values.firstWhere((e) => e.name == cmd.params['property'], orElse: () => KeyframeProperty.scale),
          (cmd.params['value'] as num).toDouble(),
        );
        break;
      case 'add_chroma_key':
        await setChromaKey(
          cmd.params['clip_id'] ?? '',
          cmd.params['color_hex'] ?? 0xFF00FF00,
          (cmd.params['threshold'] as num?)?.toDouble() ?? 0.3,
          (cmd.params['softness'] as num?)?.toDouble() ?? 0.1,
        );
        break;
      case 'add_track':
        await addTrack(cmd.params['type'] == 'audio' ? TrackType.audio : TrackType.video);
        break;
      case 'set_project_resolution':
        if (_project != null) {
          _project!.width = cmd.params['width'] ?? 1920;
          _project!.height = cmd.params['height'] ?? 1080;
          _project!.fps = cmd.params['fps'] ?? 30;
        }
        break;
    }
    _project?.recalculateDuration();
  }

  // Export
  Future<String> exportVideo(ExportSettings settings) async {
    if (_project == null) throw Exception('没有项目');
    _isExporting = true;
    _exportProgress = 0;
    notifyListeners();
    try {
      final path = await _ffmpeg.exportProject(_project!, settings,
        onProgress: (p) {
          _exportProgress = p;
          notifyListeners();
        },
      );
      return path;
    } finally {
      _isExporting = false;
      notifyListeners();
    }
  }

  Future<void> setTouchMode(bool enabled) async {
    _touchMode = enabled;
    await _settings.setTouchMode(enabled);
    notifyListeners();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
}
