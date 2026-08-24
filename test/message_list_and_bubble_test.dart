import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:provider/provider.dart";
import "package:aigroup_desktop/models/conversation.dart";
import "package:aigroup_desktop/models/message.dart";
import "package:aigroup_desktop/models/member.dart";
import "package:aigroup_desktop/providers/conversation_provider.dart";
import "package:aigroup_desktop/providers/member_provider.dart";
import "package:aigroup_desktop/pages/home_page.dart";
import "package:aigroup_desktop/pages/widgets/message_bubble.dart";

void main() {
  group("MessageBubble Widget Tests", () {
    testWidgets("渲染用户消息文本并支持划词", (WidgetTester tester) async {
      final userMessage = Message(
        id: "msg-1",
        conversationId: "conv-1",
        senderId: "user",
        senderName: "用户",
        role: MessageRole.user,
        content: "这是一条测试长消息",
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: userMessage,
              isUser: true,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("这是一条测试长消息"),
        ),
        findsOneWidget,
      );
      expect(find.byType(SelectionArea), findsOneWidget);
    });

    testWidgets("渲染AI成员流式消息", (WidgetTester tester) async {
      final aiMessage = Message(
        id: "msg-2",
        conversationId: "conv-1",
        senderId: "ai-1",
        senderName: "Claude",
        role: MessageRole.assistant,
        content: "你好！有什么我可以帮你的？",
        isStreaming: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageBubble(
              message: aiMessage,
              isUser: false,
              memberColors: const [Color(0xFFFF6B35), Color(0xFFFF4081)],
            ),
          ),
        ),
      );

      expect(find.text("Claude"), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("你好！有什么我可以帮你的？"),
        ),
        findsOneWidget,
      );
    });
  });

  group("HomePage Indicator Navigation Tests", () {
    testWidgets("用户发送新消息时自动将列表滚动到底部并可见", (WidgetTester tester) async {
      final conv = Conversation(
        id: "test-conv-scroll",
        title: "滚动测试对话",
        memberIds: ["ai-1"],
      );

      conv.messages.addAll([
        Message(
          id: "old-user-1",
          conversationId: "test-conv-scroll",
          senderId: "user",
          senderName: "用户",
          role: MessageRole.user,
          content: "第一条旧提问",
        ),
        Message(
          id: "old-ai-1",
          conversationId: "test-conv-scroll",
          senderId: "ai-1",
          senderName: "AI-1",
          role: MessageRole.assistant,
          content: List.generate(80, (i) => "这是第1段长长长长回复 \$i").join(String.fromCharCode(10) + String.fromCharCode(10)),
        ),
      ]);

      final convProvider = ConversationProvider();
      convProvider.conversations.add(conv);
      convProvider.setActiveConversation(conv.id);

      final memberProvider = MemberProvider();
      memberProvider.members.add(
        Member(
          id: "ai-1",
          name: "Claude",
          aiTool: AiTool.claude,
          accessType: AccessType.anthropic,
          providerUrl: "https://api.anthropic.com",
          apiKey: "test-key",
          modelId: "claude-3-5-sonnet",
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: convProvider),
            ChangeNotifierProvider.value(value: memberProvider),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 先滚动到最顶部（第一条旧提问）
      final firstDot = find.byTooltip("跳转到第 1 条消息: 第一条旧提问");
      expect(firstDot, findsOneWidget);
      await tester.tap(firstDot);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("第一条旧提问"),
        ),
        findsOneWidget,
      );

      // 在输入框输入新消息并点击发送
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, "这是刚刚发送的最新消息");
      await tester.pump();

      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);
      await tester.tap(sendButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // 验证最新发送的消息在视口中可见
      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("这是刚刚发送的最新消息"),
        ),
        findsOneWidget,
      );
    });

    testWidgets("点击用户消息指示器能够正确触发双向跳转并准确定位", (WidgetTester tester) async {
      final conv = Conversation(
        id: "test-conv",
        title: "测试对话",
        memberIds: ["ai-1"],
      );

      conv.messages.addAll([
        Message(
          id: "user-msg-1",
          conversationId: "test-conv",
          senderId: "user",
          senderName: "用户",
          role: MessageRole.user,
          content: "这是第1条用户提问",
        ),
        Message(
          id: "ai-msg-1",
          conversationId: "test-conv",
          senderId: "ai-1",
          senderName: "AI-1",
          role: MessageRole.assistant,
          content: List.generate(120, (i) => "这是超长AI回复段落 \$i，包含了大量的Markdown内容与长文本输出。").join(String.fromCharCode(10) + String.fromCharCode(10)),
        ),
        Message(
          id: "user-msg-2",
          conversationId: "test-conv",
          senderId: "user",
          senderName: "用户",
          role: MessageRole.user,
          content: "这是第2条用户提问",
        ),
        Message(
          id: "ai-msg-2",
          conversationId: "test-conv",
          senderId: "ai-1",
          senderName: "AI-1",
          role: MessageRole.assistant,
          content: List.generate(90, (i) => "这是第2段AI长回复 \$i").join(String.fromCharCode(10) + String.fromCharCode(10)),
        ),
        Message(
          id: "user-msg-3",
          conversationId: "test-conv",
          senderId: "user",
          senderName: "用户",
          role: MessageRole.user,
          content: "这是第3条用户提问",
        ),
      ]);

      final convProvider = ConversationProvider();
      convProvider.conversations.add(conv);
      convProvider.setActiveConversation(conv.id);

      final memberProvider = MemberProvider();
      memberProvider.members.add(
        Member(
          id: "ai-1",
          name: "Claude",
          aiTool: AiTool.claude,
          accessType: AccessType.anthropic,
          providerUrl: "https://api.anthropic.com",
          apiKey: "test-key",
          modelId: "claude-3-5-sonnet",
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: convProvider),
            ChangeNotifierProvider.value(value: memberProvider),
          ],
          child: const MaterialApp(
            home: HomePage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 点击第3个圆点（直接向下跨越2篇巨大长文跳转到第3条）
      final thirdDot = find.byTooltip("跳转到第 3 条消息: 这是第3条用户提问");
      expect(thirdDot, findsOneWidget);

      await tester.tap(thirdDot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("这是第3条用户提问"),
        ),
        findsOneWidget,
      );

      // 2. 点击第1个圆点（向上跨越长文回滚到第1条）
      final firstDot = find.byTooltip("跳转到第 1 条消息: 这是第1条用户提问");
      expect(firstDot, findsOneWidget);

      await tester.tap(firstDot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("这是第1条用户提问"),
        ),
        findsOneWidget,
      );

      // 3. 再次点击第2个圆点
      final secondDot = find.byTooltip("跳转到第 2 条消息: 这是第2条用户提问");
      expect(secondDot, findsOneWidget);

      await tester.tap(secondDot);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(MessageBubble),
          matching: find.text("这是第2条用户提问"),
        ),
        findsOneWidget,
      );
    });
  });
}
