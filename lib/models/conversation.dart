import 'message.dart';

/// 对话模型
class Conversation {
  final String id;
  String title;
  List<String> memberIds; // 参与的成员ID列表
  List<Message> messages;
  final DateTime createdAt;
  DateTime updatedAt;
  bool isActive; // 是否允许AI成员自动接力回复

  Conversation({
    required this.id,
    required this.title,
    required this.memberIds,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isActive = true,
  }) : messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Message? get lastMessage => messages.isEmpty ? null : messages.last;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'memberIds': memberIds,
    'messages': messages.map((m) => m.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isActive': isActive,
  };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: json['id'] as String,
    title: json['title'] as String,
    memberIds: List<String>.from(json['memberIds'] as List),
    messages: (json['messages'] as List)
        .map((m) => Message.fromJson(m as Map<String, dynamic>))
        .toList(),
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    isActive: json['isActive'] as bool? ?? true,
  );
}
