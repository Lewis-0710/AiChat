import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/member.dart';

/// 获取真实的用户 HOME 目录（绕过 macOS 沙盒）
String _getRealHome() {
  // 优先使用 USER 环境变量构造路径
  final user = Platform.environment['USER'];
  if (user != null && user.isNotEmpty) {
    final realHome = '/Users/$user';
    if (Directory(realHome).existsSync()) {
      return realHome;
    }
  }

  // 回退到 Platform.environment
  return Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '';
}

/// SDK检测结果
class SdkDetectionResult {
  final bool found;
  final String? path;
  final String? version;

  SdkDetectionResult({required this.found, this.path, this.version});
}

/// SDK检测服务：在本地查找AI工具SDK
class SdkDetector {
  static final SdkDetector _instance = SdkDetector._internal();
  factory SdkDetector() => _instance;
  SdkDetector._internal();

  @visibleForTesting
  List<String> executablesForTesting(AiTool tool) =>
      _executables[tool] ?? const [];

  @visibleForTesting
  List<String> fixedFilePathsForTesting(AiTool tool) =>
      _fixedFilePaths[tool] ?? const [];

  @visibleForTesting
  List<String> fixedDirectoryPathsForTesting(AiTool tool) =>
      _fixedDirectoryPaths[tool] ?? const [];

  /// AI工具对应的可执行文件名
  static const Map<AiTool, List<String>> _executables = {
    AiTool.codex: ['codex'],
    AiTool.claude: ['claude'],
    AiTool.openCode: ['opencode'],
    AiTool.pi: ['pi'],
    AiTool.goose: ['goose'],
    AiTool.cursor: ['cursor'],
    AiTool.zcode: ['zcode'],
    AiTool.traeCode: ['trae-cn', 'traecli', 'traework', 'trae-work'],
    AiTool.codeBuudy: ['codebuddy', 'codebuudy'],
  };

  /// 各工具的精确候选文件路径
  static const Map<AiTool, List<String>> _fixedFilePaths = {
    AiTool.codex: [
      '/Applications/ChatGPT.app/Contents/MacOS/ChatGPT',
      '~/Applications/ChatGPT.app/Contents/MacOS/ChatGPT',
    ],
    AiTool.claude: [
      '/Applications/Claude.app/Contents/MacOS/Claude',
      '~/Applications/Claude.app/Contents/MacOS/Claude',
    ],
    AiTool.zcode: [
      '~/.zcode/cli/zcode',
      '~/.zcode/cli/bin/zcode',
      '~/.local/bin/zcode',
      '/opt/homebrew/bin/zcode',
      '/usr/local/bin/zcode',
      '<npm-prefix>/bin/zcode',
      '/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs',
    ],
    AiTool.traeCode: [
      '/Applications/Trae CN.app/Contents/Resources/app/bin/trae-cn',
      '~/Applications/Trae CN.app/Contents/Resources/app/bin/trae-cn',
      '~/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code',
      '/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code',
      '~/.local/bin/traecli',
      '/opt/homebrew/bin/traecli',
      '/usr/local/bin/traecli',
      '~/.local/bin/traework',
      '~/.local/bin/trae-work',
      '/opt/homebrew/bin/traework',
      '/usr/local/bin/traework',
      '<npm-prefix>/bin/traework',
    ],
    AiTool.codeBuudy: [
      '~/.local/bin/codebuddy',
      '/opt/homebrew/bin/codebuddy',
      '/usr/local/bin/codebuddy',
      '<npm-prefix>/bin/codebuddy',
      '/Applications/CodeBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy',
      '/Applications/WorkBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy',
      '~/Applications/WorkBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy',
    ],
  };

  /// 各工具需要作为目录搜索的路径
  static const Map<AiTool, List<String>> _fixedDirectoryPaths = {
    AiTool.codex: ['~/.codemoss/dependencies/codex-sdk/node_modules'],
    AiTool.claude: ['~/.codemoss/dependencies/claude-sdk/node_modules'],
    AiTool.openCode: ['~/.opencode'],
  };

  String? _cachedNpmPrefix;
  bool _npmPrefixResolved = false;

