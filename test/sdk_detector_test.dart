import 'package:aigroup_desktop/models/member.dart';
import 'package:aigroup_desktop/services/sdk_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('各AI工具包含指定的精确扫描路径', () {
    const expectedPaths = {
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
      AiTool.zcode: [
        '~/.zcode/cli/zcode',
        '~/.zcode/cli/bin/zcode',
        '~/.local/bin/zcode',
        '/opt/homebrew/bin/zcode',
        '/usr/local/bin/zcode',
        '<npm-prefix>/bin/zcode',
        '/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs',
      ],
      AiTool.openCode: ['~/.opencode'],
      AiTool.claude: [
        '/Applications/Claude.app/Contents/MacOS/Claude',
        '~/Applications/Claude.app/Contents/MacOS/Claude',
      ],
      AiTool.codex: [
        '/Applications/ChatGPT.app/Contents/MacOS/ChatGPT',
        '~/Applications/ChatGPT.app/Contents/MacOS/ChatGPT',
      ],
    };

    for (final entry in expectedPaths.entries) {
      final detector = SdkDetector();
      final paths = [
        ...detector.fixedFilePathsForTesting(entry.key),
        ...detector.fixedDirectoryPathsForTesting(entry.key),
      ];
      expect(paths, containsAll(entry.value));
    }
  });

  test('新增入口文件纳入可执行文件名匹配', () {
    final detector = SdkDetector();

    expect(
      detector.executablesForTesting(AiTool.traeCode),
      containsAll(['traecli', 'traework', 'trae-work']),
    );
    expect(
      detector.fixedFilePathsForTesting(AiTool.traeCode),
      contains(
        '/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code',
      ),
    );
    expect(
      detector.executablesForTesting(AiTool.codeBuudy),
      contains('codebuddy'),
    );
  });
}
