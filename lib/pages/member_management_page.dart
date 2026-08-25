import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../providers/member_provider.dart';
import '../theme/app_theme.dart';
import 'widgets/member_form_dialog.dart';

/// 成员管理页面 - 科技感风格
class MemberManagementPage extends StatelessWidget {
  const MemberManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      appBar: _buildAppBar(context),
      body: Consumer<MemberProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryCyan),
            );
          }

          if (provider.members.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.members.length,
            itemBuilder: (context, index) {
              final member = provider.members[index];
              return _buildMemberCard(context, member, provider);
            },
          );
        },
      ),
    );
  }

  PreferredSize _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        // 预留字体实际行高，避免标题和副标题在窗口缩放时发生底部溢出。
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
        ),
        child: Row(
          children: [
            // 返回按钮
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: AppTheme.textSecondary,
                    size: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '成员管理',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '管理你的AI协作成员',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            // 添加按钮
            _buildAddButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showAddDialog(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryCyan.withValues(alpha: 0.15),
                AppTheme.primaryBlue.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(
              color: AppTheme.primaryCyan.withValues(alpha: 0.3),
            ),
            boxShadow: AppTheme.glowShadow(AppTheme.primaryCyan, blur: 12),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: AppTheme.primaryCyan, size: 18),
              SizedBox(width: 6),
              Text(
                '添加成员',
                style: TextStyle(
                  color: AppTheme.primaryCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                width: 1.5,
              ),
              color: AppTheme.primaryCyan.withValues(alpha: 0.03),
            ),
            child: Icon(
              Icons.people_outline_rounded,
              size: 44,
              color: AppTheme.primaryCyan.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '暂无AI成员',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加AI成员来开始协作对话',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 32),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _showAddDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: AppTheme.glowShadow(
                    AppTheme.primaryCyan,
                    blur: 16,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '添加新成员',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    Member member,
    MemberProvider provider,
  ) {
    final colors = _getMemberColors(member);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surfaceCard,
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: Column(
          children: [
            // 头部
            Container(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // 头像
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          colors[0].withValues(alpha: 0.8),
                          colors[1].withValues(alpha: 0.6),
                        ],
                      ),
                      boxShadow: AppTheme.glowShadow(colors[0], blur: 12),
                    ),
                    child: Center(
                      child: Text(
                        member.name.isNotEmpty
                            ? member.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // 名称和标签
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildTag(
                              label: member.aiTool.label,
                              color: member.sdkConfigured
                                  ? AppTheme.accentGreen
                                  : Colors.orange,
                              icon: member.sdkConfigured
                                  ? Icons.check_circle
                                  : Icons.warning,
                            ),
                            const SizedBox(width: 8),
                            _buildTag(
                              label: member.accessType.label,
                              color: AppTheme.primaryBlue,
                              icon: Icons.api,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 操作按钮
                  _buildIconButton(
                    icon: Icons.edit_outlined,
                    onTap: () => _showEditDialog(context, member),
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  _buildIconButton(
                    icon: Icons.delete_outline,
                    onTap: () => _confirmDelete(context, member, provider),
                    color: AppTheme.accentPink,
                  ),
                ],
              ),
            ),
            // 分隔线
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppTheme.borderSubtle,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // 详情信息
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                children: [
                  _buildInfoRow(
                    icon: Icons.link,
                    label: '供应商URL',
                    value: member.providerUrl,
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.key,
                    label: 'API KEY',
                    value:
                        '${member.apiKey.substring(0, 8)}...${member.apiKey.substring(member.apiKey.length - 4)}',
                  ),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.model_training,
                    label: '模型',
                    value: member.modelId,
                    valueColor: AppTheme.primaryCyan,
                  ),
                  if (member.sdkPath != null) ...[
                    const SizedBox(height: 10),
                    _buildInfoRow(
                      icon: Icons.folder_outlined,
                      label: 'SDK路径',
                      value: member.sdkPath!,
                    ),
                  ],
                ],
              ),
            ),
          ],
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

  Widget _buildTag({
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            color: color.withValues(alpha: 0.05),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppTheme.textMuted),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppTheme.textSecondary,
              fontSize: 13,
              fontFamily: value.contains('sk-') || value.contains('...')
                  ? 'Menlo'
                  : null,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final result = await showDialog<Member>(
      context: context,
      builder: (_) => const MemberFormDialog(),
    );

    if (result != null && context.mounted) {
      await context.read<MemberProvider>().addMember(result);
    }
  }

  Future<void> _showEditDialog(BuildContext context, Member member) async {
    final result = await showDialog<Member>(
      context: context,
      builder: (_) => MemberFormDialog(member: member),
    );

    if (result != null && context.mounted) {
      await context.read<MemberProvider>().updateMember(result);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Member member,
    MemberProvider provider,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '确认删除',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                  children: [
                    const TextSpan(text: '确定要删除成员 '),
                    TextSpan(
                      text: '"${member.name}"',
                      style: const TextStyle(
                        color: AppTheme.accentPink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' 吗？'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentPink,
                    ),
                    child: const Text('删除'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await provider.deleteMember(member.id);
    }
  }
}