  /// 在本地系统中检测SDK
  Future<SdkDetectionResult> detect(AiTool tool) async {
    final execNames = _executables[tool] ?? [];
    debugPrint('[SdkDetector] detect() 开始检测 $tool，查找: $execNames');

    // 1. 先尝试 which/where 命令
    for (final exec in execNames) {
      final result = await _findInPath(exec);
      if (result != null) {
        debugPrint('[SdkDetector] 在 PATH 中找到: $result');
        final version = await _getVersion(result);
        return SdkDetectionResult(found: true, path: result, version: version);
      }
    }

    // 2. 检查各工具的精确候选文件
    final fixedFilePaths = await _expandPaths(_fixedFilePaths[tool] ?? []);
    for (final filePath in fixedFilePaths) {
      final found = await _checkExecutable(filePath);
      if (found != null) {
        debugPrint('[SdkDetector] 在固定路径中找到: $found');
        final version = await _getVersion(found);
        return SdkDetectionResult(found: true, path: found, version: version);
      }
    }

    // 3. 搜索常见安装路径
    final searchPaths = await _expandPaths([
      ...?_fixedDirectoryPaths[tool],
      ..._getSearchPaths(tool),
    ]);
    debugPrint('[SdkDetector] 搜索路径列表: $searchPaths');
    for (final dirPath in searchPaths) {
      final found = await _findExecutableIn(dirPath, execNames, tool);
      if (found != null) {
        debugPrint('[SdkDetector] 在搜索路径中找到: $found');
        final version = await _getVersion(found);
        return SdkDetectionResult(found: true, path: found, version: version);
      }
    }

    // 4. macOS: 搜索 /Applications 下的 .app 包
    if (Platform.isMacOS) {
      debugPrint('[SdkDetector] 搜索 /Applications 下的 .app 包');
      final found = await _searchMacOSApps(execNames);
      if (found != null) {
        debugPrint('[SdkDetector] 在 .app 包中找到: $found');
        final version = await _getVersion(found);
        return SdkDetectionResult(found: true, path: found, version: version);
      }
    }

    // 5. 扫描用户 HOME 目录下的常见隐藏目录
    final home = _getRealHome();
    if (home.isNotEmpty) {
      debugPrint('[SdkDetector] 扫描用户 HOME 目录下的隐藏目录');
      final found = await _scanUserHomeDirs(home, execNames, tool);
      if (found != null) {
        debugPrint('[SdkDetector] 在用户目录中找到: $found');
        final version = await _getVersion(found);
        return SdkDetectionResult(found: true, path: found, version: version);
      }
    }

    debugPrint('[SdkDetector] 自动检测未找到 $tool');
    return SdkDetectionResult(found: false);
  }

  /// 验证用户手动配置的路径是否有效
  Future<SdkDetectionResult> validatePath(String userPath, AiTool tool) async {
    final execNames = _executables[tool] ?? [];
    debugPrint('[SdkDetector] validatePath() 开始验证');
    debugPrint('[SdkDetector]   用户输入: $userPath');
    debugPrint('[SdkDetector]   工具: $tool');
    debugPrint('[SdkDetector]   查找文件: $execNames');

    final expandedPath = (await _expandPath(userPath)).trim();
    debugPrint('[SdkDetector]   展开后: $expandedPath');

    if (expandedPath.isEmpty) {
      debugPrint('[SdkDetector]   路径为空，返回 false');
      return SdkDetectionResult(found: false);
    }

    // 检查路径是否存在
    final pathType = await FileSystemEntity.type(expandedPath);
    debugPrint('[SdkDetector]   路径类型: $pathType');

    if (pathType == FileSystemEntityType.notFound) {
      debugPrint('[SdkDetector]   路径不存在，返回 false');
      return SdkDetectionResult(found: false);
    }

    // 如果是文件，直接检查
    if (pathType == FileSystemEntityType.file) {
      debugPrint('[SdkDetector]   路径是文件，检查是否匹配');
      final fileName = Uri.parse(expandedPath).pathSegments.last;
      final baseName = fileName.split('.').first;
      if (execNames.contains(baseName) || execNames.contains(fileName)) {
        debugPrint('[SdkDetector]   文件名匹配: $fileName');
        final version = await _getVersion(expandedPath);
        return SdkDetectionResult(
          found: true,
          path: expandedPath,
          version: version,
        );
      }
      final version = await _getVersion(expandedPath);
      if (version != null) {
        debugPrint('[SdkDetector]   可执行文件，版本: $version');
        return SdkDetectionResult(
          found: true,
          path: expandedPath,
          version: version,
        );
      }
      debugPrint('[SdkDetector]   文件不匹配，返回 false');
      return SdkDetectionResult(found: false);
    }

    // 如果是目录，在其中搜索
    if (pathType == FileSystemEntityType.directory) {
      debugPrint('[SdkDetector]   路径是目录，开始搜索');
      final found = await _findExecutableIn(expandedPath, execNames, tool);
      if (found != null) {
        debugPrint('[SdkDetector]   在目录中找到: $found');
        final version = await _getVersion(found);
        return SdkDetectionResult(found: true, path: found, version: version);
      }
      debugPrint('[SdkDetector]   在目录中未找到，返回 false');
    }

    return SdkDetectionResult(found: false);
  }

