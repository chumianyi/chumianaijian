import 'clip.dart';

enum TrackType { video, audio, effect, text }

class Track {
  final String id;
  final String name;
  final TrackType type;
  final List<Clip> clips;
  bool isMuted;
  bool isLocked;
  bool isVisible;

  Track({
    required this.id,
    required this.name,
    required this.type,
    List<Clip>? clips,
    this.isMuted = false,
    this.isLocked = false,
    this.isVisible = true,
  }) : clips = clips ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'clips': clips.map((c) => c.toJson()).toList(),
    'isMuted': isMuted,
    'isLocked': isLocked,
    'isVisible': isVisible,
  };

  factory Track.fromJson(Map<String, dynamic> json) => Track(
    id: json['id'],
    name: json['name'] ?? '',
    type: TrackType.values.firstWhere((e) => e.name == json['type'], orElse: () => TrackType.video),
    clips: (json['clips'] as List?)?.map((c) => Clip.fromJson(c)).toList() ?? [],
    isMuted: json['isMuted'] ?? false,
    isLocked: json['isLocked'] ?? false,
    isVisible: json['isVisible'] ?? true,
  );

  void addClip(Clip clip) {
    clips.add(clip);
    clips.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void removeClip(String clipId) {
    clips.removeWhere((c) => c.id == clipId);
  }

  Clip? findClipAt(Duration time) {
    for (final clip in clips) {
      if (time >= clip.startTime && time < clip.endTime) return clip;
    }
    return null;
  }
}
