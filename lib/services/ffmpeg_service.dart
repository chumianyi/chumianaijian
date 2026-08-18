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
    final safeName = project.name.replaceAll(RegExp(r'[^\w\u4e00-\u9fa5]'), '_');
    final outputPath = '$exportDir/${safeName}_${DateTime.now().millisecondsSinceEpoch}.${settings.format}';

    project.recalculateDuration();
    final totalDuration = project.totalDuration.inMilliseconds / 1000.0;
    if (totalDuration <= 0) {
      throw Exception('项目时长为0，请先添加素材');
    }

    final videoTracks = project.videoTracks.where((t) => t.isVisible).toList();
    final audioTracks = project.audioTracks.where((t) => !t.isMuted).toList();

    final videoInputs = <_VideoInput>[];
    for (final track in videoTracks) {
      for (final clip in track.clips) {
        if (clip.type == ClipType.color || clip.type == ClipType.video || clip.type == ClipType.image) {
          videoInputs.add(_VideoInput(clip: clip, trackIndex: videoTracks.indexOf(track)));
        }
      }
    }

    final audioInputs = <_AudioInput>[];
    for (final track in audioTracks) {
      for (final clip in track.clips) {
        if (clip.type == ClipType.audio && clip.filePath.isNotEmpty && File(clip.filePath).existsSync()) {
          audioInputs.add(_AudioInput(clip: clip));
        }
      }
    }

    final args = <String>[];
    final filterParts = <String>[];
    int inputIdx = 0;

    for (final vi in videoInputs) {
      final clip = vi.clip;
      final dur = (clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
      if (clip.type == ClipType.color) {
        final hex = _colorToHex(clip.colorValue ?? 0xFF000000);
        args.addAll(['-f', 'lavfi', '-i', 'color=c=$hex:s=${settings.width}x${settings.height}:d=$dur']);
      } else if (clip.filePath.isNotEmpty && File(clip.filePath).existsSync()) {
        args.addAll([
          '-ss', (clip.sourceStart.inMilliseconds / 1000).toStringAsFixed(3),
          '-t', dur,
          '-i', clip.filePath,
        ]);
      } else {
        args.addAll(['-f', 'lavfi', '-i', 'color=c=black:s=${settings.width}x${settings.height}:d=$dur']);
      }
      inputIdx++;
    }

    if (videoInputs.isEmpty) {
      args.addAll(['-f', 'lavfi', '-i', 'color=c=black:s=${settings.width}x${settings.height}:d=$totalDuration']);
      inputIdx++;
    }

    for (final ai in audioInputs) {
      final clip = ai.clip;
      final dur = (clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
      args.addAll([
        '-ss', (clip.sourceStart.inMilliseconds / 1000).toStringAsFixed(3),
        '-t', dur,
        '-i', clip.filePath,
      ]);
      inputIdx++;
    }

    String? lastVideoLabel;
    for (int i = 0; i < videoInputs.length; i++) {
      final clip = videoInputs[i].clip;
      var label = '[$i:v]';
      final transforms = <String>[];

      if (clip.scale != 1.0) {
        final sw = (settings.width * clip.scale).round();
        final sh = (settings.height * clip.scale).round();
        transforms.add('scale=$sw:$sh');
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
        final outL = 'vf$i';
        filterParts.add('$label${transforms.join(',')}[$outL]');
        label = '[$outL]';
      }

      final delay = clip.startTime.inMilliseconds / 1000.0;
      final delayedL = 'vd$i';
      filterParts.add('${label}setpts=PTS+$delay/TB[$delayedL]');
      label = '[$delayedL]';

      if (lastVideoLabel == null) {
        lastVideoLabel = label;
      } else {
        final ovL = 'ov$i';
        final x = (settings.width * (0.5 + clip.positionX / 2) - settings.width * clip.scale / 2).round();
        final y = (settings.height * (0.5 + clip.positionY / 2) - settings.height * clip.scale / 2).round();
        final endT = (delay + clip.duration.inMilliseconds / 1000).toStringAsFixed(3);
        filterParts.add('$lastVideoLabel${label}overlay=x=$x:y=$y:enable=between(t\\,${delay.toStringAsFixed(3)}\\,$endT)[$ovL]');
        lastVideoLabel = '[$ovL]';
      }
    }

    if (lastVideoLabel == null) {
      lastVideoLabel = '[0:v]';
    }
    filterParts.add('${lastVideoLabel}trim=duration=$totalDuration,setpts=PTS-STARTPTS[vout]');

    final audioLabels = <String>[];
    int audioBaseIdx = videoInputs.isEmpty ? 1 : videoInputs.length;
    for (int i = 0; i < audioInputs.length; i++) {
      final clip = audioInputs[i].clip;
      final idx = audioBaseIdx + i;
      final delay = clip.startTime.inMilliseconds.round();
      final aL = 'af$i';
      filterParts.add('[$idx:a]adelay=$delay|$delay,volume=${clip.volume}[$aL]');
      audioLabels.add('[$aL]');
    }

    String audioMapArg = '';
    if (audioLabels.isNotEmpty) {
      filterParts.add('${audioLabels.join()}amix=inputs=${audioLabels.length}:duration=longest[aout]');
      audioMapArg = '[aout]';
    } else {
      args.addAll(['-f', 'lavfi', '-i', 'anullsrc=r=44100:cl=stereo']);
      audioMapArg = '${inputIdx}:a';
    }

    final filterComplex = filterParts.join(';');
    final fullArgs = <String>[
      ...args,
      '-filter_complex', filterComplex,
      '-map', '[vout]',
      '-map', audioMapArg,
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-crf', '23',
      '-b:v', '${settings.videoBitrate}k',
      '-r', '${settings.fps}',
      '-s', '${settings.width}x${settings.height}',
      '-pix_fmt', 'yuv420p',
      '-c:a', 'aac',
      '-b:a', '${settings.audioBitrate}k',
      '-ar', '44100',
      '-movflags', '+faststart',
      '-y',
      outputPath,
    ];

    onLog?.call('FFmpeg args count: ${fullArgs.length}');
    onProgress?.call(0.0);

    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(fullArgs, (session) async {
        final rc = await session.getReturnCode();
        onLog?.call('FFmpeg finished: ${ReturnCode.isSuccess(rc) ? "SUCCESS" : "FAIL rc=$rc"}');
      }, (log) {
        onLog?.call(log.getMessage());
      }, (stats) {
        if (totalDuration > 0 && stats.getTime() > 0) {
          final p = (stats.getTime() / 1000000) / totalDuration;
          onProgress?.call(p.clamp(0.0, 0.99));
        }
      });

      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        onProgress?.call(1.0);
        final outFile = File(outputPath);
        if (await outFile.exists() && await outFile.length() > 1000) {
          return outputPath;
        } else {
          throw Exception('输出文件不存在或大小异常');
        }
      } else {
        final fail = await session.getFailStackTrace();
        final output = await session.getOutput();
        throw Exception('FFmpeg失败: rc=$returnCode\n$fail\n$output');
      }
    } catch (e) {
      onLog?.call('Exception: $e');
      rethrow;
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
    try {
      final session = await FFmpegKit.executeWithArguments(['-i', filePath, '-f', 'null', '-']);
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
    } catch (_) {}
    if (info['duration'] == null) {
      info['duration'] = const Duration(seconds: 10);
    }
    return info;
  }
}

class _VideoInput {
  final Clip clip;
  final int trackIndex;
  _VideoInput({required this.clip, required this.trackIndex});
}

class _AudioInput {
  final Clip clip;
  _AudioInput({required this.clip});
}
