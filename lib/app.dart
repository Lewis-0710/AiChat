import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/member_provider.dart';
import 'providers/conversation_provider.dart';
import 'pages/home_page.dart';
import 'theme/app_theme.dart';

/// 应用入口
class AiGroupApp extends StatelessWidget {
  const AiGroupApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MemberProvider()..loadMembers()),
        ChangeNotifierProvider(
          create: (_) => ConversationProvider()..loadConversations(),
        ),
      ],
      child: MaterialApp(
        title: 'AI聊天室',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        // 桌面端默认滚动条会显示滑动指示器，这里统一关闭。
        scrollBehavior: const MaterialScrollBehavior().copyWith(
          scrollbars: false,
        ),
        home: const HomePage(),
      ),
    );
  }
}
