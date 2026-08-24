import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/member.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';

/// 对话管理Provider
class ConversationProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _uuid = const Uuid();

  List<Conversation> _conversations = [];
  String? _activeConversationId;
  bool _isLoading = false;
  bool _isAiResponding = false;

  List<Conversation> get conversations => _conversations;
  String? get activeConversationId => _activeConversationId;
  bool get isLoading => _isLoading;
  bool get isAiResponding => _isAiResponding;

  Conversation? get activeConversation {
    if (_activeConversationId == null) return null;
    try {
      return _conversations.firstWhere((c) => c.id == _activeConversationId);
    } catch (_) {
      return null;
    }
  }

  /// 加载所有对话
  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _storage.loadConversations();
    } catch (e) {
      debugPrint('加载对话失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 创建新对话
  Future<Conversation> createConversation({
    required String title,
    required List<String> memberIds,
  }) async {
    final conversation = Conversation(
      id: _uuid.v4(),
      title: title,
      memberIds: memberIds,
    );
    _conversations.insert(0, conversation);
    _activeConversationId = conversation.id;
    await _storage.saveConversations(_conversations);
    notifyListeners();
    return conversation;
  }

  /// 选择活跃对话
  void setActiveConversation(String conversationId) {
    _activeConversationId = conversationId;
    notifyListeners();
  }

  /// 修改对话标题
  Future<void> renameConversation(String conversationId, String title) async {
    final newTitle = title.trim();
    if (newTitle.isEmpty) return;

    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    _conversations[index].title = newTitle;
    _conversations[index].updatedAt = DateTime.now();
    await _storage.saveConversations(_conversations);
    notifyListeners();
  }

  /// 删除对话
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    if (_activeConversationId == conversationId) {
      _activeConversationId = _conversations.isEmpty
          ? null
          : _conversations.first.id;
    }
    await _storage.saveConversations(_conversations);
    notifyListeners();
  }

  /// 停止AI成员自动接力，但保留用户继续输入并@成员发起回复的能力。
  Future<void> endConversation(String conversationId) async {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      _conversations[index].isActive = false;
      await _storage.saveConversations(_conversations);
      notifyListeners();
    }
  }

  /// 发送用户消息并触发AI回复
  Future<void> sendMessage({
    required String conversationId,
    required String content,
    List<String>? imageDatas,
    required List<String> responderOrder,
    required List<Member> allMembers,
  }) async {
    final convIndex = _conversations.indexWhere((c) => c.id == conversationId);
    if (convIndex == -1) return;

    final conversation = _conversations[convIndex];
    final normalizedResponderOrder = _normalizeResponderOrder(
      conversation,
      responderOrder,
    );
    if (normalizedResponderOrder.isEmpty) return;

    // 停止自动接力后，用户发送新消息时重新开启AI成员自动接力。
    conversation.isActive = true;

    // 添加用户消息
    final userMessage = Message(
      id: _uuid.v4(),
      conversationId: conversationId,
      senderId: 'user',
      senderName: '用户',
      role: MessageRole.user,
      content: content,
      imageDatas: imageDatas,
    );
    conversation.messages.add(userMessage);
    conversation.updatedAt = DateTime.now();
    unawaited(_storage.saveConversations(_conversations));
    notifyListeners();

    // 触发首个AI回复
    _isAiResponding = true;
    notifyListeners();

    try {
      await _triggerAiResponse(
        conversation: conversation,
        responderId: normalizedResponderOrder.first,
        responderOrder: normalizedResponderOrder,
        allMembers: allMembers,
        userMessage: content,
        imageDatas: imageDatas,
        allowAutoContinuation: conversation.isActive,
      );
    } catch (e) {
      debugPrint('AI回复失败: $e');
      // 添加错误消息
      conversation.messages.add(
        Message(
          id: _uuid.v4(),
          conversationId: conversationId,
          senderId: 'system',
          senderName: '系统',
          role: MessageRole.system,
          content: 'AI回复失败: $e',
        ),
      );
      notifyListeners();
    }

    _isAiResponding = false;
    notifyListeners();
  }

  String _buildMemberRequestMessage({
    required Conversation conversation,
    required Member member,
    required List<Member> allMembers,
    required String userMessage,
  }) {
    final membersById = {for (final item in allMembers) item.id: item};
    final groupMembers = conversation.memberIds
        .map((id) {
          final groupMember = membersById[id];
          return groupMember == null
              ? id
              : '[${groupMember.name} | ${groupMember.modelId}]';
        })
        .join('、');

    return '这是一个群组对话。\n'
        '群组成员（按配置顺序）：$groupMembers。\n'
        '当前发言成员：[${member.name} | ${member.modelId}]。\n'
        '历史消息中的发言人名称表示对应成员的真实发言。\n'
        '聊天氛围保持轻松、自然、有活力，允许适度俏皮、接梗和使用emoji，但不要为了热闹强行玩梗。\n'
        '像真实群聊一样回应：有内容就直接说，没必要说太多时就简短一些，不要写成正式报告或团队宣言。\n'
        '如果用户只是简单问候，就自然简短地回应，不要主动罗列能力、工作范围或把话题扩展成任务说明会。\n'
        '回答请直接从内容开始，不要把当前发言成员的名字或模型名作为署名或开头。\n\n'
        '需要回应的内容：\n$userMessage';
  }

  List<String> _normalizeResponderOrder(
    Conversation conversation,
    List<String> responderOrder,
  ) {
    final order = <String>[];
    for (final id in responderOrder) {
      if (conversation.memberIds.contains(id) && !order.contains(id)) {
        order.add(id);
      }
    }
    for (final id in conversation.memberIds) {
      if (!order.contains(id)) order.add(id);
    }
    return order;
  }

  /// 触发AI回复
  Future<void> _triggerAiResponse({
    required Conversation conversation,
    required String responderId,
    required List<String> responderOrder,
    required List<Member> allMembers,
    required String userMessage,
    List<String>? imageDatas,
    required bool allowAutoContinuation,
  }) async {
    final member = allMembers.firstWhere((m) => m.id == responderId);
    final client = ApiClientFactory.create(member.accessType);
    final requestMessage = _buildMemberRequestMessage(
      conversation: conversation,
      member: member,
      allMembers: allMembers,
      userMessage: userMessage,
    );

    // 构建历史消息（排除系统消息）
    final history = conversation.messages
        .where((m) => m.senderId != 'system' && !m.isStreaming)
        .toList();

    // 创建占位消息
    final msgId = _uuid.v4();
    var assistantMessage = Message(
      id: msgId,
      conversationId: conversation.id,
      senderId: member.id,
      senderName: member.name,
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
    conversation.messages.add(assistantMessage);
    notifyListeners();

    final buffer = StringBuffer();
    var lastNotifyTime = DateTime.fromMillisecondsSinceEpoch(0);
    const throttleDuration = Duration(milliseconds: 40);
    try {
      await for (final chunk in client.sendMessageStream(
        member: member,
        history: history,
        userMessage: requestMessage,
        imageDatas: imageDatas,
      )) {
        buffer.write(chunk);
        final now = DateTime.now();
        if (now.difference(lastNotifyTime) >= throttleDuration) {
          lastNotifyTime = now;
          final msgIndex = conversation.messages.indexWhere((m) => m.id == msgId);
          if (msgIndex != -1) {
            conversation.messages[msgIndex] = Message(
              id: msgId,
              conversationId: conversation.id,
              senderId: member.id,
              senderName: member.name,
              role: MessageRole.assistant,
              content: _removeSelfIntroduction(buffer.toString(), member),
              isStreaming: true,
            );
            notifyListeners();
          }
        }
      }
    } catch (e) {
      buffer.write('\n\n[错误: $e]');
    }

    // 标记流式完成
    final finalMsgIndex = conversation.messages.indexWhere(
      (m) => m.id == msgId,
    );
    if (finalMsgIndex != -1) {
      conversation.messages[finalMsgIndex] = Message(
        id: msgId,
        conversationId: conversation.id,
        senderId: member.id,
        senderName: member.name,
        role: MessageRole.assistant,
        content: _removeSelfIntroduction(buffer.toString(), member),
        isStreaming: false,
      );
    }

    conversation.updatedAt = DateTime.now();
    await _storage.saveConversations(_conversations);
    notifyListeners();

    // 只有未结束自动接力时，才允许下一个AI继续回复。
    if (allowAutoContinuation && conversation.isActive) {
      await _checkAndTriggerNextResponder(
        conversation: conversation,
        currentResponderId: responderId,
        responderOrder: responderOrder,
        allMembers: allMembers,
      );
    }
  }

  String _removeSelfIntroduction(String content, Member member) {
    final headerPattern = RegExp(
      r'^\s*[【\[]\s*AI成员\s*[:：]\s*'
      '${RegExp.escape(member.name)}'
      r'\s*(?:\|｜)\s*'
      '${RegExp.escape(member.modelId)}'
      r'\s*[】\]]\s*',
    );
    return content.replaceFirst(headerPattern, '');
  }

  /// 检查并触发下一个AI回复（多AI协作）
  Future<void> _checkAndTriggerNextResponder({
    required Conversation conversation,
    required String currentResponderId,
    required List<String> responderOrder,
    required List<Member> allMembers,
  }) async {
    // 用户点击“结束对话”后，停止当前对话中的AI自动接力。
    if (!conversation.isActive) return;

    if (responderOrder.length <= 1) return;

    final currentIndex = responderOrder.indexOf(currentResponderId);
    if (currentIndex == -1 || currentIndex >= responderOrder.length - 1) return;

    final nextResponderId = responderOrder[currentIndex + 1];

    // 构建上下文
    final lastMessage = conversation.messages.last;
    final previousMember = allMembers.where(
      (m) => m.id == lastMessage.senderId,
    );
    final previousSpeaker = previousMember.isEmpty
        ? lastMessage.senderName
        : '[${previousMember.first.name} | ${previousMember.first.modelId}]';
    final contextPrompt =
        '上一位发言者 $previousSpeaker 说：\n${lastMessage.content}\n\n'
        '请结合用户原始问题和当前全部对话，自然地接着聊。'
        '可以赞同、补充、提出不同看法或接住上一位的话，直接表达你认为有价值的内容。\n'
        '如果只是简单问候，就保持简短，不要主动扩展出新的任务或话题。\n'
        '如果提到其他成员，可以使用 [成员名 | 模型名]、“楼上”或“刚才那位”自然切入；'
        '不要把自己的成员名或模型名作为署名。';

    await _triggerAiResponse(
      conversation: conversation,
      responderId: nextResponderId,
      responderOrder: responderOrder,
      allMembers: allMembers,
      userMessage: contextPrompt,
      allowAutoContinuation: true,
    );
  }
}
