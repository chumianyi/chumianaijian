import 'track.dart';
import 'dart:convert';

class Project {
  final String id;
  String name;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<Track> tracks;
  Duration totalDuration;
  int width;
  int height;
  int fps;
  String? thumbnailPath;

  Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    List<Track>? tracks,
    this.totalDuration = Duration.zero,
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.thumbnailPath,
  }) : tracks = tracks ?? [];

  List<Track> get videoTracks => tracks.where((t) => t.type == TrackType.video).toList();
  List<Track> get audioTracks => tracks.where((t) => t.type == TrackType.audio).toList();

  void recalculateDuration() {
    Duration maxEnd = Duration.zero;
    for (final track in tracks) {
      for (final clip in track.clips) {
        if (clip.endTime > maxEnd) maxEnd = clip.endTime;
      }
    }
    totalDuration = maxEnd;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tracks': tracks.map((t) => t.toJson()).toList(),
    'totalDurationMs': totalDuration.inMilliseconds,
    'width': width,
    'height': height,
    'fps': fps,
    'thumbnailPath': thumbnailPath,
  };

  factory Project.fromJson(Map<String, dynamic> json) => Project(
    id: json['id'],
    name: json['name'] ?? '未命名项目',
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
    tracks: (json['tracks'] as List?)?.map((t) => Track.fromJson(t)).toList() ?? [],
    totalDuration: Duration(milliseconds: json['totalDurationMs'] ?? 0),
    width: json['width'] ?? 1920,
    height: json['height'] ?? 1080,
    fps: json['fps'] ?? 30,
    thumbnailPath: json['thumbnailPath'],
  );

  String toJsonString() => jsonEncode(toJson());
  factory Project.fromJsonString(String str) => Project.fromJson(jsonDecode(str));
}
