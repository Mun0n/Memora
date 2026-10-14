import '../identity/identifiers.dart';
import '../memories/memory_entry.dart';
import '../offline/offline_identifiers.dart';

/// Optional family-authored help card attached to one [ConversationPrompt].
///
/// Zero-or-one per prompt. At least one of [cue] or [memoryId] is required.
/// Content is deterministic caregiver authoring only — never selected from
/// answers, silence or inferred uncertainty.
final class ConversationPromptHelp {
  static const int minCueLength = 1;
  static const int maxCueLength = 160;

  ConversationPromptHelp({String? cue, this.memoryId})
    : cue = _normalizeCue(cue) {
    if (this.cue == null && memoryId == null) {
      throw ArgumentError(
        'help card requires a cue and/or an approved memory reference',
      );
    }
  }

  /// Family-authored contextual cue (trimmed), or null when memory-only.
  final String? cue;

  /// Optional reference to one already-approved family memory.
  final MemoryId? memoryId;

  bool get hasCue => cue != null;

  bool get hasMemoryReference => memoryId != null;

  /// Whether the supported-person help action can be offered.
  ///
  /// Cue-only help stays usable even when a linked memory later disappears.
  /// Memory-only help requires an approved, non-deleted, same-family memory.
  bool isUsable({
    required FamilySpaceId familySpaceId,
    MemoryEntry? resolvedMemory,
  }) {
    if (hasCue) {
      return true;
    }
    final memory = resolvedMemory;
    if (memory == null || memoryId == null) {
      return false;
    }
    return memory.id == memoryId &&
        memory.familySpaceId == familySpaceId &&
        memory.isApprovedForViewing;
  }

  /// Text Memora may speak when help is revealed (cue preferred).
  String? spokenText({String? memoryCaption}) {
    if (cue != null) {
      return cue;
    }
    final caption = memoryCaption?.trim();
    if (caption != null && caption.isNotEmpty) {
      return caption;
    }
    return null;
  }

  ConversationPromptHelp copyWith({
    String? cue,
    bool clearCue = false,
    MemoryId? memoryId,
    bool clearMemoryId = false,
  }) {
    return ConversationPromptHelp(
      cue: clearCue ? null : (cue ?? this.cue),
      memoryId: clearMemoryId ? null : (memoryId ?? this.memoryId),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ConversationPromptHelp &&
      other.cue == cue &&
      other.memoryId == memoryId;

  @override
  int get hashCode => Object.hash(cue, memoryId);

  static String? _normalizeCue(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    if (trimmed.length > maxCueLength) {
      throw ArgumentError.value(
        raw,
        'cue',
        'must be $minCueLength–$maxCueLength characters after trim',
      );
    }
    return trimmed;
  }
}
