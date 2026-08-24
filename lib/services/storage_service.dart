import "dart:convert";
import "dart:io";
import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";
import "../models/member.dart";
import "../models/conversation.dart";

/// 本地JSON文件持久化存储服务
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Directory? _appDir;
  File? _membersFile;
  File? _conversationsFile;

  /// 初始化存储目录
  Future<void> init() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      _appDir = Directory(p.join(appSupportDir.path, "aigroup"));
      if (!await _appDir!.exists()) {
        await _appDir!.create(recursive: true);
      }
      _membersFile = File(p.join(_appDir!.path, "members.json"));
      _conversationsFile = File(p.join(_appDir!.path, "conversations.json"));
    } catch (_) {}
  }

  // ============ 成员管理 ============

  Future<List<Member>> loadMembers() async {
    final file = _membersFile;
    if (file == null || !await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final list = jsonDecode(content) as List;
    return list.map((e) => Member.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveMembers(List<Member> members) async {
    final file = _membersFile;
    if (file == null) return;
    final json = jsonEncode(members.map((m) => m.toJson()).toList());
    await file.writeAsString(json);
  }

  // ============ 对话管理 ============

  Future<List<Conversation>> loadConversations() async {
    final file = _conversationsFile;
    if (file == null || !await file.exists()) return [];
    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];
    final list = jsonDecode(content) as List;
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final file = _conversationsFile;
    if (file == null) return;
    final json = jsonEncode(conversations.map((c) => c.toJson()).toList());
    await file.writeAsString(json);
  }
}
