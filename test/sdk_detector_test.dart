import "dart:io";
import "package:aigroup_desktop/models/member.dart";
import "package:aigroup_desktop/services/sdk_detector.dart";
import "package:flutter_test/flutter_test.dart";

void main() {
  test("各AI工具包含指定的精确扫描路径", () {
    const expectedPaths = {
      AiTool.traeCode: [
        "/Applications/Trae CN.app/Contents/Resources/app/bin/trae-cn",
        "~/Applications/Trae CN.app/Contents/Resources/app/bin/trae-cn",
        "~/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code",
        "/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code",
        "~/.local/bin/traecli",
        "/opt/homebrew/bin/traecli",
        "/usr/local/bin/traecli",
        "~/.local/bin/traework",
        "~/.local/bin/trae-work",
        "/opt/homebrew/bin/traework",
        "/usr/local/bin/traework",
        "<npm-prefix>/bin/traework",
      ],
      AiTool.codeBuudy: [
        "~/.local/bin/codebuddy",
        "/opt/homebrew/bin/codebuddy",
        "/usr/local/bin/codebuddy",
        "<npm-prefix>/bin/codebuddy",
        "/Applications/CodeBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy",
        "/Applications/WorkBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy",
        "~/Applications/WorkBuddy.app/Contents/Resources/app.asar.unpacked/cli/bin/codebuddy",
      ],
      AiTool.zcode: [
        "~/.zcode/cli/zcode",
        "~/.zcode/cli/bin/zcode",
        "~/.local/bin/zcode",
        "/opt/homebrew/bin/zcode",
        "/usr/local/bin/zcode",
        "<npm-prefix>/bin/zcode",
        "/Applications/ZCode.app/Contents/Resources/glm/zcode.cjs",
      ],
      AiTool.openCode: ["~/.opencode"],
      AiTool.claude: [
        "/Applications/Claude.app/Contents/MacOS/Claude",
        "~/Applications/Claude.app/Contents/MacOS/Claude",
      ],
      AiTool.codex: [
        "/Applications/ChatGPT.app/Contents/MacOS/ChatGPT",
        "~/Applications/ChatGPT.app/Contents/MacOS/ChatGPT",
      ],
      AiTool.deepSeek: [
        "~/Library/Application Support/DSH Desktop/cli/*/bin/dsh",
        "~/Library/Application Support/DSH Desktop/cli/*/dsh",
        "~/Library/Application Support/DSH Desktop/cli",
        "~/.local/bin/dsh",
        "/opt/homebrew/bin/dsh",
        "/usr/local/bin/dsh",
        "<npm-prefix>/bin/dsh",
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

  test("新增入口文件纳入可执行文件名匹配", () {
    final detector = SdkDetector();

    expect(
      detector.executablesForTesting(AiTool.traeCode),
      containsAll(["traecli", "traework", "trae-work"]),
    );
    expect(
      detector.fixedFilePathsForTesting(AiTool.traeCode),
      contains(
        "/Applications/TRAE SOLO CN.app/Contents/Resources/app/bin/code",
      ),
    );
    expect(
      detector.executablesForTesting(AiTool.codeBuudy),
      contains("codebuddy"),
    );
    expect(
      detector.executablesForTesting(AiTool.deepSeek),
      containsAll(["dsh", "deepseek"]),
    );
  });

  test("DeepSeek 动态 hash 目录与通配路径扫描验证", () async {
    final detector = SdkDetector();
    final tempDir = await Directory.systemTemp.createTemp("deepseek_test_");

    try {
      final randomHash = "68693d02ab4fbb2331b8cc39915322e48e61f06d4d1b31e7d19913202857bc8a";
      final binDir = Directory("${tempDir.path}/cli/$randomHash/bin");
      await binDir.create(recursive: true);
      final dshFile = File("${binDir.path}/dsh");
      await dshFile.writeAsString("#!/bin/sh\necho 0.1.1-rc.2");
      await Process.run("chmod", ["+x", dshFile.path]);

      // 1. 验证通配路径匹配
      final wildcardResult = await detector.validatePath(
        "${tempDir.path}/cli/*/bin/dsh",
        AiTool.deepSeek,
      );
      expect(wildcardResult.found, isTrue);
      expect(wildcardResult.path, equals(dshFile.path));

      // 2. 验证父级目录扫描匹配
      final dirResult = await detector.validatePath(
        "${tempDir.path}/cli",
        AiTool.deepSeek,
      );
      expect(dirResult.found, isTrue);
      expect(dirResult.path, equals(dshFile.path));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
