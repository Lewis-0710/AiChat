import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/member.dart';
import '../providers/conversation_provider.dart';
import '../providers/member_provider.dart';
import '../theme/app_theme.dart';
import 'member_management_page.dart';
import 'widgets/create_conversation_dialog.dart';
import 'widgets/message_bubble.dart';


class _MessageHeightReporter extends SingleChildRenderObjectWidget {
  final String messageId;
  final void Function(double height) onHeight;

  const _MessageHeightReporter({
    required this.messageId,
    required this.onHeight,
    required super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderMessageHeightReporter(onHeight);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderMessageHeightReporter renderObject,
  ) {
    renderObject.onHeight = onHeight;
  }
}

class _RenderMessageHeightReporter extends RenderProxyBox {
  void Function(double height) onHeight;
  double? _lastHeight;

  _RenderMessageHeightReporter(this.onHeight);

  @override
  void performLayout() {
    super.performLayout();
    if (size.height > 0 && size.height != _lastHeight) {
      _lastHeight = size.height;
      onHeight(size.height);
    }
  }
}

class _PasteClipboardIntent extends Intent {
  const _PasteClipboardIntent();
}


/// 主页：左侧对话列表 + 右侧对话详情
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _conversationMenuKey = GlobalKey();
  final List<Uint8List> _pastedImageBytes = [];
  final List<String> _pastedImageDatas = [];
  final Map<String, GlobalKey> _messageKeys = {};
  final Map<String, double> _messageHeights = {};
  String? _trackedConversationId;
  bool _isMessageListAtBottom = true;
  bool _messageListUserScrollActive = false;
  bool _scrollUpdateScheduled = false;
    int _messageListAutoScrollToken = 0;
  int _messageScrollRequestToken = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleMessageListScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleMessageListScroll);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceDark,
      body: Row(
        children: [
          // 左侧：科技感侧边栏
          SizedBox(width: 300, child: _buildSidebar(context)),
          // 分隔线（带发光效果）
          Container(
            width: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppTheme.primaryCyan.withValues(alpha: 0.3),
                  AppTheme.primaryCyan.withValues(alpha: 0.1),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // 右侧：对话详情
          Expanded(child: _buildConversationDetail(context)),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.sidebarGradient),
      child: Consumer<ConversationProvider>(
        builder: (context, convProvider, _) {
          return Column(
            children: [
              // 顶部 Logo 区域
              _buildSidebarHeader(context),
              // 对话列表
              Expanded(
                child: convProvider.conversations.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: convProvider.conversations.length,
                        itemBuilder: (context, index) {
                          final conv = convProvider.conversations[index];
                          final isActive =
                              conv.id == convProvider.activeConversationId;
                          return _buildConversationItem(
                            context,
                            conv,
                            isActive,
                          );
                        },
                      ),
              ),
              // 底部操作区
              _buildSidebarFooter(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Row(
            children: [
              // Logo 图标
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: AppTheme.glowShadow(
                    AppTheme.primaryCyan,
                    blur: 12,
                  ),
                ),
                child: const Icon(
                  Icons.hub_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI聊天室',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      'AI多成员协作聊天',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 科技感空状态图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                color: AppTheme.primaryCyan.withValues(alpha: 0.03),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppTheme.primaryCyan.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '暂无对话',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮开始新对话',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conv,
    bool isActive,
  ) {
    final memberProvider = context.read<MemberProvider>();
    final members = memberProvider.members
        .where((m) => conv.memberIds.contains(m.id))
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            context.read<ConversationProvider>().setActiveConversation(conv.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: isActive
                  ? LinearGradient(
                      colors: [
                        AppTheme.primaryCyan.withValues(alpha: 0.12),
                        AppTheme.primaryBlue.withValues(alpha: 0.06),
                      ],
                    )
                  : null,
              color: isActive ? null : Colors.transparent,
              border: Border.all(
                color: isActive
                    ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                // 头像组
                _buildMemberAvatars(members, isActive),
                const SizedBox(width: 12),
                // 标题和最后消息
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conv.title,
                        style: TextStyle(
                          color: isActive
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontSize: 14,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conv.lastMessage?.content.isNotEmpty == true
                            ? _truncate(conv.lastMessage!.content, 30)
                            : (members.isNotEmpty
                                  ? members.map((m) => m.name).join(', ')
                                  : '暂无消息'),
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 时间和状态
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      conv.lastMessage != null
                          ? _formatTime(conv.lastMessage!.timestamp)
                          : _formatTime(conv.createdAt),
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                    ),
                    if (conv.isActive)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                            boxShadow: AppTheme.glowShadow(
                              AppTheme.accentGreen,
                              blur: 6,
                            ),
                          ),
                        ),
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

  Widget _buildMemberAvatars(List<Member> members, bool isActive) {
    if (members.isEmpty) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderSubtle),
        ),
        child: const Icon(
          Icons.person_outline,
          color: AppTheme.textMuted,
          size: 18,
        ),
      );
    }

    if (members.length == 1) {
      return _buildAvatar(members.first, isActive);
    }

    // 多个成员重叠显示
    return SizedBox(
      width: 38,
      height: 38,
      child: Stack(
        children: [
          for (int i = 0; i < members.length && i < 3; i++)
            Positioned(
              left: i * 10.0,
              child: _buildAvatar(members[i], isActive, size: 28),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Member member, bool isActive, {double size = 38}) {
    final colors = _getMemberColors(member);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors[0].withValues(alpha: 0.8),
            colors[1].withValues(alpha: 0.6),
          ],
        ),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryCyan.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
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
    }
  }

  Widget _buildSidebarFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFooterButton(
              icon: Icons.people_outline_rounded,
              label: '管理成员',
              onTap: () => _openMemberManagement(context),
              isPrimary: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildFooterButton(
              icon: Icons.add_rounded,
              label: '新建对话',
              onTap: () => _showCreateConversationDialog(context),
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }

  void _openMemberManagement(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MemberManagementPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildFooterButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: isPrimary
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryCyan.withValues(alpha: 0.15),
                      AppTheme.primaryBlue.withValues(alpha: 0.1),
                    ],
                  )
                : null,
            color: isPrimary ? null : AppTheme.surfaceElevated,
            border: Border.all(
              color: isPrimary
                  ? AppTheme.primaryCyan.withValues(alpha: 0.3)
                  : AppTheme.borderSubtle,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isPrimary
                    ? AppTheme.primaryCyan
                    : AppTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isPrimary
                      ? AppTheme.primaryCyan
                      : AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationDetail(BuildContext context) {
    return Consumer<ConversationProvider>(
      builder: (context, convProvider, _) {
        final conv = convProvider.activeConversation;
        if (conv == null) {
          return _buildWelcomeScreen(context);
        }

        final members = context
            .watch<MemberProvider>()
            .members
            .where((m) => conv.memberIds.contains(m.id))
            .toList();

        return Column(
          children: [
            // 顶部栏
            _buildDetailHeader(context, conv, members, convProvider),
            // 消息列表与左侧用户消息指示器
            Expanded(
              child: Stack(
                children: [
                  _buildMessageList(context, conv, members),
                  _buildUserMessageIndicator(context, conv),
                  if (!_isMessageListAtBottom)
                    _buildScrollToBottomButton(context),
                ],
              ),
            ),
            // 输入区域：即使停止AI自动接力，用户仍可继续输入并@成员发起回复。
            _buildInputArea(context, conv, members, convProvider),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    final memberProvider = context.watch<MemberProvider>();
    final hasMembers = memberProvider.members.isNotEmpty;
    final showQuickAction = !memberProvider.isLoading;

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 大 Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.glowShadow(AppTheme.primaryCyan, blur: 40),
              ),
              child: const Icon(
                Icons.hub_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'AI聊天室',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI多成员协作聊天',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            if (showQuickAction) ...[
              const SizedBox(height: 40),
              _buildQuickAction(
                icon: hasMembers
                    ? Icons.add_comment_outlined
                    : Icons.add_rounded,
                label: hasMembers ? '新建对话' : '添加成员',
                onTap: hasMembers
                    ? () => _showCreateConversationDialog(context)
                    : () => _openMemberManagement(context),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Align(
      alignment: Alignment.center,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.primaryCyan.withValues(alpha: 0.3),
              ),
              color: AppTheme.primaryCyan.withValues(alpha: 0.05),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppTheme.primaryCyan, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.primaryCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailHeader(
    BuildContext context,
    Conversation conv,
    List<Member> members,
    ConversationProvider convProvider,
  ) {
    Widget buildHeaderInfo() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            conv.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: conv.isActive
                      ? AppTheme.accentGreen
                      : AppTheme.textMuted,
                  boxShadow: conv.isActive
                      ? AppTheme.glowShadow(AppTheme.accentGreen, blur: 6)
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                conv.isActive ? '自动接力中' : '已停止自动接力',
                style: TextStyle(
                  color: conv.isActive
                      ? AppTheme.accentGreen
                      : AppTheme.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${members.length} 位成员',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      );
    }

    Widget buildMemberAvatars() {
      return LayoutBuilder(
        builder: (context, constraints) {
          final avatarRow = Row(
            mainAxisSize: MainAxisSize.min,
            children: members.map((m) {
              final colors = _getMemberColors(m);
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Tooltip(
                  message: '${m.name} (${m.aiTool.label})',
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          colors[0].withValues(alpha: 0.8),
                          colors[1].withValues(alpha: 0.6),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        m.name.isNotEmpty ? m.name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: Align(alignment: Alignment.centerRight, child: avatarRow),
            ),
          );
        },
      );
    }

    Widget buildStopButton() {
      return _buildHeaderButton(
        icon: Icons.stop_circle_outlined,
        label: '结束对话',
        color: AppTheme.accentPink,
        onTap: () => _endConversation(context, conv.id),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // 窄窗口下将标题、操作按钮分行，避免头像组和按钮挤出右侧边界。
        final isCompact = constraints.maxWidth < 560;
        final menuButton = _buildHeaderIconButton(
          key: _conversationMenuKey,
          icon: Icons.more_horiz,
          onTap: () => _showConversationMenu(context, conv),
        );

        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 24,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: buildHeaderInfo()),
                        const SizedBox(width: 8),
                        menuButton,
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: constraints.maxWidth / 2,
                        height: 36,
                        child: buildMemberAvatars(),
                      ),
                    ),
                    if (conv.isActive) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: buildStopButton(),
                      ),
                    ],
                  ],
                )
              : Row(
                  children: [
                    // 右半区专门承载成员列表和操作按钮，保证成员列表
                    // 的左边界不会越过对话区域的中心线。
                    Expanded(child: buildHeaderInfo()),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(child: buildMemberAvatars()),
                          const SizedBox(width: 16),
                          if (conv.isActive) buildStopButton(),
                          const SizedBox(width: 8),
                          menuButton,
                        ],
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            color: color.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          key: key,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Icon(icon, color: AppTheme.textSecondary, size: 18),
        ),
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    Conversation conv,
    List<Member> members,
  ) {
    _prepareMessageList(conv);

    if (conv.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: AppTheme.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "开始对话吧",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _handleMessageListNotification,
      child: ListView.builder(
        key: ValueKey("messages-${conv.id}"),
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: conv.messages.length,
        itemBuilder: (context, index) {
          final message = conv.messages[index];
          final isUser = message.senderId == "user";
          final messageKey =
              _messageKeys.putIfAbsent(message.id, GlobalKey.new);
          return KeyedSubtree(
            key: messageKey,
            child: _MessageHeightReporter(
              messageId: message.id,
              onHeight: (h) => _messageHeights[message.id] = h,
              child: MessageBubble(
                key: ValueKey(message.id),
                message: message,
                isUser: isUser,
                memberColors: isUser
                    ? null
                    : _getMemberColorsById(members, message.senderId),
              ),
            ),
          );
        },
      ),
    );
  }

  void _prepareMessageList(Conversation conv) {
    final isNewConversation = _trackedConversationId != conv.id;

    if (isNewConversation) {
      _messageScrollRequestToken++;
      _messageListAutoScrollToken++;
      _trackedConversationId = conv.id;
      _isMessageListAtBottom = true;
      _messageHeights.clear();
      _scheduleMessageListPositionUpdate(force: true);
    } else if (_isMessageListAtBottom) {
      _scheduleMessageListPositionUpdate(force: false);
    }

    final currentMessageIds =
        conv.messages.map((message) => message.id).toSet();
    _messageKeys.removeWhere(
      (messageId, _) => !currentMessageIds.contains(messageId),
    );
    _messageHeights.removeWhere(
      (messageId, _) => !currentMessageIds.contains(messageId),
    );
  }

  double _getEstimatedMessageHeight(Message message) {
    final measured = _messageHeights[message.id];
    if (measured != null && measured > 0) {
      return measured + 12.0;
    }

    double estimated = 64.0;
    if (message.imageDatas.isNotEmpty) {
      estimated += message.imageDatas.length * 210.0;
    }
    if (message.content.isNotEmpty) {
      final estimatedWrapLines = (message.content.length / 38.0).ceil();
      final explicitNewlines = "\n".allMatches(message.content).length;
      final totalLines = max(1, estimatedWrapLines + explicitNewlines);
      estimated += totalLines * 22.5;
    }
    return estimated;
  }

  void _scheduleMessageListPositionUpdate({bool force = false}) {
    if (_messageListUserScrollActive) return;
    if (!force && !_isMessageListAtBottom) return;

    if (_scrollUpdateScheduled) return;
    _scrollUpdateScheduled = true;
    final requestToken = _messageListAutoScrollToken;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollUpdateScheduled = false;
      if (!mounted ||
          !_scrollController.hasClients ||
          requestToken != _messageListAutoScrollToken ||
          _messageListUserScrollActive) {
        return;
      }

      if (!force && !_isMessageListAtBottom) return;

      _jumpToBottomIfNeeded(requestToken, force: force);
    });
  }

  void _jumpToBottomIfNeeded(
    int requestToken, {
    bool force = false,
    int attempt = 0,
  }) {
    if (!mounted ||
        !_scrollController.hasClients ||
        requestToken != _messageListAutoScrollToken ||
        _messageListUserScrollActive) {
      return;
    }
    if (!force && !_isMessageListAtBottom) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    final target = position.maxScrollExtent;
    if ((position.pixels - target).abs() > 1.0) {
      position.jumpTo(target);
      if (attempt < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _jumpToBottomIfNeeded(
            requestToken,
            force: force,
            attempt: attempt + 1,
          );
        });
      }
    }
  }

  void _handleMessageListScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.outOfRange || !position.hasContentDimensions) return;
    if (position.extentAfter <= 40) {
      _setMessageListAtBottom(true);
    }
  }

  bool _handleMessageListNotification(ScrollNotification notification) {
    if (notification.depth != 0) return false;

    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) {
        _messageListUserScrollActive = true;
      }
    } else if (notification is UserScrollNotification) {
      if (notification.direction != ScrollDirection.idle) {
        _messageListUserScrollActive = true;
      } else {
        _messageListUserScrollActive = false;
      }
    } else if (notification is ScrollUpdateNotification) {
      final isUserScroll = notification.dragDetails != null ||
          (notification.scrollDelta != null && notification.scrollDelta != 0);

      if (isUserScroll) {
        if (notification.scrollDelta != null && notification.scrollDelta! < 0) {
          if (notification.metrics.extentAfter > 40) {
            _setMessageListAtBottom(false);
          }
        } else if (notification.scrollDelta != null &&
            notification.scrollDelta! > 0) {
          if (notification.metrics.extentAfter <= 40) {
            _setMessageListAtBottom(true);
          }
        } else if (notification.dragDetails != null) {
          if (notification.metrics.extentAfter <= 40) {
            _setMessageListAtBottom(true);
          } else {
            _setMessageListAtBottom(false);
          }
        }
      } else {
        if (notification.metrics.extentAfter <= 40) {
          _setMessageListAtBottom(true);
        }
      }
    } else if (notification is ScrollEndNotification) {
      _messageListUserScrollActive = false;
      if (notification.metrics.extentAfter <= 40) {
        _setMessageListAtBottom(true);
      }
    }

    return false;
  }

  void _setMessageListAtBottom(bool value) {
    if (_isMessageListAtBottom == value) return;
    if (!mounted) {
      _isMessageListAtBottom = value;
      return;
    }
    setState(() {
      _isMessageListAtBottom = value;
    });
  }

  Widget _buildUserMessageIndicator(BuildContext context, Conversation conv) {
    final userMessages = conv.messages
        .where((message) => message.senderId == "user")
        .toList();
    if (userMessages.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: 6,
      top: 0,
      bottom: 0,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 280),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int index = 0; index < userMessages.length; index++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Tooltip(
                      message:
                          "跳转到第 ${index + 1} 条消息: ${_truncate(userMessages[index].content, 24)}",
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _scrollToUserMessage(
                            conv,
                            userMessages[index].id,
                          ),
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryCyan,
                              boxShadow: AppTheme.glowShadow(
                                AppTheme.primaryCyan,
                                blur: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _scrollToUserMessage(Conversation conv, String messageId) async {
    final targetIndex = conv.messages.indexWhere(
      (message) => message.id == messageId,
    );
    if (targetIndex < 0) return;

    final requestToken = ++_messageScrollRequestToken;
    _messageListAutoScrollToken++;
    _setMessageListAtBottom(false);

    if (targetIndex == 0) {
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
      return;
    }

    for (int attempt = 0; attempt < 12; attempt++) {
      if (!mounted || requestToken != _messageScrollRequestToken) return;

      final messageContext = _messageKeys[messageId]?.currentContext;
      if (messageContext != null && messageContext.mounted) {
        await Scrollable.ensureVisible(
          messageContext,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          alignment: 0.02,
        );

        if (!mounted || requestToken != _messageScrollRequestToken) return;
        await WidgetsBinding.instance.endOfFrame;

        if (messageContext.mounted) {
          await Scrollable.ensureVisible(
            messageContext,
            duration: const Duration(milliseconds: 60),
            curve: Curves.easeOut,
            alignment: 0.02,
          );
        }
        return;
      }

      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        await WidgetsBinding.instance.endOfFrame;
        continue;
      }

      final position = _scrollController.position;

      // 累积计算目标消息前所有消息的估算高度
      double targetOffset = 16.0;
      for (int i = 0; i < targetIndex; i++) {
        targetOffset += _getEstimatedMessageHeight(conv.messages[i]);
      }

      final clampedTarget = targetOffset.clamp(0.0, position.maxScrollExtent);
      if ((clampedTarget - position.pixels).abs() > 2) {
        position.jumpTo(clampedTarget);
      } else {
        int minMounted = -1;
        int maxMounted = -1;
        for (int i = 0; i < conv.messages.length; i++) {
          if (_messageKeys[conv.messages[i].id]?.currentContext != null) {
            if (minMounted == -1) minMounted = i;
            maxMounted = i;
          }
        }
        if (minMounted != -1 && targetIndex < minMounted) {
          position.jumpTo(max(0.0, position.pixels - position.viewportDimension * 0.8));
        } else if (maxMounted != -1 && targetIndex > maxMounted) {
          position.jumpTo(min(position.maxScrollExtent, position.pixels + position.viewportDimension * 0.8));
        }
      }

      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Widget _buildScrollToBottomButton(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 18,
      child: Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _scrollToMessageListBottom,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.surfaceElevated,
                border: Border.all(
                  color: AppTheme.primaryCyan.withValues(alpha: 0.55),
                ),
                boxShadow: AppTheme.glowShadow(AppTheme.primaryCyan, blur: 12),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppTheme.primaryCyan,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToMessageListBottom() {
    if (!mounted || !_scrollController.hasClients) return;
    _messageListAutoScrollToken++;
    _messageScrollRequestToken++;
    _messageListUserScrollActive = false;
    _setMessageListAtBottom(true);
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  List<Color>? _getMemberColorsById(List<Member> members, String senderId) {
    final member = members.where((m) => m.id == senderId).toList();
    if (member.isEmpty) return null;
    return _getMemberColors(member.first);
  }

  Widget _buildInputArea(
    BuildContext context,
    Conversation conv,
    List<Member> members,
    ConversationProvider convProvider,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(top: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        children: [
          // @成员快捷按钮
          if (members.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        '快速@',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ...members.map((m) {
                        final colors = _getMemberColors(m);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {
                                final text = _messageController.text;
                                final mention = '@${m.name} ';
                                _messageController.text = text.isEmpty
                                    ? mention
                                    : '$text $mention';
                                _focusNode.requestFocus();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    colors: [
                                      colors[0].withValues(alpha: 0.15),
                                      colors[1].withValues(alpha: 0.08),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: colors[0].withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  '@${m.name}',
                                  style: TextStyle(
                                    color: colors[0],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          if (_pastedImageBytes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: SizedBox(
                height: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(_pastedImageBytes.length, (
                        index,
                      ) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _pastedImageBytes[index],
                                  width: 112,
                                  height: 74,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: -5,
                                right: -5,
                                child: GestureDetector(
                                  onTap: () => _removePastedImage(index),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          // 输入框 + 发送按钮
          SizedBox(
            width: double.infinity,
            height: 136,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.borderSubtle),
                    color: AppTheme.surfaceElevated,
                  ),
                  child: Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.keyV, meta: true):
                          _PasteClipboardIntent(),
                      SingleActivator(LogicalKeyboardKey.keyV, control: true):
                          _PasteClipboardIntent(),
                    },
                    child: Actions(
                      actions: <Type, Action<Intent>>{
                        _PasteClipboardIntent:
                            CallbackAction<_PasteClipboardIntent>(
                              onInvoke: (_) {
                                _handlePaste();
                                return null;
                              },
                            ),
                      },
                      child: Focus(
                        onKeyEvent: (node, event) => _handleMessageKeyEvent(
                          event,
                          context,
                          conv,
                          members,
                          convProvider,
                        ),
                        child: TextField(
                          controller: _messageController,
                          focusNode: _focusNode,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: const InputDecoration(
                            hintText: '输入消息... 使用 @成员名称 触发AI回复',
                            hintStyle: TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.fromLTRB(16, 16, 76, 16),
                          ),
                          expands: true,
                          minLines: null,
                          maxLines: null,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: _buildSendButton(context, conv, members, convProvider),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  KeyEventResult _handleMessageKeyEvent(
    KeyEvent event,
    BuildContext context,
    Conversation conv,
    List<Member> members,
    ConversationProvider convProvider,
  ) {
    final isEnter =
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter;
    if (!isEnter || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    // Shift+Enter 保留 TextField 的默认行为，用于输入换行；同时兼容中文输入法确认候选词。
    if (HardwareKeyboard.instance.isShiftPressed ||
        (_messageController.value.composing.isValid &&
            !_messageController.value.composing.isCollapsed)) {
      return KeyEventResult.ignored;
    }

    // Enter 发送已有内容；空内容不插入空白行，也不触发发送。
    final hasContent =
        _messageController.text.trim().isNotEmpty ||
        _pastedImageDatas.isNotEmpty;
    if (hasContent && !convProvider.isAiResponding) {
      _sendMessage(context, conv, members);
    }
    return KeyEventResult.handled;
  }

  Widget _buildSendButton(
    BuildContext context,
    Conversation conv,
    List<Member> members,
    ConversationProvider convProvider,
  ) {
    return MouseRegion(
      cursor: convProvider.isAiResponding
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: convProvider.isAiResponding
            ? null
            : () => _sendMessage(context, conv, members),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: convProvider.isAiResponding
                ? null
                : AppTheme.primaryGradient,
            color: convProvider.isAiResponding
                ? AppTheme.surfaceElevated
                : null,
            border: convProvider.isAiResponding
                ? Border.all(color: AppTheme.borderSubtle)
                : null,
            boxShadow: convProvider.isAiResponding
                ? null
                : AppTheme.glowShadow(AppTheme.primaryCyan, blur: 16),
          ),
          child: convProvider.isAiResponding
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryCyan,
                    ),
                  ),
                )
              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Future<void> _handlePaste() async {
    final imageBytes = await Pasteboard.image;
    if (imageBytes != null && imageBytes.isNotEmpty) {
      _appendPastedImage(imageBytes);
      return;
    }

    // 支持从文件管理器一次粘贴多个图片文件。
    try {
      final files = await Pasteboard.files();
      var addedImage = false;
      for (final filePath in files) {
        if (!_isImageFile(filePath)) continue;
        try {
          final bytes = await File(filePath).readAsBytes();
          if (bytes.isNotEmpty) {
            _appendPastedImage(bytes, mimeType: _imageMimeType(filePath));
            addedImage = true;
          }
        } catch (_) {
          // 忽略无法读取的单个文件，继续处理其他图片。
        }
      }
      if (addedImage) return;
    } catch (_) {
      // 当前平台不支持读取文件剪贴板时，继续尝试粘贴文本。
    }

    // 剪贴板不是图片时，保留普通文字粘贴能力。
    final text = await Pasteboard.text;
    if (text == null || text.isEmpty) return;

    final value = _messageController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final start = selection.start.clamp(0, value.text.length);
    final end = selection.end.clamp(start, value.text.length);
    final newText = value.text.replaceRange(start, end, text);
    _messageController.value = value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: start + text.length),
      composing: TextRange.empty,
    );
  }

  void _appendPastedImage(Uint8List bytes, {String mimeType = 'image/png'}) {
    if (!mounted) return;
    setState(() {
      _pastedImageBytes.add(bytes);
      _pastedImageDatas.add('data:$mimeType;base64,${base64Encode(bytes)}');
    });
    _focusNode.requestFocus();
  }

  bool _isImageFile(String filePath) {
    final path = filePath.toLowerCase();
    return path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.gif') ||
        path.endsWith('.webp') ||
        path.endsWith('.bmp') ||
        path.endsWith('.heic') ||
        path.endsWith('.heif');
  }

  String _imageMimeType(String filePath) {
    final extension = filePath.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'bmp':
        return 'image/bmp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/png';
    }
  }

  void _removePastedImage(int index) {
    if (index < 0 || index >= _pastedImageBytes.length) return;
    setState(() {
      _pastedImageBytes.removeAt(index);
      _pastedImageDatas.removeAt(index);
    });
  }

  void _clearPastedImages() {
    _pastedImageBytes.clear();
    _pastedImageDatas.clear();
  }

  Future<void> _sendMessage(
    BuildContext context,
    Conversation conv,
    List<Member> members,
  ) async {
    final content = _messageController.text.trim();
    final imageDatas = List<String>.from(_pastedImageDatas);
    if (content.isEmpty && imageDatas.isEmpty) return;

    final convProvider = context.read<ConversationProvider>();

    // 解析@成员：按消息中第一次出现的位置收集被@成员，其他成员保持原顺序。
    final responderOrder = _buildResponderOrder(content, conv, members);

    if (responderOrder.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('没有可用的AI成员')));
      return;
    }

    _messageController.clear();
    _clearPastedImages();
    _messageListAutoScrollToken++;
    _messageScrollRequestToken++;
    _messageListUserScrollActive = false;
    _isMessageListAtBottom = true;
    _scheduleMessageListPositionUpdate(force: true);

    await convProvider.sendMessage(
      conversationId: conv.id,
      content: content,
      imageDatas: imageDatas,
      responderOrder: responderOrder,
      allMembers: context.read<MemberProvider>().members,
    );
  }

List<String> _buildResponderOrder(
    String content,
    Conversation conv,
    List<Member> members,
  ) {
    final membersById = {for (final member in members) member.id: member};
    final orderedMembers = <Member>[];
    for (final memberId in conv.memberIds) {
      final member = membersById[memberId];
      if (member != null) orderedMembers.add(member);
    }

    // 解析被@的成员
    final mentionedMembers = <Member>[];
    final mentionPositions = <String, int>{};
    for (final member in orderedMembers) {
      if (member.name.trim().isEmpty) continue;
      final position = content.indexOf('@${member.name}');
      if (position >= 0) {
        mentionedMembers.add(member);
        mentionPositions[member.id] = position;
      }
    }

    // 有@成员时，仅被@的成员按出现顺序发言
    if (mentionedMembers.isNotEmpty) {
      mentionedMembers.sort(
        (a, b) => mentionPositions[a.id]!.compareTo(mentionPositions[b.id]!),
      );
      final order = <String>[];
      for (final member in mentionedMembers) {
        if (!order.contains(member.id)) order.add(member.id);
      }
      return order;
    }

    // 无@成员时，所有成员随机顺序发言
    final shuffled = List<Member>.from(orderedMembers);
    shuffled.shuffle(Random());
    return shuffled.map((m) => m.id).toList();
  }

  Future<void> _showCreateConversationDialog(BuildContext context) async {
    final memberProvider = context.read<MemberProvider>();
    if (memberProvider.members.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加AI成员')));
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const CreateConversationDialog(),
    );

    if (result != null && context.mounted) {
      await context.read<ConversationProvider>().createConversation(
        title: result['title'] as String,
        memberIds: result['memberIds'] as List<String>,
      );
    }
  }

  Future<void> _endConversation(BuildContext context, String convId) async {
    await context.read<ConversationProvider>().endConversation(convId);
  }

  Future<void> _showConversationMenu(
    BuildContext context,
    Conversation conv,
  ) async {
    final buttonContext = _conversationMenuKey.currentContext;
    if (buttonContext == null) return;

    final button = buttonContext.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (button == null || overlay == null) return;

    final topLeft = button.localToGlobal(Offset.zero, ancestor: overlay);
    final buttonRect = topLeft & button.size;
    final position = RelativeRect.fromLTRB(
      buttonRect.left,
      buttonRect.bottom + 4,
      overlay.size.width - buttonRect.right,
      overlay.size.height - buttonRect.bottom,
    );

    final action = await showMenu<String>(
      context: context,
      position: position,
      color: AppTheme.surfaceCard,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: _buildPopupMenuItem(
            icon: Icons.edit_outlined,
            label: '修改标题',
            color: AppTheme.primaryCyan,
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: _buildPopupMenuItem(
            icon: Icons.delete_outline,
            label: '删除对话',
            color: AppTheme.accentPink,
          ),
        ),
      ],
    );

    if (!context.mounted) return;
    switch (action) {
      case 'rename':
        await _showRenameConversationDialog(context, conv);
      case 'delete':
        await context.read<ConversationProvider>().deleteConversation(conv.id);
    }
  }

  Widget _buildPopupMenuItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _showRenameConversationDialog(
    BuildContext context,
    Conversation conv,
  ) async {
    final conversationProvider = context.read<ConversationProvider>();
    final controller = TextEditingController(text: conv.title);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSave = controller.text.trim().isNotEmpty;
            return Dialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppTheme.borderSubtle),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '修改对话标题',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 60,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: '请输入对话标题',
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppTheme.textMuted,
                            size: 18,
                          ),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                        onSubmitted: canSave
                            ? (_) => Navigator.of(
                                dialogContext,
                              ).pop(controller.text.trim())
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('取消'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: canSave
                                ? () => Navigator.of(
                                    dialogContext,
                                  ).pop(controller.text.trim())
                                : null,
                            child: const Text('保存'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    controller.dispose();
    if (title == null || title.trim().isEmpty) return;

    await conversationProvider.renameConversation(conv.id, title.trim());
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(time).inDays == 1) {
      return '昨天';
    } else {
      return '${time.month}/${time.day}';
    }
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen)}...';
  }
}
