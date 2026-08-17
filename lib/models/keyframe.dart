import 'package:flutter/material.dart';

enum KeyframeProperty { scale, positionX, positionY, opacity, rotation }

class Keyframe {
  final String id;
  final Duration time;
  final KeyframeProperty property;
  final double value;
  final Curve curve;

  Keyframe({
    required this.id,
    required this.time,
    required this.property,
    required this.value,
    this.curve = Curves.easeInOut,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'timeMs': time.inMilliseconds,
    'property': property.name,
    'value': value,
    'curve': curve.toString(),
  };

  factory Keyframe.fromJson(Map<String, dynamic> json) => Keyframe(
    id: json['id'],
    time: Duration(milliseconds: json['timeMs']),
    property: KeyframeProperty.values.firstWhere((e) => e.name == json['property']),
    value: (json['value'] as num).toDouble(),
    curve: Curves.easeInOut,
  );

  Keyframe copyWith({Duration? time, double? value, Curve? curve}) => Keyframe(
    id: id,
    time: time ?? this.time,
    property: property,
    value: value ?? this.value,
    curve: curve ?? this.curve,
  );
}

double interpolateKeyframes(List<Keyframe> keyframes, Duration currentTime, double defaultValue) {
  if (keyframes.isEmpty) return defaultValue;
  final sorted = List<Keyframe>.from(keyframes)..sort((a, b) => a.time.compareTo(b.time));
  if (currentTime <= sorted.first.time) return sorted.first.value;
  if (currentTime >= sorted.last.time) return sorted.last.value;
  for (int i = 0; i < sorted.length - 1; i++) {
    if (currentTime >= sorted[i].time && currentTime <= sorted[i + 1].time) {
      final t = (currentTime.inMilliseconds - sorted[i].time.inMilliseconds) /
          (sorted[i + 1].time.inMilliseconds - sorted[i].time.inMilliseconds);
      final curvedT = sorted[i].curve.transform(t.clamp(0.0, 1.0));
      return sorted[i].value + (sorted[i + 1].value - sorted[i].value) * curvedT;
    }
  }
  return defaultValue;
}
