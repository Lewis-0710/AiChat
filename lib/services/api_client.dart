import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/member.dart';
import '../models/message.dart';

/// API客户端抽象基类
abstract class ApiClient {
  Future<String> sendMessage({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  });

  Stream<String> sendMessageStream({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  });
}

/// OpenAI Chat API 客户端
class OpenAiChatClient extends ApiClient {
  @override
  Future<String> sendMessage({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async {
    final url = '${member.providerUrl}/chat/completions';
    final messages = _buildMessages(history, userMessage, imageDatas);

    final body = jsonEncode({
      'model': member.modelId,
      'messages': messages,
      'stream': false,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${member.apiKey}',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['choices'][0]['message']['content'] as String;
    } else {
      throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async* {
    final url = '${member.providerUrl}/chat/completions';
    final messages = _buildMessages(history, userMessage, imageDatas);

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${member.apiKey}',
    });
    request.body = jsonEncode({
      'model': member.modelId,
      'messages': messages,
      'stream': true,
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final delta = json['choices'][0]['delta'];
            if (delta != null && delta['content'] != null) {
              yield delta['content'] as String;
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    List<Message> history,
    String userMessage,
    List<String>? imageDatas,
  ) {
    final messages = <Map<String, dynamic>>[];

    for (final msg in history) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': _openAiChatContent(_historyMessageText(msg), msg.imageDatas),
      });
    }

    messages.add({
      'role': 'user',
      'content': _openAiChatContent(userMessage, imageDatas),
    });
    return messages;
  }
}

/// OpenAI Response API 客户端
class OpenAiResponseClient extends ApiClient {
  @override
  Future<String> sendMessage({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async {
    final url = '${member.providerUrl}/responses';
    final input = _buildInput(history, userMessage, imageDatas);

    final body = jsonEncode({'model': member.modelId, 'input': input});

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${member.apiKey}',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _extractOutput(data);
    } else {
      throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async* {
    final url = '${member.providerUrl}/responses';
    final input = _buildInput(history, userMessage, imageDatas);

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${member.apiKey}',
    });
    request.body = jsonEncode({
      'model': member.modelId,
      'input': input,
      'stream': true,
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data == '[DONE]') break;

          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final type = json['type'];
            if (type == 'response.output_text.delta') {
              yield json['delta'] as String;
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> _buildInput(
    List<Message> history,
    String userMessage,
    List<String>? imageDatas,
  ) {
    final input = <Map<String, dynamic>>[];

    for (final msg in history) {
      input.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': _openAiResponseContent(
          _historyMessageText(msg),
          msg.imageDatas,
        ),
      });
    }

    input.add({
      'role': 'user',
      'content': _openAiResponseContent(userMessage, imageDatas),
    });
    return input;
  }

  String _extractOutput(Map<String, dynamic> data) {
    final output = data['output'] as List?;
    if (output == null || output.isEmpty) return '';

    final buffer = StringBuffer();
    for (final item in output) {
      if (item is Map<String, dynamic>) {
        final content = item['content'] as List?;
        if (content != null) {
          for (final c in content) {
            if (c is Map<String, dynamic> && c['type'] == 'output_text') {
              buffer.write(c['text']);
            }
          }
        }
      }
    }
    return buffer.toString();
  }
}

/// Anthropic API 客户端
class AnthropicClient extends ApiClient {
  @override
  Future<String> sendMessage({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async {
    final url = '${member.providerUrl}/v1/messages';
    final messages = _buildMessages(history, userMessage, imageDatas);

    final body = jsonEncode({
      'model': member.modelId,
      'messages': messages,
      'max_tokens': 4096,
    });

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': member.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['content'] as List;
      return content.map((c) => c['text'] as String).join('');
    } else {
      throw Exception('API调用失败: ${response.statusCode} - ${response.body}');
    }
  }

  @override
  Stream<String> sendMessageStream({
    required Member member,
    required List<Message> history,
    required String userMessage,
    List<String>? imageDatas,
  }) async* {
    final url = '${member.providerUrl}/v1/messages';
    final messages = _buildMessages(history, userMessage, imageDatas);

    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'x-api-key': member.apiKey,
      'anthropic-version': '2023-06-01',
    });
    request.body = jsonEncode({
      'model': member.modelId,
      'messages': messages,
      'max_tokens': 4096,
      'stream': true,
    });

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      final stream = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in stream) {
        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            if (json['type'] == 'content_block_delta') {
              final delta = json['delta'];
              if (delta['type'] == 'text_delta') {
                yield delta['text'] as String;
              }
            }
          } catch (_) {}
        }
      }
    } finally {
      client.close();
    }
  }

  List<Map<String, dynamic>> _buildMessages(
    List<Message> history,
    String userMessage,
    List<String>? imageDatas,
  ) {
    final messages = <Map<String, dynamic>>[];

    for (final msg in history) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': _anthropicContent(_historyMessageText(msg), msg.imageDatas),
      });
    }

    messages.add({
      'role': 'user',
      'content': _anthropicContent(userMessage, imageDatas),
    });
    return messages;
  }
}

/// API客户端工厂
class ApiClientFactory {
  static ApiClient create(AccessType accessType) {
    switch (accessType) {
      case AccessType.openaiChat:
        return OpenAiChatClient();
      case AccessType.openaiResponse:
        return OpenAiResponseClient();
      case AccessType.anthropic:
        return AnthropicClient();
    }
  }
}

String _historyMessageText(Message message) {
  if (message.role == MessageRole.user) {
    return '用户说：${message.content}';
  }
  return '${message.senderName} 说：${message.content}';
}

dynamic _openAiChatContent(String text, List<String>? imageDatas) {
  if (imageDatas == null || imageDatas.isEmpty) return text;

  return [
    if (text.isNotEmpty) {'type': 'text', 'text': text},
    for (final imageData in imageDatas)
      {
        'type': 'image_url',
        'image_url': {'url': imageData},
      },
  ];
}

dynamic _openAiResponseContent(String text, List<String>? imageDatas) {
  if (imageDatas == null || imageDatas.isEmpty) return text;

  return [
    if (text.isNotEmpty) {'type': 'input_text', 'text': text},
    for (final imageData in imageDatas)
      {'type': 'input_image', 'image_url': imageData},
  ];
}

dynamic _anthropicContent(String text, List<String>? imageDatas) {
  if (imageDatas == null || imageDatas.isEmpty) return text;

  final content = <Map<String, dynamic>>[
    if (text.isNotEmpty) {'type': 'text', 'text': text},
  ];
  for (final imageData in imageDatas) {
    final commaIndex = imageData.indexOf(',');
    if (commaIndex == -1) continue;

    final header = imageData.substring(5, commaIndex);
    final mediaType = header.split(';').first;
    final base64Data = imageData.substring(commaIndex + 1);
    content.add({
      'type': 'image',
      'source': {'type': 'base64', 'media_type': mediaType, 'data': base64Data},
    });
  }
  return content;
}
