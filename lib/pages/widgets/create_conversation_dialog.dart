import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/member.dart';
import '../../providers/member_provider.dart';
import '../../theme/app_theme.dart';

/// 创建对话弹窗 - 科技感风格
class CreateConversationDialog extends StatefulWidget {
  const CreateConversationDialog({super.key});

  @override
  State<CreateConversationDialog> createState() =>
      _CreateConversationDialogState();
}

class _CreateConversationDialogState extends State<CreateConversationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final Set<String> _selectedMemberIds = {};

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final members = memberProvider.members;

    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryCyan.withValues(alpha: 0.15)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: AppTheme.primaryGradient,
                        boxShadow: AppTheme.glowShadow(
                          AppTheme.primaryCyan,
                          blur: 10,
                        ),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '创建新对话',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '选择AI成员开始协作',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // 标题输入
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                    color: AppTheme.surfaceElevated,
                  ),
                  child: TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: '对话标题',
                      labelStyle: TextStyle(color: AppTheme.textSecondary),
                      hintText: '例如：技术讨论、代码审查',
                      hintStyle: TextStyle(color: AppTheme.textMuted),
                      prefixIcon: Icon(
                        Icons.title,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? '请输入对话标题' : null,
                  ),
                ),
                const SizedBox(height: 20),
                // 选择成员标题
                Row(
                  children: [
                    const Text(
                      '选择参与的AI成员',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedMemberIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppTheme.primaryCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          '${_selectedMemberIds.length}',
                          style: const TextStyle(
                            color: AppTheme.primaryCyan,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const Spacer(),
                    if (members.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _toggleSelectAll(members),
                        icon: Icon(
                          _isAllSelected(members)
                              ? Icons.deselect_outlined
                              : Icons.select_all_outlined,
                          size: 16,
                        ),
                        label: Text(_isAllSelected(members) ? '取消全选' : '全选'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryCyan,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // 成员列表
                if (members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderSubtle),
                      color: AppTheme.surfaceElevated,
                    ),
                    child: const Center(
                      child: Text(
                        '暂无可用成员，请先添加成员',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 300),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderSubtle),
                        color: AppTheme.surfaceElevated,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final isSelected = _selectedMemberIds.contains(
                            member.id,
                          );
                          return _buildMemberCheckbox(
                            context,
                            member,
                            isSelected,
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // 操作按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildButton(
                      label: '取消',
                      onTap: () => Navigator.of(context).pop(),
                      isPrimary: false,
                    ),
                    const SizedBox(width: 10),
                    _buildButton(
                      label: '创建',
                      onTap: _selectedMemberIds.isEmpty ? null : _create,
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isAllSelected(List<Member> members) {
    return members.isNotEmpty &&
        members.every((member) => _selectedMemberIds.contains(member.id));
  }

  void _toggleSelectAll(List<Member> members) {
    setState(() {
      if (_isAllSelected(members)) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds.addAll(members.map((member) => member.id));
      }
    });
  }

  Widget _buildMemberCheckbox(
    BuildContext context,
    Member member,
    bool isSelected,
  ) {
    final colors = _getMemberColors(member);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedMemberIds.remove(member.id);
              } else {
                _selectedMemberIds.add(member.id);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isSelected
                  ? colors[0].withValues(alpha: 0.06)
                  : Colors.transparent,
              border: Border.all(
                color: isSelected
                    ? colors[0].withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // 头像
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        colors[0].withValues(alpha: 0.8),
                        colors[1].withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      member.name.isNotEmpty
                          ? member.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 名称和描述
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${member.aiTool.label} · ${member.accessType.label}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // 选择指示器
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: isSelected
                        ? AppTheme.primaryCyan
                        : AppTheme.surfaceCard,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryCyan
                          : AppTheme.textSecondary,
                      width: isSelected ? 1.5 : 1.25,
                    ),
                    boxShadow: isSelected
                        ? AppTheme.glowShadow(AppTheme.primaryCyan, blur: 8)
                        : null,
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: AppTheme.surfaceDark,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getMemberColors(Member member) {
    switch (member.aiTool) {
      case AiTool.codex:
        return [const Color(0xFF00E5FF), const Color(0xFF2979FF)];
      case AiTool.claude:
        return [const Color(0xFFFF6B35), const Color(0xFFFF4081)];
      case AiTool.openCode:
        return [const Color(0xFF7C4DFF), const Color(0xFF536DFE)];
      case AiTool.pi:
        return [const Color(0xFF00E676), const Color(0xFF1DE9B6)];
      case AiTool.goose:
        return [const Color(0xFF00BCD4), const Color(0xFF26A69A)];
      case AiTool.cursor:
        return [const Color(0xFF8B5CF6), const Color(0xFF6366F3)];
      case AiTool.zcode:
      case AiTool.traeCode:
      case AiTool.codeBuudy:
        return [const Color(0xFF00BCD4), const Color(0xFF2979FF)];
      case AiTool.deepSeek:
        return [const Color(0xFF4D6BFE), const Color(0xFF2563EB)];
    }
  }

  Widget _buildButton({
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isPrimary && enabled ? AppTheme.primaryGradient : null,
            color: isPrimary
                ? (enabled ? null : AppTheme.surfaceElevated)
                : AppTheme.surfaceElevated,
            border: isPrimary ? null : Border.all(color: AppTheme.borderSubtle),
            boxShadow: isPrimary && enabled
                ? AppTheme.glowShadow(AppTheme.primaryCyan, blur: 12)
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? (enabled ? Colors.white : AppTheme.textMuted)
                  : AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _create() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMemberIds.isEmpty) return;

    Navigator.of(context).pop({
      'title': _titleController.text.trim(),
      'memberIds': _selectedMemberIds.toList(),
    });
  }
}
