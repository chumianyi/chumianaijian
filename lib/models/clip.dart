import 'dart:ui' show Offset;
import 'keyframe.dart';

enum ClipType { video, image, audio, color, text }

class Clip {
  final String id;
  final ClipType type;
  String filePath;
  String name;
  Duration startTime; // position on timeline
  Duration duration; // visible duration
  Duration sourceStart; // trim start in source
  Duration sourceDuration; // total source duration
  double volume;
  double speed;
  double scale;
  double positionX;
  double positionY;
  double opacity;
  double rotation;
  int? colorValue; // for color clips
  String? textContent;
  List<Keyframe> keyframes;
  ChromaKeyConfig? chromaKey;
  MaskConfig? mask;
  double? borderRadius;

  Clip({
    required this.id,
    required this.type,
    required this.filePath,
    required this.name,
    required this.startTime,
    required this.duration,
    required this.sourceStart,
    required this.sourceDuration,
    this.volume = 1.0,
    this.speed = 1.0,
    this.scale = 1.0,
    this.positionX = 0,
    this.positionY = 0,
    this.opacity = 1.0,
    this.rotation = 0,
    this.colorValue,
    this.textContent,
    List<Keyframe>? keyframes,
    this.chromaKey,
    this.mask,
    this.borderRadius,
  }) : keyframes = keyframes ?? [];

  Duration get endTime => startTime + duration;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'filePath': filePath,
    'name': name,
    'startTimeMs': startTime.inMilliseconds,
    'durationMs': duration.inMilliseconds,
    'sourceStartMs': sourceStart.inMilliseconds,
    'sourceDurationMs': sourceDuration.inMilliseconds,
    'volume': volume,
    'speed': speed,
    'scale': scale,
    'positionX': positionX,
    'positionY': positionY,
    'opacity': opacity,
    'rotation': rotation,
    'colorValue': colorValue,
    'textContent': textContent,
    'keyframes': keyframes.map((k) => k.toJson()).toList(),
    'chromaKey': chromaKey?.toJson(),
    'mask': mask?.toJson(),
    'borderRadius': borderRadius,
  };

  factory Clip.fromJson(Map<String, dynamic> json) => Clip(
    id: json['id'],
    type: ClipType.values.firstWhere((e) => e.name == json['type']),
    filePath: json['filePath'] ?? '',
    name: json['name'] ?? '',
    startTime: Duration(milliseconds: json['startTimeMs'] ?? 0),
    duration: Duration(milliseconds: json['durationMs'] ?? 0),
    sourceStart: Duration(milliseconds: json['sourceStartMs'] ?? 0),
    sourceDuration: Duration(milliseconds: json['sourceDurationMs'] ?? 0),
    volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
    speed: (json['speed'] as num?)?.toDouble() ?? 1.0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
    positionX: (json['positionX'] as num?)?.toDouble() ?? 0,
    positionY: (json['positionY'] as num?)?.toDouble() ?? 0,
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
    colorValue: json['colorValue'],
    textContent: json['textContent'],
    keyframes: (json['keyframes'] as List?)?.map((k) => Keyframe.fromJson(k)).toList() ?? [],
    chromaKey: json['chromaKey'] != null ? ChromaKeyConfig.fromJson(json['chromaKey']) : null,
    mask: json['mask'] != null ? MaskConfig.fromJson(json['mask']) : null,
    borderRadius: (json['borderRadius'] as num?)?.toDouble(),
  );

  Clip copyWith({
    Duration? startTime,
    Duration? duration,
    Duration? sourceStart,
    double? volume,
    double? speed,
    double? scale,
    double? positionX,
    double? positionY,
    double? opacity,
    double? rotation,
  }) => Clip(
    id: id,
    type: type,
    filePath: filePath,
    name: name,
    startTime: startTime ?? this.startTime,
    duration: duration ?? this.duration,
    sourceStart: sourceStart ?? this.sourceStart,
    sourceDuration: sourceDuration,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
    scale: scale ?? this.scale,
    positionX: positionX ?? this.positionX,
    positionY: positionY ?? this.positionY,
    opacity: opacity ?? this.opacity,
    rotation: rotation ?? this.rotation,
    colorValue: colorValue,
    textContent: textContent,
    keyframes: keyframes,
    chromaKey: chromaKey,
    mask: mask,
    borderRadius: borderRadius,
  );
}

class ChromaKeyConfig {
  final int color;
  final double threshold;
  final double softness;
  final bool enabled;

  ChromaKeyConfig({
    this.color = 0xFF00FF00,
    this.threshold = 0.3,
    this.softness = 0.1,
    this.enabled = true,
  });

  Map<String, dynamic> toJson() => {
    'color': color,
    'threshold': threshold,
    'softness': softness,
    'enabled': enabled,
  };

  factory ChromaKeyConfig.fromJson(Map<String, dynamic> json) => ChromaKeyConfig(
    color: json['color'] ?? 0xFF00FF00,
    threshold: (json['threshold'] as num?)?.toDouble() ?? 0.3,
    softness: (json['softness'] as num?)?.toDouble() ?? 0.1,
    enabled: json['enabled'] ?? true,
  );
}

class MaskConfig {
  final List<Offset> points;
  final double feather;
  final bool invert;
  final bool enabled;

  MaskConfig({
    List<Offset>? points,
    this.feather = 0.0,
    this.invert = false,
    this.enabled = false,
  }) : points = points ?? [];

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    'feather': feather,
    'invert': invert,
    'enabled': enabled,
  };

  factory MaskConfig.fromJson(Map<String, dynamic> json) => MaskConfig(
    points: (json['points'] as List?)?.map((p) => Offset((p['dx'] as num?)?.toDouble() ?? 0, (p['dy'] as num?)?.toDouble() ?? 0)).toList() ?? [],
    feather: (json['feather'] as num?)?.toDouble() ?? 0.0,
    invert: json['invert'] ?? false,
    enabled: json['enabled'] ?? false,
  );
}
