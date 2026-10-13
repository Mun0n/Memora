import 'dart:convert';
import 'dart:io';

import 'package:domain/domain.dart';

import 'in_memory_sync_authority.dart';
import 'local_demo_fictional_baseline.dart';
import 'local_demo_sync_codec.dart';
import 'local_demo_sync_config.dart';
import 'local_demo_sync_snapshot_store.dart';

/// Loopback-only HTTP demo sync authority for separately running clients.
///
/// Fictional family spaces only. No credentials, no content logging, no hosted
/// Supabase. Durable across process restarts when [snapshotPath] is set.
/// Reset via `POST /v1/reset` (restores the fictional pastime baseline).
final class LocalDemoSyncServer {
  LocalDemoSyncServer._({
    required HttpServer server,
    required this.authority,
    required LocalDemoSyncSnapshotStore? snapshotStore,
    required this.ensureFictionalBaselineWhenEmpty,
  }) : _server = server,
       _snapshotStore = snapshotStore;

  final HttpServer _server;
  final InMemorySyncAuthority authority;
  final LocalDemoSyncSnapshotStore? _snapshotStore;
  final bool ensureFictionalBaselineWhenEmpty;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  String? get snapshotPath => _snapshotStore?.path;

  bool get isDurable => _snapshotStore != null;

  /// Binds to [host]:[port]. Use port `0` for an ephemeral test port.
  ///
  /// When [snapshotPath] is set, the authority is loaded from that file and
  /// persisted after mutations. [ensureFictionalBaselineWhenEmpty] publishes
  /// the documented pastime baseline exactly once when no pastime rows exist.
  static Future<LocalDemoSyncServer> bind({
    String host = LocalDemoSyncConfig.defaultHost,
    int port = LocalDemoSyncConfig.defaultPort,
    InMemorySyncAuthority? authority,
    String? snapshotPath,
    bool ensureFictionalBaselineWhenEmpty = false,
  }) async {
    if (host != '127.0.0.1' && host != 'localhost') {
      throw ArgumentError.value(
        host,
        'host',
        'local demo server must bind to loopback',
      );
    }
    final store = snapshotPath == null
        ? null
        : LocalDemoSyncSnapshotStore(snapshotPath);
    final resolvedAuthority =
        authority ?? store?.load() ?? InMemorySyncAuthority();
    if (ensureFictionalBaselineWhenEmpty) {
      LocalDemoFictionalBaseline.ensureBaseline(resolvedAuthority);
    }
    final httpServer = await HttpServer.bind(host, port);
    final demo = LocalDemoSyncServer._(
      server: httpServer,
      authority: resolvedAuthority,
      snapshotStore: store,
      ensureFictionalBaselineWhenEmpty: ensureFictionalBaselineWhenEmpty,
    );
    if (store != null) {
      await store.save(resolvedAuthority);
    }
    httpServer.listen(demo._handle);
    return demo;
  }

  Future<void> reset() async {
    authority.reset();
    if (ensureFictionalBaselineWhenEmpty) {
      LocalDemoFictionalBaseline.ensureBaseline(authority);
    }
    await _persist();
  }

  Future<void> close() async {
    await _server.close(force: true);
  }

  Future<void> _persist() async {
    final store = _snapshotStore;
    if (store == null) {
      return;
    }
    await store.save(authority);
  }

  Future<void> _handle(HttpRequest request) async {
    _applyCors(request.response);
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    try {
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/v1/health') {
        _writeJson(request.response, HttpStatus.ok, {
          'status': 'ok',
          'mode': 'local_fictional_demo',
          'durable': isDurable,
          'rowCount': authority.rowCount,
          'pastimeBaseline': authority.hasPastimeRowsFor(
            LocalDemoFictionalBaseline.familySpaceId.value,
          ),
          'conversationTopicBaseline': authority.hasConversationTopicRowsFor(
            LocalDemoFictionalBaseline.familySpaceId.value,
          ),
        });
        return;
      }
      if (request.method == 'POST' && path == '/v1/reset') {
        await reset();
        _writeJson(request.response, HttpStatus.ok, {
          'reset': true,
          'baselineRestored': ensureFictionalBaselineWhenEmpty,
        });
        return;
      }
      if (request.method == 'POST' && path == '/v1/bootstrap') {
        final published = LocalDemoFictionalBaseline.ensureBaseline(authority);
        if (published) {
          await _persist();
        }
        _writeJson(request.response, HttpStatus.ok, {
          'initialized': published,
          'pastimeBaseline': true,
          'conversationTopicBaseline': true,
        });
        return;
      }
      if (request.method == 'POST' && path == '/v1/push') {
        await _handlePush(request);
        return;
      }
      if (request.method == 'GET' && path == '/v1/pull') {
        await _handlePull(request);
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } on FormatException {
      request.response.statusCode = HttpStatus.badRequest;
      await request.response.close();
    } on LocalDemoSyncSnapshotException {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    } catch (_) {
      request.response.statusCode = HttpStatus.internalServerError;
      await request.response.close();
    }
  }

  Future<void> _handlePush(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('push body must be an object');
    }
    final envelope = LocalDemoSyncCodec.decodeEnvelope(<String, Object?>{
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    });
    if (!LocalDemoSyncConfig.isAllowedFamilySpaceId(envelope.familySpaceId)) {
      _writeJson(request.response, HttpStatus.forbidden, {
        'error': 'fictional_family_space_required',
      });
      return;
    }
    final result = authority.push(envelope);
    if (result.outcome == PushOutcome.applied ||
        result.outcome == PushOutcome.duplicateIgnored) {
      await _persist();
    }
    _writeJson(
      request.response,
      HttpStatus.ok,
      LocalDemoSyncCodec.encodePushResult(result),
    );
  }

  Future<void> _handlePull(HttpRequest request) async {
    final familySpaceId = request.uri.queryParameters['familySpaceId'];
    if (familySpaceId == null || familySpaceId.trim().isEmpty) {
      throw const FormatException('familySpaceId required');
    }
    if (!LocalDemoSyncConfig.isAllowedFamilySpaceId(familySpaceId)) {
      _writeJson(request.response, HttpStatus.forbidden, {
        'error': 'fictional_family_space_required',
      });
      return;
    }
    final afterRaw = request.uri.queryParameters['afterCursor'];
    final afterCursor = afterRaw == null ? null : int.parse(afterRaw);
    final records = authority.pull(
      familySpaceId: FamilySpaceId(familySpaceId),
      afterCursor: afterCursor,
    );
    _writeJson(
      request.response,
      HttpStatus.ok,
      LocalDemoSyncCodec.encodePullResponse(records),
    );
  }

  static void _applyCors(HttpResponse response) {
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set(
      'Access-Control-Allow-Headers',
      'Content-Type, Accept',
    );
  }

  static void _writeJson(
    HttpResponse response,
    int statusCode,
    Map<String, Object?> body,
  ) {
    response.statusCode = statusCode;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    response.close();
  }
}
