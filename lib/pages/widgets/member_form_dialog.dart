import 'package:flutter/material.dart';
import '../../models/member.dart';
import '../../utils/constants.dart';
import '../../services/model_fetcher.dart';
import '../../services/sdk_detector.dart';
import '../../theme/app_theme.dart';

/// 成员添加/编辑弹窗 - 科技感风格
class MemberFormDialog extends StatefulWidget {
  final Member? member;

  const MemberFormDialog({super.key, this.member});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _sdkPathController;

  late AiTool _selectedTool;
  late AccessType _selectedAccessType;
  String? _selectedModel;
  List<ModelInfo> _availableModels = [];
  bool _isLoadingModels = false;
  bool _isDetectingSdk = false;
  bool _isValidatingPath = false;
  SdkDetectionResult? _sdkResult;
  String? _modelError;
  String? _pathValidationMessage;

  bool get isEditing => widget.member != null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;

    _urlController = TextEditingController(text: m?.providerUrl ?? '');
    _apiKeyController = TextEditingController(text: m?.apiKey ?? '');
    _sdkPathController = TextEditingController(text: m?.sdkPath ?? '');
    _selectedTool = m?.aiTool ?? AiTool.codex;
    _selectedAccessType = _accessTypeForTool(_selectedTool, m?.accessType);
    _selectedModel = m?.modelId;

    if (isEditing) {
      _sdkResult = SdkDetectionResult(found: m!.sdkConfigured, path: m.sdkPath);
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _apiKeyController.dispose();
    _sdkPathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.primaryCyan.withValues(alpha: 0.15)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
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
                        child: Icon(
                          isEditing ? Icons.edit : Icons.person_add_alt_1,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? '编辑成员' : '添加新成员',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            isEditing ? '修改AI成员配置' : '配置AI成员信息',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection('AI工具', _buildAiToolSelector()),
                  const SizedBox(height: 16),
                  _buildSection('接入类型', _buildAccessTypeSelector()),
                  const SizedBox(height: 16),
                  _buildSection('SDK检测', _buildSdkSection()),
                  const SizedBox(height: 16),
                  _buildSection('SDK路径（手动配置）', _buildSdkPathField()),
                  const SizedBox(height: 16),
                  _buildSection('供应商URL', _buildUrlField()),
                  const SizedBox(height: 16),
                  _buildSection('API KEY', _buildApiKeyField()),
                  const SizedBox(height: 16),
                  _buildSection('模型', _buildModelSelector()),
                  const SizedBox(height: 28),
                  _buildActions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String label, Widget field) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 2),
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        field,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    ValueChanged<String>? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        color: AppTheme.surfaceElevated,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          prefixIcon: icon != null
              ? Icon(icon, color: AppTheme.textMuted, size: 18)
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  /// 根据AI工具决定接入类型：Codex和Claude只能使用对应的API，其他工具默认使用OpenAI Chat。
  AccessType _accessTypeForTool(AiTool tool, [AccessType? preferred]) {
    switch (tool) {
      case AiTool.codex:
        return AccessType.openaiResponse;
      case AiTool.claude:
        return AccessType.anthropic;
      default:
        return preferred ?? AccessType.openaiChat;
    }
  }

  bool get _isAccessTypeLocked =>
      _selectedTool == AiTool.codex || _selectedTool == AiTool.claude;

  List<AccessType> _availableAccessTypesForTool(AiTool tool) {
    switch (tool) {
      case AiTool.codex:
        return [AccessType.openaiResponse];
      case AiTool.claude:
        return [AccessType.anthropic];
      default:
        return AccessType.values;
    }
  }

  String get _providerUrlHint {
    if (_selectedTool == AiTool.deepSeek) {
      return ProviderDefaults.deepseek;
    }
    return _selectedAccessType == AccessType.anthropic
        ? ProviderDefaults.anthropic
        : ProviderDefaults.openai;
  }