  /// 在目录中智能查找可执行文件
  Future<String?> _findExecutableIn(
    String dirPath,
    List<String> execNames,
    AiTool tool,
  ) async {
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      debugPrint('[SdkDetector]     _findExecutableIn: 目录不存在 $dirPath');
      return null;
    }

    debugPrint('[SdkDetector]     _findExecutableIn: 搜索目录 $dirPath');

    // 1. 直接子文件
    for (final exec in execNames) {
      final path = '${dir.path}/$exec';
      final found = await _checkExecutable(path);
      if (found != null) {
        debugPrint('[SdkDetector]     步骤1 找到直接子文件: $found');
        return found;
      }
    }

    // 2. .bin 子目录 (node_modules 标准模式)
    final binDir = Directory('${dir.path}/.bin');
    if (await binDir.exists()) {
      debugPrint('[SdkDetector]     步骤2 检查 .bin 目录');
      for (final exec in execNames) {
        final path = '${binDir.path}/$exec';
        final found = await _checkExecutable(path);
        if (found != null) {
          debugPrint('[SdkDetector]     步骤2 找到: $found');
          return found;
        }
      }
    }

    // 3. bin 子目录
    final binDir2 = Directory('${dir.path}/bin');
    if (await binDir2.exists()) {
      debugPrint('[SdkDetector]     步骤3 检查 bin 目录');
      for (final exec in execNames) {
        final path = '${binDir2.path}/$exec';
        final found = await _checkExecutable(path);
        if (found != null) {
          debugPrint('[SdkDetector]     步骤3 找到: $found');
          return found;
        }
      }
    }

    // 4. node_modules/.bin 子目录
    final nmBinDir = Directory('${dir.path}/node_modules/.bin');
    if (await nmBinDir.exists()) {
      debugPrint('[SdkDetector]     步骤4 检查 node_modules/.bin 目录');
      for (final exec in execNames) {
        final path = '${nmBinDir.path}/$exec';
        final found = await _checkExecutable(path);
        if (found != null) {
          debugPrint('[SdkDetector]     步骤4 找到: $found');
          return found;
        }
      }
    }

    // 5. 工具特定的深层搜索策略
    final toolSpecific = await _toolSpecificSearch(dir.path, execNames, tool);
    if (toolSpecific != null) {
      debugPrint('[SdkDetector]     步骤5 工具特定搜索找到: $toolSpecific');
      return toolSpecific;
    }

    // 6. 通用递归搜索子目录（深度限制3层）
    final deepFound = await _deepSearch(dir.path, execNames, 0, 3);
    if (deepFound != null) {
      debugPrint('[SdkDetector]     步骤6 深层搜索找到: $deepFound');
      return deepFound;
    }

