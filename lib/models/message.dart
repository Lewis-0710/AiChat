/// 消息角色
enum MessageRole {
  user('用户'),
  assistant('AI助手'),
  system('系统');

  final String label;
  const MessageRole(this.label);
}

/// 消息模型
class Message {
  final String id;
  final String conversationId;
  final String senderId; // 成员ID，用户消息为 'user'
  final String senderName;
  final MessageRole role;
  final String content;

  /// 图片附件的 data URL 列表，便于本地持久化并传给支持视觉的模型。
  final List<String> imageDatas;
  final DateTime timestamp;
  final bool isStreaming; // 是否正在流式输出

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.role,
    required this.content,
    List<String>? imageDatas,
    String? imageData,
    DateTime? timestamp,
    this.isStreaming = false,
  }) : imageDatas =
           imageDatas?.where((data) => data.isNotEmpty).toList() ??
           (imageData == null ? <String>[] : [imageData]),
       timestamp = timestamp ?? DateTime.now();

  /// 兼容旧代码和旧数据：返回第一张图片。
  String? get imageData => imageDatas.isEmpty ? null : imageDatas.first;

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversationId': conversationId,
    'senderId': senderId,
    'senderName': senderName,
    'role': role.name,
    'content': content,
    if (imageDatas.isNotEmpty) 'imageDatas': imageDatas,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Message.fromJson(Map<String, dynamic> json) {
    final savedImageDatas = json['imageDatas'];
    final legacyImageData = json['imageData'] as String?;
    final imageDatas = savedImageDatas is List
        ? savedImageDatas.whereType<String>().toList()
        : (legacyImageData == null ? <String>[] : [legacyImageData]);

    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      role: MessageRole.values.firstWhere((e) => e.name == json['role']),
      content: json['content'] as String,
      imageDatas: imageDatas,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    MessageRole? role,
    String? content,
    List<String>? imageDatas,
    DateTime? timestamp,
    bool? isStreaming,
  }) => Message(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    senderName: senderName ?? this.senderName,
    role: role ?? this.role,
    content: content ?? this.content,
    imageDatas: imageDatas ?? this.imageDatas,
    timestamp: timestamp ?? this.timestamp,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}
