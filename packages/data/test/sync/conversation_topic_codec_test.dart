import 'package:data/data.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  test('Slice 10 prompt maps without help decode unchanged', () {
    final prompt = ConversationTopicCodec.decodePrompt(<String, Object?>{
      'order': 0,
      'text': 'Invitación Slice 10 Demo',
    });
    expect(prompt.order, 0);
    expect(prompt.text, 'Invitación Slice 10 Demo');
    expect(prompt.help, isNull);
  });

  test('round-trips cue and memory help attached to prompt order', () {
    final topic = OfflineFixtures.gardenTalkTopic;
    final payload = ConversationTopicCodec.encodePayload(topic);
    final restored = ConversationTopicCodec.decodeTopic(
      aggregateId: topic.id.value,
      familySpaceId: topic.familySpaceId.value,
      payload: payload,
      version: topic.version,
      tombstoned: false,
      syncState: SyncState.synced,
    );
    expect(restored.prompts[0].help?.cue, topic.prompts[0].help?.cue);
    expect(restored.prompts[1].help, isNull);
    expect(restored.memoryId, topic.memoryId);

    // Conflict-style keep of whole prompts array keeps help glued to order 0.
    final prompts = (payload['prompts'] as List).cast<Map<String, Object?>>();
    expect(prompts[0]['help'], isNotNull);
    expect(prompts[1].containsKey('help'), isFalse);
  });

  test('memory-only help encodes without cue key value', () {
    final help = ConversationPromptHelp(
      memoryId: OfflineFixtures.gardenMemoryId,
    );
    final encoded = ConversationTopicCodec.encodeHelp(help);
    expect(encoded['cue'], isNull);
    expect(encoded['memoryId'], OfflineFixtures.gardenMemoryId.value);
    final decoded = ConversationTopicCodec.decodeHelp(encoded);
    expect(decoded.cue, isNull);
    expect(decoded.memoryId, OfflineFixtures.gardenMemoryId);
  });
}