    debugPrint('[SdkDetector]     所有步骤均未找到');
    return null;
  }

  /// 工具特定的搜索策略
  Future<String?> _toolSpecificSearch(
    String basePath,
    List<String> execNames,
    AiTool tool,
  ) async {
    switch (tool) {
      case AiTool.codex:
        return await _searchScopedPackage(basePath, '@openai', execNames, [
          'bin',
        ]);

      case AiTool.claude:
        final result = await _searchScopedPackage(
          basePath,
          '@anthropic-ai',
          execNames,
          [],
          packagePrefix: 'claude',
        );
        if (result != null) return result;
        final binLink = '$basePath/.bin/anthropic-ai-sdk';
        final binFile = File(binLink);
        if (await binFile.exists()) {
          return binLink;
        }
        return null;

      case AiTool.openCode:
        final result = await _searchScopedPackage(
          basePath,
          '@opencode-ai',
          execNames,
          ['bin'],
        );
        if (result != null) return result;
        final binOpencode = '$basePath/bin/opencode';
        final f = File(binOpencode);
        if (await f.exists()) return binOpencode;
        return null;

      case AiTool.pi:
      case AiTool.goose:
      case AiTool.cursor:
      case AiTool.zcode:
      case AiTool.traeCode:
      case AiTool.codeBuudy:
        return null;
    }
  }

  /// 搜索 scoped package 目录
  Future<String?> _searchScopedPackage(
    String basePath,
    String scope,
    List<String> execNames,
    List<String> subDirs, {
    String? packagePrefix,
  }) async {
    final scopeDir = Directory('$basePath/$scope');
    if (!await scopeDir.exists()) return null;

    try {
      await for (final entity in scopeDir.list(followLinks: true)) {
        if (entity is Directory) {
          final dirName = entity.uri.pathSegments
              .where((s) => s.isNotEmpty)
              .last;
          if (packagePrefix != null && !dirName.startsWith(packagePrefix)) {
            continue;
          }

          if (subDirs.isEmpty) {
            for (final exec in execNames) {
              final found = await _checkExecutable('${entity.path}/$exec');
              if (found != null) return found;
            }
          } else {
            for (final sub in subDirs) {
              final subDir = Directory('${entity.path}/$sub');
              if (await subDir.exists()) {
                for (final exec in execNames) {
                  final found = await _checkExecutable('${subDir.path}/$exec');
                  if (found != null) return found;
                }
              }
            }
            for (final exec in execNames) {
              final found = await _checkExecutable('${entity.path}/$exec');
              if (found != null) return found;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// 通用深层递归搜索
  Future<String?> _deepSearch(
    String dirPath,
    List<String> execNames,
    int depth,
    int maxDepth,
  ) async {
    if (depth >= maxDepth) return null;

    try {
      final dir = Directory(dirPath);
      await for (final entity in dir.list(followLinks: true)) {
        if (entity is Directory) {
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;

          if (name.startsWith('.') && name != '.bin') {
            continue;
          }
          if (['dist', 'build', 'test', 'tests', '__tests__'].contains(name)) {
            continue;
          }

          for (final exec in execNames) {
            final found = await _checkExecutable('${entity.path}/$exec');
            if (found != null) return found;
          }

          for (final binName in ['bin', '.bin']) {
            final binDir = Directory('${entity.path}/$binName');
            if (await binDir.exists()) {
              for (final exec in execNames) {
                final found = await _checkExecutable('${binDir.path}/$exec');
                if (found != null) return found;
              }
            }
          }

          if (name != 'node_modules') {
            final found = await _deepSearch(
              entity.path,
              execNames,
              depth + 1,
              maxDepth,
            );
            if (found != null) return found;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// 检查路径是否为有效可执行文件
  Future<String?> _checkExecutable(String basePath) async {
    final file = File(basePath);
    if (await file.exists()) {
      return basePath;
    }

    for (final ext in ['.js', '.sh', '.cmd', '.exe', '.bat']) {
      final withExt = File('$basePath$ext');
      if (await withExt.exists()) {
        return '$basePath$ext';
      }
    }

    return null;
  }

  /// 在 PATH 中查找可执行文件
  Future<String?> _findInPath(String execName) async {
    try {
      final command = Platform.isWindows ? 'where' : 'which';
      final result = await Process.run(command, [execName]);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim().split('\n').first.trim();
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}
    return null;
  }

  /// 获取SDK版本
  Future<String?> _getVersion(String path) async {
    try {
      if (path.endsWith('.js') ||
          path.endsWith('.cjs') ||
          path.endsWith('.mjs')) {
        final file = File(path);
        if (await file.exists()) {
          final content = await file
              .openRead(0, 256)
              .fold<List<int>>([], (prev, chunk) => prev..addAll(chunk));
          final firstLine = String.fromCharCodes(content).split('\n').first;
          if (firstLine.startsWith('#!')) {
            try {
              final result = await Process.run(path, [
                '--version',
              ]).timeout(const Duration(seconds: 5));
              if (result.exitCode == 0) {
                return _parseVersion(result.stdout as String);
              }
            } catch (_) {}
          }
          try {
            final result = await Process.run('node', [
              path,
              '--version',
            ]).timeout(const Duration(seconds: 5));
            if (result.exitCode == 0) {
              return _parseVersion(result.stdout as String);
            }
          } catch (_) {}
        }
        return null;
      }

      final result = await Process.run(path, [
        '--version',
      ]).timeout(const Duration(seconds: 5));
      if (result.exitCode == 0) {
        return _parseVersion(result.stdout as String);
      }
    } catch (_) {}
    return null;
  }

  /// 从版本输出中提取版本号
  String? _parseVersion(String output) {
    final trimmed = output.trim();
    if (trimmed.isEmpty) return null;
    final firstLine = trimmed.split('\n').first.trim();
    final versionRegex = RegExp(r'v?(\d+\.\d+\.\d+[^\s]*)');
    final match = versionRegex.firstMatch(firstLine);
    if (match != null) {
      return match.group(0);
    }
    return firstLine;
  }

  /// 扫描用户 HOME 目录下的常见隐藏目录
  /// 查找模式: ~/.*  (如 ~/.codemoss, ~/.opencode, ~/.local 等)
  Future<String?> _scanUserHomeDirs(
    String home,
    List<String> execNames,
    AiTool tool,
  ) async {
    final homeDir = Directory(home);
    if (!await homeDir.exists()) return null;

    try {
      await for (final entity in homeDir.list(followLinks: false)) {
        if (entity is Directory) {
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
          // 只处理以 . 开头的隐藏目录
          if (name.startsWith('.')) {
            debugPrint('[SdkDetector]   检查隐藏目录: $name');

            // 检查目录本身
            final found = await _findExecutableIn(entity.path, execNames, tool);
            if (found != null) return found;

            // 如果是 dependencies 类型的目录，扫描其子目录
            if (name == '.codemoss' || name.contains('dependencies')) {
              final depsDir = Directory('${entity.path}/dependencies');
              if (await depsDir.exists()) {
                debugPrint('[SdkDetector]     扫描 dependencies 子目录');
                await for (final dep in depsDir.list(followLinks: true)) {
                  if (dep is Directory) {
                    // 检查 node_modules 子目录
                    final nmDir = Directory('${dep.path}/node_modules');
                    if (await nmDir.exists()) {
                      final found = await _findExecutableIn(
                        nmDir.path,
                        execNames,
                        tool,
                      );
                      if (found != null) return found;
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// 搜索 macOS /Applications 目录下的 .app 包
  Future<String?> _searchMacOSApps(List<String> execNames) async {
    if (!Platform.isMacOS) return null;

    final appsDir = Directory('/Applications');
    if (!await appsDir.exists()) return null;

    try {
      await for (final entity in appsDir.list(followLinks: true)) {
        if (entity is Directory) {
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
          if (name.endsWith('.app')) {
            final binDir = Directory('${entity.path}/Contents/Resources/bin');
            if (await binDir.exists()) {
              for (final exec in execNames) {
                final execFile = File('${binDir.path}/$exec');
                if (await execFile.exists()) {
                  return execFile.path;
                }
              }
            }

            final appBinDir = Directory(
              '${entity.path}/Contents/Resources/app/bin',
            );
            if (await appBinDir.exists()) {
              for (final exec in execNames) {
                final execFile = File('${appBinDir.path}/$exec');
                if (await execFile.exists()) {
                  return execFile.path;
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  /// 获取搜索路径
  List<String> _getSearchPaths(AiTool tool) {
    final home = _getRealHome();

    if (Platform.isMacOS) {
      return [
        '/usr/local/bin',
        '/opt/homebrew/bin',
        '/usr/bin',
        '$home/.local/bin',
        '$home/.npm-global/bin',
        '$home/.npm-global/lib/node_modules',
        '$home/.nvm/current/bin',
      ];
    } else if (Platform.isWindows) {
      final username = Platform.environment['USERNAME'] ?? '';
      return [
        r'C:\Program Files',
        r'C:\Program Files (x86)',
        'C:\\Users\\$username\\AppData\\Local\\Programs',
        'C:\\Users\\$username\\AppData\\Roaming\\npm',
      ];
    }
    return [];
  }

  Future<List<String>> _expandPaths(List<String> paths) async {
    if (paths.isEmpty) return [];
    final npmPrefix = await _getNpmPrefix();
    final expandedPaths = <String>[];
    for (final path in paths) {
      expandedPaths.add(await _expandPath(path, npmPrefix: npmPrefix));
    }
    return expandedPaths;
  }

  Future<String?> _getNpmPrefix() async {
    if (_npmPrefixResolved) return _cachedNpmPrefix;
    _npmPrefixResolved = true;
    try {
      final result = await Process.run('npm', [
        'config',
        'get',
        'prefix',
      ]).timeout(const Duration(seconds: 3));
      if (result.exitCode == 0) {
        final prefix = (result.stdout as String).trim();
        if (prefix.isNotEmpty && !prefix.contains('\n')) {
          _cachedNpmPrefix = prefix;
        }
      }
    } catch (_) {}
    return _cachedNpmPrefix;
  }

  /// 展开路径中的环境变量
  Future<String> _expandPath(String path, {String? npmPrefix}) async {
    var result = path;
    if (result.startsWith('~/') || result == '~') {
      final home = _getRealHome();
      result = result.replaceFirst('~', home);
    }
    if (npmPrefix != null) {
      result = result.replaceAll('<npm-prefix>', npmPrefix);
    }
    Platform.environment.forEach((key, value) {
      result = result.replaceAll('%$key%', value);
      result = result.replaceAll('\$$key', value);
    });
    return result;
  }
}
