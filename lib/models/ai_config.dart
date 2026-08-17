class AIConfig {
  String apiBaseUrl;
  String apiKey;
  String modelName;
  String customHeaders;
  double temperature;
  int maxTokens;
  bool enabled;

  AIConfig({
    this.apiBaseUrl = 'https://api.openai.com/v1',
    this.apiKey = '',
    this.modelName = 'gpt-4o',
    this.customHeaders = '',
    this.temperature = 0.7,
    this.maxTokens = 4096,
    this.enabled = false,
  });

  Map<String, dynamic> toJson() => {
    'apiBaseUrl': apiBaseUrl,
    'apiKey': apiKey,
    'modelName': modelName,
    'customHeaders': customHeaders,
    'temperature': temperature,
    'maxTokens': maxTokens,
    'enabled': enabled,
  };

  factory AIConfig.fromJson(Map<String, dynamic> json) => AIConfig(
    apiBaseUrl: json['apiBaseUrl'] ?? 'https://api.openai.com/v1',
    apiKey: json['apiKey'] ?? '',
    modelName: json['modelName'] ?? 'gpt-4o',
    customHeaders: json['customHeaders'] ?? '',
    temperature: (json['temperature'] as num?)?.toDouble() ?? 0.7,
    maxTokens: json['maxTokens'] ?? 4096,
    enabled: json['enabled'] ?? false,
  );
}

class AICommand {
  final String action;
  final Map<String, dynamic> params;

  AICommand({required this.action, required this.params});

  factory AICommand.fromJson(Map<String, dynamic> json) => AICommand(
    action: json['action'] ?? '',
    params: json['params'] ?? {},
  );
}

class AIInstruction {
  final List<AICommand> commands;
  final String description;

  AIInstruction({required this.commands, this.description = ''});

  factory AIInstruction.fromJson(Map<String, dynamic> json) => AIInstruction(
    commands: (json['commands'] as List?)?.map((c) => AICommand.fromJson(c)).toList() ?? [],
    description: json['description'] ?? '',
  );
}
