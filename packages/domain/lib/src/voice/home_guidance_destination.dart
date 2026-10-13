/// One of the four supported-person home destinations voice guidance may suggest.
///
/// Order matches the stable home grid: Mi día, Pasatiempos, Quiero hablar, Recuerdos.
/// Domain stays UI-free; presentation maps these to navigation tiles.
enum HomeGuidanceDestination {
  /// Routine / current day steps.
  miDia,

  /// Family-configured active pastimes.
  pasatiempos,

  /// Honest talk placeholder (not a working call feature in this slice).
  quieroHablar,

  /// Approved cached family memories.
  recuerdos,
}
