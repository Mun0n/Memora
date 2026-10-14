import 'package:domain/domain.dart';

/// Encode/decode conversation-topic sync payloads (topic + prompts + help).
///
/// Slice 10 records without `help` decode unchanged. Conflict resolution keeps
/// the whole prompts array as one aggregate so a help card cannot move prompts.
abstract final class ConversationTopicCodec {
  static Map<String, Object?> encodePayload(ConversationTopic topic) {
    return <String, Object?>{
      'title': topic.title,
      'introduction': topic.introduction,
      'prompts': topic.prompts.map(encodePrompt).toList(growable: false),
      'closing': topic.closing,
      'displayOrder': topic.displayOrder,
      'lifecycle': topic.lifecycleStatus.wireName,
      'memoryId': topic.memoryId?.value,
      'tombstoned': topic.isDeleted,
      'version': topic.version.value,
    };
  }

  static Map<String, Object?> encodePrompt(ConversationPrompt prompt) {
    final map = <String, Object?>{'order': prompt.order, 'text': prompt.text};
    final help = prompt.help;
    if (help != null) {
      map['help'] = encodeHelp(help);
    }
    return map;
  }

  static Map<String, Object?> encodeHelp(ConversationPromptHelp help) {
    return <String, Object?>{'cue': help.cue, 'memoryId': help.memoryId?.value};
  }

  static ConversationPrompt decodePrompt(Map<String, Object?> map) {
    final rawHelp = map['help'];
    return ConversationPrompt(
      order: map['order']! as int,
      text: map['text']! as String,
      help: rawHelp == null
          ? null
          : decodeHelp(Map<String, Object?>.from(rawHelp as Map)),
    );
  }

  static ConversationPromptHelp decodeHelp(Map<String, Object?> map) {
    final memoryRaw = map['memoryId'] as String?;
    return ConversationPromptHelp(
      cue: map['cue'] as String?,
      memoryId: memoryRaw == null ? null : MemoryId(memoryRaw),
    );
  }

  static ConversationTopic decodeTopic({
    required String aggregateId,
    required String familySpaceId,
    required Map<String, Object?> payload,
    required AggregateVersion version,
    required bool tombstoned,
    required SyncState syncState,
  }) {
    final rawPrompts = payload['prompts'] as List<dynamic>? ?? const [];
    final prompts = rawPrompts.map((raw) {
      return decodePrompt(Map<String, Object?>.from(raw as Map));
    }).toList();
    final memoryRaw = payload['memoryId'] as String?;
    return ConversationTopic(
      id: ConversationTopicId(aggregateId),
      familySpaceId: FamilySpaceId(familySpaceId),
      title: payload['title']! as String,
      introduction: payload['introduction']! as String,
      prompts: prompts,
      closing: payload['closing']! as String,
      displayOrder: payload['displayOrder'] as int? ?? 0,
      lifecycleStatus: ConversationTopicLifecycleStatus.parse(
        payload['lifecycle'] as String? ?? 'draft',
      ),
      version: version,
      syncState: syncState,
      memoryId: memoryRaw == null ? null : MemoryId(memoryRaw),
      tombstone: tombstoned
          ? Tombstone(
              aggregateId: aggregateId,
              version: version,
              deletedAt: DateTime.now().toUtc(),
            )
          : null,
    );
  }
}
