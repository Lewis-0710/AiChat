import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/member.dart';

/// 模型信息
class ModelInfo {
  final String id;
  final String? name;
  final DateTime? created;

  ModelInfo({required this.id, this.name, this.created});
}

/// 模型列表获取服务
class ModelFetcher {
  static final ModelFetcher _instance = ModelFetcher._internal();
  factory ModelFetcher() => _instance;
  ModelFetcher._internal();

  /// 从供应商API获取可用模型列表
  Future<List<ModelInfo>> fetchModels({
    required String providerUrl,
    required String apiKey,
    required AccessType accessType,
  }) async {
    try {
      final url = _buildModelsUrl(providerUrl, accessType);
      final headers = _buildHeaders(apiKey, accessType);

      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode == 200) {
        return _parseModelsResponse(response.body, accessType);
      } else {
        throw Exception('获取模型列表失败: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取模型列表失败: $e');
    }
  }

  String _buildModelsUrl(String providerUrl, AccessType accessType) {
    final baseUrl = providerUrl.endsWith('/') 
        ? providerUrl.substring(0, providerUrl.length - 1) 
        : providerUrl;
    
    switch (accessType) {
      case AccessType.openaiChat:
      case AccessType.openaiResponse:
        return '$baseUrl/models';
      case AccessType.anthropic:
        return '$baseUrl/v1/models';
    }
  }

  Map<String, String> _buildHeaders(String apiKey, AccessType accessType) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    switch (accessType) {
      case AccessType.openaiChat:
      case AccessType.openaiResponse:
        headers['Authorization'] = 'Bearer $apiKey';
        break;
      case AccessType.anthropic:
        headers['x-api-key'] = apiKey;
        headers['anthropic-version'] = '2023-06-01';
        break;
    }

    return headers;
  }

  List<ModelInfo> _parseModelsResponse(String body, AccessType accessType) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final data = json['data'] as List? ?? [];
    
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return ModelInfo(
        id: map['id'] as String,
        name: map['name'] as String? ?? map['id'] as String,
        created: map['created'] != null 
            ? DateTime.fromMillisecondsSinceEpoch((map['created'] as int) * 1000)
            : null,
      );
    }).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  }
}
