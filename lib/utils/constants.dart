/// 默认供应商URL
class ProviderDefaults {
  static const String openai = 'https://api.openai.com/v1';
  static const String anthropic = 'https://api.anthropic.com';
  static const String deepseek = 'https://api.deepseek.com';
}

/// SDK 默认搜索路径（按平台）
class SdkSearchPaths {
  /// macOS 上各AI工具的常见安装路径
  static const List<String> macos = [
    '/usr/local/bin',
    '/opt/homebrew/bin',
    '/usr/bin',
  ];

  /// Windows 上各AI工具的常见安装路径
  static const List<String> windows = [
    r'C:\Program Files',
    r'C:\Program Files (x86)',
    r'C:\Users\%USERNAME%\AppData\Local\Programs',
    r'C:\Users\%USERNAME%\AppData\Roaming\npm',
  ];
}

/// AI工具对应的可执行文件名
class AiToolExecutables {
  static const Map<String, List<String>> executables = {
    'codex': ['codex'],
    'claude': ['claude'],
    'openCode': ['opencode'],
    'pi': ['pi'],
    'zcode': ['zcode'],
    'traeCode': ['trae-cn'],
    'codeBuudy': ['codebuudy'],
    'deepSeek': ['dsh', 'deepseek'],
  };
}

/// 应用名称
const String appName = 'AI聊天室';
