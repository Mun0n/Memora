/// Deterministic intent classes for Spanish-first home guidance matching.
///
/// Matching is rule/fixture based — never probabilistic or generative.
enum VoiceIntentClass {
  /// Routine / now / what the person has to do → Mi día.
  routineNow,

  /// Activity / entertainment / something to do → Pasatiempos when available.
  activity,

  /// Photographs / family memories / familiar moments → Recuerdos when available.
  memories,

  /// Explicit talk or call request → Quiero hablar with honest placeholder wording.
  explicitTalk,

  /// Generic help choosing (`No sé qué hacer` class) → priority chain.
  genericHelp,

  /// Unsupported or unclear — no destination guess.
  unclear,

  /// Medical, danger or emergency language — fixed limitation notice only.
  safetySensitive,
}
