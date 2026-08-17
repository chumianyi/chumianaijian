import 'dart:io';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import '../models/project.dart';
import '../models/clip.dart';
import '../models/track.dart';
import 'project_storage.dart';

class ExportSettings {
  final int width;
  final int height;
  final int fps;
  final int videoBitrate;
  final int audioBitrate;
  final String format;

  ExportSettings({
    this.width = 1920,
    this.height = 1080,
    this.fps = 30,
    this.videoBitrate = 8000,
    this.audioBitrate = 192,
    this.format = 'mp4',
  });
}

class FFmpegService {
  final ProjectStorage _storage = ProjectStorage();

  Future<String> exportProject(Project project, ExportSettings settings, {
    Function(double progress)? onProgress,
    Function(String log)? onLog,
  }) async {
    final exportDir = await _storage.getExportDirectory();
    final outputPath = '$exportDir/${project.name}_${DateTime.now().millisecondsSinceEpoch}.${settings.format}';

    project.recalculateDuration();
    final totalDuration = project.totalDuration.inMilliseconds / 1000.0;
    if (totalDuration <= 0) {
      throw Exception('项目时长为0，请先添加素材');
    }

    final videoTracks = project.videoTracks.where((t) => t.isVisible).toList();
    final audioTracks = project.audioTracks.where((t) => !t.isMuted).toList();

    final inputs = <String>[];
    final filterParts = <String>[];
    int inputIndex = 0;

    String? lastVideoLabel;
    for (final track in videoTracks) {
      for (final clip in track.clips) {
        final clipDur = (clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
        if (clip.type == ClipType.color) {
          final colorHex = _colorToHex(clip.colorValue ?? 0xFF000000);
          inputs.addAll(['-f', 'lavfi', '-i', 'color=c=$colorHex:s=${settings.width}x${settings.height}:d=$clipDur']);
        } else if (clip.type == ClipType.video || clip.type == ClipType.image) {
          if (File(clip.filePath).existsSync()) {
            inputs.addAll([
              '-ss', (clip.sourceStart.inMilliseconds / 1000).toStringAsFixed(3),
              '-t', clipDur,
              '-i', clip.filePath,
            ]);
          } else {
            inputs.addAll(['-f', 'lavfi', '-i', 'color=c=black:s=${settings.width}x${settings.height}:d=$clipDur']);
          }
        } else {
          continue;
        }

        final idx = inputIndex++;
        var label = '[$idx:v]';

        final transforms = <String>[];
        if (clip.scale != 1.0) {
          final scaleW = (settings.width * clip.scale).round();
          final scaleH = (settings.height * clip.scale).round();
          transforms.add('scale=$scaleW:$scaleH');
        }
        if (clip.rotation != 0) {
          transforms.add('rotate=${clip.rotation}*PI/180');
        }
        if (clip.opacity < 1.0) {
          transforms.add('format=rgba,colorchannelmixer=aa=${clip.opacity}');
        }
        if (clip.chromaKey != null && clip.chromaKey!.enabled) {
          final keyColor = _colorToHex(clip.chromaKey!.color);
          transforms.add('colorkey=$keyColor:${clip.chromaKey!.threshold}:${clip.chromaKey!.softness}');
        }
        if (transforms.isNotEmpty) {
          final outLabel = 'v${idx}f';
          filterParts.add('$label${transforms.join(',')}[$outLabel]');
          label = '[$outLabel]';
        }

        final delay = clip.startTime.inMilliseconds / 1000.0;
        final delayedLabel = 'v${idx}d';
        filterParts.add('${label}setpts=PTS+$delay/TB[$delayedLabel]');
        label = '[$delayedLabel]';

        if (lastVideoLabel == null) {
          lastVideoLabel = label;
        } else {
          final overlayLabel = 'ov$idx';
          final x = (settings.width * (0.5 + clip.positionX / 2) - settings.width * clip.scale / 2).round();
          final y = (settings.height * (0.5 + clip.positionY / 2) - settings.height * clip.scale / 2).round();
          final endT = (delay + clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
          filterParts.add('$lastVideoLabel${label}overlay=x=$x:y=$y:enable=between(t,${delay.toStringAsFixed(3)},$endT)[$overlayLabel]');
          lastVideoLabel = '[$overlayLabel]';
        }
      }
    }

    if (lastVideoLabel == null) {
      inputs.addAll(['-f', 'lavfi', '-i', 'color=c=black:s=${settings.width}x${settings.height}:d=$totalDuration']);
      lastVideoLabel = '[$inputIndex:v]';
      inputIndex++;
    }

    filterParts.add('${lastVideoLabel}trim=duration=$totalDuration,setpts=PTS-STARTPTS[vout]');

    final audioLabels = <String>[];
    int audioInputIdx = inputIndex;
    for (final track in audioTracks) {
      for (final clip in track.clips) {
        if (clip.type == ClipType.audio && File(clip.filePath).existsSync()) {
          final clipDur = (clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
          inputs.addAll([
            '-ss', (clip.sourceStart.inMilliseconds / 1000).toStringAsFixed(3),
            '-t', clipDur,
            '-i', clip.filePath,
          ]);
          final idx = audioInputIdx++;
          final delay = (clip.startTime.inMilliseconds).round();
          final aLabel = 'a$idx';
          filterParts.add('[$idx:a]adelay=$delay|$delay,volume=${clip.volume}[$aLabel]');
          audioLabels.add('[$aLabel]');
        }
      }
    }

    String audioMap = '';
    if (audioLabels.isNotEmpty) {
      filterParts.add('${audioLabels.join()}amix=inputs=${audioLabels.length}:duration=longest[aout]');
      audioMap = '-map [aout]';
    } else {
      inputs.addAll(['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo']);
      audioMap = '-map $audioInputIdx:a';
    }

    final filterComplex = filterParts.join(';');
    final cmdParts = <String>[
      ...inputs,
      '-filter_complex', filterComplex,
      '-map', '[vout]',
      ...audioMap.split(' '),
      '-c:v', 'libx264',
      '-preset', 'medium',
      '-crf', '23',
      '-b:v', '${settings.videoBitrate}k',
      '-r', '${settings.fps}',
      '-s', '${settings.width}x${settings.height}',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '${settings.audioBitrate}k',
      '-ar', '44100',
      '-y',
      outputPath,
    ];

    final command = cmdParts.map((p) => p.contains(' ') ? '"$p"' : p).join(' ');
    onLog?.call('FFmpeg: $command');

    final session = await FFmpegKit.executeAsync(command, (session) async {
      final rc = await session.getReturnCode();
      onLog?.call('Done: ${ReturnCode.isSuccess(rc) ? "OK" : "FAIL"}');
    }, (log) {
      onLog?.call(log.getMessage());
    }, (stats) {
      if (totalDuration > 0) {
        onProgress?.call((stats.getTime() / 1000000) / totalDuration);
      }
    });

    final returnCode = await session.getReturnCode();
    if (ReturnCode.isSuccess(returnCode)) {
      return outputPath;
    } else {
      final fail = await session.getFailStackTrace();
      throw Exception('Export failed: $fail');
    }
  }

  String _colorToHex(int color) {
    final r = (color >> 16) & 0xFF;
    final g = (color >> 8) & 0xFF;
    final b = color & 0xFF;
    return '0x${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
  }

  Future<Map<String, dynamic>> getVideoInfo(String filePath) async {
    final info = <String, dynamic>{};
    final session = await FFmpegKit.execute('-i "$filePath" -f null -');
    final output = await session.getOutput() ?? '';
    final durMatch = RegExp(r'Duration: (\d+):(\d+):(\d+\.\d+)').firstMatch(output);
    if (durMatch != null) {
      final h = int.parse(durMatch.group(1)!);
      final m = int.parse(durMatch.group(2)!);
      final s = double.parse(durMatch.group(3)!);
      info['duration'] = Duration(milliseconds: ((h * 3600 + m * 60 + s) * 1000).round());
    }
    final resMatch = RegExp(r'(\d{3,5})x(\d{3,5})').firstMatch(output);
    if (resMatch != null) {
      info['width'] = int.parse(resMatch.group(1)!);
      info['height'] = int.parse(resMatch.group(2)!);
    }
    if (info['duration'] == null) {
      info['duration'] = const Duration(seconds: 10);
    }
    return info;
  }
}