  Widget _buildAiToolSelector() {
    return _buildDropdown<AiTool>(
      value: _selectedTool,
      items: AiTool.values,
      itemLabel: (tool) => tool.label,
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _selectedTool = v;
            _selectedAccessType = _accessTypeForTool(v);
            _availableModels = [];
            _selectedModel = null;
            _modelError = null;
            _sdkResult = null;
            _pathValidationMessage = null;
          });
          _detectSdk(v);
        }
      },
      icon: Icons.smart_toy_outlined,
      trailing: _sdkResult?.found == true
          ? const Icon(
              Icons.check_circle,
              color: AppTheme.accentGreen,
              size: 18,
            )
          : null,
    );
  }

  Widget _buildAccessTypeSelector() {
    return _buildDropdown<AccessType>(
      value: _selectedAccessType,
      items: _availableAccessTypesForTool(_selectedTool),
      itemLabel: (type) => type.label,
      onChanged: _isAccessTypeLocked
          ? null
          : (v) {
              if (v != null) {
                setState(() {
                  _selectedAccessType = v;
                  _availableModels = [];
                  _selectedModel = null;
                  _modelError = null;
                });
              }
            },
      icon: Icons.api,
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?>? onChanged,
    IconData? icon,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
        color: AppTheme.surfaceElevated,
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(icon, color: AppTheme.textMuted, size: 18),
            ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                dropdownColor: AppTheme.surfaceCard,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
                items: items.map((item) {
                  return DropdownMenuItem<T>(
                    value: item,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(itemLabel(item)),
                        if (trailing != null && item == value) trailing,
                      ],
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSdkSection() {
    // 根据状态决定边框和背景色
    Color borderColor;
    Color bgColor;
    if (_isDetectingSdk) {
      borderColor = AppTheme.primaryCyan.withValues(alpha: 0.3);
      bgColor = AppTheme.primaryCyan.withValues(alpha: 0.03);
    } else if (_sdkResult?.found == true) {
      borderColor = AppTheme.accentGreen.withValues(alpha: 0.3);
      bgColor = AppTheme.accentGreen.withValues(alpha: 0.03);
    } else if (_sdkResult != null && !_sdkResult!.found) {
      borderColor = AppTheme.accentPink.withValues(alpha: 0.2);
      bgColor = AppTheme.accentPink.withValues(alpha: 0.02);
    } else {
      borderColor = AppTheme.borderSubtle;
      bgColor = AppTheme.surfaceElevated;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        color: bgColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_isDetectingSdk)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.primaryCyan,
                  ),
                )
              else
                Icon(
                  _sdkResult?.found == true
                      ? Icons.check_circle
                      : Icons.search_off,
                  color: _sdkResult?.found == true
                      ? AppTheme.accentGreen
                      : AppTheme.textMuted,
                  size: 18,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isDetectingSdk
                      ? '正在检测 ${_selectedTool.label} ...'
                      : (_sdkResult?.found == true
                            ? '${_selectedTool.label} SDK 已检测到'
                            : (_sdkResult != null && !_sdkResult!.found)
                            ? '未自动检测到 ${_selectedTool.label}'
                            : '点击右侧按钮自动检测 ${_selectedTool.label}'),
                  style: TextStyle(
                    color: _isDetectingSdk
                        ? AppTheme.primaryCyan
                        : (_sdkResult?.found == true
                              ? AppTheme.accentGreen
                              : (_sdkResult != null && !_sdkResult!.found)
                              ? AppTheme.accentPink
                              : AppTheme.textSecondary),
                    fontSize: 13,
                    fontWeight: (_sdkResult != null || _isDetectingSdk)
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              _buildSmallButton(
                label: _isDetectingSdk ? '检测中...' : '自动检测',
                onTap: _isDetectingSdk ? null : () => _detectSdk(_selectedTool),
                color: _isDetectingSdk
                    ? AppTheme.textMuted
                    : AppTheme.primaryCyan,
              ),
            ],
          ),
          // 检测成功时显示详细信息
          if (_sdkResult != null && _sdkResult!.found) ...[
            if (_sdkResult!.version != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 26),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tag,
                      size: 12,
                      color: AppTheme.accentGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '版本: ${_sdkResult!.version}',
                      style: const TextStyle(
                        color: AppTheme.accentGreen,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            if (_sdkResult!.path != null)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 26),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '路径: ${_sdkResult!.path}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontFamily: 'Menlo',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          // 检测失败时显示提示
          if (_sdkResult != null && !_sdkResult!.found && !_isDetectingSdk)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 26),
              child: Row(
                children: [
                  const Icon(
                    Icons.arrow_downward,
                    size: 12,
                    color: AppTheme.accentPink,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '请在下方手动输入 ${_selectedTool.label} 可执行文件所在目录',
                      style: const TextStyle(
                        color: AppTheme.accentPink,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 自动生成成员名称
  String _generateMemberName() {
    final toolName = _selectedTool.label;
    final modelName = _selectedModel ?? '未选择模型';
    return '$toolName | $modelName';
  }

  /// 获取当前工具的推荐路径提示
  String _getSdkPathHint() {
    return '输入可执行文件所在目录路径';
  }

  /// 获取当前工具的路径说明
  String _getSdkPathDescription() {
    return '支持填写包含可执行文件的目录，或 node_modules 目录';
  }

  Widget _buildSdkPathField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 提示文本
        Padding(
          padding: const EdgeInsets.only(bottom: 6, left: 2),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: AppTheme.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _getSdkPathDescription(),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _pathValidationMessage != null
                        ? (_sdkResult?.found == true
                              ? AppTheme.accentGreen.withValues(alpha: 0.5)
                              : AppTheme.accentPink.withValues(alpha: 0.5))
                        : AppTheme.borderSubtle,
                  ),
                  color: AppTheme.surfaceElevated,
                ),
                child: TextFormField(
                  controller: _sdkPathController,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontFamily: 'Menlo',
                  ),
                  decoration: InputDecoration(
                    hintText: _getSdkPathHint(),
                    hintStyle: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontFamily: 'Menlo',
                    ),
                    prefixIcon: const Icon(
                      Icons.folder_outlined,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (_) {
                    setState(() {
                      _pathValidationMessage = null;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildSmallButton(
              label: _isValidatingPath ? '验证中...' : '验证路径',
              onTap: _isValidatingPath ? null : _validateSdkPath,
              color: AppTheme.primaryCyan,
            ),
          ],
        ),
        if (_pathValidationMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _sdkResult?.found == true
                  ? AppTheme.accentGreen.withValues(alpha: 0.08)
                  : AppTheme.accentPink.withValues(alpha: 0.08),
              border: Border.all(
                color: _sdkResult?.found == true
                    ? AppTheme.accentGreen.withValues(alpha: 0.2)
                    : AppTheme.accentPink.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _sdkResult?.found == true
                      ? Icons.check_circle
                      : Icons.error_outline,
                  size: 16,
                  color: _sdkResult?.found == true
                      ? AppTheme.accentGreen
                      : AppTheme.accentPink,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pathValidationMessage!,
                    style: TextStyle(
                      color: _sdkResult?.found == true
                          ? AppTheme.accentGreen
                          : AppTheme.accentPink,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSmallButton({
    required String label,
    required VoidCallback? onTap,
    required Color color,
  }) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
            color: color.withValues(alpha: 0.08),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrlField() {
    return _buildTextField(
      controller: _urlController,
      hintText: _providerUrlHint,
      icon: Icons.link,
      validator: (v) => v == null || v.trim().isEmpty ? '请输入供应商URL' : null,
      onChanged: (_) {
        setState(() {
          _availableModels = [];
          _selectedModel = null;
        });
      },
    );
  }

  Widget _buildApiKeyField() {
    return _buildTextField(
      controller: _apiKeyController,
      hintText: 'sk-xxxxxxxxxxxx',
      icon: Icons.key,
      obscureText: true,
      validator: (v) => v == null || v.trim().isEmpty ? '请输入API KEY' : null,
      onChanged: (_) {
        setState(() {
          _availableModels = [];
          _selectedModel = null;
        });
      },
    );
  }

  Widget _buildModelSelector() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _modelError != null
                        ? AppTheme.accentPink.withValues(alpha: 0.5)
                        : AppTheme.borderSubtle,
                  ),
                  color: AppTheme.surfaceElevated,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedModel,
                    isExpanded: true,
                    hint: const Text(
                      '选择模型',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                    ),
                    dropdownColor: AppTheme.surfaceCard,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                    items: _availableModels.map((m) {
                      return DropdownMenuItem(
                        value: m.id,
                        child: Text(m.id, style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: _isLoadingModels
                        ? null
                        : (v) => setState(() => _selectedModel = v),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _buildSmallButton(
              label: _isLoadingModels ? '加载中...' : '获取模型',
              onTap: _isLoadingModels ? null : _fetchModels,
              color: AppTheme.primaryCyan,
            ),
          ],
        ),
        if (_modelError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              _modelError!,
              style: const TextStyle(color: AppTheme.accentPink, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildActionButton(
          label: '取消',
          onTap: () => Navigator.of(context).pop(),
          isPrimary: false,
        ),
        const SizedBox(width: 10),
        _buildActionButton(
          label: isEditing ? '保存' : '添加',
          onTap: _save,
          isPrimary: true,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onTap,
    required bool isPrimary,
  }) {
    final enabled = onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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

  /// 自动检测SDK
  Future<void> _detectSdk(AiTool tool) async {
    setState(() {
      _isDetectingSdk = true;
      _sdkResult = null;
      _pathValidationMessage = null;
    });

    final result = await SdkDetector().detect(tool);
    if (!mounted) return;
    setState(() {
      _isDetectingSdk = false;
      _sdkResult = result;
      if (result.found && result.path != null) {
        _sdkPathController.text = result.path!;
        final versionStr = result.version != null
            ? '，版本: ${result.version}'
            : '';
        _pathValidationMessage = '自动检测成功！找到 ${tool.label}$versionStr';
      } else {
        _pathValidationMessage = '未自动检测到 ${tool.label}，请在下方手动输入路径';
      }
    });
  }

  /// 验证用户手动输入的SDK路径
  Future<void> _validateSdkPath() async {
    final path = _sdkPathController.text.trim();
    if (path.isEmpty) {
      setState(() {
        _pathValidationMessage = '请先输入SDK路径';
        _sdkResult = SdkDetectionResult(found: false);
      });
      return;
    }

    setState(() {
      _isValidatingPath = true;
      _pathValidationMessage = '正在验证路径...';
    });

    final result = await SdkDetector().validatePath(path, _selectedTool);
    if (!mounted) return;
    setState(() {
      _isValidatingPath = false;
      _sdkResult = result;
      if (result.found) {
        final versionStr = result.version != null
            ? '，版本: ${result.version}'
            : '';
        _pathValidationMessage = '验证通过！找到 ${_selectedTool.label}$versionStr';
      } else {
        _pathValidationMessage = '验证失败：在该路径下未找到 ${_selectedTool.label} 可执行文件';
      }
    });
  }

  Future<void> _fetchModels() async {
    final url = _urlController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (url.isEmpty || apiKey.isEmpty) {
      setState(() => _modelError = '请先填写供应商URL和API KEY');
      return;
    }

    setState(() {
      _isLoadingModels = true;
      _modelError = null;
    });

    try {
      final models = await ModelFetcher().fetchModels(
        providerUrl: url,
        apiKey: apiKey,
        accessType: _selectedAccessType,
      );
      setState(() {
        _isLoadingModels = false;
        _availableModels = models;
        if (models.isNotEmpty && _selectedModel == null) {
          _selectedModel = models.first.id;
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingModels = false;
        _modelError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedModel == null) {
      setState(() => _modelError = '请先获取并选择模型');
      return;
    }

    // 判断SDK是否配置：自动检测结果 或 手动路径验证通过
    final sdkFound = _sdkResult?.found == true;
    final sdkPathText = _sdkPathController.text.trim();

    final member = Member(
      id: widget.member?.id ?? '',
      name: _generateMemberName(),
      aiTool: _selectedTool,
      accessType: _selectedAccessType,
      providerUrl: _urlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      modelId: _selectedModel!,
      sdkPath: sdkPathText.isEmpty ? null : sdkPathText,
      sdkConfigured: sdkFound || sdkPathText.isNotEmpty,
    );

    Navigator.of(context).pop(member);
  }
}
