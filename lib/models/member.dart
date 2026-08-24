/// AI工具类型
enum AiTool {
  codex('Codex'),
  claude('Claude'),
  openCode('OpenCode'),
  pi('PI'),
  goose('Goose'),
  cursor('Cursor'),
  zcode('Zcode'),
  traeCode('TraeCode'),
  codeBuudy('CodeBuudy');

  final String label;
  const AiTool(this.label);
}

/// 接入类型
enum AccessType {
  openaiChat('OpenAI Chat'),
  openaiResponse('OpenAI Response'),
  anthropic('Anthropic');

  final String label;
  const AccessType(this.label);
}

/// AI成员模型
class Member {
  final String id;
  String name;
  AiTool aiTool;
  AccessType accessType;
  String providerUrl;
  String apiKey;
  String modelId;
  String? sdkPath; // SDK路径（本地检测或手动配置）
  bool sdkConfigured;

  Member({
    required this.id,
    required this.name,
    required this.aiTool,
    required this.accessType,
    required this.providerUrl,
    required this.apiKey,
    required this.modelId,
    this.sdkPath,
    this.sdkConfigured = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'aiTool': aiTool.name,
    'accessType': accessType.name,
    'providerUrl': providerUrl,
    'apiKey': apiKey,
    'modelId': modelId,
    'sdkPath': sdkPath,
    'sdkConfigured': sdkConfigured,
  };

  factory Member.fromJson(Map<String, dynamic> json) => Member(
    id: json['id'] as String,
    name: json['name'] as String,
    aiTool: AiTool.values.firstWhere((e) => e.name == json['aiTool']),
    accessType: AccessType.values.firstWhere(
      (e) => e.name == json['accessType'],
    ),
    providerUrl: json['providerUrl'] as String,
    apiKey: json['apiKey'] as String,
    modelId: json['modelId'] as String,
    sdkPath: json['sdkPath'] as String?,
    sdkConfigured: json['sdkConfigured'] as bool? ?? false,
  );

  Member copyWith({
    String? id,
    String? name,
    AiTool? aiTool,
    AccessType? accessType,
    String? providerUrl,
    String? apiKey,
    String? modelId,
    String? sdkPath,
    bool? sdkConfigured,
  }) => Member(
    id: id ?? this.id,
    name: name ?? this.name,
    aiTool: aiTool ?? this.aiTool,
    accessType: accessType ?? this.accessType,
    providerUrl: providerUrl ?? this.providerUrl,
    apiKey: apiKey ?? this.apiKey,
    modelId: modelId ?? this.modelId,
    sdkPath: sdkPath ?? this.sdkPath,
    sdkConfigured: sdkConfigured ?? this.sdkConfigured,
  );
}
