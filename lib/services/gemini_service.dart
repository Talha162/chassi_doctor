import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/models/track_configuration.dart';

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey =
      'AIzaSyAZUFsCI8oYV0ZZAKtICt5vw701DsR7vJs';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final http.Client _client;

  Future<List<AdjustmentRecommendation>> getRecommendations({
    required ChassisSymptom symptom,
    required List<ChassisIssueOption> issues,
    required TrackConfiguration? trackConfiguration,
  }) async {
    final issueLines = issues.isEmpty
        ? '- No specific issues selected.'
        : issues
            .map((issue) =>
                '- ${issue.title}: ${issue.description.isEmpty ? 'No description.' : issue.description}')
            .join('\n');
    final track = trackConfiguration;
    final trackText = track == null
        ? 'No saved track configuration.'
        : 'Track type: ${track.trackType ?? 'Not set'}, '
            'Surface type: ${track.surfaceType ?? 'Not set'}, '
            'Weather: ${track.weatherCondition ?? 'Not set'}.';

    final prompt = '''
You are a race setup expert. Based on the selected issues and the current track configuration, provide concise recommended adjustments.
Return ONLY valid JSON with this exact structure:
{"recommendations":[{"title":"...","details":"...","category":"..."}]}

Selected symptom:
- ${symptom.title}: ${symptom.description.isEmpty ? 'No description.' : symptom.description}

Selected issues:
$issueLines

Current track configuration:
$trackText
''';

    final uri = Uri.parse('$_endpoint?key=$_apiKey');
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ],
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 400,
      },
    });

    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini request failed: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No recommendations returned.');
    }
    final content = candidates.first['content'] as Map?;
    final parts = content?['parts'] as List?;
    final text = parts != null && parts.isNotEmpty ? parts.first['text'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw Exception('Gemini response was empty.');
    }

    return _parseRecommendations(text);
  }

  List<AdjustmentRecommendation> _parseRecommendations(String text) {
    final cleaned = _stripCodeFences(text);
    try {
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final list = decoded['recommendations'] as List?;
      if (list == null) {
        throw const FormatException('Missing recommendations list');
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(AdjustmentRecommendation.fromJson)
          .where((rec) => rec.title.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [
        AdjustmentRecommendation(
          title: 'Recommended Adjustments',
          details: text.trim(),
          category: null,
        ),
      ];
    }
  }

  String _stripCodeFences(String text) {
    final trimmed = text.trim();
    if (trimmed.startsWith('```')) {
      final lines = trimmed.split('\n');
      if (lines.length >= 3) {
        return lines.sublist(1, lines.length - 1).join('\n').trim();
      }
    }
    return trimmed;
  }
}
