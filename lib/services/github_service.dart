import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Data model representing a GitHub repository summary.
class GitHubRepo {
  final String name;
  final String fullName;
  final String description;
  final String htmlUrl;
  final List<String> topics;
  final String language;
  final int stargazersCount;
  final int forksCount;
  final String owner;

  const GitHubRepo({
    required this.name,
    required this.fullName,
    required this.description,
    required this.htmlUrl,
    required this.topics,
    required this.language,
    required this.stargazersCount,
    required this.forksCount,
    required this.owner,
  });

  factory GitHubRepo.fromJson(Map<String, dynamic> json) {
    final ownerObj = json['owner'];
    final ownerName = ownerObj is Map<String, dynamic>
        ? (ownerObj['login']?.toString() ?? '')
        : '';

    final rawTopics = json['topics'];
    final topicsList = rawTopics is List
        ? rawTopics.map((e) => e.toString()).toList()
        : <String>[];

    return GitHubRepo(
      name: json['name']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      htmlUrl: json['html_url']?.toString() ?? '',
      topics: topicsList,
      language: json['language']?.toString() ?? '',
      stargazersCount: (json['stargazers_count'] as num?)?.toInt() ?? 0,
      forksCount: (json['forks_count'] as num?)?.toInt() ?? 0,
      owner: ownerName,
    );
  }
}

/// Service to interact with public GitHub API for user repos and metadata.
class GitHubService {
  static final GitHubService instance = GitHubService._internal();
  GitHubService._internal();

  /// Extract GitHub username from full URL or return clean username.
  String? parseGithubUsername(String input) {
    if (input.trim().isEmpty) return null;
    var clean = input.trim();
    clean = clean.replaceAll(RegExp(r'^https?:\/\/(www\.)?github\.com\/'), '');
    clean = clean.replaceAll(RegExp(r'^github\.com\/'), '');
    clean = clean.replaceAll(RegExp(r'^@'), '');
    final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return null;
  }

  /// Parse owner and repository name from GitHub URL or string.
  /// Example: "https://github.com/owner/repo" -> MapEntry("owner", "repo")
  MapEntry<String, String>? parseGithubUrl(String rawUrl) {
    if (rawUrl.trim().isEmpty) return null;
    var clean = rawUrl.trim();
    if (clean.contains('://') && !clean.contains('github.com')) {
      return null;
    }
    clean = clean.replaceAll(RegExp(r'^https?:\/\/(www\.)?github\.com\/', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'^(www\.)?github\.com\/', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'\.git\/?$', caseSensitive: false), '');
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    final parts = clean.split('/').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return MapEntry(parts[0], parts[1]);
    }
    return null;
  }


  /// Fetch public repositories for a GitHub username.
  Future<List<GitHubRepo>> fetchUserRepositories(String username) async {
    final clean = username.trim().replaceAll('@', '');
    if (clean.isEmpty) return [];

    final url = Uri.parse('https://api.github.com/users/$clean/repos?sort=updated&per_page=100');
    try {
      final res = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        return data.map((json) => GitHubRepo.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        debugPrint('[GitHubService] fetchUserRepositories status ${res.statusCode}: ${res.body}');
        throw Exception('GitHub user "$clean" not found or rate limit reached.');
      }
    } catch (e) {
      debugPrint('[GitHubService] Error fetching repos for $clean: $e');
      rethrow;
    }
  }

  /// Fetch single repository details.
  Future<GitHubRepo?> fetchRepositoryDetails(String owner, String repo) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo');
    try {
      final res = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});
      if (res.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(res.body);
        return GitHubRepo.fromJson(data);
      }
    } catch (e) {
      debugPrint('[GitHubService] Error fetching repo details ($owner/$repo): $e');
    }
    return null;
  }

  /// Fetch raw README markdown content for a repository.
  Future<String?> fetchRepositoryReadme(String owner, String repo) async {
    final url = Uri.parse('https://api.github.com/repos/$owner/$repo/readme');
    try {
      final res = await http.get(url, headers: {'Accept': 'application/vnd.github.v3.raw'});
      if (res.statusCode == 200) {
        return res.body;
      }
      // Fallback with JSON response containing base64 content
      final jsonRes = await http.get(url, headers: {'Accept': 'application/vnd.github.v3+json'});
      if (jsonRes.statusCode == 200) {
        final data = jsonDecode(jsonRes.body) as Map<String, dynamic>;
        final rawBase64 = data['content']?.toString().replaceAll('\n', '').replaceAll('\r', '') ?? '';
        if (rawBase64.isNotEmpty) {
          return utf8.decode(base64.decode(rawBase64));
        }
      }
    } catch (e) {
      debugPrint('[GitHubService] Error fetching readme ($owner/$repo): $e');
    }
    return null;
  }
}
