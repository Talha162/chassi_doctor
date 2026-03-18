import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:motorsport/config/api_keys.dart';
import 'package:motorsport/models/adjustment_recommendation.dart';
import 'package:motorsport/models/chassis_issue_option.dart';
import 'package:motorsport/models/chassis_symptom.dart';
import 'package:motorsport/models/track_configuration.dart';

class GeminiService {
  GeminiService({http.Client? client}) : _client = client ?? http.Client();

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
              .map(
                (issue) =>
                    '- ${issue.title}: ${issue.description.isEmpty ? 'No description.' : issue.description}',
              )
              .join('\n');
    final track = trackConfiguration;
    final trackText = track == null
        ? 'No saved track configuration.'
        : 'Track type: ${track.trackType ?? 'Not set'}, '
              'Surface type: ${track.surfaceType ?? 'Not set'}, '
              'Weather: ${track.weatherCondition ?? 'Not set'}.';

    final prompt =
        '''
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

    final uri = Uri.parse('$_endpoint?key=${ApiKeys.geminiApiKey}');
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.3, 'maxOutputTokens': 400},
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

  /// Rank provided recommendations by selecting top K from candidates.
  /// Does NOT invent new recommendations; only ranks and filters the provided ones.
  /// Returns the selected (ranked) recommendations.
  Future<List<AdjustmentRecommendation>> rankRecommendations({
    required ChassisSymptom symptom,
    required List<ChassisIssueOption> issues,
    required TrackConfiguration? trackConfiguration,
    required List<AdjustmentRecommendation> candidates,
    int topK = 4,
  }) async {
    // If we have few candidates, just return them in priority order
    if (candidates.length <= topK) {
      debugPrint(
        '[GEMINI] Skipping Gemini ranking: candidates (${candidates.length}) <= topK ($topK). Using Supabase candidates as-is.',
      );
      return candidates;
    }

    debugPrint(
      '[GEMINI] Ranking ${candidates.length} candidates to select top $topK via Gemini.',
    );

    final issueLines = issues.isEmpty
        ? '- No specific issues selected.'
        : issues
              .map(
                (issue) =>
                    '- ${issue.title}: ${issue.description.isEmpty ? 'No description.' : issue.description}',
              )
              .join('\n');
    final track = trackConfiguration;
    final trackText = track == null
        ? 'No saved track configuration.'
        : 'Track type: ${track.trackType ?? 'Not set'}, '
              'Surface type: ${track.surfaceType ?? 'Not set'}, '
              'Weather: ${track.weatherCondition ?? 'Not set'}.';

    // Build candidate list for Gemini
    final candidateList = candidates
        .asMap()
        .entries
        .map((e) {
          final rec = e.value;
          return '${e.key + 1}. ID: ${rec.id ?? 'N/A'} | Title: ${rec.title} | Details: ${rec.details}';
        })
        .join('\n');

    final prompt =
        '''
You are a race setup expert. Given a list of adjustment recommendations that apply to the selected symptom and issues, select the top $topK most relevant and important ones to present to the user.

CRITICAL CONSTRAINT: You MUST ONLY select from the provided candidates below. DO NOT invent or suggest any new recommendations that are not in the list.

Selected symptom:
- ${symptom.title}: ${symptom.description.isEmpty ? 'No description.' : symptom.description}

Selected issues:
$issueLines

Current track configuration:
$trackText

Available candidates (select $topK of these):
$candidateList

Return ONLY valid JSON with this exact structure:
{"selected":[{"id":"<id_from_candidate>","title":"<title_from_candidate>","reason":"<short_reason_why_it_applies>"}]}

Make sure the IDs and titles match exactly from the candidates list above. Select the $topK most critical adjustments for this specific symptom and issues combination.
''';

    final uri = Uri.parse('$_endpoint?key=${ApiKeys.geminiApiKey}');
    final body = jsonEncode({
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {'temperature': 0.2, 'maxOutputTokens': 400},
    });

    try {
      debugPrint('[GEMINI] Sending ranking request to Gemini API...');
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Gemini ranking failed: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final resContent = data['candidates'] as List?;
      if (resContent == null || resContent.isEmpty) {
        throw Exception('No ranking response returned.');
      }
      final content = resContent.first['content'] as Map?;
      final parts = content?['parts'] as List?;
      final text = parts != null && parts.isNotEmpty
          ? parts.first['text']
          : null;
      if (text is! String || text.trim().isEmpty) {
        throw Exception('Ranking response was empty.');
      }

      final rankedRecs = _parseRankingResponse(text, candidates);
      debugPrint(
        '[GEMINI] Successfully ranked recommendations from Supabase candidates.',
      );
      for (final rec in rankedRecs) {
        debugPrint('  - [From Supabase] ${rec.title} (id: ${rec.id})');
      }
      return rankedRecs;
    } catch (e) {
      // Fallback: return top K by priority order
      debugPrint(
        '[GEMINI] Ranking failed: $e. Falling back to top $topK by priority order.',
      );
      final fallback = candidates.take(topK).toList();
      for (final rec in fallback) {
        debugPrint('  - [Fallback] ${rec.title} (id: ${rec.id})');
      }
      return fallback;
    }
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

  /// Parse the ranking response and return selected recommendations from candidates.
  List<AdjustmentRecommendation> _parseRankingResponse(
    String text,
    List<AdjustmentRecommendation> candidates,
  ) {
    try {
      final cleaned = _stripCodeFences(text);
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final selected = decoded['selected'] as List?;
      if (selected == null) {
        throw const FormatException('Missing selected list');
      }

      final results = <AdjustmentRecommendation>[];
      for (final item in selected) {
        final id = item['id'] as String?;
        // Find matching candidate by id
        final candidate = candidates.firstWhere(
          (c) => c.id == id,
          orElse: () => AdjustmentRecommendation(
            title: item['title'] as String? ?? 'Adjustment',
            details: '',
          ),
        );
        if (candidate.title.trim().isNotEmpty) {
          results.add(candidate);
        }
      }
      return results.isNotEmpty ? results : candidates.take(4).toList();
    } catch (_) {
      // Fallback: return first 4 candidates
      return candidates.take(4).toList();
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
