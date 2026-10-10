/// Spanish-first, localization-ready copy for Slice 4–5 presentation.
///
/// Values are the default `es` surface. Keys are stable identifiers for a
/// future ARB/`AppLocalizations` migration — do not hardcode English-only
/// critical copy in widgets; use these accessors instead.
abstract final class MemoraCopy {
  static const String localeTag = 'es';

  // Demo / non-production
  static const String demoBanner = 'DEMOSTRACIÓN — NO PRODUCCIÓN';
  static const String demoBannerSemantics =
      'Entorno de demostración, no producción';
  static const String syntheticMarker = 'SYNTHETIC / NON-PRODUCTION';
  static const String noRealData =
      'Sin datos reales. Sin conexión remota de producción.';
  static const String notMedical =
      'Memora no es un servicio médico ni de emergencias.';

  // Sync / recovery (plain language)
  static const String syncLocal = 'Guardado en este dispositivo';
  static const String syncPending = 'Pendiente de sincronizar';
  static const String syncSynced = 'Sincronizado';
  static const String syncConflicted =
      'Hay un conflicto de sincronización. Puedes seguir usando la rutina.';
  static const String syncFailed =
      'No se pudo sincronizar. Los cambios siguen en este dispositivo.';
  static const String stateEmpty = 'No hay rutinas activas para hoy.';
  static const String stateLoading = 'Cargando rutinas…';
  static const String stateOffline =
      'Sin red. Puedes usar las rutinas con normalidad.';
  static const String recoveryRetry = 'Reintentar';
  static const String recoveryContinueOffline = 'Seguir sin red';
  static const String recoveryReviewConflict = 'Revisar conflicto';
  static const String recoveryCreateRoutine = 'Crear rutina Demo';

  // Navigation
  static const String navRoutines = 'Rutinas';
  static const String navMemories = 'Recuerdos';
  static const String navObservations = 'Observaciones';
  static const String navHelp = 'Ayuda';

  // User home
  static const String userHomeTitle = 'Hoy';
  static const String todaysRoutines = 'Rutinas de hoy';
  static const String primaryActionComplete = 'Marcar como hecho';
  static const String primaryActionCorrect = 'Corregir: aún no hecho';
  static const String stepPending = 'Pendiente';
  static const String stepCompleted = 'Hecho';
  static const String noPrimaryAction = 'Todas las tareas de hoy están hechas.';
  static const String nextStepLabel = 'Siguiente paso';

  // Family web configure
  static const String familyHomeTitle = 'Rutinas y recordatorios';
  static const String routinesSection = 'Rutinas';
  static const String remindersSection = 'Recordatorios';
  static const String createRoutine = 'Crear rutina';
  static const String editRoutine = 'Editar rutina';
  static const String saveRoutine = 'Guardar rutina';
  static const String activateRoutine = 'Activar';
  static const String archiveRoutine = 'Archivar';
  static const String moveStepUp = 'Subir paso';
  static const String moveStepDown = 'Bajar paso';
  static const String addStep = 'Añadir paso';
  static const String removeStep = 'Quitar paso';
  static const String routineTitleLabel = 'Título de la rutina';
  static const String stepInstructionLabel = 'Instrucción del paso';
  static const String lifecycleActive = 'Activa';
  static const String lifecycleArchived = 'Archivada';
  static const String createReminder = 'Crear recordatorio';
  static const String editReminder = 'Editar recordatorio';
  static const String saveReminder = 'Guardar recordatorio';
  static const String reminderTitleLabel = 'Título del recordatorio';
  static const String quietHoursLabel = 'Horas de silencio';
  static const String quietHoursHint =
      'Durante estas horas no se muestran avisos de comodidad.';
  static const String reminderConvenienceNotice =
      'Los recordatorios son avisos de comodidad. '
      'No son cobertura de emergencia ni alerta médica.';
  static const String quietStartLabel = 'Inicio (hora local)';
  static const String quietEndLabel = 'Fin (hora local)';

  // Memories
  static const String memoriesTitle = 'Recuerdos de la familia';
  static const String memoriesApprovedTitle = 'Recuerdos';
  static const String memoriesEmpty = 'No hay recuerdos para mostrar.';
  static const String memoriesLoading = 'Cargando recuerdos…';
  static const String memoriesOffline =
      'Sin red. Los recuerdos guardados siguen disponibles.';
  static const String createMemory = 'Crear recuerdo';
  static const String contributeMemory = 'Proponer recuerdo';
  static const String editMemory = 'Editar recuerdo';
  static const String saveMemory = 'Guardar recuerdo';
  static const String approveMemory = 'Aprobar';
  static const String archiveMemory = 'Archivar';
  static const String moveMemoryUp = 'Subir recuerdo';
  static const String moveMemoryDown = 'Bajar recuerdo';
  static const String memoryCaptionLabel = 'Pie de foto / descripción';
  static const String memoryDateContextLabel = 'Contexto de fecha';
  static const String memoryLifecycleProposed = 'Propuesto';
  static const String memoryLifecycleApproved = 'Aprobado';
  static const String memoryLifecycleArchived = 'Archivado';
  static const String mediaStatusLabel = 'Estado del medio';
  static const String mediaFailedPlaceholder =
      'La imagen no está disponible. Puedes seguir con el recuerdo.';
  static const String mediaRetryUpload = 'Reintentar medio';
  static const String continueAfterFailedMedia = 'Seguir viendo recuerdos';
  static const String memoryMediaPathLabel = 'Ruta (familia)';
  static const String memoryMediaChecksumLabel = 'Suma de comprobación';

  // Observations (non-clinical storage only)
  static const String observationsTitle = 'Peso y tensión (registro)';
  static const String observationDisclaimer =
      'Memora no interpreta estos valores. '
      'No es un servicio médico ni de emergencias.';
  static const String weightSection = 'Peso';
  static const String bloodPressureSection = 'Tensión arterial';
  static const String weightValueLabel = 'Peso (kg)';
  static const String systolicLabel = 'Sistólica (mmHg)';
  static const String diastolicLabel = 'Diastólica (mmHg)';
  static const String saveWeight = 'Guardar peso';
  static const String saveBloodPressure = 'Guardar tensión';
  static const String correctObservation = 'Corregir (añadir fila)';
  static const String tombstoneObservation = 'Marcar como retirado';
  static const String observationHistory = 'Historial cronológico';
  static const String observationAuthorLabel = 'Autor';
  static const String observationCorrectionOf = 'Corrección de';
  static const String observationTombstoned = 'Retirado';
  static const String observationsEmpty = 'No hay observaciones registradas.';
  static const String observationsLoading = 'Cargando observaciones…';

  // Help / About
  static const String helpAboutTitle = 'Ayuda y acerca de';
  static const String helpAboutBody =
      'Memora ayuda con rutinas diarias y coordinación familiar. '
      'Usa solo datos de demostración en este entorno.';
  static const String helpAboutDisclaimer =
      'Memora no interpreta valores de peso ni tensión. '
      'No es un servicio médico ni de emergencias.';

  // Shared chrome
  static const String personaPrefix = 'Persona sintética';
}
