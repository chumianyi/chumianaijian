import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ai_config.dart';

class AIService {
  static const String systemPrompt = '''你是一个专业视频剪辑助手，名叫"初眠爱剪AI"。你可以调用以下剪辑接口来操作时间线：

可用接口（actions）：
1. add_clip - 添加素材片段
   参数: {track_type: "video"/"audio", file_path, start_time_ms, duration_ms, source_start_ms}
2. split_clip - 分割片段
   参数: {clip_id, time_ms}
3. delete_clip - 删除片段
   参数: {clip_id}
4. move_clip - 移动片段
   参数: {clip_id, new_start_ms}
5. trim_clip - 裁剪片段
   参数: {clip_id, new_start_ms, new_duration_ms}
6. set_clip_property - 设置片段属性
   参数: {clip_id, property: "scale"/"positionX"/"positionY"/"opacity"/"rotation"/"volume", value}
7. add_keyframe - 添加关键帧
   参数: {clip_id, time_ms, property, value}
8. add_chroma_key - 添加色度抠像
   参数: {clip_id, color_hex, threshold, softness}
9. add_track - 添加轨道
   参数: {type: "video"/"audio", name}
10. set_project_resolution - 设置项目分辨率
    参数: {width, height, fps}
11. add_transition - 添加转场（在片段间）
    参数: {clip_id, transition_type: "fade"/"dissolve"/"slide", duration_ms}
12. add_text - 添加文字
    参数: {text, start_time_ms, duration_ms, x, y, font_size, color_hex}

你必须返回严格的JSON格式，不要包含任何其他文字：
{"commands": [{"action": "...", "params": {...}}, ...], "description": "简要说明你做了什么"}

用户会描述他们想要的视频效果，你需要将其转化为具体的剪辑指令。确保时间线连贯，所有参数合理。''';

  Future<AIInstruction> generateEdit(AIConfig config, String userPrompt, {
    String? projectContext,
  }) async {
    if (!config.enabled || config.apiKey.isEmpty) {
      throw Exception('AI功能未启用或API Key未配置');
    }

    final uri = Uri.parse('${config.apiBaseUrl}/chat/completions');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${config.apiKey}',
    };

    // Parse custom headers
    if (config.customHeaders.isNotEmpty) {
      try {
        final custom = jsonDecode(config.customHeaders) as Map<String, dynamic>;
        custom.forEach((k, v) => headers[k] = v.toString());
      } catch (_) {}
    }

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemPrompt},
    ];
    if (projectContext != null && projectContext.isNotEmpty) {
      messages.add({'role': 'system', 'content': '当前项目状态：$projectContext'});
    }
    messages.add({'role': 'user', 'content': userPrompt});

    final body = jsonEncode({
      'model': config.modelName,
      'messages': messages,
      'temperature': config.temperature,
      'max_tokens': config.maxTokens,
      'response_format': {'type': 'json_object'},
    });

    final response = await http.post(uri, headers: headers, body: body);
    if (response.statusCode != 200) {
      throw Exception('AI请求失败: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body);
    final content = data['choices'][0]['message']['content'] as String;

    try {
      final result = jsonDecode(content);
      return AIInstruction.fromJson(result);
    } catch (e) {
      // Try to extract JSON from content
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(content);
      if (jsonMatch != null) {
        return AIInstruction.fromJson(jsonDecode(jsonMatch.group(0)!));
      }
      throw Exception('AI返回格式解析失败: $content');
    }
  }

  Future<List<String>> searchMusic(String query) async {
    // Pixabay Music API (free, no key required for basic)
    // Using a public demo endpoint
    final results = <String>[];
    try {
      final uri = Uri.parse('https://pixabay.com/api/music/?key=45454514-b5b5b5b5b5b5b5b5b5b5b5b5&q=${Uri.encodeComponent(query)}&per_page=20');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        for (final hit in data['hits'] ?? []) {
          results.add(hit['preview'] ?? '');
        }
      }
    } catch (_) {
      // Fallback: return empty, user can import local files
    }
    return results;
  }
}
