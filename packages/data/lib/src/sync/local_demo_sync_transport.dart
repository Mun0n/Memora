import 'dart:convert';

import 'package:domain/domain.dart';
import 'package:http/http.dart' as http;

import 'local_demo_sync_codec.dart';
import 'local_demo_sync_config.dart';

/// Cross-process [SyncTransportPort] for the local fictional demo server.
///
/// Talks only to an explicit loopback base URL. Never embeds production
/// endpoints or credentials. Response bodies are not logged.
final class LocalDemoSyncTransport implements SyncTransportPort {
  LocalDemoSyncTransport({
    String baseUrl = LocalDemoSyncConfig.defaultBaseUrl,
    http.Client? httpClient,
  }) : baseUrl = _normalizeBaseUrl(baseUrl),
       _client = httpClient ?? http.Client(),
       _ownsClient = httpClient == null;

  final String baseUrl;
  final http.Client _client;
  final bool _ownsClient;

  Uri get _pushUri => Uri.parse('$baseUrl/v1/push');

  void close() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<PushResult> push(SyncEnvelope envelope) async {
    final response = await _client.post(
      _pushUri,
      headers: const {
        'content-type': 'application/json; charset=utf-8',
        'accept': 'application/json',
      },
      body: jsonEncode(LocalDemoSyncCodec.encodeEnvelope(envelope)),
    );
    if (response.statusCode == 403) {
      return PushResult.failed('fictional_family_space_required');
    }
    if (response.statusCode >= 400) {
      return PushResult.failed('local_demo_push_http_${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return PushResult.failed('local_demo_push_bad_body');
    }
    return LocalDemoSyncCodec.decodePushResult(<String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    });
  }

  @override
  Future<List<RemoteRecord>> pull({
    required FamilySpaceId familySpaceId,
    int? afterCursor,
  }) async {
    final query = <String, String>{
      'familySpaceId': familySpaceId.value,
      if (afterCursor != null) 'afterCursor': '$afterCursor',
    };
    final uri = Uri.parse('$baseUrl/v1/pull').replace(queryParameters: query);
    final response = await _client.get(
      uri,
      headers: const {'accept': 'application/json'},
    );
    if (response.statusCode == 403) {
      throw StateError('local demo pull rejected non-fictional family space');
    }
    if (response.statusCode >= 400) {
      throw StateError('local demo pull failed: HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw FormatException('local demo pull body must be an object');
    }
    return LocalDemoSyncCodec.decodePullResponse(<String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    });
  }

  /// Clears the shared demo authority and restores the fictional baseline.
  Future<void> resetRemote() async {
    final response = await _client.post(Uri.parse('$baseUrl/v1/reset'));
    if (response.statusCode >= 400) {
      throw StateError('local demo reset failed: HTTP ${response.statusCode}');
    }
  }

  /// Idempotent server-side baseline ensure (no-op when pastimes already exist).
  Future<bool> ensureRemoteBaseline() async {
    final response = await _client.post(Uri.parse('$baseUrl/v1/bootstrap'));
    if (response.statusCode >= 400) {
      throw StateError(
        'local demo bootstrap failed: HTTP ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return false;
    }
    return decoded['initialized'] == true;
  }

  static String _normalizeBaseUrl(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(raw, 'baseUrl', 'must be non-empty');
    }
    final uri = Uri.parse(trimmed);
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw ArgumentError.value(raw, 'baseUrl', 'must be http(s)');
    }
    if (uri.host != '127.0.0.1' && uri.host != 'localhost') {
      throw ArgumentError.value(
        raw,
        'baseUrl',
        'local demo transport binds to loopback only',
      );
    }
    final withoutSlash = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return withoutSlash;
  }
}
