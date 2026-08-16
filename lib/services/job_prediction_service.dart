import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/backend_config.dart';
import '../models/job_prediction_model.dart';

class JobPredictionClientService {
  static final JobPredictionClientService instance = JobPredictionClientService._internal();
  JobPredictionClientService._internal();

  String baseUrl = BackendConfig.baseUrl;

  Future<Map<String, dynamic>> fetchExtractedFeatures(String resumeId) async {
    try {
      final url = Uri.parse('$baseUrl/api/job-prediction/features/$resumeId');
      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Backend fetch features note ($e) - using client fallback features.');
    }

    // Demo / Offline fallback features
    return {
      'resume_id': resumeId,
      'structured_features': {
        'Skills': 'Flutter, Dart, State Management, REST APIs, Git, Node.js',
        'Certifications': 'AWS Certified Developer',
        'Education': 'B.Tech Computer Science',
        'Job Role': 'Senior Flutter Engineer',
        'Experience (Years)': 4.0,
        'Salary Expectation (\$)': 135000.0,
        'Projects Count': 5,
      },
      'tailored_resume_hash': 'demo_hash_987654321',
      'structured_feature_columns': [
        'Skills', 'Certifications', 'Education', 'Job Role',
        'Experience (Years)', 'Salary Expectation (\$)', 'Projects Count'
      ],
    };
  }

  Future<JobPredictionResult> predictJobMatch({
    required String resumeId,
    required String jobDescription,
    String? jobTitle,
    Map<String, dynamic>? structuredFeaturesOverride,
    String? resumeVersionId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/api/job-prediction/predict');
      final body = json.encode({
        'resume_id': resumeId,
        'job_description': jobDescription,
        'job_title': jobTitle,
        'structured_features_override': structuredFeaturesOverride,
        'resume_version_id': resumeVersionId,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return JobPredictionResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Backend prediction service note ($e) - executing client fallback inference.');
    }

    // Client fallback prediction for Demo Mode / Offline
    return _computeFallbackPrediction(
      resumeId: resumeId,
      jobDescription: jobDescription,
      jobTitle: jobTitle,
      featuresOverride: structuredFeaturesOverride,
    );
  }

  Future<JobPredictionResult?> fetchLatestPrediction(String resumeId) async {
    try {
      final url = Uri.parse('$baseUrl/api/job-prediction/latest/$resumeId');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return JobPredictionResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Latest prediction fetch note: $e');
    }
    return null;
  }

  JobPredictionResult _computeFallbackPrediction({
    required String resumeId,
    required String jobDescription,
    String? jobTitle,
    Map<String, dynamic>? featuresOverride,
  }) {
    final feats = featuresOverride ?? {
      'Skills': 'Flutter, Dart, State Management, REST APIs',
      'Certifications': 'AWS Certified Developer',
      'Education': 'B.Tech Computer Science',
      'Job Role': 'Senior Flutter Engineer',
      'Experience (Years)': 4.0,
      'Salary Expectation (\$)': 135000.0,
      'Projects Count': 5,
    };

    final expYears = double.tryParse(feats['Experience (Years)'].toString()) ?? 4.0;
    final skillsStr = feats['Skills'].toString().toLowerCase();

    double structProb = 0.65;
    if (expYears >= 3) structProb += 0.15;
    if (skillsStr.contains('flutter') || skillsStr.contains('python')) structProb += 0.10;
    structProb = structProb.clamp(0.1, 0.95);

    double fitProb = 0.50;
    final jdLower = jobDescription.toLowerCase();
    int matches = 0;
    for (final s in ['flutter', 'dart', 'api', 'state', 'mobile', 'senior']) {
      if (jdLower.contains(s)) matches++;
    }
    fitProb = (0.4 + (matches * 0.08)).clamp(0.2, 0.92);

    final combinedProb = (0.65 * structProb) + (0.35 * fitProb);
    final isMatch = combinedProb >= 0.5;

    String matchLevel = 'Low Model Match';
    if (combinedProb >= 0.75) {
      matchLevel = 'High Model Match';
    } else if (combinedProb >= 0.50) {
      matchLevel = 'Moderate Model Match';
    }

    return JobPredictionResult(
      id: 'pred_${DateTime.now().millisecondsSinceEpoch}',
      resumeId: resumeId,
      jobTitle: jobTitle ?? feats['Job Role'].toString(),
      jobDescription: jobDescription,
      extractedFeatures: feats,
      structuredProbability: double.parse(structProb.toStringAsFixed(4)),
      fitProbability: double.parse(fitProb.toStringAsFixed(4)),
      combinedProbability: double.parse(combinedProb.toStringAsFixed(4)),
      isMatch: isMatch,
      estimatedMatchLevel: matchLevel,
      isStale: false,
      disclaimer: 'Model-estimated probability based on statistical feature match. '
          'This score does not guarantee interview shortlisting or employment outcomes, '
          'nor is it an automated hiring decision.',
      createdAt: DateTime.now(),
    );
  }
}
