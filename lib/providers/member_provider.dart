import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/member.dart';
import '../services/storage_service.dart';
import '../services/sdk_detector.dart';

/// 成员管理Provider
class MemberProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final SdkDetector _sdkDetector = SdkDetector();
  final _uuid = const Uuid();

  List<Member> _members = [];
  bool _isLoading = false;

  List<Member> get members => _members;
  bool get isLoading => _isLoading;

  /// 加载所有成员
  Future<void> loadMembers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _members = await _storage.loadMembers();
    } catch (e) {
      debugPrint('加载成员失败: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 添加新成员
  Future<void> addMember(Member member) async {
    final newMember = member.copyWith(id: _uuid.v4());
    _members.add(newMember);
    await _storage.saveMembers(_members);
    notifyListeners();
  }

  /// 更新成员
  Future<void> updateMember(Member member) async {
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index != -1) {
      _members[index] = member;
      await _storage.saveMembers(_members);
      notifyListeners();
    }
  }

  /// 删除成员
  Future<void> deleteMember(String memberId) async {
    _members.removeWhere((m) => m.id == memberId);
    await _storage.saveMembers(_members);
    notifyListeners();
  }

  /// 根据ID获取成员
  Member? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  /// 检测SDK
  Future<SdkDetectionResult> detectSdk(AiTool tool) async {
    return await _sdkDetector.detect(tool);
  }

  /// 手动设置SDK路径
  Future<void> setSdkPath(String memberId, String path) async {
    final member = getMemberById(memberId);
    if (member != null) {
      member.sdkPath = path;
      member.sdkConfigured = true;
      await updateMember(member);
    }
  }
}
